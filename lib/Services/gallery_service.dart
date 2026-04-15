import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../Models/recorded_video.dart';

class GalleryService {
  Future<Directory> _getVideoDirectory() async {
    final dir = await getApplicationDocumentsDirectory();

    final videoDir = Directory(
      '${dir.path}/recordings',
    );

    if (!await videoDir.exists()) {
      await videoDir.create(recursive: true);
    }

    return videoDir;
  }

  Future<String> saveVideo(File tempFile) async {
    final videoDir = await _getVideoDirectory();

    final fileName = 'video_${DateTime.now().millisecondsSinceEpoch}.mp4';

    final savedFile = await tempFile.copy(
      '${videoDir.path}/$fileName',
    );

    return savedFile.path;
  }

  Future<List<RecordedVideo>> getAllVideos() async {
    final videoDir = await _getVideoDirectory();

    final files = videoDir.listSync();

    final videos = files.whereType<File>().map((file) {
      final stat = file.statSync();

      return RecordedVideo(
        path: file.path,
        fileName: file.uri.pathSegments.last,
        createdAt: stat.modified,
      );
    }).toList();

    videos.sort(
      (a, b) => b.createdAt.compareTo(a.createdAt),
    );

    return videos;
  }

  Future<void> deleteVideo(String path) async {
    final file = File(path);

    if (await file.exists()) {
      await file.delete();
    }
  }
}
