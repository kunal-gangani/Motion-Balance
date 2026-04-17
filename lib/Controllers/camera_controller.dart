import 'dart:async';
import 'dart:developer' show log;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:motion_balance/Controllers/tracking_controller.dart';

import '../Services/camera_service.dart';
import '../Services/permission_service.dart';

enum CameraScreenStatus {
  initial,
  requestingPermissions,
  initializing,
  ready,
  error,
}

class CameraState {
  final CameraScreenStatus status;
  final bool isRecording;
  final bool isSwitching;
  final bool isFrontCamera;
  final StabilizationMode stabilizationMode;
  final String? errorMessage;
  final Duration recordingDuration;

  const CameraState({
    this.status = CameraScreenStatus.initial,
    this.isRecording = false,
    this.isSwitching = false,
    this.isFrontCamera = false,
    this.stabilizationMode = StabilizationMode.native,
    this.errorMessage,
    this.recordingDuration = Duration.zero,
  });

  CameraState copyWith({
    CameraScreenStatus? status,
    bool? isRecording,
    bool? isSwitching,
    bool? isFrontCamera,
    StabilizationMode? stabilizationMode,
    String? errorMessage,
    bool clearErrorMessage = false,
    Duration? recordingDuration,
  }) {
    return CameraState(
      status: status ?? this.status,
      isRecording: isRecording ?? this.isRecording,
      isSwitching: isSwitching ?? this.isSwitching,
      isFrontCamera: isFrontCamera ?? this.isFrontCamera,
      stabilizationMode: stabilizationMode ?? this.stabilizationMode,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      recordingDuration: recordingDuration ?? this.recordingDuration,
    );
  }
}

