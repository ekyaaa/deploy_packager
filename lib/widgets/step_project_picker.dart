import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_providers.dart';

class StepProjectPicker extends ConsumerStatefulWidget {
  const StepProjectPicker({super.key});

  @override
  ConsumerState<StepProjectPicker> createState() => _StepProjectPickerState();
}

class _StepProjectPickerState extends ConsumerState<StepProjectPicker>
    with SingleTickerProviderStateMixin {
  bool _isValidating = false;
  String? _error;
  late final AnimationController _pulseController;
  List<String> _history = [];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // Auto-load saved project path & history
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSavedPath();
      _loadHistory();
    });
  }

  Future<void> _loadSavedPath() async {
    final settings = ref.read(settingsServiceProvider);
    final savedPath = settings.projectPath;
    if (savedPath != null) {
      final gitService = ref.read(gitServiceProvider);
      final isValid = await gitService.isGitRepository(savedPath);
      if (isValid && mounted) {
        ref.read(projectPathProvider.notifier).state = savedPath;
      }
    }
  }

  void _loadHistory() {
    final settings = ref.read(settingsServiceProvider);
    setState(() {
      _history = settings.projectHistory;
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final selectedPath = ref.watch(projectPathProvider);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final value = _pulseController.value;
                  return Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colors.primary.withValues(alpha: 0.15 + value * 0.1),
                          colors.primary.withValues(alpha: 0.08 + value * 0.05),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.folder_open_rounded,
                      size: 38,
                      color: colors.primary.withValues(alpha: 0.8),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              Text(
                'Select Your Project',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: colors.onSurface,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                'Choose a folder that contains a local Git repository.\nWe\'ll scan it for recent commits.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: colors.onSurface.withValues(alpha: 0.55),
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 32),

              // Pick button or selected path
              if (selectedPath == null) ...[
                _buildPickButton(context, colors),
              ] else ...[
                _buildSelectedPath(context, colors, selectedPath),
              ],

              if (_error != null) ...[
                const SizedBox(height: 16),
                _buildErrorCard(context, colors),
              ],

              if (_isValidating) ...[
                const SizedBox(height: 24),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
                const SizedBox(height: 8),
                Text(
                  'Validating Git repository...',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: colors.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],

              if (selectedPath != null) ...[
                const SizedBox(height: 28),
                _buildNextButton(context, colors),
              ],

              // History section
              _buildHistorySection(context, colors, selectedPath),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPickButton(BuildContext context, ColorScheme colors) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _pickFolder,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colors.primary.withValues(alpha: 0.25),
                width: 1.5,
              ),
              color: colors.primary.withValues(alpha: 0.04),
            ),
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.create_new_folder_outlined,
                    color: colors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Pick Project Folder',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Click to browse and select your project directory',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: colors.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedPath(
    BuildContext context,
    ColorScheme colors,
    String path,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.green,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Repository Selected',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    path,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: colors.onSurface.withValues(alpha: 0.7),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: _pickFolder,
              icon: Icon(
                Icons.edit_outlined,
                size: 20,
                color: colors.onSurface.withValues(alpha: 0.5),
              ),
              tooltip: 'Change folder',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, ColorScheme colors) {
    return Card(
      color: Colors.red.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.red.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.red,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _error!,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.red.shade200,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextButton(BuildContext context, ColorScheme colors) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () {
          ref.read(currentStepProvider.notifier).state = 1;
        },
        icon: const Icon(Icons.arrow_forward_rounded, size: 20),
        label: const Text('Scan Commits'),
      ),
    );
  }

  // ─── History Section ─────────────────────────────────────────

  Widget _buildHistorySection(
    BuildContext context,
    ColorScheme colors,
    String? selectedPath,
  ) {
    // Filter out the currently selected path from history display
    final displayHistory = _history.where((p) => p != selectedPath).toList();

    if (displayHistory.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        const SizedBox(height: 36),

        // Divider with label
        Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      colors.onSurface.withValues(alpha: 0.08),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 14,
                    color: colors.onSurface.withValues(alpha: 0.35),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Recent Projects',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface.withValues(alpha: 0.35),
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors.onSurface.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // History list
        ...List.generate(displayHistory.length, (index) {
          return _HistoryItem(
            path: displayHistory[index],
            index: index,
            totalCount: displayHistory.length,
            onSelect: () => _selectFromHistory(displayHistory[index]),
            onRemove: () => _removeFromHistory(displayHistory[index]),
          );
        }),

        // Clear all button
        if (displayHistory.length > 1) ...[
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _clearHistory,
            icon: Icon(
              Icons.delete_sweep_outlined,
              size: 16,
              color: colors.onSurface.withValues(alpha: 0.3),
            ),
            label: Text(
              'Clear History',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: colors.onSurface.withValues(alpha: 0.3),
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ],
    );
  }

  // ─── Actions ─────────────────────────────────────────────────

  Future<void> _pickFolder() async {
    setState(() {
      _error = null;
    });

    final result = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select a Git project folder',
    );

    if (result == null) return;

    setState(() {
      _isValidating = true;
      _error = null;
    });

    final gitService = ref.read(gitServiceProvider);
    final isValid = await gitService.isGitRepository(result);

    if (!isValid) {
      setState(() {
        _isValidating = false;
        _error =
            'The selected folder is not a valid Git repository. Please choose a folder with a .git directory.';
      });
      return;
    }

    setState(() {
      _isValidating = false;
    });

    ref.read(projectPathProvider.notifier).state = result;
    ref.read(selectedCommitHashesProvider.notifier).state = {};

    // Persist the project path (also adds to history)
    await ref.read(settingsServiceProvider).setProjectPath(result);
    _loadHistory();
  }

  Future<void> _selectFromHistory(String path) async {
    setState(() {
      _error = null;
      _isValidating = true;
    });

    final gitService = ref.read(gitServiceProvider);
    final isValid = await gitService.isGitRepository(path);

    if (!mounted) return;

    if (!isValid) {
      setState(() {
        _isValidating = false;
        _error =
            'This repository no longer exists or is invalid. It has been removed from history.';
      });
      await ref.read(settingsServiceProvider).removeFromProjectHistory(path);
      _loadHistory();
      return;
    }

    setState(() {
      _isValidating = false;
    });

    ref.read(projectPathProvider.notifier).state = path;
    ref.read(selectedCommitHashesProvider.notifier).state = {};

    await ref.read(settingsServiceProvider).setProjectPath(path);
    _loadHistory();
  }

  Future<void> _removeFromHistory(String path) async {
    await ref.read(settingsServiceProvider).removeFromProjectHistory(path);
    _loadHistory();
  }

  Future<void> _clearHistory() async {
    await ref.read(settingsServiceProvider).clearProjectHistory();
    _loadHistory();
  }
}

