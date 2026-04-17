import 'dart:async';
import 'dart:developer' show log;
import 'dart:io';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

final cameraServiceProvider = Provider<CameraService>((ref) {
  final service = CameraService();
  ref.onDispose(service.dispose);
  return service;
});

enum StabilizationMode { off, native, software }

enum StabilizationLevel { native, softwareOnly, unsupported }

class CameraCapabilities {
  final bool hasStabilization;
  final bool hasFrontCamera;
  final bool hasUltraWide;
  final bool hasGyroscope;
  final bool hasAccelerometer;
  final ResolutionPreset maxResolution;

  const CameraCapabilities({
    required this.hasStabilization,
    required this.hasFrontCamera,
    required this.hasUltraWide,
    required this.hasGyroscope,
    required this.hasAccelerometer,
    required this.maxResolution,
  });

  StabilizationLevel get bestLevel {
    if (hasStabilization) return StabilizationLevel.native;
    if (hasGyroscope) return StabilizationLevel.softwareOnly;
    return StabilizationLevel.unsupported;
  }
}

class RecordingResult {
  final String videoPath;
  final Duration duration;
  final DateTime timestamp;

  const RecordingResult({
    required this.videoPath,
    required this.duration,
    required this.timestamp,
  });
}

class CameraService {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _activeCameraIndex = 0;
  bool _isInitialized = false;
  bool _isRecording = false;
  StabilizationMode _stabilizationMode = StabilizationMode.off;
  CameraCapabilities? _capabilities;
  DateTime? _recordingStartedAt;
  String? _lastError;

  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;
  bool get isRecording => _isRecording;
  CameraCapabilities? get capabilities => _capabilities;
  StabilizationMode get stabilizationMode => _stabilizationMode;
  String? get lastError => _lastError;

  CameraLensDirection get activeLensDirection => _cameras.isNotEmpty
      ? _cameras[_activeCameraIndex].lensDirection
      : CameraLensDirection.back;

  Duration get currentRecordingDuration {
    if (!_isRecording || _recordingStartedAt == null) return Duration.zero;
    return DateTime.now().difference(_recordingStartedAt!);
  }

