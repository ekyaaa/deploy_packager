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

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // Auto-load saved project path
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSavedPath();
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

    // Persist the project path
    ref.read(settingsServiceProvider).setProjectPath(result);
  }
}
