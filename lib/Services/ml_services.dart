import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

final mlServiceProvider = Provider<MLService>((ref) {
  final service = MLService();
  ref.onDispose(service.dispose);
  return service;
});

class MLService {
  final ObjectDetector _objectDetector = ObjectDetector(
    options: ObjectDetectorOptions(
      mode: DetectionMode.stream,
      classifyObjects: true,
      multipleObjects: false,
    ),
  );

  ObjectDetector get objectDetector => _objectDetector;

  void dispose() {
    _objectDetector.close();
  }
}
