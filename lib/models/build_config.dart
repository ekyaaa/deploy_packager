import 'dart:convert';

class BuildConfig {
  final bool enabled;
  final bool runCollectstatic;

  final String frontendDir;
  final String frontendCommand;
  final String frontendOutput;

  final String backendDir;
  final String collectstaticCommand;
  final String collectstaticOutput;

  const BuildConfig({
    this.enabled = false,
    this.runCollectstatic = false,
    this.frontendDir = '',
    this.frontendCommand = 'npm run build',
    this.frontendOutput = 'dist',
    this.backendDir = '',
    this.collectstaticCommand = 'python3 manage.py collectstatic --noinput',
    this.collectstaticOutput = 'collected',
  });

  BuildConfig copyWith({
    bool? enabled,
    bool? runCollectstatic,
    String? frontendDir,
    String? frontendCommand,
    String? frontendOutput,
    String? backendDir,
    String? collectstaticCommand,
    String? collectstaticOutput,
  }) {
    return BuildConfig(
      enabled: enabled ?? this.enabled,
      runCollectstatic: runCollectstatic ?? this.runCollectstatic,
      frontendDir: frontendDir ?? this.frontendDir,
      frontendCommand: frontendCommand ?? this.frontendCommand,
      frontendOutput: frontendOutput ?? this.frontendOutput,
      backendDir: backendDir ?? this.backendDir,
      collectstaticCommand: collectstaticCommand ?? this.collectstaticCommand,
      collectstaticOutput: collectstaticOutput ?? this.collectstaticOutput,
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'runCollectstatic': runCollectstatic,
    'frontendDir': frontendDir,
    'frontendCommand': frontendCommand,
    'frontendOutput': frontendOutput,
    'backendDir': backendDir,
    'collectstaticCommand': collectstaticCommand,
    'collectstaticOutput': collectstaticOutput,
  };

  factory BuildConfig.fromJson(Map<String, dynamic> json) => BuildConfig(
    enabled: json['enabled'] as bool? ?? false,
    runCollectstatic: json['runCollectstatic'] as bool? ?? false,
    frontendDir: json['frontendDir'] as String? ?? '',
    frontendCommand: json['frontendCommand'] as String? ?? 'npm run build',
    frontendOutput: json['frontendOutput'] as String? ?? 'dist',
    backendDir: json['backendDir'] as String? ?? '',
    collectstaticCommand: json['collectstaticCommand'] as String? ?? 'python3 manage.py collectstatic --noinput',
    collectstaticOutput: json['collectstaticOutput'] as String? ?? 'collected',
  );

  String toJsonString() => jsonEncode(toJson());

  factory BuildConfig.fromJsonString(String jsonStr) =>
      BuildConfig.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
}
