import 'package:vibration/vibration.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final hapticServiceProvider = Provider((ref) => HapticService());

class HapticService {
  Future<void> _vibrate({int duration = 50, int amplitude = -1}) async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: duration, amplitude: amplitude);
    }
  }

  void triggerLockSuccess() {
    _vibrate(duration: 40); 
  }

  void triggerSubjectLost() {
    Vibration.vibrate(pattern: [0, 50, 50, 50]);
  }
  void triggerStabilityWarning() {
    _vibrate(duration: 100, amplitude: 255);
  }
}