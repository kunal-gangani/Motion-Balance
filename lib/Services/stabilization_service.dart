import 'dart:math';
import '../Models/motion_data.dart';

enum StabilityLevel { excellent, good, moderate, poor }

class StabilizationResult {
  final double smoothnessScore;
  final StabilityLevel level;
  final String guidanceMessage;
  final bool needsLevelCorrection;
  final bool suddenPanDetected;

  const StabilizationResult({
    required this.smoothnessScore,
    required this.level,
    required this.guidanceMessage,
    required this.needsLevelCorrection,
    required this.suddenPanDetected,
  });
}

class StabilizationService {
  static const double shakeThreshold = 1.8;
  static const double panThreshold = 3.2;  
  static const double tiltThreshold = 12.0; 

  StabilizationResult analyzeMotion(MotionData motion) {
    final shakeMagnitude = _calculateShakeMagnitude(motion);
    final tiltAngle = motion.rollDegrees.abs();
    final suddenPan = motion.gyroZ.abs() > panThreshold;

    final smoothness =
        _calculateSmoothness(shakeMagnitude, tiltAngle, suddenPan);
    final level = _getStabilityLevel(smoothness);
    final guidance =
        _generateGuidance(shakeMagnitude, tiltAngle, suddenPan, smoothness);

    return StabilizationResult(
      smoothnessScore: smoothness,
      level: level,
      guidanceMessage: guidance,
      needsLevelCorrection: tiltAngle > tiltThreshold,
      suddenPanDetected: suddenPan,
    );
  }

  double _calculateShakeMagnitude(MotionData motion) {
    return sqrt(
      motion.accelX * motion.accelX +
          motion.accelY * motion.accelY +
          motion.accelZ * motion.accelZ,
    );
  }

  double _calculateSmoothness(
      double shake, double tilt, bool suddenPan) {
    double score = 100;
    score -= shake * 15;
    score -= tilt * 0.8;
    if (suddenPan) score -= 20;
    return score.clamp(0.0, 100.0);
  }

  StabilityLevel _getStabilityLevel(double score) {
    if (score >= 85) return StabilityLevel.excellent;
    if (score >= 70) return StabilityLevel.good;
    if (score >= 50) return StabilityLevel.moderate;
    return StabilityLevel.poor;
  }

  String _generateGuidance(
      double shake, double tilt, bool suddenPan, double score) {
    if (tilt > tiltThreshold) return 'Hold phone level';
    if (suddenPan) return 'Reduce sudden pans';
    if (shake > shakeThreshold) return 'Move slower';
    if (score < 40) return 'Use both hands for a steadier shot';
    return 'Stable shot';
  }
}