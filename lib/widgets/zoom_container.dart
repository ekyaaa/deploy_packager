import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';

class _ZoomInIntent extends Intent {
  const _ZoomInIntent();
}

class _ZoomOutIntent extends Intent {
  const _ZoomOutIntent();
}

class _ZoomResetIntent extends Intent {
  const _ZoomResetIntent();
}

/// InheritedWidget providing the current active zoom scale to all descendant widgets.
class AppScaleScope extends InheritedWidget {
  final double scale;

  const AppScaleScope({
    super.key,
    required this.scale,
    required super.child,
  });

  static double of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppScaleScope>()?.scale ?? 1.0;
  }

  @override
  bool updateShouldNotify(AppScaleScope oldWidget) => scale != oldWidget.scale;
}

/// Helper extension on BuildContext to scale dimensions, paddings, and spacings.
extension ScaleContextExt on BuildContext {
  double scale(num value) => (value * AppScaleScope.of(this));
  EdgeInsets scaleAll(num value) => EdgeInsets.all(scale(value));
  EdgeInsets scaleSymmetric({num h = 0, num v = 0}) =>
      EdgeInsets.symmetric(horizontal: scale(h), vertical: scale(v));
  EdgeInsets scaleLTRB(num l, num t, num r, num b) =>
      EdgeInsets.fromLTRB(scale(l), scale(t), scale(r), scale(b));
  SizedBox scaleHeight(num h) => SizedBox(height: scale(h));
  SizedBox scaleWidth(num w) => SizedBox(width: scale(w));
}

class ZoomContainer extends ConsumerWidget {
  final Widget child;

  const ZoomContainer({super.key, required this.child});

  /// Computes the auto-scale factor based on window dimensions.
  /// Standard reference desktop resolution is 1920x1080.
  static double computeAutoScale(double width, double height) {
    if (width >= 1800 && height >= 980) {
      return 1.0;
    }
    final scaleH = height / 1080;
    final scaleW = width / 1920;
    final raw = scaleH < scaleW ? scaleH : scaleW;
    final clamped = raw.clamp(0.70, 1.25);
    // Snap to 0.05 increments for clean rendering
    return (clamped * 20).round() / 20;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zoom = ref.watch(zoomProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double effectiveScale;
        if (zoom.isAuto) {
          effectiveScale = computeAutoScale(
            constraints.maxWidth,
            constraints.maxHeight,
          );
          // Update effective scale in provider for UI display
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(zoomProvider.notifier).updateEffectiveScale(effectiveScale);
          });
        } else {
          effectiveScale = zoom.manualScale;
        }

        final currentTheme = Theme.of(context);
        final scaledIconTheme = currentTheme.iconTheme.copyWith(
          size: (22 * effectiveScale).clamp(14.0, 36.0),
        );

        return Shortcuts(
          shortcuts: <ShortcutActivator, Intent>{
            LogicalKeySet(
              LogicalKeyboardKey.control,
              LogicalKeyboardKey.equal,
            ): const _ZoomInIntent(),
            LogicalKeySet(
              LogicalKeyboardKey.control,
              LogicalKeyboardKey.add,
            ): const _ZoomInIntent(),
            LogicalKeySet(
              LogicalKeyboardKey.control,
              LogicalKeyboardKey.minus,
            ): const _ZoomOutIntent(),
            LogicalKeySet(
              LogicalKeyboardKey.control,
              LogicalKeyboardKey.digit0,
            ): const _ZoomResetIntent(),
            LogicalKeySet(
              LogicalKeyboardKey.control,
              LogicalKeyboardKey.numpad0,
            ): const _ZoomResetIntent(),
            // macOS Cmd shortcuts
            LogicalKeySet(
              LogicalKeyboardKey.meta,
              LogicalKeyboardKey.equal,
            ): const _ZoomInIntent(),
            LogicalKeySet(
              LogicalKeyboardKey.meta,
              LogicalKeyboardKey.add,
            ): const _ZoomInIntent(),
            LogicalKeySet(
              LogicalKeyboardKey.meta,
              LogicalKeyboardKey.minus,
            ): const _ZoomOutIntent(),
            LogicalKeySet(
              LogicalKeyboardKey.meta,
              LogicalKeyboardKey.digit0,
            ): const _ZoomResetIntent(),
            LogicalKeySet(
              LogicalKeyboardKey.meta,
              LogicalKeyboardKey.numpad0,
            ): const _ZoomResetIntent(),
          },
          child: Actions(
            actions: <Type, Action<Intent>>{
              _ZoomInIntent: CallbackAction<_ZoomInIntent>(
                onInvoke: (_) => ref.read(zoomProvider.notifier).zoomIn(),
              ),
              _ZoomOutIntent: CallbackAction<_ZoomOutIntent>(
                onInvoke: (_) => ref.read(zoomProvider.notifier).zoomOut(),
              ),
              _ZoomResetIntent: CallbackAction<_ZoomResetIntent>(
                onInvoke: (_) => ref.read(zoomProvider.notifier).reset(),
              ),
            },
            child: AppScaleScope(
              scale: effectiveScale,
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(effectiveScale),
                ),
                child: Theme(
                  data: currentTheme.copyWith(
                    iconTheme: scaledIconTheme,
                  ),
                  child: SizedBox.expand(
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
