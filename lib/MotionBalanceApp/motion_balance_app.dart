// lib/Views/CameraView/camera_view.dart

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../Controllers/camera_controller.dart';
import '../../Controllers/sensor_controller.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  final SensorController _sensorController = SensorController();

  double _currentRoll = 0.0;
  double _shakeIntensity = 0.0;
  String _guidanceText = "Stable shot";

  @override
  void initState() {
    super.initState();

    _sensorController.onDataUpdate = (shake, roll) {
      if (!mounted) return;

      setState(() {
        _shakeIntensity = shake;
        _currentRoll = roll;
        _guidanceText = _sensorController.getGuidance(shake);
      });
    };

    _sensorController.startListening();
  }

  @override
  void dispose() {
    _sensorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cameraNotifierProvider);
    final cameraService = ref.watch(cameraServiceProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: switch (state.status) {
        CameraScreenStatus.initial ||
        CameraScreenStatus.requestingPermissions ||
        CameraScreenStatus.initializing =>
          _buildLoading(),
        CameraScreenStatus.error => CameraErrorView(
            message: state.errorMessage ?? "Unknown error",
            onRetry: () =>
                ref.read(cameraNotifierProvider.notifier).initialize(),
            onSettings: () => ref
                .read(cameraNotifierProvider.notifier)
                .openPermissionSettings(),
          ),
        CameraScreenStatus.ready => _buildCameraPreview(state, cameraService),
      },
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: Colors.white),
    );
  }

  Widget _buildCameraPreview(
    CameraState state,
    CameraService cameraService,
  ) {
    final controller = cameraService.controller;

    if (controller == null || !controller.value.isInitialized) {
      return _buildLoading();
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(controller),

        // Horizon leveling overlay
        HorizonLeveler(roll: _currentRoll),

        // Shake meter overlay
        Positioned(
          right: 20,
          top: 140,
          child: StabilityMeter(
            intensity: _shakeIntensity,
          ),
        ),

        // Guidance text
        Positioned(
          top: 70,
          width: MediaQuery.of(context).size.width,
          child: Center(
            child: Text(
              _guidanceText,
              style: TextStyle(
                color: _shakeIntensity > 3 ? Colors.red : Colors.greenAccent,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                fontSize: 15,
              ),
            ),
          ),
        ),

        // Top status bar
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                StabilizationBadge(
                  mode: state.stabilizationMode,
                ),
                const Spacer(),
                if (state.isRecording)
                  RecordingTimer(
                    duration: state.recordingDuration,
                  ),
              ],
            ),
          ),
        ),

        // Bottom controls
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 36),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Switch camera button
                IconButton(
                  icon: Icon(
                    state.isFrontCamera
                        ? Icons.camera_rear
                        : Icons.camera_front,
                    color: Colors.white,
                    size: 30,
                  ),
                  onPressed: () {
                    ref.read(cameraNotifierProvider.notifier).switchCamera();
                  },
                ),

                // Record button
                RecordButton(
                  isRecording: state.isRecording,
                  onTap: () async {
                    final notifier = ref.read(cameraNotifierProvider.notifier);

                    if (state.isRecording) {
                      await notifier.stopRecording();
                    } else {
                      await notifier.startRecording();
                    }
                  },
                ),

                // Placeholder future gallery/export button
                IconButton(
                  icon: const Icon(
                    Icons.video_library,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
