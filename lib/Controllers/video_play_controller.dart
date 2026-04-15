import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

final videoPlayerProvider = StateNotifierProvider.autoDispose
    .family<VideoPlayerNotifier, AsyncValue<VideoPlayerController>, String>(
  (ref, path) => VideoPlayerNotifier(ref, path),
);

class VideoPlayerNotifier
    extends StateNotifier<AsyncValue<VideoPlayerController>> {
  final String videoPath;
  final Ref ref;
  VideoPlayerController? _controller;

  VideoPlayerNotifier(this.ref, this.videoPath) : super(const AsyncLoading()) {
    initialize();
  }

  Future<void> initialize() async {
    try {
      final controller = VideoPlayerController.file(File(videoPath));
      await controller.initialize();
      _controller = controller;

      controller.addListener(() {
        if (mounted) {
          state = AsyncData(controller);
        }
      });

      ref.onDispose(() {
        controller.dispose();
      });

      state = AsyncData(controller);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> playPause() async {
    final controller = _controller;
    if (controller == null) {
      return;
    }

    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }

    if (mounted) {
      state = AsyncData(controller);
    }
  }
}