// ═══════════════════════════════════════════════════════════════
// History Item Widget (with staggered animation)
// ═══════════════════════════════════════════════════════════════

class _HistoryItem extends StatefulWidget {
  final String path;
  final int index;
  final int totalCount;
  final VoidCallback onSelect;
  final VoidCallback onRemove;

  const _HistoryItem({
    required this.path,
    required this.index,
    required this.totalCount,
    required this.onSelect,
    required this.onRemove,
  });

  @override
  State<_HistoryItem> createState() => _HistoryItemState();
}

class _HistoryItemState extends State<_HistoryItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    final delay = widget.index * 0.12;
    final curvedAnimation = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        delay.clamp(0.0, 0.8),
        (delay + 0.5).clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(curvedAnimation);
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(curvedAnimation);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Extract the project/folder name from the path
  String _extractProjectName(String path) {
    final segments = path.split(Platform.pathSeparator);
    return segments.isNotEmpty ? segments.last : path;
  }

  /// Get a shortened display path
  String _getShortenedPath(String path) {
    final sep = Platform.pathSeparator;
    final segments = path.split(sep);
    if (segments.length <= 3) return path;
    return '...$sep${segments.sublist(segments.length - 3).join(sep)}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: _isHovered
                    ? colors.primary.withValues(alpha: 0.06)
                    : Colors.transparent,
                border: Border.all(
                  color: _isHovered
                      ? colors.primary.withValues(alpha: 0.15)
                      : colors.onSurface.withValues(alpha: 0.06),
                  width: 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: widget.onSelect,
                  borderRadius: BorderRadius.circular(12),
                  splashColor: colors.primary.withValues(alpha: 0.08),
                  highlightColor: colors.primary.withValues(alpha: 0.04),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        // Folder icon with gradient background
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: _isHovered
                                  ? [
                                      colors.primary.withValues(alpha: 0.2),
                                      colors.primary.withValues(alpha: 0.1),
                                    ]
                                  : [
                                      colors.onSurface.withValues(alpha: 0.08),
                                      colors.onSurface.withValues(alpha: 0.04),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.folder_rounded,
                            size: 18,
                            color: _isHovered
                                ? colors.primary
                                : colors.onSurface.withValues(alpha: 0.4),
                          ),
                        ),

                        const SizedBox(width: 14),

                        // Project name and path
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _extractProjectName(widget.path),
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _isHovered
                                      ? colors.primary
                                      : colors.onSurface.withValues(
                                          alpha: 0.85,
                                        ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _getShortenedPath(widget.path),
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: colors.onSurface.withValues(
                                    alpha: 0.35,
                                  ),
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Open arrow (visible on hover)
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 150),
                          opacity: _isHovered ? 1.0 : 0.0,
                          child: AnimatedSlide(
                            duration: const Duration(milliseconds: 200),
                            offset: _isHovered
                                ? Offset.zero
                                : const Offset(-0.3, 0),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 16,
                              color: colors.primary.withValues(alpha: 0.6),
                            ),
                          ),
                        ),

                        // Remove button
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 150),
                          opacity: _isHovered ? 1.0 : 0.0,
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: IconButton(
                              onPressed: widget.onRemove,
                              padding: EdgeInsets.zero,
                              icon: Icon(
                                Icons.close_rounded,
                                size: 14,
                                color: colors.onSurface.withValues(alpha: 0.35),
                              ),
                              tooltip: 'Remove from history',
                              splashRadius: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
