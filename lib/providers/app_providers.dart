import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/git_commit.dart';
import '../models/changed_file.dart';
import '../models/build_config.dart';
import '../services/git_service.dart';
import '../services/export_service.dart';
import '../services/build_service.dart';
import '../services/settings_service.dart';

// ─── Services ───────────────────────────────────────────────

final gitServiceProvider = Provider<GitService>((ref) => GitService());
final exportServiceProvider = Provider<ExportService>((ref) => ExportService());
final buildServiceProvider = Provider<BuildService>((ref) => BuildService());
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

// ─── Step 4: Build Config ───────────────────────────────────

final buildConfigProvider = StateNotifierProvider<BuildConfigNotifier, BuildConfig>((ref) {
  final notifier = BuildConfigNotifier(ref);
  ref.listen(projectPathProvider, (_, next) {
    if (next != null) {
      notifier.loadForProject(next);
    }
  });
  return notifier;
});

class BuildConfigNotifier extends StateNotifier<BuildConfig> {
  final Ref ref;

  BuildConfigNotifier(this.ref) : super(const BuildConfig()) {
    final projectPath = ref.read(projectPathProvider);
    if (projectPath != null) {
      final saved = ref.read(settingsServiceProvider).getBuildConfig(projectPath);
      if (saved != null) state = saved;
    }
  }

  void loadForProject(String projectPath) {
    final saved = ref.read(settingsServiceProvider).getBuildConfig(projectPath);
    state = saved ?? const BuildConfig();
  }

  void update(BuildConfig config) {
    state = config;
    final projectPath = ref.read(projectPathProvider);
    if (projectPath != null) {
      ref.read(settingsServiceProvider).setBuildConfig(projectPath, config);
    }
  }

  void toggleEnabled() => update(state.copyWith(enabled: !state.enabled));
  void toggleCollectstatic() => update(state.copyWith(runCollectstatic: !state.runCollectstatic));

  void setFrontendDir(String v) => update(state.copyWith(frontendDir: v));
  void setFrontendCommand(String v) => update(state.copyWith(frontendCommand: v));
  void setDistFolder(String v) => update(state.copyWith(distFolder: v));
  void setBackendDir(String v) => update(state.copyWith(backendDir: v));
  void setCollectstaticCommand(String v) => update(state.copyWith(collectstaticCommand: v));
}

// ─── Step 5: Export ─────────────────────────────────────────

enum ExportStatus { idle, picking, exporting, success, error }

class ExportState {
  final ExportStatus status;
  final String? destinationPath;
  final double progress;
  final ExportResult? result;
  final String? errorMessage;
  final String? buildOutput;

  const ExportState({
    this.status = ExportStatus.idle,
    this.destinationPath,
    this.progress = 0.0,
    this.result,
    this.errorMessage,
    this.buildOutput,
  });

  ExportState copyWith({
    ExportStatus? status,
    String? destinationPath,
    double? progress,
    ExportResult? result,
    String? errorMessage,
    String? buildOutput,
  }) {
    return ExportState(
      status: status ?? this.status,
      destinationPath: destinationPath ?? this.destinationPath,
      progress: progress ?? this.progress,
      result: result ?? this.result,
      errorMessage: errorMessage ?? this.errorMessage,
      buildOutput: buildOutput ?? this.buildOutput,
    );
  }
}

class ExportNotifier extends StateNotifier<ExportState> {
  final Ref ref;

  ExportNotifier(this.ref) : super(const ExportState()) {
    final settings = ref.read(settingsServiceProvider);
    final savedPath = settings.exportPath;
    if (savedPath != null) {
      state = state.copyWith(destinationPath: savedPath);
    }
  }

