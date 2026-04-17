import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

final permissionServiceProvider = Provider<PermissionService>(
  (_) => PermissionService(),
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

  Future<bool> requestCamera() async =>
      (await Permission.camera.request()).isGranted;

  Future<bool> requestMicrophone() async =>
      (await Permission.microphone.request()).isGranted;

  Future<void> openSettings() async => openAppSettings();

  Future<bool> isPermanentlyDenied() async {
    final cam = await Permission.camera.status;
    final mic = await Permission.microphone.status;
    return cam.isPermanentlyDenied || mic.isPermanentlyDenied;
  }

  Future<bool> _requestStoragePermission() async {
    if (Platform.isIOS) return true;
    if (Platform.isAndroid) {
      final sdk = await _getAndroidSdkVersion();
      if (sdk >= 33) {
        final photos = await Permission.photos.request();
        final videos = await Permission.videos.request();
        return photos.isGranted || videos.isGranted;
      }
      return (await Permission.storage.request()).isGranted;
    }
    return true;
  }

  Future<bool> _checkStoragePermission() async {
    if (Platform.isIOS) return true;
    if (Platform.isAndroid) {
      final sdk = await _getAndroidSdkVersion();
      if (sdk >= 33) {
        final photos = await Permission.photos.status;
        final videos = await Permission.videos.status;
        return photos.isGranted || videos.isGranted;
      }
      return (await Permission.storage.status).isGranted;
    }
    return true;
  }

  Future<int> _getAndroidSdkVersion() async {
    try {
      final match = RegExp(r'\d+').firstMatch(Platform.operatingSystemVersion);
      if (match == null) return 33; // safe default
      final value = int.tryParse(match.group(0)!) ?? 33;
      return (value >= 21 && value <= 99) ? value : 33;
    } catch (_) {
      return 33;
    }
  }
}
