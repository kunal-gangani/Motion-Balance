import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../Controllers/stabilization_intelligence_controller.dart';
import '../../Models/shot_type.dart';

class ShotTypeBadge extends ConsumerWidget {
  const ShotTypeBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(stabilizationIntelligenceProvider);
    return _ShotTypeBadgeView(
      shotType: state.shotType,
      aggressiveness: state.aggressiveness,
      angularVelocity: state.angularVelocity,
    );
  }
}

class _ShotTypeBadgeView extends StatelessWidget {
  final ShotType shotType;
  final double aggressiveness;
  final double angularVelocity;

  const _ShotTypeBadgeView({
    required this.shotType,
    required this.aggressiveness,
    required this.angularVelocity,
  });

  Color get _shotColor => switch (shotType) {
        ShotType.staticShot => Colors.greenAccent,
        ShotType.pan => Colors.cyanAccent,
        ShotType.tilt => Colors.blueAccent,
        ShotType.dolly => Colors.purpleAccent,
        ShotType.walk => Colors.orangeAccent,
        ShotType.freehand => Colors.redAccent,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _shotColor.withOpacity(0.7), width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                shotType.icon,
                style: TextStyle(
                  color: _shotColor,
                  fontSize: 11,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                shotType.label.toUpperCase(),
                style: TextStyle(
                  color: _shotColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 80,
            height: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: aggressiveness,
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation<Color>(_shotColor),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Stab ${(aggressiveness * 100).toStringAsFixed(0)}%',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 9,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class ShotTypePill extends ConsumerWidget {
  const ShotTypePill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shotType =
        ref.watch(stabilizationIntelligenceProvider.select((s) => s.shotType));

    final Color color = switch (shotType) {
      ShotType.staticShot => Colors.greenAccent,
      ShotType.pan => Colors.cyanAccent,
      ShotType.tilt => Colors.blueAccent,
      ShotType.dolly => Colors.purpleAccent,
      ShotType.walk => Colors.orangeAccent,
      ShotType.freehand => Colors.redAccent,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(12),
        // ignore: deprecated_member_use
        border: Border.all(color: color.withOpacity(0.6), width: 0.5),
      ),
      child: Text(
        '${shotType.icon} ${shotType.label}',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
