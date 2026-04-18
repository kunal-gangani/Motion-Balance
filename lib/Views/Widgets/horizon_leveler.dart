import 'dart:math';
import 'package:flutter/material.dart';

class HorizonLeveler extends StatelessWidget {
  final double roll;
  const HorizonLeveler({super.key, required this.roll});

  @override
  Widget build(BuildContext context) {
    final double rollRadians = roll * (pi / 180);
    final double clampedRadians = rollRadians.clamp(-pi / 6, pi / 6);
    final double tiltFraction = (roll.abs() / 30).clamp(0.0, 1.0);
    final Color lineColor =
        Color.lerp(Colors.white, Colors.amberAccent, tiltFraction)!
            .withOpacity(0.85);

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 40,
            height: 2,
            color: Colors.yellowAccent,
          ),
          Transform.rotate(
            angle: clampedRadians,
            child: Container(
              width: 250,
              height: 1.5,
              decoration: BoxDecoration(
                color: lineColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyanAccent.withOpacity(0.5),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
