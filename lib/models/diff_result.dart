class DiffResult {
  final String diffText;
  final String? baseCommitTime;
  final String? newCommitTime;
  final bool isNewFile;
  final bool isDeleted;
  final bool isBinary;

  DiffResult({
    required this.diffText,
    this.baseCommitTime,
    this.newCommitTime,
    this.isNewFile = false,
    this.isDeleted = false,
    this.isBinary = false,
  });
}
