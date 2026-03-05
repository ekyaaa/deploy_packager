import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_providers.dart';
import '../services/export_service.dart';

class StepExport extends ConsumerWidget {
  const StepExport({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final exportState = ref.watch(exportProvider);
    final changedFiles = ref.watch(changedFilesProvider).valueOrNull ?? [];
    final projectPath = ref.watch(projectPathProvider) ?? '';

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 12, 28, 8),
          child: Row(
            children: [
              Icon(
                Icons.rocket_launch_rounded,
                size: 20,
                color: colors.primary,
              ),
              const SizedBox(width: 10),
              Text(
                'Export Files',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Summary card
                _SummaryCard(
                  projectPath: projectPath,
                  fileCount: changedFiles.length,
                  destinationPath: exportState.destinationPath,
                  colors: colors,
                ),
                const SizedBox(height: 16),

                // Destination picker
                if (exportState.status != ExportStatus.success)
                  _buildDestPicker(context, ref, colors, exportState),

                if (exportState.status == ExportStatus.exporting) ...[
                  const SizedBox(height: 24),
                  _buildProgress(colors, exportState),
                ],

                if (exportState.status == ExportStatus.success) ...[
                  const SizedBox(height: 24),
                  _SuccessCard(
                    result: exportState.result!,
                    colors: colors,
                    destPath: exportState.destinationPath!,
                  ),
                ],

                if (exportState.status == ExportStatus.error) ...[
                  const SizedBox(height: 16),
                  _buildError(
                    colors,
                    exportState.errorMessage ?? 'Unknown error',
                  ),
                ],
              ],
            ),
          ),
        ),

        // Bottom bar
        _buildBottom(
          context,
          ref,
          colors,
          exportState,
          changedFiles.isNotEmpty,
        ),
      ],
    );
  }

  Widget _buildDestPicker(
    BuildContext ctx,
    WidgetRef ref,
    ColorScheme c,
    ExportState state,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _pickDest(ref),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: c.primary.withValues(
                alpha: state.destinationPath != null ? 0.3 : 0.15,
              ),
            ),
            color: c.primary.withValues(alpha: 0.04),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: c.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.folder_open_rounded,
                  color: c.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.destinationPath != null
                          ? 'Destination Selected'
                          : 'Pick Destination Folder',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: state.destinationPath != null
                            ? Colors.green
                            : c.primary,
                      ),
                    ),
                    if (state.destinationPath != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        state.destinationPath!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: c.onSurface.withValues(alpha: 0.5),
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ] else ...[
                      const SizedBox(height: 4),
                      Text(
                        'Choose where to export the changed files',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: c.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: c.onSurface.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgress(ColorScheme c, ExportState state) {
    final pct = (state.progress * 100).toInt();
    return Column(
      children: [
        LinearProgressIndicator(
          value: state.progress,
          minHeight: 8,
          borderRadius: BorderRadius.circular(8),
        ),
        const SizedBox(height: 12),
        Text(
          'Copying files... $pct%',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: c.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildError(ColorScheme c, String msg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.red.withValues(alpha: 0.08),
        border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              msg,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.red.shade200,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottom(
    BuildContext ctx,
    WidgetRef ref,
    ColorScheme c,
    ExportState state,
    bool hasFiles,
  ) {
    final canExport =
        state.destinationPath != null &&
        hasFiles &&
        state.status != ExportStatus.exporting;
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
            onPressed: state.status == ExportStatus.exporting
                ? null
                : () => ref.read(currentStepProvider.notifier).state = 2,
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text('Back'),
          ),
          const Spacer(),
          if (state.status == ExportStatus.success) ...[
            OutlinedButton.icon(
              onPressed: () => _openFolder(state.destinationPath!),
              icon: const Icon(Icons.folder_open_rounded, size: 18),
              label: const Text('Open Folder'),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: () {
                ref.read(currentStepProvider.notifier).state = 0;
                ref.read(projectPathProvider.notifier).state = null;
                ref.read(selectedCommitHashesProvider.notifier).state = {};
                ref.read(exportProvider.notifier).reset();
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Start Over'),
            ),
          ] else
            FilledButton.icon(
              onPressed: canExport
                  ? () => ref.read(exportProvider.notifier).startExport()
                  : null,
              icon: state.status == ExportStatus.exporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.file_copy_rounded, size: 18),
              label: Text(
                state.status == ExportStatus.exporting
                    ? 'Exporting...'
                    : 'Export Files',
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pickDest(WidgetRef ref) async {
    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select export destination',
    );
    if (result != null) {
      ref.read(exportProvider.notifier).setDestinationPath(result);
    }
  }

  void _openFolder(String path) {
    if (Platform.isLinux) {
      Process.run('xdg-open', [path]);
    } else if (Platform.isMacOS) {
      Process.run('open', [path]);
    } else if (Platform.isWindows) {
      Process.run('explorer', [path]);
    }
  }
}

class _SummaryCard extends StatelessWidget {
  final String projectPath;
  final int fileCount;
  final String? destinationPath;
  final ColorScheme colors;

  const _SummaryCard({
    required this.projectPath,
    required this.fileCount,
    required this.destinationPath,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export Summary',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            _row(Icons.source_rounded, 'Source', projectPath),
            const SizedBox(height: 10),
            _row(Icons.file_copy_outlined, 'Files to copy', '$fileCount files'),
            if (destinationPath != null) ...[
              const SizedBox(height: 10),
              _row(Icons.save_alt_rounded, 'Destination', destinationPath!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: colors.primary.withValues(alpha: 0.7)),
        const SizedBox(width: 12),
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: colors.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: colors.onSurface.withValues(alpha: 0.8),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _SuccessCard extends StatefulWidget {
  final ExportResult result;
  final ColorScheme colors;
  final String destPath;
  const _SuccessCard({
    required this.result,
    required this.colors,
    required this.destPath,
  });

  @override
  State<_SuccessCard> createState() => _SuccessCardState();
}

class _SuccessCardState extends State<_SuccessCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    return FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.green.withValues(alpha: 0.12),
                Colors.teal.withValues(alpha: 0.06),
              ],
            ),
            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 36,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Export Complete!',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: c.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.result.copiedFiles} of ${widget.result.totalFiles} files copied successfully.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: c.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.destPath,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 12,
                  color: c.onSurface.withValues(alpha: 0.4),
                ),
              ),
              if (widget.result.skippedFiles > 0) ...[
                const SizedBox(height: 12),
                Text(
                  '${widget.result.skippedFiles} file(s) skipped.',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.orange),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
