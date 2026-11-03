import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/app_providers.dart';
import '../models/git_commit.dart';
import 'zoom_container.dart';

class StepCommitList extends ConsumerStatefulWidget {
  const StepCommitList({super.key});

  @override
  ConsumerState<StepCommitList> createState() => _StepCommitListState();
}

class _StepCommitListState extends ConsumerState<StepCommitList> {
  int? _lastClickedIndex;
  bool _lastActionWasSelect = true;

  void _toggleCommit(int index, List<GitCommit> commits) {
    final commit = commits[index];
    final current = Set<String>.from(ref.read(selectedCommitHashesProvider));
    final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;

    if (isShiftPressed && _lastClickedIndex != null && _lastClickedIndex! < commits.length) {
      final start = min(_lastClickedIndex!, index);
      final end = max(_lastClickedIndex!, index);
      for (int i = start; i <= end; i++) {
        if (_lastActionWasSelect) {
          current.add(commits[i].hash);
        } else {
          current.remove(commits[i].hash);
        }
      }
    } else {
      if (current.contains(commit.hash)) {
        current.remove(commit.hash);
        _lastActionWasSelect = false;
      } else {
        current.add(commit.hash);
        _lastActionWasSelect = true;
      }
      _lastClickedIndex = index;
    }

    ref.read(selectedCommitHashesProvider.notifier).state = current;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final commitsAsync = ref.watch(commitsProvider);
    final selectedHashes = ref.watch(selectedCommitHashesProvider);

    return Column(
      children: [
        // Header bar
        _buildHeaderBar(context, colors, selectedHashes, commitsAsync),

        // Commit list
        Expanded(
          child: commitsAsync.when(
            loading: () => _buildLoading(context, colors),
            error: (error, _) => _buildError(context, colors, error),
            data: (commits) {
              if (commits.isEmpty) {
                return _buildEmpty(context, colors);
              }
              return _buildCommitList(
                context,
                colors,
                commits,
                selectedHashes,
              );
            },
          ),
        ),

        // Bottom bar with navigation
        _buildBottomBar(context, colors, selectedHashes),
      ],
    );
  }

