import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../Models/shot_type.dart';
import '../Services/camera_service.dart';
import '../Services/kalman_filter.dart';
import '../Services/shot_classifier_service.dart';

class StabilizationIntelligenceState {
  final double rollDegrees;
  final double pitchDegrees;
  final double angularVelocity;
  final ShotType shotType;
  final double aggressiveness;
  final double smoothnessScore;
  final bool didAdjustCamera;

  const StabilizationIntelligenceState({
    this.rollDegrees = 0.0,
    this.pitchDegrees = 0.0,
    this.angularVelocity = 0.0,
    this.shotType = ShotType.staticShot,
    this.aggressiveness = 0.2,
    this.smoothnessScore = 100.0,
    this.didAdjustCamera = false,
  });

  StabilizationIntelligenceState copyWith({
    double? rollDegrees,
    double? pitchDegrees,
    double? angularVelocity,
    ShotType? shotType,
    double? aggressiveness,
    double? smoothnessScore,
    bool? didAdjustCamera,
  }) {
    return StabilizationIntelligenceState(
      rollDegrees: rollDegrees ?? this.rollDegrees,
      pitchDegrees: pitchDegrees ?? this.pitchDegrees,
      angularVelocity: angularVelocity ?? this.angularVelocity,
      shotType: shotType ?? this.shotType,
      aggressiveness: aggressiveness ?? this.aggressiveness,
      smoothnessScore: smoothnessScore ?? this.smoothnessScore,
      didAdjustCamera: didAdjustCamera ?? this.didAdjustCamera,
    );
  }
}

class StabilizationIntelligenceNotifier
    extends StateNotifier<StabilizationIntelligenceState> {
  final Ref ref;
  final KalmanFilter _rollKalman =
      KalmanFilter(processNoise: 0.001, measurementNoise: 0.1);
  final KalmanFilter _pitchKalman =
      KalmanFilter(processNoise: 0.001, measurementNoise: 0.1);

  final ShotClassifierService _classifier = ShotClassifierService();

  StreamSubscription<UserAccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  double _gyroX = 0.0;
  double _gyroY = 0.0;
  double _gyroZ = 0.0;

  DateTime? _lastAccelTime;
  DateTime? _lastGyroTime;
  ShotType? _lastAutoAdjustedType;
  DateTime? _lastAutoAdjustTime;

  StabilizationIntelligenceNotifier(this.ref)
      : super(const StabilizationIntelligenceState()) {
    _startListening();
  }

  void _startListening() {
    _gyroSub = gyroscopeEventStream(
      samplingPeriod: SensorInterval.uiInterval,
    ).listen((event) {
      final now = DateTime.now();
      _lastGyroTime = now;
      _gyroX = event.x * (180 / pi);
      _gyroY = event.y * (180 / pi);
      _gyroZ = event.z * (180 / pi);
    });

    _accelSub = userAccelerometerEventStream(
      samplingPeriod: SensorInterval.uiInterval,
    ).listen((event) {
      final now = DateTime.now();
      final double dt = _lastAccelTime != null
          ? now.difference(_lastAccelTime!).inMicroseconds / 1e6
          : 0.016;
      _lastAccelTime = now;

      final double accelRoll = atan2(event.y, event.z) * (180 / pi);
      final double accelPitch =
          atan2(-event.x, sqrt(event.y * event.y + event.z * event.z)) *
              (180 / pi);
      final double roll = _rollKalman.update(_gyroY, accelRoll, dt);
      final double pitch = _pitchKalman.update(_gyroX, accelPitch, dt);
      _classifier.addSample(SensorSample(
        accelX: event.x,
        accelY: event.y,
        accelZ: event.z,
        gyroX: _gyroX,
        gyroY: _gyroY,
        gyroZ: _gyroZ,
        timestamp: now,
      ));

      final ShotType shotType = _classifier.classify();
      final double aggressiveness = shotType.stabilizationAggressiveness;
      final double smoothness = _calculateSmoothness(event, shotType);
      _maybeAutoAdjust(shotType);

      state = state.copyWith(
        rollDegrees: roll,
        pitchDegrees: pitch,
        angularVelocity: _rollKalman.angularVelocity,
        shotType: shotType,
        aggressiveness: aggressiveness,
        smoothnessScore: smoothness,
        didAdjustCamera: false,
      );
    });
  }

  Future<void> _maybeAutoAdjust(ShotType newType) async {
    if (newType == _lastAutoAdjustedType) return;

    final now = DateTime.now();
    if (_lastAutoAdjustTime != null &&
        now.difference(_lastAutoAdjustTime!).inSeconds < 2) {
      return;
    }

    _lastAutoAdjustedType = newType;
    _lastAutoAdjustTime = now;

    final cameraService = ref.read(cameraServiceProvider);
    if (!cameraService.isInitialized) return;

    final targetMode = newType.preferNativeStabilization
        ? StabilizationMode.native
        : StabilizationMode.off;

    if (cameraService.stabilizationMode != targetMode) {
      await cameraService.setStabilizationMode(targetMode);
    }
  }

  double _calculateSmoothness(UserAccelerometerEvent event, ShotType shotType) {
    final magnitude =
        sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
    final penalty =
        magnitude * (1.0 - shotType.stabilizationAggressiveness * 0.3);
    return (100 - penalty * 15).clamp(0.0, 100.0);
  }

  void reset() {
    _rollKalman.reset();
    _pitchKalman.reset();
    _classifier.reset();
    _lastAutoAdjustedType = null;
    state = const StabilizationIntelligenceState();
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _gyroSub?.cancel();
    super.dispose();
  }
}

final stabilizationIntelligenceProvider = StateNotifierProvider<
    StabilizationIntelligenceNotifier, StabilizationIntelligenceState>(
  (ref) => StabilizationIntelligenceNotifier(ref),
);
