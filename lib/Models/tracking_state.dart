import 'package:flutter/material.dart';

class TrackingState {
  final Rect? faceBox;
  final Offset relativeOffset;
  final bool isLocked;
  final String instruction;

  const TrackingState({
    this.faceBox,
    this.relativeOffset = Offset.zero,
    this.isLocked = false,
    this.instruction = 'Searching...',
  });

  TrackingState copyWith({
    Rect? faceBox,
    bool clearFaceBox = false,
    Offset? relativeOffset,
    bool? isLocked,
    String? instruction,
  }) {
    return TrackingState(
      faceBox: clearFaceBox ? null : (faceBox ?? this.faceBox),
      relativeOffset: relativeOffset ?? this.relativeOffset,
      isLocked: isLocked ?? this.isLocked,
      instruction: instruction ?? this.instruction,
    );
  }
}
