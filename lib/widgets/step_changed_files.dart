import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_providers.dart';
import '../models/changed_file.dart';
import 'diff_viewer_dialog.dart';

class StepChangedFiles extends ConsumerStatefulWidget {
  const StepChangedFiles({super.key});

  @override
  ConsumerState<StepChangedFiles> createState() => _StepChangedFilesState();
}

class _StepChangedFilesState extends ConsumerState<StepChangedFiles> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final filesAsync = ref.watch(changedFilesProvider);
    final selectedHashes = ref.watch(selectedCommitHashesProvider);

    return Column(
      children: [
        _buildHeader(colors, filesAsync, selectedHashes),
        Expanded(
          child: filesAsync.when(
            loading: () => _loading(colors),
            error: (e, _) => _error(colors, e),
            data: (files) {
              if (files.isEmpty) return _empty(colors);
              final filtered = _searchQuery.isEmpty
                  ? files
                  : files
                        .where(
                          (f) => f.relativePath.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ),
                        )
                        .toList();
              return _fileList(colors, filtered);
            },
          ),
        ),
        _buildBottom(colors, filesAsync),
      ],
    );
  }

  Widget _buildHeader(ColorScheme c, AsyncValue<List<ChangedFile>> av, Set<String> sel) {
    final files = av.valueOrNull ?? [];
    final count = files.length;
    final addedCount = files.where((f) => f.isAdded).length;
    final modifiedCount = files.where((f) => f.isModified).length;
    final deletedCount = files.where((f) => f.isDeleted).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 8),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.compare_arrows_rounded, size: 20, color: c.primary),
              const SizedBox(width: 10),
              Text(
                'Changed Files',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: c.onSurface,
                ),
              ),
              const SizedBox(width: 12),
              if (count > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: c.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$count total',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: c.primary,
                    ),
                  ),
                ),
                if (addedCount > 0) ...[
                  const SizedBox(width: 6),
                  _buildCountPill(
                    label: '$addedCount added',
                    color: Colors.green,
                    icon: Icons.add_circle_outline_rounded,
                  ),
                ],
                if (modifiedCount > 0) ...[
                  const SizedBox(width: 6),
                  _buildCountPill(
                    label: '$modifiedCount modified',
                    color: Colors.blue,
                    icon: Icons.edit_note_rounded,
                  ),
                ],
                if (deletedCount > 0) ...[
                  const SizedBox(width: 6),
                  _buildCountPill(
                    label: '$deletedCount deleted',
                    color: Colors.red,
                    icon: Icons.remove_circle_outline_rounded,
                  ),
                ],
              ],
              const Spacer(),
              Text(
                '${sel.length} commit(s)',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: c.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
          if (count > 0) ...[
            const SizedBox(height: 12),
            TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search files...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 13,
                  color: c.onSurface.withValues(alpha: 0.3),
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: c.onSurface.withValues(alpha: 0.3),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                isDense: true,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCountPill({
    required String label,
    required MaterialColor color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color.shade300),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color.shade300,
            ),
          ),
        ],
      ),
    );
  }

  Widget _loading(ColorScheme c) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(strokeWidth: 3, color: c.primary),
        ),
        const SizedBox(height: 16),
        Text(
          'Analyzing changed files...',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: c.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    ),
  );

  Widget _error(ColorScheme c, Object e) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to get changed files',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: c.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            e.toString(),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: c.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _empty(ColorScheme c) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.check_circle_outline_rounded,
          size: 48,
          color: c.onSurface.withValues(alpha: 0.25),
        ),
        const SizedBox(height: 16),
        Text(
          'No changed files found',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: c.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    ),
  );

  Widget _fileList(ColorScheme c, List<ChangedFile> files) {
    if (files.isEmpty && _searchQuery.isNotEmpty) {
      return Center(
        child: Text(
          'No files matching "$_searchQuery"',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: c.onSurface.withValues(alpha: 0.4),
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 4),
      itemCount: files.length,
      itemBuilder: (ctx, i) => _FileTile(
        file: files[i], 
        index: i,
        onTap: () => _openDiff(files[i].relativePath),
      ),
    );
  }

  void _openDiff(String filePath) {
    final projectPath = ref.read(projectPathProvider);
    final selectedHashes = ref.read(selectedCommitHashesProvider);
    final allCommits = ref.read(commitsProvider).valueOrNull ?? [];

    if (projectPath == null || selectedHashes.isEmpty || allCommits.isEmpty) return;

    final selectedCommits = allCommits.where((c) => selectedHashes.contains(c.hash)).toList();
    if (selectedCommits.isEmpty) return;
    
    selectedCommits.sort((a, b) => a.date.compareTo(b.date));

    final oldestHash = selectedCommits.first.hash;
    final newestHash = selectedCommits.last.hash;

    showDialog(
      context: context,
      builder: (ctx) => DiffViewerDialog(
        projectPath: projectPath,
        filePath: filePath,
        oldestHash: oldestHash,
        newestHash: newestHash,
      ),
    );
  }

  Widget _buildBottom(ColorScheme c, AsyncValue av) {
    final hasFiles = (av.valueOrNull ?? []).isNotEmpty;
    final isBuildEnabled = ref.watch(buildConfigProvider).enabled;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(
          top: BorderSide(color: c.onSurface.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: () => ref.read(currentStepProvider.notifier).state = 1,
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text('Back'),
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: hasFiles
                ? () => ref.read(currentStepProvider.notifier).state = 3
                : null,
            icon: Icon(
              isBuildEnabled
                  ? Icons.construction_rounded
                  : Icons.rocket_launch_rounded,
              size: 18,
            ),
            label: Text(
              isBuildEnabled ? 'Configure Build' : 'Proceed to Export',
            ),
          ),
        ],
      ),
    );
  }
}

