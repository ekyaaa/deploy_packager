import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_changes_generator/services/settings_service.dart';
import 'package:project_changes_generator/providers/app_providers.dart';

void main() {
  group('ExportNotifier per-project persistence', () {
    late SettingsService settingsService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      settingsService = SettingsService();
      await settingsService.init();
    });

    test('new project without saved export starts with null destinationPath', () async {
      final container = ProviderContainer(
        overrides: [
          settingsServiceProvider.overrideWithValue(settingsService),
        ],
      );
      addTearDown(container.dispose);

      // Select Project A
      container.read(projectPathProvider.notifier).state = '/home/user/project_a';

      // Read exportProvider
      final exportState = container.read(exportProvider);
      expect(exportState.destinationPath, isNull);
    });

    test('sets and persists export path per project without leaking to other projects', () async {
      final container = ProviderContainer(
        overrides: [
          settingsServiceProvider.overrideWithValue(settingsService),
        ],
      );
      addTearDown(container.dispose);

      // 1. Select Project A and set destination path
      container.read(projectPathProvider.notifier).state = '/home/user/project_a';
      container.read(exportProvider.notifier).setDestinationPath('/dest/site_a');
      expect(container.read(exportProvider).destinationPath, equals('/dest/site_a'));

      // 2. Switch to Project B (unconfigured)
      container.read(projectPathProvider.notifier).state = '/home/user/project_b';
      // Destination path must be null, not leaked from Project A!
      expect(container.read(exportProvider).destinationPath, isNull);

      // 3. Set destination path for Project B
      container.read(exportProvider.notifier).setDestinationPath('/dest/site_b');
      expect(container.read(exportProvider).destinationPath, equals('/dest/site_b'));

      // 4. Switch back to Project A -> destination path must automatically restore to site_a
      container.read(projectPathProvider.notifier).state = '/home/user/project_a';
      expect(container.read(exportProvider).destinationPath, equals('/dest/site_a'));

      // 5. Switch back to Project B -> destination path must automatically restore to site_b
      container.read(projectPathProvider.notifier).state = '/home/user/project_b';
      expect(container.read(exportProvider).destinationPath, equals('/dest/site_b'));
    });

    test('restores saved project export path on fresh app launch / new container', () async {
      const projectA = '/home/user/project_a';
      const destA = '/dest/site_a';

      // Simulate prior session
      await settingsService.setProjectPath(projectA);
      await settingsService.setExportPathForProject(projectA, destA);

      // New container simulates fresh app launch
      final container = ProviderContainer(
        overrides: [
          settingsServiceProvider.overrideWithValue(settingsService),
        ],
      );
      addTearDown(container.dispose);

      // StepProjectPicker sets projectPathProvider on launch
      container.read(projectPathProvider.notifier).state = projectA;

      // When user navigates to StepExport:
      final exportState = container.read(exportProvider);
      expect(exportState.destinationPath, equals(destA));
    });
  });
}
