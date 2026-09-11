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
    final result = await Process.run(
      'git',
      [
        'log',
        '--format=%H%x1F%h%x1F%s%x1F%an%x1F%aI',
        '-n',
        '$limit',
      ],
      workingDirectory: projectPath,
      runInShell: Platform.isWindows,
    );

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

  /// Get the list of changed files for the given commit hashes with their change type (added, modified, deleted).
  Future<List<ChangedFile>> getChangedFiles(
    String projectPath,
    List<String> commitHashes,
  ) async {
    if (commitHashes.isEmpty) return [];

    // Order commits chronologically (oldest to newest)
    final orderRes = await Process.run(
      'git',
      ['log', '--reverse', '--format=%H', '--no-walk', ...commitHashes],
      workingDirectory: projectPath,
      runInShell: Platform.isWindows,
    );

    final orderedHashes = orderRes.exitCode == 0 && (orderRes.stdout as String).trim().isNotEmpty
        ? (orderRes.stdout as String).trim().split('\n').map((h) => h.trim()).toList()
        : commitHashes;

    final fileStatusMap = <String, FileChangeType>{};

    for (final hash in orderedHashes) {
      final result = await Process.run(
        'git',
        [
          'diff-tree',
          '--no-commit-id',
          '--name-status',
          '-r',
          hash,
        ],
        workingDirectory: projectPath,
        runInShell: Platform.isWindows,
      );

      if (result.exitCode != 0) {
        throw Exception(
          'Failed to get changed files for $hash: ${result.stderr}',
        );
      }

      final output = (result.stdout as String).trim();
      if (output.isEmpty) continue;

      for (final line in output.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) continue;

        final parts = trimmed.split(RegExp(r'\s+'));
        if (parts.isEmpty) continue;

        final statusCode = parts[0];

        if (statusCode.startsWith('R') && parts.length >= 3) {
          // Renamed: parts[1] is old path (deleted), parts[2] is new path (added/modified)
          final oldPath = parts[1];
          final newPath = parts[2];
          fileStatusMap[oldPath] = FileChangeType.deleted;
          fileStatusMap[newPath] = FileChangeType.added;
        } else if (parts.length >= 2) {
          final filePath = parts.sublist(1).join(' ');
          if (statusCode.startsWith('A')) {
            fileStatusMap[filePath] = FileChangeType.added;
          } else if (statusCode.startsWith('D')) {
            fileStatusMap[filePath] = FileChangeType.deleted;
          } else {
            // Modified or other status
            if (fileStatusMap[filePath] != FileChangeType.added) {
              fileStatusMap[filePath] = FileChangeType.modified;
            }
          }
        }
      }
    }

    return fileStatusMap.entries
        .map((e) => ChangedFile(relativePath: e.key, changeType: e.value))
        .toList()
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
    ], workingDirectory: projectPath, runInShell: Platform.isWindows);

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
      ], workingDirectory: projectPath, runInShell: Platform.isWindows);
      if (timeRes.exitCode == 0) {
        baseTime = (timeRes.stdout as String).trim();
      }
    }

    String? newTime;
    final newTimeRes = await Process.run('git', [
      'log', '-1', '--format=%aI', newestCommit
    ], workingDirectory: projectPath, runInShell: Platform.isWindows);
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

    final diffRes = await Process.run('git', diffArgs, workingDirectory: projectPath, runInShell: Platform.isWindows);
    final diffText = diffRes.stdout as String;

    bool isDeleted = diffText.contains('deleted file mode ');
    bool isNewFile = !isDeleted && (baseCommit == null || diffText.contains('new file mode '));
    bool isBinary = diffText.contains('Binary files ') && diffText.contains(' differ');

    return DiffResult(
      diffText: diffText,
      baseCommitTime: baseTime,
      newCommitTime: newTime,
      isNewFile: isNewFile,
      isDeleted: isDeleted,
      isBinary: isBinary,
    );
  }
}
