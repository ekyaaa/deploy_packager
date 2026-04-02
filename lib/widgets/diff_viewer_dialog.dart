import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/diff_result.dart';
import '../providers/app_providers.dart';

class DiffViewerDialog extends ConsumerStatefulWidget {
  final String projectPath;
  final String filePath;
  final String oldestHash;
  final String newestHash;

  const DiffViewerDialog({
    super.key,
    required this.projectPath,
    required this.filePath,
    required this.oldestHash,
    required this.newestHash,
  });

  @override
  ConsumerState<DiffViewerDialog> createState() => _DiffViewerDialogState();
}

class _DiffViewerDialogState extends ConsumerState<DiffViewerDialog> {
  Future<DiffResult>? _diffFuture;

  @override
  void initState() {
    super.initState();
    _loadDiff();
  }

  void _loadDiff() {
    final gitService = ref.read(gitServiceProvider);
    _diffFuture = gitService.getFileDiff(
      widget.projectPath,
      widget.filePath,
      widget.oldestHash,
      widget.newestHash,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 800,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.difference_rounded, color: colors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.filePath,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: colors.surfaceContainerHigh.withValues(alpha: 0.3),
                  border: Border.all(color: colors.onSurface.withValues(alpha: 0.05)),
                ),
                child: FutureBuilder<DiffResult>(
                  future: _diffFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: GoogleFonts.inter(color: Colors.red),
                        ),
                      );
                    }
                    if (!snapshot.hasData) return const SizedBox.shrink();

                    final diff = snapshot.data!;
                    return _buildDiffContent(diff, colors);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiffContent(DiffResult diff, ColorScheme colors) {
    if (diff.isBinary) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_not_supported_rounded, size: 48, color: colors.onSurface.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(
              'Binary file tidak dapat di-diff',
              style: GoogleFonts.inter(fontSize: 14, color: colors.onSurface.withValues(alpha: 0.5)),
            )
          ],
        ),
      );
    }

    if (diff.isNewFile) {
      return Column(
        children: [
          _buildTimelineInfo(diff, colors),
          const Divider(height: 1),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.note_add_rounded, size: 48, color: Colors.green.withValues(alpha: 0.6)),
                  const SizedBox(height: 16),
                  Text(
                    'New File (Berkas Baru)',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade300,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pilih opsi lain untuk melihat text, raw diff kosong untuk berkas baru.',
                    style: GoogleFonts.inter(fontSize: 13, color: colors.onSurface.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (diff.diffText.isEmpty) {
      return Center(
        child: Text(
          'Tidak ada perubahan text yang terdeteksi.',
          style: GoogleFonts.inter(fontSize: 14, color: colors.onSurface.withValues(alpha: 0.5)),
        ),
      );
    }

    final diffLines = _parseDiff(diff.diffText);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTimelineInfo(diff, colors),
        const Divider(height: 0, thickness: 1),
        Expanded(
          child: SelectionArea(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: diffLines.length,
              itemBuilder: (context, index) {
                return _buildDiffLineWidget(diffLines[index], colors);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDiffLineWidget(_DiffLine diffLine, ColorScheme colors) {
    Color? bgColor;
    Color? textColor;

    switch (diffLine.type) {
      case 'added':
        bgColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green.shade300;
        break;
      case 'removed':
        bgColor = Colors.red.withValues(alpha: 0.1);
        textColor = Colors.red.shade300;
        break;
      case 'chunk':
        bgColor = colors.primary.withValues(alpha: 0.05);
        textColor = Colors.blue.shade300;
        break;
      case 'info':
        textColor = colors.onSurface.withValues(alpha: 0.5);
        break;
      case 'unchanged':
      default:
        textColor = colors.onSurface.withValues(alpha: 0.8);
        break;
    }

    final numStyle = GoogleFonts.jetBrainsMono(
      fontSize: 12,
      color: colors.onSurface.withValues(alpha: 0.35),
    );

    return Container(
      width: double.infinity,
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (diffLine.type == 'chunk' || diffLine.type == 'info')
            const SizedBox(width: 88) // 36 + 36 + 16
          else ...[
            SizedBox(
              width: 36,
              child: Text(diffLine.oldLineNum ?? '', style: numStyle, textAlign: TextAlign.right),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 36,
              child: Text(diffLine.newLineNum ?? '', style: numStyle, textAlign: TextAlign.right),
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(
              diffLine.text,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 13,
                color: textColor,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineInfo(DiffResult diff, ColorScheme colors) {
    final format = DateFormat('dd MMM yyyy, HH:mm:ss');
    String baseStr = 'Unknown';
    if (diff.baseCommitTime != null) {
      baseStr = format.format(DateTime.parse(diff.baseCommitTime!).toLocal());
    }
    String newStr = 'Unknown';
    if (diff.newCommitTime != null) {
      newStr = format.format(DateTime.parse(diff.newCommitTime!).toLocal());
    }

    if (diff.isNewFile) {
      baseStr = '(Before creation)';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: colors.primary.withValues(alpha: 0.03),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Before: ', style: GoogleFonts.inter(fontSize: 12, color: colors.onSurface.withValues(alpha: 0.5))),
          Text(baseStr, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: colors.onSurface)),
          const SizedBox(width: 16),
          Icon(Icons.arrow_right_alt_rounded, size: 16, color: colors.onSurface.withValues(alpha: 0.3)),
          const SizedBox(width: 16),
          Text('After: ', style: GoogleFonts.inter(fontSize: 12, color: colors.onSurface.withValues(alpha: 0.5))),
          Text(newStr, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: colors.onSurface)),
        ],
      ),
    );
  }

  List<_DiffLine> _parseDiff(String diffText) {
    final lines = <_DiffLine>[];
    final chunkRegex = RegExp(r'^@@ -(\d+)(?:,\d+)? \+(\d+)(?:,\d+)? @@');
    int? oldLn;
    int? newLn;
    bool isHeader = true;

    for (final line in diffText.split('\n')) {
      if (line.isEmpty) continue;

      if (isHeader) {
        if (line.startsWith('@@')) {
          isHeader = false;
        } else {
          continue; // Skip the git diff header
        }
      }

      if (line.startsWith('@@')) {
        final match = chunkRegex.firstMatch(line);
        if (match != null) {
          oldLn = int.parse(match.group(1)!);
          newLn = int.parse(match.group(2)!);
        }
        lines.add(_DiffLine(text: line, type: 'chunk'));
      } else if (line.startsWith('+')) {
        lines.add(_DiffLine(
          newLineNum: newLn?.toString(),
          text: line,
          type: 'added',
        ));
        if (newLn != null) newLn = newLn + 1;
      } else if (line.startsWith('-')) {
        lines.add(_DiffLine(
          oldLineNum: oldLn?.toString(),
          text: line,
          type: 'removed',
        ));
        if (oldLn != null) oldLn = oldLn + 1;
      } else if (line.startsWith(' ')) {
        lines.add(_DiffLine(
          oldLineNum: oldLn?.toString(),
          newLineNum: newLn?.toString(),
          text: line,
          type: 'unchanged',
        ));
        if (oldLn != null) oldLn = oldLn + 1;
        if (newLn != null) newLn = newLn + 1;
      } else if (line.startsWith('\\')) {
        lines.add(_DiffLine(text: line, type: 'info'));
      } else {
        lines.add(_DiffLine(text: line, type: 'info'));
      }
    }
    return lines;
  }
}

class _DiffLine {
  final String? oldLineNum;
  final String? newLineNum;
  final String text;
  final String type;

  _DiffLine({
    this.oldLineNum,
    this.newLineNum,
    required this.text,
    required this.type,
  });
}
