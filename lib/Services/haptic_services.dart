import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibration/vibration.dart';

final hapticServiceProvider = Provider((_) => HapticService());

class HapticService {
  bool? _hasVibrator;

  Future<bool> _canVibrate() async {
    _hasVibrator ??= await Vibration.hasVibrator() ?? false;
    return _hasVibrator!;
  }

  Future<void> _vibrate({int duration = 50, int amplitude = -1}) async {
    if (!await _canVibrate()) return;
    Vibration.vibrate(duration: duration, amplitude: amplitude);
  }

  Future<void> _vibratePattern(List<int> pattern) async {
    Vibration.vibrate(pattern: pattern);
  }

  void triggerLockSuccess() {
    _vibrate(duration: 40);
  }

  void triggerSubjectLost() {
    _vibratePattern([0, 50, 50, 50]);
  }

  void triggerStabilityWarning() {
    _vibrate(duration: 100, amplitude: 255);
  }
}
