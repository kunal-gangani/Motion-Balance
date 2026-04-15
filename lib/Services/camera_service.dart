import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum StabilizationMode {
  off,
  native,
  software,
}

class CameraService {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _activeIndex = 0;

  CameraController? get controller => _controller;

  CameraLensDirection get activeLensDirection =>
      _cameras[_activeIndex].lensDirection;

  Future<void> initialize() async {
    _cameras = await availableCameras();

    if (_cameras.isEmpty) {
      throw Exception("No cameras available.");
    }

    _activeIndex = _cameras.indexWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
    );

    if (_activeIndex == -1) {
      _activeIndex = 0;
    }

    await _initController(_cameras[_activeIndex]);
  }

  Future<void> _initController(CameraDescription camera) async {
    await _controller?.dispose();

    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: true,
    );

    await _controller!.initialize();
  }

  Future<void> switchCamera() async {
    _activeIndex = (_activeIndex + 1) % _cameras.length;

    await _initController(_cameras[_activeIndex]);
  }

  Future<void> startRecording() async {
    if (_controller == null) return;

    await _controller!.startVideoRecording();
  }

  Future<void> stopRecording() async {
    if (_controller == null) return;

    await _controller!.stopVideoRecording();
  }

  Future<void> setStabilizationMode(StabilizationMode mode) async {
    // Placeholder:
    // Native stabilization integration per platform here.
  }

  StabilizationMode bestAvailableStabilizationMode() {
    return StabilizationMode.native;
  }

  Duration get currentRecordingDuration {
    final controller = _controller;
    if (controller == null) {
      return Duration.zero;
    }

    return controller.value.isRecordingVideo
        ? const Duration(seconds: 1)
        : Duration.zero;
  }

  Future<void> dispose() async {
    await _controller?.dispose();
  }
}

final cameraServiceProvider = Provider<CameraService>((ref) {
  final service = CameraService();

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});
