import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const _keyProjectPath = 'project_path';
  static const _keyExportPath = 'export_path';

  late final SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get the saved project path.
  String? get projectPath => _prefs.getString(_keyProjectPath);

  /// Save the project path.
  Future<void> setProjectPath(String path) async {
    await _prefs.setString(_keyProjectPath, path);
  }

  /// Get the saved export path.
  String? get exportPath => _prefs.getString(_keyExportPath);

  /// Save the export path.
  Future<void> setExportPath(String path) async {
    await _prefs.setString(_keyExportPath, path);
  }

  /// Clear all saved settings.
  Future<void> clear() async {
    await _prefs.remove(_keyProjectPath);
    await _prefs.remove(_keyExportPath);
  }
}
