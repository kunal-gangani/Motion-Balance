import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_balance/Controllers/camera_controller.dart';
import 'package:motion_balance/Models/tracking_state.dart';
import '../../Controllers/sensor_controller.dart';
import '../../Services/camera_service.dart';
import '../Widgets/camera_error_view.dart';
import '../Widgets/horizon_leveler.dart';
import '../Widgets/recording_button.dart';
import '../Widgets/recording_timer.dart';
import '../Widgets/stability_meter.dart';
import '../Widgets/stabilization_badge.dart';
import '../Widgets/tracking_overlay.dart';
import '../../Controllers/tracking_controller.dart';

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
            message: cameraState.errorMessage ?? 'Unknown error',
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
    final trackingState = ref.watch(trackingProvider);

    // For demonstration: you can turn this into a state variable later
    const bool isComparisonMode = true;

    if (controller == null || !controller.value.isInitialized) {
      return const _LoadingView();
    }

    final previewSize = Size(
      controller.value.previewSize!.height,
      controller.value.previewSize!.width,
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(controller),
        if (isComparisonMode) ...[
          Center(
            child: Container(
              width: 2,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
          const Positioned(
            left: 20,
            bottom: 120,
            child: Text(
              "RAW FEED",
              style: TextStyle(
                color: Colors.white54,
                fontSize: 10,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
        isComparisonMode
            ? _buildComparisonOverlay(context, trackingState, previewSize)
            : _buildFullOverlay(context, trackingState, previewSize),
        HorizonLeveler(roll: sensorState.currentRoll),
        _buildGuidanceUI(context, trackingState, sensorState),
        _buildInterfaceOverlays(cameraState),
      ],
    );
  }

  Widget _buildComparisonOverlay(
      BuildContext context, TrackingState tracking, Size previewSize) {
    return Row(
      children: [
        const Spacer(),
        Expanded(
          child: CustomPaint(
            painter: TrackingReticlePainter(
              faceBox: tracking.faceBox,
              imageSize: previewSize,
              isLocked: tracking.isLocked,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFullOverlay(
      BuildContext context, TrackingState tracking, Size previewSize) {
    return CustomPaint(
      size: MediaQuery.sizeOf(context),
      painter: TrackingReticlePainter(
        faceBox: tracking.faceBox,
        imageSize: previewSize,
        isLocked: tracking.isLocked,
      ),
    );
  }

  Widget _buildGuidanceUI(
      BuildContext context, TrackingState tracking, SensorState sensor) {
    return Positioned(
      top: 70,
      width: MediaQuery.sizeOf(context).width,
      child: Column(
        children: [
          Text(
            tracking.isLocked
                ? "SUBJECT LOCKED: ${tracking.instruction}"
                : "SEARCHING FOR SUBJECT...",
            style: const TextStyle(
              color: Colors.cyanAccent,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            sensor.guidanceText,
            style: TextStyle(
              color:
                  sensor.shakeIntensity > 3 ? Colors.red : Colors.greenAccent,
              fontWeight: FontWeight.bold,
              fontSize: 15,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterfaceOverlays(CameraState state) {
    return Stack(
      children: [
        Positioned(
          right: 20,
          top: 140,
          child: StabilityMeter(intensity: sensorState.shakeIntensity),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                StabilizationBadge(mode: state.stabilizationMode),
                const Spacer(),
                if (state.isRecording)
                  RecordingTimer(duration: state.recordingDuration),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 36),
            child: CameraBottomControls(cameraState: state),
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
    final notifier = ref.read(
      cameraNotifierProvider.notifier,
    );

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
          onPressed: () => Navigator.of(context).pushNamed('/gallery'),
        ),
      ],
    );
  }
}
