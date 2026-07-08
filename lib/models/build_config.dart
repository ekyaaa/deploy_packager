import 'dart:convert';

class BuildConfig {
  final bool enabled;
  final bool runCollectstatic;

  final String frontendDir;
  final String frontendCommand;
  final String distFolder;

  final String backendDir;
  final String collectstaticCommand;

  const BuildConfig({
    this.enabled = false,
    this.runCollectstatic = false,
    this.frontendDir = '',
    this.frontendCommand = 'npm run build',
    this.distFolder = 'dist',
    this.backendDir = '',
    this.collectstaticCommand = 'python3 manage.py collectstatic --noinput',
  });

  BuildConfig copyWith({
    bool? enabled,
    bool? runCollectstatic,
    String? frontendDir,
    String? frontendCommand,
    String? distFolder,
    String? backendDir,
    String? collectstaticCommand,
  }) {
    return BuildConfig(
      enabled: enabled ?? this.enabled,
      runCollectstatic: runCollectstatic ?? this.runCollectstatic,
      frontendDir: frontendDir ?? this.frontendDir,
      frontendCommand: frontendCommand ?? this.frontendCommand,
      distFolder: distFolder ?? this.distFolder,
      backendDir: backendDir ?? this.backendDir,
      collectstaticCommand: collectstaticCommand ?? this.collectstaticCommand,
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'runCollectstatic': runCollectstatic,
    'frontendDir': frontendDir,
    'frontendCommand': frontendCommand,
    'distFolder': distFolder,
    'backendDir': backendDir,
    'collectstaticCommand': collectstaticCommand,
  };

  factory BuildConfig.fromJson(Map<String, dynamic> json) => BuildConfig(
    enabled: json['enabled'] as bool? ?? false,
    runCollectstatic: json['runCollectstatic'] as bool? ?? false,
    frontendDir: json['frontendDir'] as String? ?? '',
    frontendCommand: json['frontendCommand'] as String? ?? 'npm run build',
    distFolder: json['distFolder'] as String? ?? 'dist',
    backendDir: json['backendDir'] as String? ?? '',
    collectstaticCommand: json['collectstaticCommand'] as String? ?? 'python3 manage.py collectstatic --noinput',
  );

  String toJsonString() => jsonEncode(toJson());

  factory BuildConfig.fromJsonString(String jsonStr) =>
      BuildConfig.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
}
