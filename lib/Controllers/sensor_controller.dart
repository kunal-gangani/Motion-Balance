import 'dart:async';
import 'dart:math' hide log;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';

class SensorState {
  final double currentShake;
  final double currentRoll;
  final String guidanceText;
  final double smoothnessScore;
  final bool gyroscopeAvailable;
  final bool accelerometerAvailable;

  const SensorState({
    this.currentShake = 0.0,
    this.currentRoll = 0.0,
    this.guidanceText = 'Stable',
    this.smoothnessScore = 100.0,
    this.gyroscopeAvailable = true,
    this.accelerometerAvailable = true,
  });

  double get shakeIntensity => currentShake;

  SensorState copyWith({
    double? currentShake,
    double? currentRoll,
    String? guidanceText,
    double? smoothnessScore,
    bool? gyroscopeAvailable,
    bool? accelerometerAvailable,
  }) {
    return SensorState(
      currentShake: currentShake ?? this.currentShake,
      currentRoll: currentRoll ?? this.currentRoll,
      guidanceText: guidanceText ?? this.guidanceText,
      smoothnessScore: smoothnessScore ?? this.smoothnessScore,
      gyroscopeAvailable: gyroscopeAvailable ?? this.gyroscopeAvailable,
      accelerometerAvailable:
          accelerometerAvailable ?? this.accelerometerAvailable,
    );
  }
}

class SensorNotifier extends StateNotifier<SensorState> {
  StreamSubscription<UserAccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;

  double _lastMagnitude = 0.0;
  double _smoothedShake = 0.0;
  double _filteredRoll = 0.0;
  DateTime? _lastGyroTime;

  static const double _alpha = 0.96;

  SensorNotifier() : super(const SensorState()) {
    _initSensors();
  }

  void _initSensors() {
    _listenAccelerometer();
    _listenGyroscope();
  }

  void _listenAccelerometer() {
    _accelSub = userAccelerometerEventStream(
      samplingPeriod: SensorInterval.uiInterval,
    ).listen(
      (event) {
        final magnitude =
            sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
        final delta = (magnitude - _lastMagnitude).abs();
        _lastMagnitude = magnitude;
        _smoothedShake = (_smoothedShake * 0.8) + (delta * 0.2);
        final accelRoll = atan2(event.y, event.z) * (180 / pi);
        state = state.copyWith(
          currentShake: _smoothedShake,
          guidanceText: _generateGuidance(_smoothedShake),
          smoothnessScore: _calculateSmoothnessScore(_smoothedShake),
          accelerometerAvailable: true,
        );

        _filteredRoll = _alpha * _filteredRoll + (1 - _alpha) * accelRoll;
      },
      onError: (_) => state = state.copyWith(accelerometerAvailable: false),
    );
  }

  void _listenGyroscope() {
    _gyroSub = gyroscopeEventStream(
      samplingPeriod: SensorInterval.uiInterval,
    ).listen(
      (event) {
        final now = DateTime.now();
        final dt = _lastGyroTime != null
            ? now.difference(_lastGyroTime!).inMicroseconds / 1e6
            : 0.01;
        _lastGyroTime = now;
        final gyroDelta = event.z * dt * (180 / pi);
        _filteredRoll = _alpha * (_filteredRoll + gyroDelta);

        state = state.copyWith(
          currentRoll: _filteredRoll,
          gyroscopeAvailable: true,
        );
      },
      onError: (_) => state = state.copyWith(gyroscopeAvailable: false),
    );
  }

  void updateRoll(double rollDegrees) {
    if ((state.currentRoll - rollDegrees).abs() < 0.01) return;
    state = state.copyWith(currentRoll: rollDegrees);
  }

  String _generateGuidance(double shake) {
    if (shake > 6.0) return 'REDUCE SUDDEN PANS';
    if (shake > 4.0) return 'MOVE SLOWER';
    if (shake > 2.0) return 'SMOOTH PANNING';
    return 'STABLE';
  }

  double _calculateSmoothnessScore(double shake) {
    return (100 - (shake * 12)).clamp(0.0, 100.0);
  }

  void reset() {
    _smoothedShake = 0.0;
    _lastMagnitude = 0.0;
    _filteredRoll = 0.0;
    _lastGyroTime = null;
    state = const SensorState();
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _gyroSub?.cancel();
    super.dispose();
  }
}

final sensorControllerProvider =
    StateNotifierProvider<SensorNotifier, SensorState>(
  (ref) => SensorNotifier(),
);