  Widget _buildRangeSelectPill(BuildContext context, ColorScheme colors) {
    return Tooltip(
      message: 'Click to check/uncheck a commit, then hold Shift and click another commit to select or deselect all commits in between',
      waitDuration: const Duration(milliseconds: 300),
      child: Container(
        padding: context.scaleSymmetric(h: 10, v: 5),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHigh.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(context.scale(8)),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: colors.onSurface.withValues(alpha: 0.15),
                ),
              ),
              child: Text(
                'Shift',
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ),
            SizedBox(width: context.scale(6)),
            Text(
              '+ Click to select/deselect range',
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: colors.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBar(
    BuildContext context,
    ColorScheme colors,
    Set<String> selectedHashes,
    AsyncValue<List<GitCommit>> commitsAsync,
  ) {
    final commits = commitsAsync.valueOrNull ?? [];

    return Container(
      padding: context.scaleSymmetric(h: 28, v: 12),
      child: Row(
        children: [
          Icon(Icons.history_rounded, size: context.scale(20), color: colors.primary),
          SizedBox(width: context.scale(10)),
          Text(
            'Select Commits',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          SizedBox(width: context.scale(12)),
          if (selectedHashes.isNotEmpty)
            Container(
              padding: context.scaleSymmetric(h: 10, v: 4),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(context.scale(8)),
              ),
              child: Text(
                '${selectedHashes.length} selected',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.primary,
                ),
              ),
            ),
          const Spacer(),
          if (commits.isNotEmpty) ...[
            _buildRangeSelectPill(context, colors),
            SizedBox(width: context.scale(10)),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _lastClickedIndex = null;
                  _lastActionWasSelect = true;
                });
                if (selectedHashes.length == commits.length) {
                  ref.read(selectedCommitHashesProvider.notifier).state = {};
                } else {
                  ref.read(selectedCommitHashesProvider.notifier).state =
                      commits.map((c) => c.hash).toSet();
                }
              },
              icon: Icon(
                selectedHashes.length == commits.length
                    ? Icons.deselect_rounded
                    : Icons.select_all_rounded,
                size: context.scale(18),
              ),
              label: Text(
                selectedHashes.length == commits.length
                    ? 'Deselect All'
                    : 'Select All',
              ),
              style: TextButton.styleFrom(
                padding: context.scaleSymmetric(h: 14, v: 10),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoading(BuildContext context, ColorScheme colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: colors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Scanning Git history...',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: colors.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, ColorScheme colors, Object error) {
    return Center(
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
              'Failed to load commits',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: colors.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, ColorScheme colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inbox_rounded,
            size: 48,
            color: colors.onSurface.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 16),
          Text(
            'No commits found',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'This repository doesn\'t have any commits yet.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: colors.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommitList(
    BuildContext context,
    ColorScheme colors,
    List<GitCommit> commits,
    Set<String> selectedHashes,
  ) {
    return ListView.builder(
      padding: context.scaleSymmetric(h: 28),
      itemCount: commits.length,
      itemBuilder: (context, index) {
        final commit = commits[index];
        final isSelected = selectedHashes.contains(commit.hash);
        return _CommitTile(
          commit: commit,
          isSelected: isSelected,
          onToggle: () => _toggleCommit(index, commits),
        );
      },
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    ColorScheme colors,
    Set<String> selectedHashes,
  ) {
    return Container(
      padding: context.scaleAll(20),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(color: colors.onSurface.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: () {
              ref.read(currentStepProvider.notifier).state = 0;
            },
            icon: Icon(Icons.arrow_back_rounded, size: context.scale(18)),
            label: const Text('Back'),
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: selectedHashes.isEmpty
                ? null
                : () {
                    ref.read(currentStepProvider.notifier).state = 2;
                  },
            icon: Icon(Icons.arrow_forward_rounded, size: context.scale(18)),
            label: const Text('View Changed Files'),
          ),
        ],
      ),
    );
  }
}

class _CommitTile extends StatelessWidget {
  final GitCommit commit;
  final bool isSelected;
  final VoidCallback onToggle;

  const _CommitTile({
    required this.commit,
    required this.isSelected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dateFormatter = DateFormat('dd MMM yyyy, HH:mm');

    return Padding(
      padding: EdgeInsets.only(bottom: context.scale(6)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(context.scale(12)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: context.scaleSymmetric(h: 16, v: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(context.scale(12)),
              color: isSelected
                  ? colors.primary.withValues(alpha: 0.08)
                  : colors.surfaceContainerHigh.withValues(alpha: 0.4),
              border: Border.all(
                color: isSelected
                    ? colors.primary.withValues(alpha: 0.35)
                    : Colors.white.withValues(alpha: 0.04),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Checkbox
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: context.scale(22),
                  height: context.scale(22),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(context.scale(6)),
                    color: isSelected ? colors.primary : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? colors.primary
                          : colors.onSurface.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check_rounded,
                          size: context.scale(15),
                          color: Colors.white,
                        )
                      : null,
                ),

                SizedBox(width: context.scale(14)),

                // Hash badge
                Container(
                  padding: context.scaleSymmetric(h: 8, v: 3),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(context.scale(6)),
                  ),
                  child: Text(
                    commit.shortHash,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colors.primary,
                    ),
                  ),
                ),

                SizedBox(width: context.scale(14)),

                // Commit message
                Expanded(
                  child: Text(
                    commit.message,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: colors.onSurface.withValues(alpha: 0.9),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),

                const SizedBox(width: 14),

                // Author + date
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      commit.author,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: colors.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateFormatter.format(commit.date.toLocal()),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: colors.onSurface.withValues(alpha: 0.35),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
