import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/build_config.dart';

class SettingsService {
  static const _keyProjectPath = 'project_path';
  static const _keyExportPath = 'export_path';
  static const _keyProjectHistory = 'project_history';
  static const _keyBuildConfigPrefix = 'build_config_';
  static const _keyCleanDestination = 'clean_destination';
  static const _maxHistory = 10;

  late final SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get the saved project path.
  String? get projectPath => _prefs.getString(_keyProjectPath);

  /// Save the project path and add to history.
  Future<void> setProjectPath(String path) async {
    await _prefs.setString(_keyProjectPath, path);
    await addToProjectHistory(path);
  }

  /// Get the project path history list.
  List<String> get projectHistory {
    return _prefs.getStringList(_keyProjectHistory) ?? [];
  }

  /// Add a path to the project history.
  Future<void> addToProjectHistory(String path) async {
    final history = List<String>.from(projectHistory);
    // Remove if already exists (to move it to top)
    history.remove(path);
    // Add to the beginning
    history.insert(0, path);
    // Keep only max items
    if (history.length > _maxHistory) {
      history.removeRange(_maxHistory, history.length);
    }
    await _prefs.setStringList(_keyProjectHistory, history);
  }

  /// Remove a path from the project history.
  Future<void> removeFromProjectHistory(String path) async {
    final history = List<String>.from(projectHistory);
    history.remove(path);
    await _prefs.setStringList(_keyProjectHistory, history);
  }

  /// Clear project history.
  Future<void> clearProjectHistory() async {
    await _prefs.remove(_keyProjectHistory);
  }

  /// Get the saved export path.
  String? get exportPath => _prefs.getString(_keyExportPath);

  /// Save the export path.
  Future<void> setExportPath(String path) async {
    await _prefs.setString(_keyExportPath, path);
  }

  /// Get the saved clean destination setting.
  bool get cleanDestination => _prefs.getBool(_keyCleanDestination) ?? false;

  /// Save the clean destination setting.
  Future<void> setCleanDestination(bool value) async {
    await _prefs.setBool(_keyCleanDestination, value);
  }

  /// Clear all saved settings.
  Future<void> clear() async {
    await _prefs.remove(_keyProjectPath);
    await _prefs.remove(_keyExportPath);
    await _prefs.remove(_keyProjectHistory);
  }

  /// Get the build config for a given project path.
  BuildConfig? getBuildConfig(String projectPath) {
    final key = '$_keyBuildConfigPrefix${_hashPath(projectPath)}';
    final jsonStr = _prefs.getString(key);
    if (jsonStr == null) return null;
    try {
      return BuildConfig.fromJsonString(jsonStr);
    } catch (_) {
      return null;
    }
  }

  /// Save the build config for a given project path.
  Future<void> setBuildConfig(String projectPath, BuildConfig config) async {
    final key = '$_keyBuildConfigPrefix${_hashPath(projectPath)}';
    await _prefs.setString(key, config.toJsonString());
  }

  /// Simple hash for project path keys.
  String _hashPath(String path) {
    final bytes = utf8.encode(path);
    return base64Encode(bytes);
  }
}
