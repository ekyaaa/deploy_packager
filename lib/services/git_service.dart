import 'dart:io';
import '../models/git_commit.dart';
import '../models/changed_file.dart';

class GitService {
  /// Check if the given path is a valid Git repository.
  Future<bool> isGitRepository(String path) async {
    final gitDir = Directory('$path/.git');
    return gitDir.exists();
  }

  /// Get the list of recent commits from the repository.
  Future<List<GitCommit>> getCommits(
    String projectPath, {
    int limit = 50,
  }) async {
    final result = await Process.run('git', [
      'log',
      '--format=%H||%h||%s||%an||%aI',
      '-n',
      '$limit',
    ], workingDirectory: projectPath);

    if (result.exitCode != 0) {
      throw Exception('Failed to get git commits: ${result.stderr}');
    }

    final output = (result.stdout as String).trim();
    if (output.isEmpty) return [];

    return output
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .map((line) => GitCommit.fromLogLine(line))
        .toList();
  }

  /// Get the list of changed files for the given commit hashes.
  /// Uses `git diff-tree` to find added/modified files (excludes deleted).
  Future<List<ChangedFile>> getChangedFiles(
    String projectPath,
    List<String> commitHashes,
  ) async {
    final allFiles = <String>{};

    for (final hash in commitHashes) {
      final result = await Process.run('git', [
        'diff-tree',
        '--no-commit-id',
        '--name-only',
        '--diff-filter=d',
        '-r',
        hash,
      ], workingDirectory: projectPath);

      if (result.exitCode != 0) {
        throw Exception(
          'Failed to get changed files for $hash: ${result.stderr}',
        );
      }

      final output = (result.stdout as String).trim();
      if (output.isEmpty) continue;

      final files = output
          .split('\n')
          .where((line) => line.trim().isNotEmpty)
          .map((line) => line.trim());

      allFiles.addAll(files);
    }

    return allFiles.map((path) => ChangedFile(relativePath: path)).toList()
      ..sort((a, b) => a.relativePath.compareTo(b.relativePath));
  }
}
