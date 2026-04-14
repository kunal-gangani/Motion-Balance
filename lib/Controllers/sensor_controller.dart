import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';

class SensorController {
  StreamSubscription<UserAccelerometerEvent>? _accelSub;
  double currentShake = 0.0;
  
  // Callback to update the View
  Function(double shake, double roll)? onDataUpdate;

  void startListening() {
    _accelSub = userAccelerometerEventStream().listen((event) {
      // Calculate magnitude of movement
      currentShake = (event.x.abs() + event.y.abs() + event.z.abs()) / 3;
      
      // Calculate roll for horizon (simplified)
      double roll = event.x / 9.81; 
      
      onDataUpdate?.call(currentShake, roll);
    });
  }

  void dispose() {
    _accelSub?.cancel();
  }

  String getGuidance(double shake) {
    if (shake > 5.0) return "MOVE SLOWER";
    if (shake > 2.0) return "SMOOTH PANNING";
    return "STABLE";
  }
}