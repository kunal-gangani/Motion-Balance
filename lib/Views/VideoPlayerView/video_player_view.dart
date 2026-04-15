import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_balance/Controllers/video_play_controller.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerScreen extends ConsumerWidget {
  final String videoPath;

  const VideoPlayerScreen({
    super.key,
    required this.videoPath,
  });

  Future<void> _shareVideo() async {
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(videoPath),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(videoPlayerProvider(videoPath));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Playback"),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              _shareVideo();
            },
          ),
        ],
      ),
      body: playerState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, _) => Center(
          child: Text(
            error.toString(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        data: (controller) {
          return Center(
            child: AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: VideoPlayer(controller),
            ),
          );
        },
      ),
      floatingActionButton: playerState.maybeWhen(
        data: (_) => FloatingActionButton(
          onPressed: () {
            ref.read(videoPlayerProvider(videoPath).notifier).playPause();
          },
          child: Icon(
            playerState.valueOrNull?.value.isPlaying == true
                ? Icons.pause
                : Icons.play_arrow,
          ),
        ),
        orElse: () => null,
      ),
    );
  }
}
