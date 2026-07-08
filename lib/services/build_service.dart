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
  Future<BuildStepResult> runFrontendBuild(
    String projectPath,
    BuildConfig config,
  ) async {
    try {
      final result = await Process.run(
        config.packageManager,
        config.buildCommand.split(' '),
        workingDirectory: projectPath,
        runInShell: Platform.isWindows,
      );

      final output = (result.stdout as String).trim();
      final stderr = (result.stderr as String).trim();

      if (result.exitCode != 0) {
        return BuildStepResult(
          success: false,
          output: output,
          error: stderr.isNotEmpty ? stderr : 'Build exited with code ${result.exitCode}',
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

  Future<BuildStepResult> runCollectstatic(
    String projectPath,
    BuildConfig config,
  ) async {
    try {
      final workDir = config.managePyDir.isNotEmpty
          ? '$projectPath/${config.managePyDir}'
          : projectPath;

      final result = await Process.run(
        config.pythonPath,
        ['manage.py', 'collectstatic', '--noinput'],
        workingDirectory: workDir,
        runInShell: Platform.isWindows,
      );

      final output = (result.stdout as String).trim();
      final stderr = (result.stderr as String).trim();

      if (result.exitCode != 0) {
        return BuildStepResult(
          success: false,
          output: output,
          error: stderr.isNotEmpty ? stderr : 'collectstatic exited with code ${result.exitCode}',
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

  Future<void> copyFolderContents({
    required String sourcePath,
    required String destPath,
  }) async {
    final sourceDir = Directory(sourcePath);
    if (!await sourceDir.exists()) return;

    await Directory(destPath).create(recursive: true);

    await for (final entity in sourceDir.list(recursive: true)) {
      if (entity is File) {
        final relativePath = entity.path.substring(sourcePath.length + 1);
        final destFile = File('$destPath/$relativePath');
        await destFile.parent.create(recursive: true);
        await entity.copy(destFile.path);
      }
    }
  }
}
