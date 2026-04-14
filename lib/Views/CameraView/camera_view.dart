import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:motion_balance/Controllers/sensor_controller.dart'
    show SensorController;
import 'package:motion_balance/Views/Widgets/horizon_leveler.dart';

class CameraView extends StatefulWidget {
  const CameraView({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _CameraViewState createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  CameraController? _cameraController;
  final SensorController _sensorController = SensorController();
  double _currentRoll = 0.0;
  double _shakeIntensity = 0.0;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _sensorController.onDataUpdate = (shake, roll) {
      setState(() {
        _shakeIntensity = shake;
        _currentRoll = roll;
      });
    };
    _sensorController.startListening();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    _cameraController = CameraController(cameras.first, ResolutionPreset.max);
    await _cameraController!.initialize();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Container(color: Colors.black);
    }

    return Scaffold(
      body: Stack(
        children: [
          CameraPreview(_cameraController!),

          // Overlay UI
          HorizonLeveler(roll: _currentRoll),

          // Guidance Text
          Positioned(
            top: 60,
            width: MediaQuery.of(context).size.width,
            child: Center(
              child: Text(
                _sensorController.getGuidance(_shakeIntensity),
                style: TextStyle(
                  color: _shakeIntensity > 3 ? Colors.red : Colors.greenAccent,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),

          // Record Button
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                backgroundColor: Colors.white,
                onPressed: () {}, // Handled in Phase 2
                child: const Icon(
                  Icons.videocam,
                  color: Colors.black,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _sensorController.dispose();
    super.dispose();
  }
}
