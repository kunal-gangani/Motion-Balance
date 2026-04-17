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
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final controller = VideoPlayerController.file(File(videoPath));
      await controller.initialize();
      _controller = controller;

      ref.onDispose(controller.dispose);

      state = AsyncData(controller);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> playPause() async {
    final controller = _controller;
    if (controller == null || !mounted) return;

    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }
    if (mounted) state = AsyncData(controller);
  }

  Future<void> seekTo(Duration position) async {
    final controller = _controller;
    if (controller == null || !mounted) return;
    await controller.seekTo(position);
    if (mounted) state = AsyncData(controller);
  }

  bool get isPlaying => _controller?.value.isPlaying ?? false;
  Duration get position => _controller?.value.position ?? Duration.zero;
  Duration get duration => _controller?.value.duration ?? Duration.zero;
}
