class KalmanFilter {
  final double processNoise;
  final double measurementNoise;
  double _angle = 0.0;
  double _bias = 0.0;

  double _p00 = 0.0;
  double _p01 = 0.0;
  double _p10 = 0.0;
  double _p11 = 0.0;

  KalmanFilter({
    this.processNoise = 0.001,
    this.measurementNoise = 0.1,
  });

  double get angle => _angle;
  double get bias => _bias;
  double _lastRate = 0.0;
  double get angularVelocity => _lastRate;

  double update(double gyroRate, double accelAngle, double dt) {
    final double rate = gyroRate - _bias;
    _lastRate = rate;
    _angle += dt * rate;

    _p00 += dt * (dt * _p11 - _p01 - _p10 + processNoise);
    _p01 -= dt * _p11;
    _p10 -= dt * _p11;
    _p11 += processNoise * dt;

    final double s = _p00 + measurementNoise;
    final double k0 = _p00 / s;
    final double k1 = _p10 / s;

    final double y = accelAngle - _angle;
    _angle += k0 * y;
    _bias += k1 * y;

    final double p00Tmp = _p00;
    final double p01Tmp = _p01;
    _p00 -= k0 * p00Tmp;
    _p01 -= k0 * p01Tmp;
    _p10 -= k1 * p00Tmp;
    _p11 -= k1 * p01Tmp;

    return _angle;
  }

  void reset() {
    _angle = 0.0;
    _bias = 0.0;
    _p00 = 0.0;
    _p01 = 0.0;
    _p10 = 0.0;
    _p11 = 0.0;
    _lastRate = 0.0;
  }
}
