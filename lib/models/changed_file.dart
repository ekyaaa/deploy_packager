class ChangedFile {
  final String relativePath;

  const ChangedFile({required this.relativePath});

  /// The filename without the directory path.
  String get fileName => relativePath.split('/').last;

  /// The directory part of the path, or empty if root level.
  String get directory {
    final parts = relativePath.split('/');
    if (parts.length <= 1) return '';
    return parts.sublist(0, parts.length - 1).join('/');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChangedFile &&
          runtimeType == other.runtimeType &&
          relativePath == other.relativePath;

  @override
  int get hashCode => relativePath.hashCode;
}
