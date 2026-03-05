import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_providers.dart';
import '../widgets/step_project_picker.dart';
import '../widgets/step_commit_list.dart';
import '../widgets/step_changed_files.dart';
import '../widgets/step_export.dart';

class DeployPackagerPage extends ConsumerStatefulWidget {
  const DeployPackagerPage({super.key});

  @override
  ConsumerState<DeployPackagerPage> createState() => _DeployPackagerPageState();
}

class _DeployPackagerPageState extends ConsumerState<DeployPackagerPage> {
  static const _stepLabels = ['Project', 'Commits', 'Changed Files', 'Export'];

  static const _stepIcons = [
    Icons.folder_outlined,
    Icons.history_outlined,
    Icons.compare_arrows_outlined,
    Icons.rocket_launch_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final currentStep = ref.watch(currentStepProvider);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: Column(
        children: [
          // ─── App Header ─────────────────────────────────────
          _buildHeader(context, colors),

          // ─── Step Indicator ─────────────────────────────────
          _buildStepIndicator(context, currentStep, colors),

          const SizedBox(height: 8),

          // ─── Step Content ───────────────────────────────────
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.04, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: _buildStepContent(currentStep),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 8),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [colors.primary, colors.primary.withValues(alpha: 0.7)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.rocket_launch_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Deploy Packager',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: colors.onSurface,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Extract changed files from Git commits for deployment',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: colors.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const Spacer(),
          _buildResetButton(context, colors),
        ],
      ),
    );
  }

  Widget _buildResetButton(BuildContext context, ColorScheme colors) {
    final currentStep = ref.watch(currentStepProvider);
    if (currentStep == 0) return const SizedBox.shrink();

    return Tooltip(
      message: 'Start Over',
      child: IconButton(
        onPressed: _handleReset,
        icon: Icon(
          Icons.refresh_rounded,
          color: colors.onSurface.withValues(alpha: 0.5),
        ),
        style: IconButton.styleFrom(
          backgroundColor: colors.surfaceContainerHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(
    BuildContext context,
    int currentStep,
    ColorScheme colors,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
      child: Row(
        children: List.generate(_stepLabels.length * 2 - 1, (index) {
          if (index.isOdd) {
            // Connector line
            final stepIndex = index ~/ 2;
            final isCompleted = stepIndex < currentStep;
            return Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(1),
                  color: isCompleted
                      ? colors.primary.withValues(alpha: 0.6)
                      : colors.onSurface.withValues(alpha: 0.1),
                ),
              ),
            );
          }

          // Step circle
          final stepIndex = index ~/ 2;
          final isActive = stepIndex == currentStep;
          final isCompleted = stepIndex < currentStep;

          return _StepDot(
            label: _stepLabels[stepIndex],
            icon: _stepIcons[stepIndex],
            isActive: isActive,
            isCompleted: isCompleted,
            colors: colors,
          );
        }),
      ),
    );
  }

  Widget _buildStepContent(int currentStep) {
    return switch (currentStep) {
      0 => const StepProjectPicker(key: ValueKey('step_0')),
      1 => const StepCommitList(key: ValueKey('step_1')),
      2 => const StepChangedFiles(key: ValueKey('step_2')),
      3 => const StepExport(key: ValueKey('step_3')),
      _ => const SizedBox.shrink(),
    };
  }

  void _handleReset() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Over?'),
        content: const Text(
          'This will reset all selections and take you back to the beginning.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(currentStepProvider.notifier).state = 0;
              ref.read(projectPathProvider.notifier).state = null;
              ref.read(selectedCommitHashesProvider.notifier).state = {};
              ref.read(exportProvider.notifier).reset();
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final bool isCompleted;
  final ColorScheme colors;

  const _StepDot({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.isCompleted,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          width: isActive ? 44 : 36,
          height: isActive ? 44 : 36,
          decoration: BoxDecoration(
            gradient: (isActive || isCompleted)
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colors.primary,
                      colors.primary.withValues(alpha: 0.7),
                    ],
                  )
                : null,
            color: (!isActive && !isCompleted)
                ? colors.surfaceContainerHigh
                : null,
            shape: BoxShape.circle,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Icon(
            isCompleted ? Icons.check_rounded : icon,
            size: isActive ? 20 : 16,
            color: (isActive || isCompleted)
                ? Colors.white
                : colors.onSurface.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive
                ? colors.primary
                : isCompleted
                ? colors.onSurface.withValues(alpha: 0.7)
                : colors.onSurface.withValues(alpha: 0.35),
          ),
        ),
      ],
    );
  }
}
