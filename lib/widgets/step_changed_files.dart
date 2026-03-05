import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_providers.dart';
import '../models/changed_file.dart';

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

  Widget _buildHeader(ColorScheme c, AsyncValue av, Set<String> sel) {
    final count = av.valueOrNull?.length ?? 0;
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
              if (count > 0)
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
                    '$count files',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: c.primary,
                    ),
                  ),
                ),
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
      itemBuilder: (ctx, i) => _FileTile(file: files[i], index: i),
    );
  }

  Widget _buildBottom(ColorScheme c, AsyncValue av) {
    final hasFiles = (av.valueOrNull ?? []).isNotEmpty;
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
            icon: const Icon(Icons.rocket_launch_rounded, size: 18),
            label: const Text('Proceed to Export'),
          ),
        ],
      ),
    );
  }
}

class _FileTile extends StatelessWidget {
  final ChangedFile file;
  final int index;
  const _FileTile({required this.file, required this.index});

  IconData _icon(String name) {
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

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: c.surfaceContainerHigh.withValues(alpha: 0.35),
          border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(
                '${index + 1}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  color: c.onSurface.withValues(alpha: 0.3),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              _icon(file.fileName),
              size: 18,
              color: c.primary.withValues(alpha: 0.7),
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
                          color: c.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    TextSpan(
                      text: file.fileName,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: c.onSurface.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
