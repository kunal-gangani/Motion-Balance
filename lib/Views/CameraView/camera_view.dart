import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_balance/Views/Widgets/recording_button.dart';

import '../../Controllers/camera_controller.dart';
import '../../Controllers/sensor_controller.dart';
import '../../Services/camera_service.dart';

import '../Widgets/camera_error_view.dart';
import '../Widgets/horizon_leveler.dart';
import '../Widgets/recording_timer.dart';
import '../Widgets/stability_meter.dart';
import '../Widgets/stabilization_badge.dart';

class CameraScreen extends ConsumerWidget {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cameraState = ref.watch(cameraNotifierProvider);
    final cameraService = ref.watch(cameraServiceProvider);
    final sensorState = ref.watch(sensorControllerProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: switch (cameraState.status) {
        CameraScreenStatus.initial ||
        CameraScreenStatus.requestingPermissions ||
        CameraScreenStatus.initializing =>
          const _LoadingView(),
        CameraScreenStatus.error => CameraErrorView(
            message: cameraState.errorMessage ?? "Unknown error",
            onRetry: () =>
                ref.read(cameraNotifierProvider.notifier).initialize(),
            onSettings: () => ref
                .read(cameraNotifierProvider.notifier)
                .openPermissionSettings(),
          ),
        CameraScreenStatus.ready => CameraPreviewLayout(
            cameraState: cameraState,
            cameraService: cameraService,
            sensorState: sensorState,
          ),
      },
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: Colors.white),
    );
  }
}

class CameraPreviewLayout extends ConsumerWidget {
  final CameraState cameraState;
  final CameraService cameraService;
  final SensorState sensorState;

  const CameraPreviewLayout({
    super.key,
    required this.cameraState,
    required this.cameraService,
    required this.sensorState,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CameraController? controller = cameraService.controller;

    if (controller == null || !controller.value.isInitialized) {
      return const _LoadingView();
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(controller),
        HorizonLeveler(
          roll: sensorState.currentRoll,
        ),
        Positioned(
          right: 20,
          top: 140,
          child: StabilityMeter(
            intensity: sensorState.shakeIntensity,
          ),
        ),
        Positioned(
          top: 70,
          width: MediaQuery.of(context).size.width,
          child: Center(
            child: Text(
              sensorState.guidanceText,
              style: TextStyle(
                color: sensorState.shakeIntensity > 3
                    ? Colors.red
                    : Colors.greenAccent,
                fontWeight: FontWeight.bold,
                fontSize: 15,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                StabilizationBadge(
                  mode: cameraState.stabilizationMode,
                ),
                const Spacer(),
                if (cameraState.isRecording)
                  RecordingTimer(
                    duration: cameraState.recordingDuration,
                  ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 36),
            child: CameraBottomControls(
              cameraState: cameraState,
            ),
          ),
        ),
      ],
    );
  }
}

class CameraBottomControls extends ConsumerWidget {
  final CameraState cameraState;

  const CameraBottomControls({
    super.key,
    required this.cameraState,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(cameraNotifierProvider.notifier);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: Icon(
            cameraState.isFrontCamera ? Icons.camera_rear : Icons.camera_front,
            color: Colors.white,
            size: 30,
          ),
          onPressed: notifier.switchCamera,
        ),
        RecordButton(
          isRecording: cameraState.isRecording,
          onTap: notifier.toggleRecording,
        ),
        IconButton(
          icon: const Icon(
            Icons.video_library,
            color: Colors.white,
            size: 28,
          ),
          onPressed: notifier.openGallery,
        ),
      ],
    );
  }
}
