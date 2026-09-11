enum FileChangeType {
  added,
  modified,
  deleted;

  String get label => switch (this) {
        FileChangeType.added => 'Added',
        FileChangeType.modified => 'Modified',
        FileChangeType.deleted => 'Deleted',
      };
}

class ChangedFile {
  final String relativePath;
  final FileChangeType changeType;

  const ChangedFile({
    required this.relativePath,
    this.changeType = FileChangeType.modified,
  });

  bool get isDeleted => changeType == FileChangeType.deleted;
  bool get isAdded => changeType == FileChangeType.added;
  bool get isModified => changeType == FileChangeType.modified;

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
          relativePath == other.relativePath &&
          changeType == other.changeType;

  @override
  int get hashCode => Object.hash(relativePath, changeType);
}
