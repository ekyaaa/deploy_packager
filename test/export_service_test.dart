import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_changes_generator/models/changed_file.dart';
import 'package:project_changes_generator/services/export_service.dart';

void main() {
  group('ChangedFile and FileChangeType', () {
    test('correctly identifies Added, Modified, and Deleted files', () {
      const added = ChangedFile(
        relativePath: 'lib/new_feature.dart',
        changeType: FileChangeType.added,
      );
      const modified = ChangedFile(
        relativePath: 'lib/existing.dart',
        changeType: FileChangeType.modified,
      );
      const deleted = ChangedFile(
        relativePath: 'lib/obsolete.dart',
        changeType: FileChangeType.deleted,
      );

      expect(added.isAdded, isTrue);
      expect(added.isDeleted, isFalse);
      expect(added.changeType.label, 'Added');

      expect(modified.isModified, isTrue);
      expect(modified.isDeleted, isFalse);
      expect(modified.changeType.label, 'Modified');

      expect(deleted.isDeleted, isTrue);
      expect(deleted.isModified, isFalse);
      expect(deleted.changeType.label, 'Deleted');
    });
  });

  group('ExportService with deleted files', () {
    late Directory tempSource;
    late Directory tempDest;
    late ExportService exportService;

    setUp(() async {
      tempSource = await Directory.systemTemp.createTemp('source_test_');
      tempDest = await Directory.systemTemp.createTemp('dest_test_');
      exportService = ExportService();
    });

    tearDown(() async {
      if (await tempSource.exists()) await tempSource.delete(recursive: true);
      if (await tempDest.exists()) await tempDest.delete(recursive: true);
    });

    test('generateDeleteScript creates executable bash script with rm commands', () async {
      final deletedFiles = [
        const ChangedFile(
          relativePath: 'src/old_component.dart',
          changeType: FileChangeType.deleted,
        ),
        const ChangedFile(
          relativePath: 'assets/old_icon.png',
          changeType: FileChangeType.deleted,
        ),
      ];

      final success = await exportService.generateDeleteScript(
        destinationPath: tempDest.path,
        deletedFiles: deletedFiles,
      );

      expect(success, isTrue);

      final scriptFile = File('${tempDest.path}/delete_files.sh');
      expect(await scriptFile.exists(), isTrue);

      final content = await scriptFile.readAsString();
      expect(content, contains('#!/bin/bash'));
      expect(content, contains('rm -f "src/old_component.dart"'));
      expect(content, contains('rm -f "assets/old_icon.png"'));
      expect(content, contains('rm -f -- "\$0"'));
    });

    test('exportFiles skips deleted files and copies active files', () async {
      // Create active files in tempSource
      final activeFile1 = File('${tempSource.path}/file1.txt');
      await activeFile1.writeAsString('Hello 1');

      final activeFile2 = File('${tempSource.path}/subdir/file2.txt');
      await activeFile2.parent.create(recursive: true);
      await activeFile2.writeAsString('Hello 2');

      final files = [
        const ChangedFile(relativePath: 'file1.txt', changeType: FileChangeType.added),
        const ChangedFile(relativePath: 'subdir/file2.txt', changeType: FileChangeType.modified),
        const ChangedFile(relativePath: 'deleted_file.txt', changeType: FileChangeType.deleted),
      ];

      final result = await exportService.exportFiles(
        sourcePath: tempSource.path,
        destinationPath: tempDest.path,
        files: files,
        deletedFilesCount: 1,
        scriptGenerated: true,
      );

      expect(result.copiedFiles, equals(2));
      expect(result.skippedFiles, equals(0));
      expect(result.deletedFilesCount, equals(1));
      expect(result.hasErrors, isFalse);
      expect(result.isSuccess, isTrue);

      expect(File('${tempDest.path}/file1.txt').existsSync(), isTrue);
      expect(File('${tempDest.path}/subdir/file2.txt').existsSync(), isTrue);
      expect(File('${tempDest.path}/deleted_file.txt').existsSync(), isFalse);
    });
  });
}
