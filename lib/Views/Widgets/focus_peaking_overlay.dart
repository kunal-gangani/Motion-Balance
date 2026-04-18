import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../Controllers/pro_monitoring_controller.dart';

class FocusPeakingOverlay extends ConsumerWidget {
  const FocusPeakingOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(proMonitoringProvider);

    if (!ref.read(proMonitoringProvider.notifier).focusPeakingEnabled ||
        state.focusPeakingMap == null ||
        state.focusMapWidth == 0) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: _FocusPeakingPainter(
        edgeMap: state.focusPeakingMap!,
        mapWidth: state.focusMapWidth,
        mapHeight: state.focusMapHeight,
      ),
    );
  }
}

class _FocusPeakingPainter extends StatefulWidget {
  final Uint8List edgeMap;
  final int mapWidth;
  final int mapHeight;

  const _FocusPeakingPainter({
    required this.edgeMap,
    required this.mapWidth,
    required this.mapHeight,
  });

  @override
  State<_FocusPeakingPainter> createState() => _FocusPeakingPainterState();
}

class _FocusPeakingPainterState extends State<_FocusPeakingPainter> {
  ui.Image? _image;
  Uint8List? _lastMap;

  @override
  void didUpdateWidget(_FocusPeakingPainter old) {
    super.didUpdateWidget(old);
    if (widget.edgeMap != _lastMap) {
      _buildImage();
    }
  }

  @override
  void initState() {
    super.initState();
    _buildImage();
  }

  Future<void> _buildImage() async {
    _lastMap = widget.edgeMap;
    final int w = widget.mapWidth;
    final int h = widget.mapHeight;

    final rgba = Uint8List(w * h * 4);
    for (int i = 0; i < w * h; i++) {
      final bool isEdge = widget.edgeMap[i] > 0;
      final int base = i * 4;
      rgba[base] = 0; // R
      rgba[base + 1] = isEdge ? 255 : 0;
      rgba[base + 2] = isEdge ? 255 : 0;
      rgba[base + 3] = isEdge ? 200 : 0;
    }

    final codec = await ui.instantiateImageCodec(
      rgba,
      targetWidth: w,
      targetHeight: h,
    );
    final frame = await codec.getNextFrame();
    if (mounted) setState(() => _image = frame.image);
  }

  @override
  Widget build(BuildContext context) {
    if (_image == null) return const SizedBox.shrink();
    return CustomPaint(
      painter: _ImagePainter(image: _image!),
    );
  }
}

class _ImagePainter extends CustomPainter {
  final ui.Image image;
  const _ImagePainter({required this.image});

  @override
  void paint(Canvas canvas, Size size) {
    final src =
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(image, src, dst, Paint());
  }

  @override
  bool shouldRepaint(covariant _ImagePainter old) => old.image != image;
}
