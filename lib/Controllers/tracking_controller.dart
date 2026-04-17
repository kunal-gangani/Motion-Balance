import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../Models/tracking_state.dart';
import '../Services/haptic_services.dart';
import 'sensor_controller.dart';

class TrackingNotifier extends StateNotifier<TrackingState> {
  final Ref ref;

  TrackingNotifier(this.ref) : super(const TrackingState());

  void updateFacePosition(Rect? boundingBox, Size imageSize) {
    final haptics = ref.read(hapticServiceProvider);
    final sensorState = ref.read(sensorControllerProvider);

    final double motionIntensity = sensorState.currentShake;

    if (boundingBox == null || imageSize == Size.zero) {
      if (state.isLocked) haptics.triggerSubjectLost();
      state = state.copyWith(
        isLocked: false,
        faceBox: null,
        instruction: 'Searching...',
        relativeOffset: Offset.zero,
      );
      return;
    }

    if (!state.isLocked) {
      haptics.triggerLockSuccess();
    }

    final double faceCenterX =
        (boundingBox.left + boundingBox.right) / 2 / imageSize.width;
    final double faceCenterY =
        (boundingBox.top + boundingBox.bottom) / 2 / imageSize.height;

    final double offsetX = faceCenterX - 0.5;
    final double offsetY = faceCenterY - 0.5;
    const double oversteerThreshold = 3.0;

    String instruction = 'Centered';

    if (offsetX < -0.15) {
      instruction = motionIntensity > oversteerThreshold
          ? 'Oversteer — slow down'
          : 'Pan left';
    } else if (offsetX > 0.15) {
      instruction = motionIntensity > oversteerThreshold
          ? 'Oversteer — slow down'
          : 'Pan right';
    } else if (offsetY > 0.15) {
      instruction = 'Tilt down';
    } else if (offsetY < -0.15) {
      instruction = 'Tilt up';
    }

    state = state.copyWith(
      faceBox: boundingBox,
      relativeOffset: Offset(offsetX, offsetY),
      isLocked: true,
      instruction: instruction,
    );
  }

  void reset() => state = const TrackingState();
}

final trackingProvider = StateNotifierProvider<TrackingNotifier, TrackingState>(
  (ref) => TrackingNotifier(ref),
);
