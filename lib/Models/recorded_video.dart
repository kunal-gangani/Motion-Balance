import 'dart:io';

class RecordedVideo {
  final String path;
  final DateTime createdAt;
  final Duration duration;
  final int fileSizeBytes;

  const RecordedVideo({
    required this.path,
    required this.createdAt,
    required this.duration,
    required this.fileSizeBytes,
  });

  String get fileName => path.split('/').last;

  String get formattedDuration {
    final m = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String get formattedSize {
    final kb = fileSizeBytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    return '${(kb / 1024).toStringAsFixed(1)} MB';
  }

  static Future<RecordedVideo> fromPath(String path) async {
    final file = File(path);
    final stat = await file.stat();
    return RecordedVideo(
      path: path,
      createdAt: stat.modified,
      duration: Duration.zero,
      fileSizeBytes: stat.size,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is RecordedVideo && other.path == path);

  @override
  int get hashCode => path.hashCode;
}
