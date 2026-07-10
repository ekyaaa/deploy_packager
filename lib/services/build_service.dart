import 'dart:io';
import '../models/build_config.dart';

class BuildStepResult {
  final bool success;
  final String output;
  final String? error;

  const BuildStepResult({
    required this.success,
    required this.output,
    this.error,
  });
}

class BuildService {
  Future<BuildStepResult> runShellCommand({
    required String workingDir,
    required String command,
  }) async {
    try {
      final result = await Process.run(
        Platform.isWindows ? 'cmd' : 'bash',
        Platform.isWindows ? ['/c', command] : ['-c', command],
        workingDirectory: workingDir,
        runInShell: Platform.isWindows,
      );

      final output = (result.stdout as String).trim();
      final stderr = (result.stderr as String).trim();

      if (result.exitCode != 0) {
        return BuildStepResult(
          success: false,
          output: output,
          error: stderr.isNotEmpty ? stderr : 'Command exited with code ${result.exitCode}',
        );
      }

      return BuildStepResult(success: true, output: output);
    } catch (e) {
      return BuildStepResult(
        success: false,
        output: '',
        error: e.toString(),
      );
    }
  }

  Future<BuildStepResult> runFrontendBuild(
    String projectPath,
    BuildConfig config,
  ) async {
    final workDir = config.frontendDir.isNotEmpty
        ? '$projectPath/${config.frontendDir}'
        : projectPath;

    return runShellCommand(
      workingDir: workDir,
      command: config.frontendCommand,
    );
  }

  Future<BuildStepResult> runCollectstatic(
    String projectPath,
    BuildConfig config,
  ) async {
    final workDir = config.backendDir.isNotEmpty
        ? '$projectPath/${config.backendDir}'
        : projectPath;

    return runShellCommand(
      workingDir: workDir,
      command: config.collectstaticCommand,
    );
  }

  /// Returns the number of files copied. Throws if source does not exist.
  Future<int> copyFolderContents({
    required String sourcePath,
    required String destPath,
  }) async {
    final sourceDir = Directory(sourcePath);
    if (!await sourceDir.exists()) {
      throw Exception('Source directory not found: $sourcePath');
    }

    await Directory(destPath).create(recursive: true);
    int count = 0;

    await for (final entity in sourceDir.list(recursive: true)) {
      if (entity is File) {
        final relativePath = entity.path.substring(sourcePath.length + 1);
        final destFile = File('$destPath/$relativePath');
        await destFile.parent.create(recursive: true);
        await entity.copy(destFile.path);
        count++;
      }
    }

    return count;
  }
}
