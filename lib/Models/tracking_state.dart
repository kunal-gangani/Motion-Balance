import 'dart:ui';

class TrackingState {
  final Rect? faceBox;
  final Offset relativeOffset;
  final bool isLocked;
  final String instruction;

  const TrackingState({
    this.faceBox,
    this.relativeOffset = Offset.zero,
    this.isLocked = false,
    this.instruction = "Searching for subject...",
  });

  TrackingState copyWith({
    Rect? faceBox,
    Offset? relativeOffset,
    bool? isLocked,
    String? instruction,
  }) {
    return TrackingState(
      faceBox: faceBox ?? this.faceBox,
      relativeOffset: relativeOffset ?? this.relativeOffset,
      isLocked: isLocked ?? this.isLocked,
      instruction: instruction ?? this.instruction,
    );
  }
}
