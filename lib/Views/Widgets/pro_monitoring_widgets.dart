// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../Controllers/pro_monitoring_controller.dart';

class AudioLevelMeter extends ConsumerWidget {
  const AudioLevelMeter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(proMonitoringProvider);
    return _AudioMeterView(
      level: state.audioLevel,
      isClipping: state.audioClipping,
    );
  }
}

class _AudioMeterView extends StatelessWidget {
  final double level;
  final bool isClipping;

  const _AudioMeterView({required this.level, required this.isClipping});

  @override
  Widget build(BuildContext context) {
    Color meterColor;
    if (isClipping || level >= 0.95) {
      meterColor = Colors.red;
    } else if (level >= 0.75) {
      meterColor = Colors.orangeAccent;
    } else {
      meterColor = Colors.greenAccent;
    }

    return Container(
      width: 14,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isClipping ? Colors.red : Colors.white24,
          width: 0.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Clip indicator pip
          AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            height: 6,
            decoration: BoxDecoration(
              color: isClipping ? Colors.red : Colors.transparent,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: level.clamp(0.0, 1.0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 60),
                  decoration: BoxDecoration(
                    color: meterColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
        ],
      ),
    );
  }
}

class ShutterRuleBadge extends ConsumerWidget {
  const ShutterRuleBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(proMonitoringProvider);
    return _ShutterBadgeView(
      fps: state.currentFps,
      recommendedShutterUs: state.recommendedShutterUs,
      violated: state.shutterRuleViolated,
    );
  }
}

class _ShutterBadgeView extends StatelessWidget {
  final double fps;
  final int recommendedShutterUs;
  final bool violated;

  const _ShutterBadgeView({
    required this.fps,
    required this.recommendedShutterUs,
    required this.violated,
  });

  String get _shutterLabel {
    final int denominator =
        (1000000 / recommendedShutterUs).round().clamp(1, 16000);
    return '1/$denominator';
  }

  @override
  Widget build(BuildContext context) {
    final Color color = violated ? Colors.red : Colors.white70;
    final Color borderColor = violated ? Colors.red : Colors.white24;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '180° rule',
            style: TextStyle(
              color: color,
              fontSize: 9,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _shutterLabel,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
          Text(
            '@ ${fps.toStringAsFixed(0)}fps',
            style: TextStyle(
              color: color.withOpacity(0.7),
              fontSize: 9,
            ),
          ),
          if (violated) ...[
            const SizedBox(height: 2),
            const Text(
              'VIOLATED',
              style: TextStyle(
                color: Colors.red,
                fontSize: 8,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ProMonitoringToolbar extends ConsumerStatefulWidget {
  const ProMonitoringToolbar({super.key});

  @override
  ConsumerState<ProMonitoringToolbar> createState() =>
      _ProMonitoringToolbarState();
}

class _ProMonitoringToolbarState extends ConsumerState<ProMonitoringToolbar> {
  bool _histOn = true;
  bool _focusOn = false;
  bool _falseColorOn = false;

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(proMonitoringProvider.notifier);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleChip(
            label: 'HIST',
            active: _histOn,
            onTap: () {
              notifier.toggleHistogram();
              setState(() => _histOn = !_histOn);
            },
          ),
          const SizedBox(width: 6),
          _ToggleChip(
            label: 'PEAK',
            active: _focusOn,
            onTap: () {
              notifier.toggleFocusPeaking();
              setState(() => _focusOn = !_focusOn);
            },
          ),
          const SizedBox(width: 6),
          _ToggleChip(
            label: 'FALSE',
            active: _falseColorOn,
            activeColor: Colors.orangeAccent,
            onTap: () {
              notifier.toggleFalseColor();
              setState(() => _falseColorOn = !_falseColorOn);
            },
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.active,
    required this.onTap,
    this.activeColor = Colors.cyanAccent,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? activeColor.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? activeColor : Colors.white30,
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? activeColor : Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
