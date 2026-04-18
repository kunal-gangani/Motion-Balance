import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../Controllers/gallery_controller.dart';
import '../VideoPlayerView/video_player_view.dart';

class GalleryScreen extends ConsumerWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final galleryState = ref.watch(galleryProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Gallery'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: galleryState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
        error: (error, _) => Center(
          child: Text(
            error.toString(),
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
        ),
        data: (videos) {
          if (videos.isEmpty) {
            return const Center(
              child: Text(
                'No videos found',
                style: TextStyle(
                  color: Colors.white70,
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(galleryProvider.notifier).refreshGallery(),
            child: ListView.builder(
              itemCount: videos.length,
              itemBuilder: (context, index) {
                final video = videos[index];

                final dt = video.createdAt;
                final dateLabel =
                    '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

                return ListTile(
                  title: Text(
                    video.fileName,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    '$dateLabel · ${video.formattedSize}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => ref
                        .read(galleryProvider.notifier)
                        .deleteVideo(video.path),
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VideoPlayerScreen(videoPath: video.path),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
