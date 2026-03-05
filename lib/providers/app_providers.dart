import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/git_commit.dart';
import '../models/changed_file.dart';
import '../services/git_service.dart';
import '../services/export_service.dart';
import '../services/settings_service.dart';

// ─── Services ───────────────────────────────────────────────

final gitServiceProvider = Provider<GitService>((ref) => GitService());
final exportServiceProvider = Provider<ExportService>((ref) => ExportService());
final settingsServiceProvider = Provider<SettingsService>((ref) {
  throw UnimplementedError('Must be overridden in main.dart');
});

// ─── Step 1: Project Path ───────────────────────────────────

final projectPathProvider = StateProvider<String?>((ref) => null);

// ─── Step 2: Commits ────────────────────────────────────────

final commitsProvider = FutureProvider<List<GitCommit>>((ref) async {
  final path = ref.watch(projectPathProvider);
  if (path == null) return [];

  final gitService = ref.read(gitServiceProvider);
  return gitService.getCommits(path, limit: 100);
});

final selectedCommitHashesProvider = StateProvider<Set<String>>((ref) => {});

// ─── Step 3: Changed Files ──────────────────────────────────

final changedFilesProvider = FutureProvider<List<ChangedFile>>((ref) async {
  final path = ref.watch(projectPathProvider);
  final selectedHashes = ref.watch(selectedCommitHashesProvider);

  if (path == null || selectedHashes.isEmpty) return [];

  final gitService = ref.read(gitServiceProvider);
  return gitService.getChangedFiles(path, selectedHashes.toList());
});

// ─── Step 4: Export ─────────────────────────────────────────

enum ExportStatus { idle, picking, exporting, success, error }

class ExportState {
  final ExportStatus status;
  final String? destinationPath;
  final double progress;
  final ExportResult? result;
  final String? errorMessage;

  const ExportState({
    this.status = ExportStatus.idle,
    this.destinationPath,
    this.progress = 0.0,
    this.result,
    this.errorMessage,
  });

  ExportState copyWith({
    ExportStatus? status,
    String? destinationPath,
    double? progress,
    ExportResult? result,
    String? errorMessage,
  }) {
    return ExportState(
      status: status ?? this.status,
      destinationPath: destinationPath ?? this.destinationPath,
      progress: progress ?? this.progress,
      result: result ?? this.result,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class ExportNotifier extends StateNotifier<ExportState> {
  final Ref ref;

  ExportNotifier(this.ref) : super(const ExportState()) {
    // Auto-load saved export path
    final settings = ref.read(settingsServiceProvider);
    final savedPath = settings.exportPath;
    if (savedPath != null) {
      state = state.copyWith(destinationPath: savedPath);
    }
  }

  void setDestinationPath(String path) {
    state = state.copyWith(destinationPath: path, status: ExportStatus.idle);
    // Persist the export path
    ref.read(settingsServiceProvider).setExportPath(path);
  }

  Future<void> startExport() async {
    final projectPath = ref.read(projectPathProvider);
    final changedFiles = ref.read(changedFilesProvider).valueOrNull;

    if (projectPath == null ||
        state.destinationPath == null ||
        changedFiles == null ||
        changedFiles.isEmpty) {
      state = state.copyWith(
        status: ExportStatus.error,
        errorMessage:
            'Missing project path, destination, or no files to export.',
      );
      return;
    }

    state = state.copyWith(status: ExportStatus.exporting, progress: 0.0);

    try {
      final exportService = ref.read(exportServiceProvider);
      final result = await exportService.exportFiles(
        sourcePath: projectPath,
        destinationPath: state.destinationPath!,
        files: changedFiles,
        onProgress: (current, total) {
          state = state.copyWith(progress: current / total);
        },
      );

      state = state.copyWith(
        status: result.hasErrors ? ExportStatus.error : ExportStatus.success,
        result: result,
        progress: 1.0,
        errorMessage: result.hasErrors ? result.errors.join('\n') : null,
      );
    } catch (e) {
      state = state.copyWith(
        status: ExportStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void reset() {
    state = const ExportState();
  }
}

final exportProvider = StateNotifierProvider<ExportNotifier, ExportState>((
  ref,
) {
  return ExportNotifier(ref);
});

// ─── Stepper ────────────────────────────────────────────────

final currentStepProvider = StateProvider<int>((ref) => 0);
