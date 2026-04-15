import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

final permissionServiceProvider = Provider<PermissionService>(
  (ref) => PermissionService(),
);

class PermissionStatusModel {
  final bool cameraGranted;
  final bool microphoneGranted;
  final bool storageGranted;

  const PermissionStatusModel({
    required this.cameraGranted,
    required this.microphoneGranted,
    required this.storageGranted,
  });

  bool get allGranted => cameraGranted && microphoneGranted;

  bool get anyDenied => !cameraGranted || !microphoneGranted;

  PermissionStatusModel copyWith({
    bool? cameraGranted,
    bool? microphoneGranted,
    bool? storageGranted,
  }) {
    return PermissionStatusModel(
      cameraGranted: cameraGranted ?? this.cameraGranted,
      microphoneGranted: microphoneGranted ?? this.microphoneGranted,
      storageGranted: storageGranted ?? this.storageGranted,
    );
  }

  @override
  String toString() {
    return '''
PermissionStatusModel(
camera: $cameraGranted,
microphone: $microphoneGranted,
storage: $storageGranted
)
''';
  }
}

class PermissionService {
  Future<PermissionStatusModel> requestAll() async {
    final camera = await Permission.camera.request();
    final microphone = await Permission.microphone.request();

    final storage = await _requestStoragePermission();

    return PermissionStatusModel(
      cameraGranted: camera.isGranted,
      microphoneGranted: microphone.isGranted,
      storageGranted: storage,
    );
  }

  Future<PermissionStatusModel> checkAll() async {
    final camera = await Permission.camera.status;
    final microphone = await Permission.microphone.status;

    final storage = await _checkStoragePermission();

    return PermissionStatusModel(
      cameraGranted: camera.isGranted,
      microphoneGranted: microphone.isGranted,
      storageGranted: storage,
    );
  }

  Future<bool> requestCamera() async {
    final result = await Permission.camera.request();
    return result.isGranted;
  }

  Future<bool> requestMicrophone() async {
    final result = await Permission.microphone.request();
    return result.isGranted;
  }

  Future<void> openSettings() async {
    await openAppSettings();
  }

  Future<bool> isPermanentlyDenied() async {
    final cam = await Permission.camera.status;
    final mic = await Permission.microphone.status;

    return cam.isPermanentlyDenied || mic.isPermanentlyDenied;
  }

  Future<bool> _requestStoragePermission() async {
    if (Platform.isIOS) {
      return true;
    }

    if (Platform.isAndroid) {
      final sdkVersion = await _getAndroidSdkVersion();

      if (sdkVersion >= 33) {
        final photos = await Permission.photos.request();
        final videos = await Permission.videos.request();

        return photos.isGranted || videos.isGranted;
      } else {
        final storage = await Permission.storage.request();
        return storage.isGranted;
      }
    }

    return true;
  }

  Future<bool> _checkStoragePermission() async {
    if (Platform.isIOS) return true;

    if (Platform.isAndroid) {
      final sdkVersion = await _getAndroidSdkVersion();

      if (sdkVersion >= 33) {
        final photos = await Permission.photos.status;
        final videos = await Permission.videos.status;

        return photos.isGranted || videos.isGranted;
      } else {
        final storage = await Permission.storage.status;
        return storage.isGranted;
      }
    }

    return true;
  }

  Future<int> _getAndroidSdkVersion() async {
    try {
      return int.parse(Platform.operatingSystemVersion
          .replaceAll(RegExp(r'[^0-9]'), '')
          .substring(0, 2));
    } catch (_) {
      return 33;
    }
  }
}
