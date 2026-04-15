import 'dart:async';
import 'dart:developer' show log;
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

// ─── Providers ────────────────────────────────────────────────────────────────

final cameraServiceProvider = Provider<CameraService>((ref) {
  final service = CameraService();
  ref.onDispose(service.dispose);
  return service;
});

// ─── Enums & Data Classes ─────────────────────────────────────────────────────

/// The three stabilization modes MotionBalance supports.
///
/// - [off]      : No stabilization applied.
/// - [native]   : OS-level OIS/EIS. Enabled by re-initializing the controller
///                at [ResolutionPreset.medium] or below — the camera plugin
///                activates OIS automatically at those presets on most devices.
///                There is NO `setVideoStabilizationMode` API in the Flutter
///                camera plugin; stabilization is implicit.
/// - [software] : Software warp via sensor data (Phase 2). Placeholder here.
enum StabilizationMode { off, native, software }

class CameraCapabilities {
  final bool hasStabilization;
  final bool hasFrontCamera;
  final bool hasUltraWide;
  final ResolutionPreset maxResolution;

  const CameraCapabilities({
    required this.hasStabilization,
    required this.hasFrontCamera,
    required this.hasUltraWide,
    required this.maxResolution,
  });
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

// ─── Camera Service ───────────────────────────────────────────────────────────

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

  // ── Getters ────────────────────────────────────────────────────────────────

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

  // ── Initialization ─────────────────────────────────────────────────────────

  Future<void> initialize() async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) {
      throw CameraException('no_cameras', 'No cameras found on device.');
    }

    _capabilities = _detectCapabilities(_cameras);

    // Prefer back camera
    final backIdx = _cameras.indexWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
    );
    _activeCameraIndex = backIdx >= 0 ? backIdx : 0;

    await _initController(_cameras[_activeCameraIndex]);
  }

  Future<void> _initController(
    CameraDescription camera, {
    StabilizationMode? modeOverride,
  }) async {
    final mode = modeOverride ?? _stabilizationMode;

    // OIS/EIS on the Flutter camera plugin is NOT a runtime API call.
    // It is implicitly activated by the OS at medium/low resolutions.
    // - native mode  → ResolutionPreset.medium  (OS enables OIS/EIS)
    // - off/software → ResolutionPreset.high    (OS may disable OIS)
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

      // Set auto exposure & focus for best stability
      try {
        await controller.setExposureMode(ExposureMode.auto);
        await controller.setFocusMode(FocusMode.auto);
      } catch (_) {
        // Not critical — some devices/emulators don't support these
      }

      _isInitialized = true;
      _lastError = null;
      log('[CameraService] initialized: ${camera.lensDirection}, preset: $preset');
    } on CameraException catch (e) {
      _lastError = e.description ?? e.code;
      log('[CameraService] init error: $_lastError');
      rethrow;
    }
  }

  // ── Stabilization ──────────────────────────────────────────────────────────

  /// Updates the stabilization mode.
  ///
  /// **Important**: The Flutter camera plugin has no `setVideoStabilizationMode`
  /// call. To switch between native (OIS) and off, we re-initialize the
  /// controller at a different [ResolutionPreset]. This is the correct approach.
  Future<void> setStabilizationMode(StabilizationMode mode) async {
    if (mode == _stabilizationMode) return;
    _stabilizationMode = mode;

    if (_isInitialized && _cameras.isNotEmpty) {
      await _initController(
        _cameras[_activeCameraIndex],
        modeOverride: mode,
      );
    }
  }

  /// Returns the best mode this device can actually support.
  StabilizationMode bestAvailableStabilizationMode() {
    if (_capabilities == null) return StabilizationMode.off;
    if (_capabilities!.hasStabilization) return StabilizationMode.native;
    return StabilizationMode.off;
  }

  // ── Camera Switching ───────────────────────────────────────────────────────

  Future<void> switchCamera() async {
    if (_cameras.length < 2) return;
    _activeCameraIndex = (_activeCameraIndex + 1) % _cameras.length;
    await _initController(
      _cameras[_activeCameraIndex],
      modeOverride: _stabilizationMode,
    );
  }

  // ── Recording ──────────────────────────────────────────────────────────────

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

  // ── Helpers ────────────────────────────────────────────────────────────────

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
    final ts = DateTime.now().millisecondsSinceEpoch;
    return p.join(dir.path, 'mb_$ts.$extension');
  }

  // ── Capability Detection ───────────────────────────────────────────────────

  CameraCapabilities _detectCapabilities(List<CameraDescription> cameras) {
    return CameraCapabilities(
      // OIS is available on virtually all physical iOS/Android rear cameras.
      // The plugin cannot query it directly — assume true on real devices.
      hasStabilization: Platform.isIOS || Platform.isAndroid,
      hasFrontCamera: cameras.any(
        (c) => c.lensDirection == CameraLensDirection.front,
      ),
      // Heuristic: 3+ cameras usually means an ultra-wide is present
      hasUltraWide: cameras.length >= 3,
      maxResolution: ResolutionPreset.high,
    );
  }

  // ── Dispose ────────────────────────────────────────────────────────────────

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
