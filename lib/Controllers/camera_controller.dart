import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/camera_service.dart';
import '../services/permission_service.dart';


enum CameraScreenStatus {
  initial,
  requestingPermissions,
  initializing,
  ready,
  error
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

// ─── Notifier ─────────────────────────────────────────────────────────────────

class CameraNotifier extends AutoDisposeNotifier<CameraState> {
  late final CameraService _camera;
  late final PermissionService _permission;

  @override
  CameraState build() {
    _camera = ref.watch(cameraServiceProvider);
    _permission = ref.watch(permissionServiceProvider);
    // Kick off init as soon as the notifier is built
    Future.microtask(initialize);
    return const CameraState();
  }

  Future<void> initialize() async {
    state = state.copyWith(status: CameraScreenStatus.requestingPermissions);

    final perms = await _permission.requestAll();
    if (!perms.allGranted) {
      state = state.copyWith(
        status: CameraScreenStatus.error,
        errorMessage: 'Camera and microphone permissions are required.',
      );
      return;
    }

    state = state.copyWith(status: CameraScreenStatus.initializing);

    try {
      await _camera.initialize();
      final bestMode = _camera.bestAvailableStabilizationMode();
      state = state.copyWith(
        status: CameraScreenStatus.ready,
        stabilizationMode: bestMode,
        isFrontCamera: _camera.activeLensDirection.name == 'front',
      );
    } catch (e) {
      state = state.copyWith(
        status: CameraScreenStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> startRecording() async {
    if (state.isRecording) return;
    await _camera.startRecording();
    state = state.copyWith(isRecording: true, recordingDuration: Duration.zero);
    _startDurationTick();
  }

  Future<RecordingResult?> stopRecording() async {
    if (!state.isRecording) return null;
    final result = await _camera.stopRecording();
    state =
        state.copyWith(isRecording: false, recordingDuration: Duration.zero);
    return result;
  }

  void _startDurationTick() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!state.isRecording) return false;
      state = state.copyWith(
        recordingDuration: _camera.currentRecordingDuration,
      );
      return true;
    });
  }

  Future<void> switchCamera() async {
    if (state.isSwitching) return;
    state = state.copyWith(isSwitching: true);
    await _camera.switchCamera();
    state = state.copyWith(
      isSwitching: false,
      isFrontCamera: _camera.activeLensDirection.name == 'front',
    );
  }

  Future<void> setStabilizationMode(StabilizationMode mode) async {
    await _camera.setStabilizationMode(mode);
    state = state.copyWith(stabilizationMode: mode);
  }

  Future<void> openPermissionSettings() => _permission.openSettings();
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final cameraNotifierProvider =
    NotifierProvider.autoDispose<CameraNotifier, CameraState>(
  CameraNotifier.new,
);
