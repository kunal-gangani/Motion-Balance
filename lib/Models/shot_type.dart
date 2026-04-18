enum ShotType {
  staticShot,
  pan,
  tilt,
  dolly,
  walk,
  freehand,
}

extension ShotTypeInfo on ShotType {
  String get label => switch (this) {
        ShotType.staticShot => 'Static',
        ShotType.pan => 'Pan',
        ShotType.tilt => 'Tilt',
        ShotType.dolly => 'Dolly',
        ShotType.walk => 'Walk',
        ShotType.freehand => 'Freehand',
      };

  String get icon => switch (this) {
        ShotType.staticShot => '■',
        ShotType.pan => '↔',
        ShotType.tilt => '↕',
        ShotType.dolly => '⇥',
        ShotType.walk => '~',
        ShotType.freehand => '✦',
      };

  double get stabilizationAggressiveness => switch (this) {
        ShotType.staticShot => 0.2,
        ShotType.pan => 0.4,
        ShotType.tilt => 0.4,
        ShotType.dolly => 0.6,
        ShotType.walk => 0.85,
        ShotType.freehand => 0.7,
      };

  bool get preferNativeStabilization => switch (this) {
        ShotType.staticShot => false,
        ShotType.pan => false,
        ShotType.tilt => false,
        ShotType.dolly => true,
        ShotType.walk => true,
        ShotType.freehand => true,
      };
}
