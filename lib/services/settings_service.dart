import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/build_config.dart';

class SettingsService {
  static const _keyProjectPath = 'project_path';
  static const _keyExportPath = 'export_path';
  static const _keyProjectHistory = 'project_history';
  static const _keyBuildConfigPrefix = 'build_config_';
  static const _keyCleanDestination = 'clean_destination';
  static const _keyZoomIsAuto = 'zoom_is_auto';
  static const _keyZoomScale = 'zoom_scale';
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

  /// Remove a path from the project history and clean up its project-specific settings.
  Future<void> removeFromProjectHistory(String path) async {
    final history = List<String>.from(projectHistory);
    history.remove(path);
    await _prefs.setStringList(_keyProjectHistory, history);
    await removeExportPathForProject(path);
    await removeBuildConfigForProject(path);
  }

  /// Clear project history and associated per-project settings.
  Future<void> clearProjectHistory() async {
    for (final path in projectHistory) {
      await removeExportPathForProject(path);
      await removeBuildConfigForProject(path);
    }
    await _prefs.remove(_keyProjectHistory);
  }

  static const _keyProjectExportPathPrefix = 'export_path_';

  /// Get the saved export path.
  String? get exportPath => _prefs.getString(_keyExportPath);

  /// Save the default/global export path.
  Future<void> setExportPath(String path) async {
    await _prefs.setString(_keyExportPath, path);
  }

  /// Get the saved export path for a specific project strictly.
  /// Returns null if this project has no dedicated export path yet.
  String? getExportPathForProject(String projectPath) {
    final key = '$_keyProjectExportPathPrefix${_hashPath(projectPath)}';
    return _prefs.getString(key);
  }

  /// Save the export path for a specific project and also update the global default.
  Future<void> setExportPathForProject(String projectPath, String path) async {
    final key = '$_keyProjectExportPathPrefix${_hashPath(projectPath)}';
    await _prefs.setString(key, path);
    await setExportPath(path);
  }

  /// Remove the saved export path for a specific project.
  Future<void> removeExportPathForProject(String projectPath) async {
    final key = '$_keyProjectExportPathPrefix${_hashPath(projectPath)}';
    await _prefs.remove(key);
  }

  /// Remove the saved build config for a specific project.
  Future<void> removeBuildConfigForProject(String projectPath) async {
    final key = '$_keyBuildConfigPrefix${_hashPath(projectPath)}';
    await _prefs.remove(key);
  }

  /// Get the saved clean destination setting.
  bool get cleanDestination => _prefs.getBool(_keyCleanDestination) ?? false;

  /// Save the clean destination setting.
  Future<void> setCleanDestination(bool value) async {
    await _prefs.setBool(_keyCleanDestination, value);
  }

  /// Whether zoom level is in automatic responsive mode. Defaults to true.
  bool get zoomIsAuto => _prefs.getBool(_keyZoomIsAuto) ?? true;

  /// Manual zoom scale factor (e.g. 0.85, 1.0). Defaults to 1.0.
  double get zoomScale => _prefs.getDouble(_keyZoomScale) ?? 1.0;

  /// Save zoom configuration.
  Future<void> setZoomSettings({required bool isAuto, required double scale}) async {
    await Future.wait([
      _prefs.setBool(_keyZoomIsAuto, isAuto),
      _prefs.setDouble(_keyZoomScale, scale),
    ]);
  }

  /// Clear all saved settings.
  Future<void> clear() async {
    await clearProjectHistory();
    await _prefs.remove(_keyProjectPath);
    await _prefs.remove(_keyExportPath);
    await _prefs.remove(_keyCleanDestination);
    await _prefs.remove(_keyZoomIsAuto);
    await _prefs.remove(_keyZoomScale);
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

  /// Normalize a filesystem path by trimming whitespace and trailing slashes.
  String _normalizePath(String path) {
    var p = path.trim();
    while ((p.endsWith('/') || p.endsWith('\\')) && p.length > 1) {
      p = p.substring(0, p.length - 1);
    }
    return p;
  }

  /// Simple hash for project path keys using normalized path.
  String _hashPath(String path) {
    final normalized = _normalizePath(path);
    final bytes = utf8.encode(normalized);
    return base64Encode(bytes);
  }
}
