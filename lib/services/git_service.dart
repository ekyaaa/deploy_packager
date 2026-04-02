import 'dart:io';
import '../models/git_commit.dart';
import '../models/changed_file.dart';
import '../models/diff_result.dart';

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
      '--format=%H%x1F%h%x1F%s%x1F%an%x1F%aI',
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

  /// Get the raw unified diff for a file between its base and new state.
  Future<DiffResult> getFileDiff(
    String projectPath,
    String filePath,
    String oldestCommit,
    String newestCommit,
  ) async {
    // get parent of oldest commit
    String? baseCommit;
    final parentResult = await Process.run('git', [
      'log', '-1', '--format=%P', oldestCommit
    ], workingDirectory: projectPath);

    if (parentResult.exitCode == 0) {
      final parents = (parentResult.stdout as String).trim().split(' ');
      if (parents.isNotEmpty && parents.first.isNotEmpty) {
        baseCommit = parents.first;
      }
    }

    String? baseTime;
    if (baseCommit != null) {
      final timeRes = await Process.run('git', [
        'log', '-1', '--format=%aI', baseCommit
      ], workingDirectory: projectPath);
      if (timeRes.exitCode == 0) {
        baseTime = (timeRes.stdout as String).trim();
      }
    }

    String? newTime;
    final newTimeRes = await Process.run('git', [
      'log', '-1', '--format=%aI', newestCommit
    ], workingDirectory: projectPath);
    if (newTimeRes.exitCode == 0) {
      newTime = (newTimeRes.stdout as String).trim();
    }

    final diffArgs = [
      'diff',
      if (baseCommit != null)
        '$baseCommit..$newestCommit'
      else
        '4b825dc642cb6eb9a060e54bf8d69288fbee4904..$newestCommit',
      '--',
      filePath
    ];

    final diffRes = await Process.run('git', diffArgs, workingDirectory: projectPath);
    final diffText = diffRes.stdout as String;

    bool isNewFile = baseCommit == null || diffText.contains('new file mode ');
    bool isBinary = diffText.contains('Binary files ') && diffText.contains(' differ');

    return DiffResult(
      diffText: diffText,
      baseCommitTime: baseTime,
      newCommitTime: newTime,
      isNewFile: isNewFile,
      isBinary: isBinary,
    );
  }
}
