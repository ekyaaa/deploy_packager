import 'dart:io';
import '../models/changed_file.dart';

class ExportResult {
  final int totalFiles;
  final int copiedFiles;
  final int skippedFiles;
  final List<String> errors;

  const ExportResult({
    required this.totalFiles,
    required this.copiedFiles,
    required this.skippedFiles,
    required this.errors,
  });

  bool get hasErrors => errors.isNotEmpty;
  bool get isSuccess => copiedFiles > 0 && !hasErrors;
}

class ExportService {
  /// Copies files from [sourcePath] to [destinationPath],
  /// preserving the relative directory structure.
  ///
  /// Calls [onProgress] with (current, total) for each file processed.
  Future<ExportResult> exportFiles({
    required String sourcePath,
    required String destinationPath,
    required List<ChangedFile> files,
    void Function(int current, int total)? onProgress,
  }) async {
    int copiedFiles = 0;
    int skippedFiles = 0;
    final errors = <String>[];

    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      try {
        final sourceFile = File('$sourcePath/${file.relativePath}');

        if (!await sourceFile.exists()) {
          skippedFiles++;
          errors.add('File not found: ${file.relativePath}');
          onProgress?.call(i + 1, files.length);
          continue;
        }

        final destFile = File('$destinationPath/${file.relativePath}');

        // Create parent directories recursively
        await destFile.parent.create(recursive: true);

        // Copy the file
        await sourceFile.copy(destFile.path);
        copiedFiles++;
      } catch (e) {
        skippedFiles++;
        errors.add('Error copying ${file.relativePath}: $e');
      }

      onProgress?.call(i + 1, files.length);
    }

    return ExportResult(
      totalFiles: files.length,
      copiedFiles: copiedFiles,
      skippedFiles: skippedFiles,
      errors: errors,
    );
  }
}
