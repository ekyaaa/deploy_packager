import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_changes_generator/services/settings_service.dart';
import 'package:project_changes_generator/providers/app_providers.dart';
import 'package:project_changes_generator/widgets/zoom_container.dart';

void main() {
  group('Zoom & Responsiveness', () {
    late SettingsService settingsService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      settingsService = SettingsService();
      await settingsService.init();
    });

    test('initial state defaults to Auto with 1.0 scale', () {
      final container = ProviderContainer(
        overrides: [
          settingsServiceProvider.overrideWithValue(settingsService),
        ],
      );
      addTearDown(container.dispose);

      final zoom = container.read(zoomProvider);
      expect(zoom.isAuto, isTrue);
      expect(zoom.manualScale, equals(1.0));
      expect(zoom.currentScale, equals(1.0));
    });

    test('setScale sets manual scale, switches off isAuto, and persists', () async {
      final container = ProviderContainer(
        overrides: [
          settingsServiceProvider.overrideWithValue(settingsService),
        ],
      );
      addTearDown(container.dispose);

      container.read(zoomProvider.notifier).setScale(0.85);
      await Future<void>.delayed(Duration.zero);

      final zoom = container.read(zoomProvider);
      expect(zoom.isAuto, isFalse);
      expect(zoom.manualScale, equals(0.85));
      expect(zoom.currentScale, equals(0.85));

      expect(settingsService.zoomIsAuto, isFalse);
      expect(settingsService.zoomScale, equals(0.85));
    });

    test('zoomIn and zoomOut increments and decrements by 0.05 step with clamping', () {
      final container = ProviderContainer(
        overrides: [
          settingsServiceProvider.overrideWithValue(settingsService),
        ],
      );
      addTearDown(container.dispose);

      container.read(zoomProvider.notifier).setScale(1.0);
      container.read(zoomProvider.notifier).zoomIn();
      expect(container.read(zoomProvider).currentScale, closeTo(1.05, 0.001));

      container.read(zoomProvider.notifier).zoomOut();
      expect(container.read(zoomProvider).currentScale, closeTo(1.0, 0.001));

      // Test upper clamp
      container.read(zoomProvider.notifier).setScale(1.5);
      expect(container.read(zoomProvider).currentScale, equals(1.30));

      // Test lower clamp
      container.read(zoomProvider.notifier).setScale(0.5);
      expect(container.read(zoomProvider).currentScale, equals(0.70));
    });

    test('setAuto switches back to auto mode and persists', () async {
      final container = ProviderContainer(
        overrides: [
          settingsServiceProvider.overrideWithValue(settingsService),
        ],
      );
      addTearDown(container.dispose);

      container.read(zoomProvider.notifier).setScale(0.75);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(zoomProvider).isAuto, isFalse);

      container.read(zoomProvider.notifier).setAuto();
      await Future<void>.delayed(Duration.zero);
      expect(container.read(zoomProvider).isAuto, isTrue);
      expect(settingsService.zoomIsAuto, isTrue);
    });

    test('computeAutoScale calculates appropriate responsive ratios', () {
      // 1920x1080 baseline desktop returns 1.0
      expect(ZoomContainer.computeAutoScale(1920, 1080), equals(1.0));

      // 1600x900 resolution (0.833 -> snapped to 0.85)
      expect(ZoomContainer.computeAutoScale(1600, 900), equals(0.85));

      // 1366x768 common laptop resolution (0.711 -> snapped to 0.70)
      expect(ZoomContainer.computeAutoScale(1366, 768), equals(0.70));

      // 1280x720 runner default size (0.667 -> clamped to 0.70)
      expect(ZoomContainer.computeAutoScale(1280, 720), equals(0.70));

      // Very small screen clamps to minimum 0.70
      expect(ZoomContainer.computeAutoScale(640, 480), equals(0.70));
    });

    test('restores saved manual zoom setting on fresh app launch', () async {
      await settingsService.setZoomSettings(isAuto: false, scale: 0.85);

      final container = ProviderContainer(
        overrides: [
          settingsServiceProvider.overrideWithValue(settingsService),
        ],
      );
      addTearDown(container.dispose);

      final zoom = container.read(zoomProvider);
      expect(zoom.isAuto, isFalse);
      expect(zoom.manualScale, equals(0.85));
      expect(zoom.currentScale, equals(0.85));
    });

    testWidgets('AppScaleScope and ScaleContextExt correctly compute scaled values', (tester) async {
      double? scaledVal;
      EdgeInsets? scaledPadding;

      await tester.pumpWidget(
        AppScaleScope(
          scale: 0.85,
          child: Builder(
            builder: (context) {
              scaledVal = context.scale(100);
              scaledPadding = context.scaleAll(20);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(scaledVal, closeTo(85.0, 0.001));
      expect(scaledPadding, equals(const EdgeInsets.all(17.0)));
    });

    testWidgets('ZoomContainer expands fully and provides proportional textScaler', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await settingsService.setZoomSettings(isAuto: false, scale: 0.80);

      double? textScaleFactor;
      Size? innerSize;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsServiceProvider.overrideWithValue(settingsService),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 1200,
                height: 800,
                child: ZoomContainer(
                  child: Builder(
                    builder: (context) {
                      textScaleFactor = MediaQuery.textScalerOf(context).scale(10);
                      return LayoutBuilder(
                        builder: (ctx, constraints) {
                          innerSize = Size(constraints.maxWidth, constraints.maxHeight);
                          return const SizedBox.expand();
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Fluid layout: innerSize should occupy the full 1200x800 without letterbox margins
      expect(innerSize?.width, equals(1200.0));
      expect(innerSize?.height, equals(800.0));

      // TextScaler scales proportionally: 10 * 0.80 = 8.0
      expect(textScaleFactor, closeTo(8.0, 0.001));
    });
  });
}
