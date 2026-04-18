// ignore_for_file: deprecated_member_use

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:motion_balance/Views/Widgets/false_colour_overlay.dart';
import '../../Controllers/camera_controller.dart';
import '../../Controllers/pro_monitoring_controller.dart';
import '../../Controllers/sensor_controller.dart';
import '../../Controllers/stabilization_intelligence_controller.dart';
import '../../Controllers/tracking_controller.dart';
import '../../Models/tracking_state.dart';
import '../../Services/camera_service.dart';
import '../Widgets/camera_error_view.dart';
import '../Widgets/focus_peaking_overlay.dart';
import '../Widgets/histogram_overlay.dart';
import '../Widgets/horizon_leveler.dart';
import '../Widgets/pro_monitoring_widgets.dart';
import '../Widgets/recording_button.dart';
import '../Widgets/recording_timer.dart';
import '../Widgets/shot_type_badge.dart';
import '../Widgets/stability_meter.dart';
import '../Widgets/stabilization_badge.dart';
import '../Widgets/tracking_overlay.dart';

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
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator(color: Colors.white));
}

class CameraPreviewLayout extends ConsumerStatefulWidget {
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
  ConsumerState<CameraPreviewLayout> createState() =>
      _CameraPreviewLayoutState();
}

class _CameraPreviewLayoutState extends ConsumerState<CameraPreviewLayout> {
  bool _streamStarted = false;
  bool _isComparisonMode = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeStartStream());
  }

  @override
  void didUpdateWidget(CameraPreviewLayout old) {
    super.didUpdateWidget(old);
    _maybeStartStream();
  }

  void _maybeStartStream() {
    if (!mounted) return;
    final controller = widget.cameraService.controller;
    if (!_streamStarted &&
        controller != null &&
        controller.value.isInitialized) {
      ref.read(cameraNotifierProvider.notifier).startImageStream();

      controller.startImageStream((CameraImage image) {
        ref.read(proMonitoringProvider.notifier).processFrame(image);
      });

      ref.read(proMonitoringProvider.notifier).updateFps(30.0);
      _streamStarted = true;
    }
  }

  @override
  void dispose() {
    ref.read(cameraNotifierProvider.notifier).stopImageStream();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final CameraController? controller = widget.cameraService.controller;
    final trackingState = ref.watch(trackingProvider);

    ref.listen(stabilizationIntelligenceProvider, (_, next) {
      ref.read(sensorControllerProvider.notifier).updateRoll(next.rollDegrees);
    });

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
        const FalseColorOverlay(),
        const FocusPeakingOverlay(),
        if (_isComparisonMode) ...[
          Center(
            child: Container(width: 2, color: Colors.white.withOpacity(0.3)),
          ),
          const Positioned(
            left: 20,
            bottom: 120,
            child: Text(
              'RAW FEED',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 10,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
        _isComparisonMode
            ? _buildComparisonOverlay(trackingState, previewSize)
            : _buildFullOverlay(context, trackingState, previewSize),
        HorizonLeveler(roll: widget.sensorState.currentRoll),
        _buildGuidanceUI(context, trackingState),
        const HistogramOverlay(),
        const Positioned(
          left: 16,
          top: 0,
          bottom: 0,
          child: Center(child: AudioLevelMeter()),
        ),
        _buildInterfaceOverlays(context),
      ],
    );
  }

  Widget _buildComparisonOverlay(TrackingState tracking, Size previewSize) {
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

  Widget _buildGuidanceUI(BuildContext context, TrackingState tracking) {
    final sensor = widget.sensorState;
    return Positioned(
      top: 70,
      width: MediaQuery.sizeOf(context).width,
      child: Column(
        children: [
          Text(
            tracking.isLocked
                ? 'Subject locked: ${tracking.instruction}'
                : 'Searching for subject...',
            style: const TextStyle(
              color: Colors.cyanAccent,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
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

  Widget _buildInterfaceOverlays(BuildContext context) {
    final state = widget.cameraState;
    return Stack(
      children: [
        Positioned(
          right: 20,
          top: 140,
          child: StabilityMeter(intensity: widget.sensorState.shakeIntensity),
        ),
        const Positioned(
          right: 14,
          top: 300,
          child: ShutterRuleBadge(),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                StabilizationBadge(mode: state.stabilizationMode),
                const SizedBox(width: 8),
                const ShotTypePill(),
                const Spacer(),
                // Comparison mode toggle
                GestureDetector(
                  onTap: () =>
                      setState(() => _isComparisonMode = !_isComparisonMode),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _isComparisonMode
                          ? Colors.white.withOpacity(0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white30, width: 0.5),
                    ),
                    child: Text(
                      _isComparisonMode ? 'COMP ON' : 'COMP OFF',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ProMonitoringToolbar(),
                const SizedBox(height: 16),
                CameraBottomControls(cameraState: state),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class CameraBottomControls extends ConsumerWidget {
  final CameraState cameraState;

  const CameraBottomControls({super.key, required this.cameraState});

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
          icon: const Icon(Icons.video_library, color: Colors.white, size: 28),
          onPressed: () => Navigator.of(context).pushNamed('/gallery'),
        ),
      ],
    );
  }
}
