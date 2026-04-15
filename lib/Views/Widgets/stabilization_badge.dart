import 'package:flutter/material.dart';
import 'package:motion_balance/Services/camera_service.dart';

class StabilizationBadge extends StatelessWidget {
  final StabilizationMode mode;

  const StabilizationBadge({
    super.key,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    final label = switch (mode) {
      StabilizationMode.native => "OIS/EIS ACTIVE",
      StabilizationMode.software => "SOFTWARE STAB",
      StabilizationMode.off => "STABILIZATION OFF",
    };

    final color = switch (mode) {
      StabilizationMode.native => Colors.greenAccent,
      StabilizationMode.software => Colors.blueAccent,
      StabilizationMode.off => Colors.white38,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}