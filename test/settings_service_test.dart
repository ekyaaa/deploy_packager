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

    test('returns null for project without specific path and keeps global exportPath separate', () async {
      const globalExport = '/var/www/default_deploy';
      const newProject = '/home/user/project_new';

      await settingsService.setExportPath(globalExport);

      expect(settingsService.getExportPathForProject(newProject), isNull);
      expect(settingsService.exportPath, equals(globalExport));
    });

    test('normalizes trailing slashes so paths resolve to the same project', () async {
      const projectWithoutSlash = '/home/user/project_a';
      const projectWithSlash = '/home/user/project_a/';
      const exportDest = '/var/www/site_a';

      await settingsService.setExportPathForProject(projectWithoutSlash, exportDest);

      expect(settingsService.getExportPathForProject(projectWithSlash), equals(exportDest));
    });

    test('cleans up project export path when removed from history', () async {
      const project = '/home/user/project_a';
      const exportDest = '/var/www/site_a';

      await settingsService.setProjectPath(project);
      await settingsService.setExportPathForProject(project, exportDest);

      expect(settingsService.getExportPathForProject(project), equals(exportDest));

      await settingsService.removeFromProjectHistory(project);

      expect(settingsService.getExportPathForProject(project), isNull);
    });
  });
}
