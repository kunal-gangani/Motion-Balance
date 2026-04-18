import 'dart:collection';
import 'dart:math';
import '../Models/shot_type.dart';

class SensorSample {
  final double accelX;
  final double accelY;
  final double accelZ;
  final double gyroX;
  final double gyroY;
  final double gyroZ;
  final DateTime timestamp;

  const SensorSample({
    required this.accelX,
    required this.accelY,
    required this.accelZ,
    required this.gyroX,
    required this.gyroY,
    required this.gyroZ,
    required this.timestamp,
  });
}

class ShotClassifierService {
  static const int _windowSize = 30;
  static const double _gyroThreshold = 2.0;
  static const double _accelThreshold = 0.3;
  static const double _walkFreqMin = 1.4;
  static const double _walkFreqMax = 3.2;

  final Queue<SensorSample> _window = Queue();

  void addSample(SensorSample sample) {
    _window.addLast(sample);
    if (_window.length > _windowSize) _window.removeFirst();
  }

  ShotType classify() {
    if (_window.length < 5) return ShotType.staticShot;

    final samples = _window.toList();

    final double rmsGyroZ = _rms(samples.map((s) => s.gyroZ));
    final double rmsGyroX = _rms(samples.map((s) => s.gyroX));
    final double rmsGyroY = _rms(samples.map((s) => s.gyroY));
    final double rmsAccelZ = _rms(samples.map((s) => s.accelZ));
    final double totalGyro = rmsGyroX + rmsGyroY + rmsGyroZ;
    final double totalAccel = rmsAccelZ;

    if (totalGyro < _gyroThreshold && totalAccel < _accelThreshold) {
      return ShotType.staticShot;
    }
    if (_isWalking(samples)) return ShotType.walk;

    if (rmsGyroZ > _gyroThreshold &&
        rmsGyroZ > rmsGyroX * 2.0 &&
        rmsGyroZ > rmsGyroY * 2.0) {
      return ShotType.pan;
    }

    if (rmsGyroX > _gyroThreshold &&
        rmsGyroX > rmsGyroZ * 2.0 &&
        rmsGyroX > rmsGyroY * 2.0) {
      return ShotType.tilt;
    }

    if (rmsAccelZ > _accelThreshold * 2 && totalGyro < _gyroThreshold * 1.5) {
      return ShotType.dolly;
    }

    return ShotType.freehand;
  }

  bool _isWalking(List<SensorSample> samples) {
    if (samples.length < 10) return false;

    final yAccels = samples.map((s) => s.accelY).toList();
    final mean = yAccels.reduce((a, b) => a + b) / yAccels.length;
    int crossings = 0;
    bool wasPositive = yAccels.first - mean > 0;
    for (int i = 1; i < yAccels.length; i++) {
      final bool isPositive = yAccels[i] - mean > 0;
      if (isPositive != wasPositive) {
        crossings++;
        wasPositive = isPositive;
      }
    }

    if (samples.length < 2) return false;
    final durationMs = samples.last.timestamp
        .difference(samples.first.timestamp)
        .inMilliseconds;
    if (durationMs <= 0) return false;

    final double freq = (crossings / 2) / (durationMs / 1000.0);
    final double rmsY = _rms(samples.map((s) => s.accelY - mean));

    return freq >= _walkFreqMin &&
        freq <= _walkFreqMax &&
        rmsY > _accelThreshold;
  }

  double _rms(Iterable<double> values) {
    final list = values.toList();
    if (list.isEmpty) return 0.0;
    final sumSq = list.fold(0.0, (acc, v) => acc + v * v);
    return sqrt(sumSq / list.length);
  }

  void reset() => _window.clear();
}