  Future<void> initialize() async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) {
      throw CameraException('no_cameras', 'No cameras found on device.');
    }
    _capabilities = _detectCapabilities(_cameras);
    final backIdx =
        _cameras.indexWhere((c) => c.lensDirection == CameraLensDirection.back);
    _activeCameraIndex = backIdx >= 0 ? backIdx : 0;
    await _initController(_cameras[_activeCameraIndex]);
  }

  Future<void> _initController(
    CameraDescription camera, {
    StabilizationMode? modeOverride,
  }) async {
    final mode = modeOverride ?? _stabilizationMode;
    final preset = mode == StabilizationMode.native
        ? ResolutionPreset.medium
        : ResolutionPreset.high;

    final old = _controller;
    if (old != null) {
      _isInitialized = false;
      if (_isRecording) {
        try {
          await old.stopVideoRecording();
        } catch (_) {}
        _isRecording = false;
      }
      await old.dispose();
    }

    final controller = CameraController(
      camera,
      preset,
      enableAudio: true,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.yuv420
          : ImageFormatGroup.bgra8888,
    );
    _controller = controller;

    try {
      await controller.initialize();
      try {
        await controller.setExposureMode(ExposureMode.auto);
        await controller.setFocusMode(FocusMode.auto);
      } catch (_) {}
      _isInitialized = true;
      _lastError = null;
      log('[CameraService] initialized: ${camera.lensDirection}, preset: $preset');
    } on CameraException catch (e) {
      _lastError = e.description ?? e.code;
      log('[CameraService] init error: $_lastError');
      rethrow;
    }
  }

  Future<void> setStabilizationMode(StabilizationMode mode) async {
    if (mode == _stabilizationMode) return;
    _stabilizationMode = mode;
    if (_isInitialized && _cameras.isNotEmpty) {
      await _initController(_cameras[_activeCameraIndex], modeOverride: mode);
    }
  }

  StabilizationMode bestAvailableStabilizationMode() {
    if (_capabilities == null) return StabilizationMode.off;
    return _capabilities!.hasStabilization
        ? StabilizationMode.native
        : StabilizationMode.off;
  }

  Future<void> switchCamera() async {
    if (_cameras.length < 2) return;
    _activeCameraIndex = (_activeCameraIndex + 1) % _cameras.length;
    await _initController(_cameras[_activeCameraIndex],
        modeOverride: _stabilizationMode);
  }

  Future<void> startRecording() async {
    if (!_isInitialized || _isRecording || _controller == null) return;
    try {
      await _controller!.startVideoRecording();
      _isRecording = true;
      _recordingStartedAt = DateTime.now();
    } on CameraException catch (e) {
      _lastError = e.description ?? e.code;
      log('[CameraService] startRecording error: $_lastError');
      rethrow;
    }
  }

  Future<RecordingResult?> stopRecording() async {
    if (!_isRecording || _controller == null) return null;
    try {
      final xFile = await _controller!.stopVideoRecording();
      final duration = _recordingStartedAt != null
          ? DateTime.now().difference(_recordingStartedAt!)
          : Duration.zero;
      _isRecording = false;
      _recordingStartedAt = null;
      return RecordingResult(
        videoPath: xFile.path,
        duration: duration,
        timestamp: DateTime.now(),
      );
    } on CameraException catch (e) {
      _lastError = e.description ?? e.code;
      _isRecording = false;
      _recordingStartedAt = null;
      log('[CameraService] stopRecording error: $_lastError');
      rethrow;
    }
  }

  Future<void> setTorchMode(bool on) async {
    if (!_isInitialized || _controller == null) return;
    try {
      await _controller!.setFlashMode(on ? FlashMode.torch : FlashMode.off);
    } catch (_) {}
  }

  Future<void> setZoom(double level) async {
    if (!_isInitialized || _controller == null) return;
    try {
      final min = await _controller!.getMinZoomLevel();
      final max = await _controller!.getMaxZoomLevel();
      await _controller!.setZoomLevel(level.clamp(min, max));
    } catch (_) {}
  }

  Future<String> buildOutputPath({String extension = 'mp4'}) async {
    final dir = await getApplicationDocumentsDirectory();
    final recordingsDir = Directory(p.join(dir.path, 'recordings'));
    if (!await recordingsDir.exists()) {
      await recordingsDir.create(recursive: true);
    }
    final ts = DateTime.now().millisecondsSinceEpoch;
    return p.join(recordingsDir.path, 'mb_$ts.$extension');
  }

  InputImage? inputImageFromCameraImage(
      CameraImage image, CameraDescription sensor) {
    final yPlane = image.planes[0];
    final metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: _getRotation(sensor.sensorOrientation),
      format: _getFormat(image.format.group),
      bytesPerRow: yPlane.bytesPerRow,
    );
    return InputImage.fromBytes(bytes: yPlane.bytes, metadata: metadata);
  }

  InputImageRotation _getRotation(int orientation) =>
      InputImageRotationValue.fromRawValue(orientation) ??
      InputImageRotation.rotation0deg;

  InputImageFormat _getFormat(ImageFormatGroup group) {
    if (group == ImageFormatGroup.yuv420) return InputImageFormat.yuv420;
    if (group == ImageFormatGroup.bgra8888) return InputImageFormat.bgra8888;
    return InputImageFormat.nv21;
  }

  CameraCapabilities _detectCapabilities(List<CameraDescription> cameras) {
    return CameraCapabilities(
      hasStabilization: Platform.isIOS || Platform.isAndroid,
      hasFrontCamera:
          cameras.any((c) => c.lensDirection == CameraLensDirection.front),
      hasUltraWide: cameras.length >= 3,
      hasGyroscope: true,
      hasAccelerometer: true,
      maxResolution: ResolutionPreset.high,
    );
  }

  Future<void> dispose() async {
    if (_isRecording) {
      try {
        await _controller?.stopVideoRecording();
      } catch (_) {}
    }
    await _controller?.dispose();
    _controller = null;
    _isInitialized = false;
    log('[CameraService] disposed');
  }
}
