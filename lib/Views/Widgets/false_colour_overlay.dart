import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../Controllers/pro_monitoring_controller.dart';

class FalseColorOverlay extends ConsumerWidget {
  const FalseColorOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(proMonitoringProvider.notifier);
    final state = ref.watch(proMonitoringProvider);

    if (!notifier.falseColorEnabled ||
        state.falseColorMap == null ||
        state.focusMapWidth == 0) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: _FalseColorPainter(
        rgbaMap: state.falseColorMap!,
        mapWidth: state.focusMapWidth,
        mapHeight: state.focusMapHeight,
      ),
    );
  }
}

class _FalseColorPainter extends StatefulWidget {
  final Uint8List rgbaMap;
  final int mapWidth;
  final int mapHeight;

  const _FalseColorPainter({
    required this.rgbaMap,
    required this.mapWidth,
    required this.mapHeight,
  });

  @override
  State<_FalseColorPainter> createState() => _FalseColorPainterState();
}

class _FalseColorPainterState extends State<_FalseColorPainter> {
  ui.Image? _image;
  Uint8List? _lastMap;

  @override
  void initState() {
    super.initState();
    _buildImage();
  }

  @override
  void didUpdateWidget(_FalseColorPainter old) {
    super.didUpdateWidget(old);
    if (widget.rgbaMap != _lastMap) _buildImage();
  }

  Future<void> _buildImage() async {
    _lastMap = widget.rgbaMap;
    final codec = await ui.instantiateImageCodec(
      widget.rgbaMap,
      targetWidth: widget.mapWidth,
      targetHeight: widget.mapHeight,
    );
    final frame = await codec.getNextFrame();
    if (mounted) setState(() => _image = frame.image);
  }

  @override
  Widget build(BuildContext context) {
    if (_image == null) return const SizedBox.shrink();
    return CustomPaint(
      painter: _RgbaPainter(image: _image!),
    );
  }
}

class _RgbaPainter extends CustomPainter {
  final ui.Image image;
  const _RgbaPainter({required this.image});

  @override
  void paint(Canvas canvas, Size size) {
    final src =
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(image, src, dst, Paint());
  }

  @override
  bool shouldRepaint(covariant _RgbaPainter old) => old.image != image;
}

class FalseColorLegend extends StatelessWidget {
  const FalseColorLegend({super.key});

  @override
  Widget build(BuildContext context) {
    const zones = [
      (Color(0xFF1E50C8), 'Crushed blacks'),
      (Color(0xFF00B4B4), 'Underexposed'),
      (Colors.white, 'Correct'),
      (Colors.yellow, 'Slightly hot'),
      (Colors.orange, 'Overexposed'),
      (Colors.red, 'Clipping'),
    ];

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: zones.map((z) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: z.$1,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  z.$2,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
