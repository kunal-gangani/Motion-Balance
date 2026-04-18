// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../Controllers/pro_monitoring_controller.dart';

class HistogramOverlay extends ConsumerWidget {
  const HistogramOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(proMonitoringProvider);
    if (!state.histogramReady || state.histogram.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 16,
      bottom: 120,
      child: _HistogramPainterWidget(
        histogram: state.histogram,
        isClipping: state.isClipping,
        isUnderexposed: state.isUnderexposed,
        averageLuminance: state.averageLuminance,
      ),
    );
  }
}

class _HistogramPainterWidget extends StatelessWidget {
  final List<double> histogram;
  final bool isClipping;
  final bool isUnderexposed;
  final double averageLuminance;

  const _HistogramPainterWidget({
    required this.histogram,
    required this.isClipping,
    required this.isUnderexposed,
    required this.averageLuminance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isClipping
              ? Colors.red
              : isUnderexposed
                  ? Colors.blue
                  : Colors.white24,
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: CustomPaint(
          painter: _HistogramPainter(histogram: histogram),
        ),
      ),
    );
  }
}

class _HistogramPainter extends CustomPainter {
  final List<double> histogram;

  const _HistogramPainter({required this.histogram});

  @override
  void paint(Canvas canvas, Size size) {
    if (histogram.isEmpty) return;

    final barWidth = size.width / histogram.length;

    for (int i = 0; i < histogram.length; i++) {
      final double value = histogram[i];
      if (value <= 0) continue;

      Color barColor;
      if (i <= 20) {
        barColor = const Color(0xFF1E50C8).withOpacity(0.8);
      } else if (i <= 80) {
        barColor = const Color(0xFF00B4B4).withOpacity(0.8);
      } else if (i <= 180) {
        barColor = Colors.white.withOpacity(0.7);
      } else if (i <= 210) {
        barColor = Colors.yellow.withOpacity(0.8);
      } else if (i <= 234) {
        barColor = Colors.orange.withOpacity(0.8);
      } else {
        barColor = Colors.red.withOpacity(0.9);
      }

      final paint = Paint()..color = barColor;
      final barHeight = value * size.height;
      canvas.drawRect(
        Rect.fromLTWH(
          i * barWidth,
          size.height - barHeight,
          barWidth.clamp(1.0, double.infinity),
          barHeight,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HistogramPainter old) =>
      old.histogram != histogram;
}
