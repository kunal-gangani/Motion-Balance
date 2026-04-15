class MotionData {
  final double accelX;
  final double accelY;
  final double accelZ;

  final double gyroX;
  final double gyroY;
  final double gyroZ;

  final DateTime timestamp;

  const MotionData({
    required this.accelX,
    required this.accelY,
    required this.accelZ,
    required this.gyroX,
    required this.gyroY,
    required this.gyroZ,
    required this.timestamp,
  });

  factory MotionData.zero() {
    return MotionData(
      accelX: 0.0,
      accelY: 0.0,
      accelZ: 0.0,
      gyroX: 0.0,
      gyroY: 0.0,
      gyroZ: 0.0,
      timestamp: DateTime.now(),
    );
  }

  double get accelerationMagnitude {
    return (accelX * accelX + accelY * accelY + accelZ * accelZ).sqrtSafe();
  }

  double get gyroscopeMagnitude {
    return (gyroX * gyroX + gyroY * gyroY + gyroZ * gyroZ).sqrtSafe();
  }
  bool get isShaking => accelerationMagnitude > 1.8;
  bool get isSuddenPan => gyroZ.abs() > 3.2;

  Map<String, dynamic> toJson() {
    return {
      'accelX': accelX,
      'accelY': accelY,
      'accelZ': accelZ,
      'gyroX': gyroX,
      'gyroY': gyroY,
      'gyroZ': gyroZ,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory MotionData.fromJson(Map<String, dynamic> json) {
    return MotionData(
      accelX: (json['accelX'] as num).toDouble(),
      accelY: (json['accelY'] as num).toDouble(),
      accelZ: (json['accelZ'] as num).toDouble(),
      gyroX: (json['gyroX'] as num).toDouble(),
      gyroY: (json['gyroY'] as num).toDouble(),
      gyroZ: (json['gyroZ'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  MotionData copyWith({
    double? accelX,
    double? accelY,
    double? accelZ,
    double? gyroX,
    double? gyroY,
    double? gyroZ,
    DateTime? timestamp,
  }) {
    return MotionData(
      accelX: accelX ?? this.accelX,
      accelY: accelY ?? this.accelY,
      accelZ: accelZ ?? this.accelZ,
      gyroX: gyroX ?? this.gyroX,
      gyroY: gyroY ?? this.gyroY,
      gyroZ: gyroZ ?? this.gyroZ,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'MotionData('
        'accel=[$accelX, $accelY, $accelZ], '
        'gyro=[$gyroX, $gyroY, $gyroZ], '
        'timestamp=$timestamp)';
  }
}

extension SafeSqrt on num {
  double sqrtSafe() {
    return this <= 0 ? 0.0 : (this as double).sqrtInternal();
  }

  double sqrtInternal() {
    double x = toDouble();
    double guess = x / 2;
    for (int i = 0; i < 10; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }
}
