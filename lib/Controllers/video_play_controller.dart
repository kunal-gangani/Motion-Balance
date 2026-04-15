// lib/Controllers/video_player_controller.dart

import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

final videoPlayerProvider = StateNotifierProvider.autoDispose
    .family<VideoPlayerNotifier, AsyncValue<VideoPlayerController>, String>(
  (ref, path) => VideoPlayerNotifier(path),
);

class VideoPlayerNotifier
    extends StateNotifier<AsyncValue<VideoPlayerController>> {
  final String videoPath;

  VideoPlayerNotifier(this.videoPath) : super(const AsyncLoading()) {
    initialize();
  }

  Future<void> initialize() async {
    try {
      final controller = VideoPlayerController.file(File(videoPath));

      await controller.initialize();

      state = AsyncData(controller);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void playPause() {
    final controller = state.value;

    if (controller == null) return;

    if (controller.value.isPlaying) {
      controller.pause();
    } else {
      controller.play();
    }

    state = AsyncData(controller);
  }

  @override
  void dispose() {
    state.value?.dispose();
    super.dispose();
  }
}
