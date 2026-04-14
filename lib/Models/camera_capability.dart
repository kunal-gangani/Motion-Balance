enum VideoStabilizationMode { auto }

enum StabilizationLevel { native, softwareOnly, unsupported }

class CameraCapability {
  final List<VideoStabilizationMode> availableModes;
  final bool hasGyroscope;
  final bool hasAccelerometer;

  CameraCapability({
    required this.availableModes,
    required this.hasGyroscope,
    required this.hasAccelerometer,
  });

  // Business logic for fallback
  StabilizationLevel get bestLevel {
    if (availableModes.contains(VideoStabilizationMode.auto)) {
      return StabilizationLevel.native;
    }
    if (hasGyroscope) return StabilizationLevel.softwareOnly;
    return StabilizationLevel.unsupported;
  }
}
