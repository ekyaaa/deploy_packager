import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_changes_generator/services/settings_service.dart';

void main() {
  group('SettingsService per-project export path', () {
    late SettingsService settingsService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      settingsService = SettingsService();
      await settingsService.init();
    });

    test('saves and retrieves export path per project', () async {
      const projectA = '/home/user/project_a';
      const projectB = '/home/user/project_b';
      const exportDestA = '/var/www/site_a';
      const exportDestB = '/var/www/site_b';

      await settingsService.setExportPathForProject(projectA, exportDestA);
      await settingsService.setExportPathForProject(projectB, exportDestB);

      expect(settingsService.getExportPathForProject(projectA), equals(exportDestA));
      expect(settingsService.getExportPathForProject(projectB), equals(exportDestB));
      // Global exportPath reflects the most recent
      expect(settingsService.exportPath, equals(exportDestB));
    });

    test('falls back to global export path if project has no specific path', () async {
      const globalExport = '/var/www/default_deploy';
      const newProject = '/home/user/project_new';

      await settingsService.setExportPath(globalExport);

      expect(settingsService.getExportPathForProject(newProject), equals(globalExport));
    });
  });
}
