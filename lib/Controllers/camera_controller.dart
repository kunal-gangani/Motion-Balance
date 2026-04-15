import 'dart:async';
import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_balance/Services/permission_service.dart';
import '../Services/camera_service.dart';

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
    Duration? recordingDuration,
  }) {
    return CameraState(
      status: status ?? this.status,
      isRecording: isRecording ?? this.isRecording,
      isSwitching: isSwitching ?? this.isSwitching,
      isFrontCamera: isFrontCamera ?? this.isFrontCamera,
      stabilizationMode: stabilizationMode ?? this.stabilizationMode,
      errorMessage: errorMessage ?? this.errorMessage,
      recordingDuration: recordingDuration ?? this.recordingDuration,
    );
  }
}

class CameraNotifier extends AutoDisposeNotifier<CameraState> {
  late final CameraService _camera;
  late final PermissionService _permission;
  Timer? _timer;

  @override
  CameraState build() {
    _camera = ref.watch(cameraServiceProvider);
    _permission = ref.watch(permissionServiceProvider);

    Future.microtask(initialize);

    ref.onDispose(() {
      _timer?.cancel();
    });

    return const CameraState();
  }

  Future<void> initialize() async {
    state = state.copyWith(
      status: CameraScreenStatus.requestingPermissions,
    );

    final perms = await _permission.requestAll();

    if (!perms.allGranted) {
      state = state.copyWith(
        status: CameraScreenStatus.error,
        errorMessage: "Camera and microphone permissions required.",
      );
      return;
    }

    state = state.copyWith(
      status: CameraScreenStatus.initializing,
    );

    try {
      await _camera.initialize();

      state = state.copyWith(
        status: CameraScreenStatus.ready,
        stabilizationMode: _camera.bestAvailableStabilizationMode(),
        isFrontCamera: _camera.activeLensDirection.name == "front",
      );
    } catch (e) {
      state = state.copyWith(
        status: CameraScreenStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> startRecording() async {
    await _camera.startRecording();

    state = state.copyWith(
      isRecording: true,
      recordingDuration: Duration.zero,
    );

    _startTimer();
  }

  Future<void> stopRecording() async {
    await _camera.stopRecording();

    _timer?.cancel();

    state = state.copyWith(
      isRecording: false,
      recordingDuration: Duration.zero,
    );
  }

  Future<void> toggleRecording() async {
    if (state.isRecording) {
      await stopRecording();
    } else {
      await startRecording();
    }
  }

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        state = state.copyWith(
          recordingDuration: _camera.currentRecordingDuration,
        );
      },
    );
  }

  Future<void> switchCamera() async {
    state = state.copyWith(isSwitching: true);

    await _camera.switchCamera();

    state = state.copyWith(
      isSwitching: false,
      isFrontCamera: _camera.activeLensDirection.name == "front",
    );
  }

  Future<void> setStabilizationMode(StabilizationMode mode) async {
    await _camera.setStabilizationMode(mode);

    state = state.copyWith(
      stabilizationMode: mode,
    );
  }

  Future<void> openPermissionSettings() => _permission.openSettings();

  void openGallery() {
    log("Open Gallery Clicked");
  }
}

final cameraNotifierProvider =
    NotifierProvider.autoDispose<CameraNotifier, CameraState>(
  CameraNotifier.new,
);
