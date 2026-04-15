import 'package:flutter/material.dart';

class StabilityMeter extends StatelessWidget {
  final double intensity;

  const StabilityMeter({
    super.key,
    required this.intensity,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = (intensity / 8).clamp(0.0, 1.0);

    return Container(
      width: 18,
      height: 140,
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: FractionallySizedBox(
          heightFactor: normalized,
          child: Container(
            decoration: BoxDecoration(
              color: intensity > 4 ? Colors.red : Colors.greenAccent,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}