class CameraNotifier extends AutoDisposeNotifier<CameraState> {
  late final CameraService _camera;
  late final PermissionService _permission;
  Timer? _timer;

  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.fast,
    ),
  );

  bool _isProcessing = false;

  @override
  CameraState build() {
    _camera = ref.watch(cameraServiceProvider);
    _permission = ref.watch(permissionServiceProvider);

    Future.microtask(initialize);

    ref.onDispose(() {
      _timer?.cancel();
      _faceDetector.close();
    });

    return const CameraState();
  }

  Future<void> initialize() async {
    state = state.copyWith(
      status: CameraScreenStatus.requestingPermissions,
      clearErrorMessage: true,
    );

    final perms = await _permission.requestAll();
    if (!ref.exists(cameraNotifierProvider)) return;

    if (!perms.allGranted) {
      state = state.copyWith(
        status: CameraScreenStatus.error,
        errorMessage: 'Camera and microphone permissions are required.',
      );
      return;
    }

    state = state.copyWith(
      status: CameraScreenStatus.initializing,
      clearErrorMessage: true,
    );

    try {
      await _camera.initialize();
      if (!ref.exists(cameraNotifierProvider)) return;

      state = state.copyWith(
        status: CameraScreenStatus.ready,
        stabilizationMode: _camera.bestAvailableStabilizationMode(),
        isFrontCamera: _camera.activeLensDirection == CameraLensDirection.front,
        clearErrorMessage: true,
      );
      log('Camera ready: ${_camera.activeLensDirection}');
    } catch (e) {
      if (!ref.exists(cameraNotifierProvider)) return;
      state = state.copyWith(
        status: CameraScreenStatus.error,
        errorMessage: e.toString(),
      );
      log('Camera init error: $e');
    }
  }

  void startImageStream() {
    final controller = _camera.controller;
    if (controller == null || !controller.value.isInitialized) return;

    controller.startImageStream((CameraImage image) async {
      if (_isProcessing) return;
      if (!ref.exists(cameraNotifierProvider)) return;
      _isProcessing = true;

      try {
        final inputImage = _camera.inputImageFromCameraImage(
          image,
          controller.description,
        );
        if (inputImage == null) return;

        final payload = _IsolatePayload(
          bytes: inputImage.bytes ?? Uint8List(0),
          width: image.width,
          height: image.height,
          rotation:
              inputImage.metadata?.rotation ?? InputImageRotation.rotation0deg,
          format: inputImage.metadata?.format ?? InputImageFormat.yuv420,
        );

        final faces = await compute(_detectFacesInIsolate, payload);

        if (!ref.exists(cameraNotifierProvider)) return;

        if (faces.isNotEmpty) {
          ref.read(trackingProvider.notifier).updateFacePosition(
                faces.first.boundingBox,
                Size(image.width.toDouble(), image.height.toDouble()),
              );
        } else {
          ref
              .read(trackingProvider.notifier)
              .updateFacePosition(null, Size.zero);
        }
      } catch (e) {
        debugPrint('ML Isolate Error: $e');
      } finally {
        _isProcessing = false;
      }
    });
  }

  void stopImageStream() {
    _camera.controller?.stopImageStream().catchError((_) {});
  }

  Future<void> startRecording() async {
    if (state.isRecording) return;
    try {
      await _camera.startRecording();
      state = state.copyWith(
        isRecording: true,
        recordingDuration: Duration.zero,
      );
      _startDurationTick();
    } catch (e) {
      log('Start recording error: $e');
    }
  }

  Future<RecordingResult?> stopRecording() async {
    if (!state.isRecording) return null;
    try {
      final result = await _camera.stopRecording();
      _timer?.cancel();
      state = state.copyWith(
        isRecording: false,
        recordingDuration: Duration.zero,
      );
      if (result != null) {
        log('Saved: ${result.videoPath} (${result.duration.inSeconds}s)');
      }
      return result;
    } catch (e) {
      log('Stop recording error: $e');
      return null;
    }
  }

  Future<void> toggleRecording() async {
    if (state.isRecording) {
      await stopRecording();
    } else {
      await startRecording();
    }
  }

  void _startDurationTick() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!ref.exists(cameraNotifierProvider) || !state.isRecording) {
        _timer?.cancel();
        return;
      }
      state = state.copyWith(
        recordingDuration: _camera.currentRecordingDuration,
      );
    });
  }

  Future<void> switchCamera() async {
    if (state.isSwitching) return;
    state = state.copyWith(isSwitching: true);
    try {
      await _camera.switchCamera();
      if (!ref.exists(cameraNotifierProvider)) return;
      state = state.copyWith(
        isSwitching: false,
        isFrontCamera: _camera.activeLensDirection == CameraLensDirection.front,
        stabilizationMode: _camera.bestAvailableStabilizationMode(),
      );
    } catch (e) {
      if (!ref.exists(cameraNotifierProvider)) return;
      state = state.copyWith(isSwitching: false);
      log('Switch camera error: $e');
    }
  }

  Future<void> setStabilizationMode(StabilizationMode mode) async {
    try {
      await _camera.setStabilizationMode(mode);
      if (!ref.exists(cameraNotifierProvider)) return;
      state = state.copyWith(stabilizationMode: mode);
    } catch (e) {
      log('Set stabilization error: $e');
    }
  }

  Future<void> openPermissionSettings() => _permission.openSettings();

  void openGallery() => log('Gallery opened');
}

final cameraNotifierProvider =
    NotifierProvider.autoDispose<CameraNotifier, CameraState>(
  CameraNotifier.new,
);

class _IsolatePayload {
  final Uint8List bytes;
  final int width;
  final int height;
  final InputImageRotation rotation;
  final InputImageFormat format;

  const _IsolatePayload({
    required this.bytes,
    required this.width,
    required this.height,
    required this.rotation,
    required this.format,
  });
}

Future<List<Face>> _detectFacesInIsolate(_IsolatePayload payload) async {
  final inputImage = InputImage.fromBytes(
    bytes: payload.bytes,
    metadata: InputImageMetadata(
      size: Size(payload.width.toDouble(), payload.height.toDouble()),
      rotation: payload.rotation,
      format: payload.format,
      bytesPerRow: payload.width,
    ),
  );

  final detector = FaceDetector(
    options: FaceDetectorOptions(performanceMode: FaceDetectorMode.fast),
  );

  try {
    return await detector.processImage(inputImage);
  } finally {
    await detector.close();
  }
}
