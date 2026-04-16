import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_balance/Services/haptic_services.dart';
import 'package:motion_balance/Controllers/sensor_controller.dart';
import '../Models/tracking_state.dart';

class TrackingNotifier extends StateNotifier<TrackingState> {
  final Ref ref;

  TrackingNotifier(this.ref) : super(const TrackingState());
  void updateFacePosition(Rect? boundingBox, Size imageSize) {
    final haptics = ref.read(hapticServiceProvider);
    final sensorState = ref.read(sensorControllerProvider);
    final double handVelocityX = sensorState.currentRoll;

    if (boundingBox == null) {
      if (state.isLocked) haptics.triggerSubjectLost();
      state = state.copyWith(isLocked: false, instruction: "SEARCHING...");
      return;
    }

    if (!state.isLocked) haptics.triggerLockSuccess();
    final double faceCenterX =
        (boundingBox.left + boundingBox.right) / 2 / imageSize.width;
    final double faceCenterY =
        (boundingBox.top + boundingBox.bottom) / 2 / imageSize.height;

    final double offsetX = faceCenterX - 0.5;
    final double offsetY = faceCenterY - 0.5;

    String guidance = "CENTERED";

    if (offsetX < -0.15) {
      guidance =
          (handVelocityX < -2.0) ? "⚠️ OVERSTEER: SLOW DOWN" : "← PAN LEFT";
    } else if (offsetX > 0.15) {
      guidance =
          (handVelocityX > 2.0) ? "⚠️ OVERSTEER: SLOW DOWN" : "PAN RIGHT →";
    } else if (offsetY > 0.15) {
      guidance = "TILT DOWN ↓";
    } else if (offsetY < -0.15) {
      guidance = "↑ TILT UP";
    }

    state = state.copyWith(
      faceBox: boundingBox,
      relativeOffset: Offset(offsetX, offsetY),
      isLocked: true,
      instruction: guidance,
    );
  }

  void reset() => state = const TrackingState();
}

final trackingProvider =
    StateNotifierProvider<TrackingNotifier, TrackingState>((ref) {
  return TrackingNotifier(ref);
});