class _FileTile extends StatelessWidget {
  final ChangedFile file;
  final int index;
  final VoidCallback onTap;
  const _FileTile({required this.file, required this.index, required this.onTap});

  IconData _icon(String name) {
    if (file.isDeleted) {
      return Icons.delete_outline_rounded;
    }

    final ext = name.split('.').last.toLowerCase();
    return switch (ext) {
      'dart' || 'py' || 'java' || 'kt' || 'swift' => Icons.code_rounded,
      'yaml' || 'yml' || 'json' || 'xml' || 'toml' => Icons.settings_rounded,
      'md' || 'txt' => Icons.description_rounded,
      'png' || 'jpg' || 'jpeg' || 'gif' || 'svg' => Icons.image_rounded,
      'html' || 'css' || 'js' || 'ts' || 'jsx' || 'tsx' => Icons.web_rounded,
      'php' => Icons.php_rounded,
      'sql' => Icons.storage_rounded,
      'sh' || 'bash' => Icons.terminal_rounded,
      _ => Icons.insert_drive_file_outlined,
    };
  }

  Widget _buildStatusBadge() {
    final (Color color, String text, IconData icon) = switch (file.changeType) {
      FileChangeType.added => (Colors.green, 'Added', Icons.add_rounded),
      FileChangeType.modified => (Colors.blue, 'Modified', Icons.edit_rounded),
      FileChangeType.deleted => (Colors.red, 'Deleted', Icons.remove_rounded),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final isDeleted = file.isDeleted;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: isDeleted
                  ? Colors.red.withValues(alpha: 0.04)
                  : c.surfaceContainerHigh.withValues(alpha: 0.35),
              border: Border.all(
                color: isDeleted
                    ? Colors.red.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.03),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Text(
                    '${index + 1}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      color: isDeleted
                          ? Colors.red.withValues(alpha: 0.4)
                          : c.onSurface.withValues(alpha: 0.3),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _icon(file.fileName),
                  size: 18,
                  color: isDeleted
                      ? Colors.red.shade400
                      : c.primary.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: RichText(
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      children: [
                        if (file.directory.isNotEmpty)
                          TextSpan(
                            text: '${file.directory}/',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 12.5,
                              color: isDeleted
                                  ? Colors.red.withValues(alpha: 0.35)
                                  : c.onSurface.withValues(alpha: 0.4),
                              decoration: isDeleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        TextSpan(
                          text: file.fileName,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: isDeleted
                                ? Colors.red.shade300
                                : c.onSurface.withValues(alpha: 0.85),
                            decoration: isDeleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusBadge(),
                const SizedBox(width: 10),
                Icon(
                  Icons.open_in_new_rounded,
                  size: 16,
                  color: c.onSurface.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
