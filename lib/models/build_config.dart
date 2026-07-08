import 'dart:convert';

class BuildConfig {
  final bool enabled;
  final String packageManager;
  final String buildCommand;
  final String distFolder;
  final bool runCollectstatic;
  final String pythonPath;
  final String managePyDir;

  const BuildConfig({
    this.enabled = false,
    this.packageManager = 'npm',
    this.buildCommand = 'run build',
    this.distFolder = 'dist',
    this.runCollectstatic = false,
    this.pythonPath = 'python3',
    this.managePyDir = '',
  });

  BuildConfig copyWith({
    bool? enabled,
    String? packageManager,
    String? buildCommand,
    String? distFolder,
    bool? runCollectstatic,
    String? pythonPath,
    String? managePyDir,
  }) {
    return BuildConfig(
      enabled: enabled ?? this.enabled,
      packageManager: packageManager ?? this.packageManager,
      buildCommand: buildCommand ?? this.buildCommand,
      distFolder: distFolder ?? this.distFolder,
      runCollectstatic: runCollectstatic ?? this.runCollectstatic,
      pythonPath: pythonPath ?? this.pythonPath,
      managePyDir: managePyDir ?? this.managePyDir,
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'packageManager': packageManager,
    'buildCommand': buildCommand,
    'distFolder': distFolder,
    'runCollectstatic': runCollectstatic,
    'pythonPath': pythonPath,
    'managePyDir': managePyDir,
  };

  factory BuildConfig.fromJson(Map<String, dynamic> json) => BuildConfig(
    enabled: json['enabled'] as bool? ?? false,
    packageManager: json['packageManager'] as String? ?? 'npm',
    buildCommand: json['buildCommand'] as String? ?? 'run build',
    distFolder: json['distFolder'] as String? ?? 'dist',
    runCollectstatic: json['runCollectstatic'] as bool? ?? false,
    pythonPath: json['pythonPath'] as String? ?? 'python3',
    managePyDir: json['managePyDir'] as String? ?? '',
  );

  String toJsonString() => jsonEncode(toJson());

  factory BuildConfig.fromJsonString(String jsonStr) =>
      BuildConfig.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
}
