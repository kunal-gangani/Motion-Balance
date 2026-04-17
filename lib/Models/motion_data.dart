class MotionData {
  final double accelX;
  final double accelY;
  final double accelZ;
  final double gyroZ;
  final double rollDegrees;

  const MotionData({
    required this.accelX,
    required this.accelY,
    required this.accelZ,
    required this.gyroZ,
    required this.rollDegrees,
  });

  factory MotionData.fromSensor({
    required double shake,
    required double roll,
    double gyroZ = 0.0,
  }) {
    final axis = shake / 1.732;
    return MotionData(
      accelX: axis,
      accelY: axis,
      accelZ: axis,
      gyroZ: gyroZ,
      rollDegrees: roll,
    );
  }
}