  void setDestinationPath(String path) {
    state = state.copyWith(destinationPath: path, status: ExportStatus.idle);
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
      final buildConfig = ref.read(buildConfigProvider);
      final buildService = ref.read(buildServiceProvider);
      final exportService = ref.read(exportServiceProvider);
      final dest = state.destinationPath!;
      final outputLines = <String>[];

      // ── Build step ──────────────────────────────────────────
      if (buildConfig.enabled) {
        outputLines.add('> cd ${buildConfig.frontendDir.isNotEmpty ? buildConfig.frontendDir : '.'}');
        outputLines.add('> ${buildConfig.frontendCommand}');

        final buildResult = await buildService.runFrontendBuild(
          projectPath, buildConfig,
        );
        if (buildResult.success) {
          outputLines.add('✓ Frontend build OK');
        } else {
          outputLines.add('✗ Frontend build FAILED');
        }
        if (buildResult.output.isNotEmpty) {
          final lines = buildResult.output.split('\n');
          outputLines.addAll(lines.take(10));
          if (lines.length > 10) outputLines.add('... (${lines.length - 10} more lines)');
        }
        if (buildResult.error != null) {
          outputLines.add('  → ${buildResult.error}');
        }

        if (buildResult.success) {
          final distSource = '$projectPath/${buildConfig.distFolder}';
          final resolvedDist = buildConfig.frontendDir.isNotEmpty
              ? '$projectPath/${buildConfig.frontendDir}/${buildConfig.distFolder}'
              : distSource;
          final actualDist = Directory(resolvedDist).existsSync() ? resolvedDist : distSource;
          await buildService.copyFolderContents(
            sourcePath: actualDist,
            destPath: '$dest/static/${buildConfig.distFolder}',
          );
          outputLines.add('  → Copied ${buildConfig.distFolder}/ → static/${buildConfig.distFolder}/');
        }

        if (buildConfig.runCollectstatic) {
          outputLines.add('');
          outputLines.add('> cd ${buildConfig.backendDir.isNotEmpty ? buildConfig.backendDir : '.'}');
          outputLines.add('> ${buildConfig.collectstaticCommand}');

          final csResult = await buildService.runCollectstatic(
            projectPath, buildConfig,
          );
          if (csResult.success) {
            outputLines.add('✓ Collectstatic OK');
          } else {
            outputLines.add('✗ Collectstatic FAILED');
          }
          if (csResult.output.isNotEmpty) {
            final lines = csResult.output.split('\n');
            outputLines.addAll(lines.take(10));
            if (lines.length > 10) outputLines.add('... (${lines.length - 10} more lines)');
          }
          if (csResult.error != null) {
            outputLines.add('  → ${csResult.error}');
          }

          if (csResult.success) {
            final csSource = buildConfig.backendDir.isNotEmpty
                ? '$projectPath/${buildConfig.backendDir}/collected'
                : '$projectPath/collected';
            await buildService.copyFolderContents(
              sourcePath: csSource,
              destPath: '$dest/static/collected',
            );
            outputLines.add('  → Copied collected/ to static/collected/');
          } else {
            outputLines.add('  → Error: ${csResult.error}');
          }
        }
      }

      // ── File export ─────────────────────────────────────────
      final totalPhases = (buildConfig.enabled ? 1 : 0) + 1;
      int completedPhases = 1;
      if (buildConfig.enabled) completedPhases = 2;

      final result = await exportService.exportFiles(
        sourcePath: projectPath,
        destinationPath: dest,
        files: changedFiles,
        onProgress: (current, total) {
          final fileProgress = current / total;
          final overall = (completedPhases - 1 + fileProgress) / totalPhases;
          state = state.copyWith(progress: overall.clamp(0.0, 1.0));
        },
      );

      final buildLog = outputLines.join('\n');

      state = state.copyWith(
        status: result.hasErrors ? ExportStatus.error : ExportStatus.success,
        result: result,
        progress: 1.0,
        errorMessage: result.hasErrors ? result.errors.join('\n') : null,
        buildOutput: buildLog.isNotEmpty ? buildLog : null,
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
