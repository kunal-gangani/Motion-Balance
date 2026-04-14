import 'package:flutter/material.dart';

class HorizonLeveler extends StatelessWidget {
  final double roll; // -1.0 to 1.0

  const HorizonLeveler({super.key, required this.roll});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Static Center Guide
          Container(width: 40, height: 2, color: Colors.yellowAccent),
          
          // Rotating Horizon Line
          Transform.rotate(
            angle: roll,
            child: Container(
              width: 250,
              height: 1,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                boxShadow: const [
                  BoxShadow(color: Colors.cyanAccent, blurRadius: 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
