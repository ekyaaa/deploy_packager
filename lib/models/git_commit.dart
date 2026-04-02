class GitCommit {
  final String hash;
  final String shortHash;
  final String message;
  final String author;
  final DateTime date;

  const GitCommit({
    required this.hash,
    required this.shortHash,
    required this.message,
    required this.author,
    required this.date,
  });

  /// Parses a line from `git log` with format:
  /// `%H%x1F%h%x1F%s%x1F%an%x1F%aI`
  factory GitCommit.fromLogLine(String line) {
    final parts = line.split('\x1F');
    if (parts.length < 5) {
      throw FormatException('Invalid git log line: $line');
    }
    return GitCommit(
      hash: parts[0].trim(),
      shortHash: parts[1].trim(),
      message: parts[2].trim(),
      author: parts[3].trim(),
      date: DateTime.parse(parts[4].trim()),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GitCommit &&
          runtimeType == other.runtimeType &&
          hash == other.hash;

  @override
  int get hashCode => hash.hashCode;
}
