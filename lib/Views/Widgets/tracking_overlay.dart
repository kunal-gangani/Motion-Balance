import 'package:flutter/material.dart';

class TrackingReticlePainter extends CustomPainter {
  final Rect? faceBox;
  final Size imageSize;
  final bool isLocked;

  TrackingReticlePainter({
    required this.faceBox,
    required this.imageSize,
    required this.isLocked,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (faceBox == null || !isLocked) return;

    final double scaleX = size.width / imageSize.width;
    final double scaleY = size.height / imageSize.height;

    final rect = Rect.fromLTRB(
      faceBox!.left * scaleX,
      faceBox!.top * scaleY,
      faceBox!.right * scaleX,
      faceBox!.bottom * scaleY,
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.cyanAccent.withOpacity(0.8);

    const double cornerSize = 20.0;
    final path = Path()
      // Top Left
      ..moveTo(rect.left, rect.top + cornerSize)
      ..lineTo(rect.left, rect.top)
      ..lineTo(rect.left + cornerSize, rect.top)
      // Top Right
      ..moveTo(rect.right - cornerSize, rect.top)
      ..lineTo(rect.right, rect.top)
      ..lineTo(rect.right, rect.top + cornerSize)
      // Bottom Left
      ..moveTo(rect.left, rect.bottom - cornerSize)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(rect.left + cornerSize, rect.bottom)
      ..moveTo(rect.right - cornerSize, rect.bottom)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.right, rect.bottom - cornerSize);

    canvas.drawPath(path, paint);
    canvas.drawCircle(rect.center, 3, paint..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant TrackingReticlePainter oldDelegate) => true;
}
