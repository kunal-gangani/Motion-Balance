import 'dart:async';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProMonitoringState {
  final List<double> histogram;
  final bool histogramReady;
  final Uint8List? focusPeakingMap;
  final int focusMapWidth;
  final int focusMapHeight;
  final Uint8List? falseColorMap;
  final double averageLuminance;
  final bool isClipping;
  final bool isUnderexposed;
  final int recommendedShutterUs;
  final double currentFps;
  final bool shutterRuleViolated;
  final double audioLevel;
  final bool audioClipping;

  const ProMonitoringState({
    this.histogram = const [],
    this.histogramReady = false,
    this.focusPeakingMap,
    this.focusMapWidth = 0,
    this.focusMapHeight = 0,
    this.falseColorMap,
    this.averageLuminance = 128,
    this.isClipping = false,
    this.isUnderexposed = false,
    this.recommendedShutterUs = 33333,
    this.currentFps = 30,
    this.shutterRuleViolated = false,
    this.audioLevel = 0.0,
    this.audioClipping = false,
  });

  ProMonitoringState copyWith({
    List<double>? histogram,
    bool? histogramReady,
    Uint8List? focusPeakingMap,
    int? focusMapWidth,
    int? focusMapHeight,
    Uint8List? falseColorMap,
    double? averageLuminance,
    bool? isClipping,
    bool? isUnderexposed,
    int? recommendedShutterUs,
    double? currentFps,
    bool? shutterRuleViolated,
    double? audioLevel,
    bool? audioClipping,
  }) {
    return ProMonitoringState(
      histogram: histogram ?? this.histogram,
      histogramReady: histogramReady ?? this.histogramReady,
      focusPeakingMap: focusPeakingMap ?? this.focusPeakingMap,
      focusMapWidth: focusMapWidth ?? this.focusMapWidth,
      focusMapHeight: focusMapHeight ?? this.focusMapHeight,
      falseColorMap: falseColorMap ?? this.falseColorMap,
      averageLuminance: averageLuminance ?? this.averageLuminance,
      isClipping: isClipping ?? this.isClipping,
      isUnderexposed: isUnderexposed ?? this.isUnderexposed,
      recommendedShutterUs: recommendedShutterUs ?? this.recommendedShutterUs,
      currentFps: currentFps ?? this.currentFps,
      shutterRuleViolated: shutterRuleViolated ?? this.shutterRuleViolated,
      audioLevel: audioLevel ?? this.audioLevel,
      audioClipping: audioClipping ?? this.audioClipping,
    );
  }
}

class _FrameAnalysisPayload {
  final Uint8List yPlane;
  final int width;
  final int height;
  final int strideBytes;

  const _FrameAnalysisPayload({
    required this.yPlane,
    required this.width,
    required this.height,
    required this.strideBytes,
  });
}

class _FrameAnalysisResult {
  final List<double> histogram;
  final double averageLuminance;
  final bool isClipping;
  final bool isUnderexposed;
  final Uint8List focusPeakingMap;
  final Uint8List falseColorMap;

  const _FrameAnalysisResult({
    required this.histogram,
    required this.averageLuminance,
    required this.isClipping,
    required this.isUnderexposed,
    required this.focusPeakingMap,
    required this.falseColorMap,
  });
}

_FrameAnalysisResult _analyseFrame(_FrameAnalysisPayload p) {
  final int w = p.width;
  final int h = p.height;
  final int stride = p.strideBytes;
  final Uint8List y = p.yPlane;

  final counts = List<int>.filled(256, 0);
  int lumSum = 0;
  int clipCount = 0;
  int darkCount = 0;

  for (int row = 0; row < h; row += 4) {
    for (int col = 0; col < w; col += 4) {
      final int idx = row * stride + col;
      if (idx >= y.length) continue;
      final int lum = y[idx];
      counts[lum]++;
      lumSum += lum;
      if (lum >= 235) clipCount++;
      if (lum <= 20) darkCount++;
    }
  }

  final int totalSamples = counts.reduce((a, b) => a + b);
  final double maxCount =
      counts.reduce(max).toDouble().clamp(1.0, double.infinity);
  final List<double> histogram =
      counts.map((c) => c / maxCount).toList(growable: false);

  final double avgLum = totalSamples > 0 ? lumSum / totalSamples : 128;
  final double clipRatio = totalSamples > 0 ? clipCount / totalSamples : 0;
  final double darkRatio = totalSamples > 0 ? darkCount / totalSamples : 0;

  final int sw = w ~/ 4;
  final int sh = h ~/ 4;
  final focusMap = Uint8List(sw * sh);

  for (int row = 1; row < sh - 1; row++) {
    for (int col = 1; col < sw - 1; col++) {
      int px(int r, int c) {
        final int oi = (r * 4) * stride + (c * 4);
        return oi < y.length ? y[oi] : 0;
      }

      final int gx = -px(row - 1, col - 1) -
          2 * px(row, col - 1) -
          px(row + 1, col - 1) +
          px(row - 1, col + 1) +
          2 * px(row, col + 1) +
          px(row + 1, col + 1);

      final int gy = -px(row - 1, col - 1) -
          2 * px(row - 1, col) -
          px(row - 1, col + 1) +
          px(row + 1, col - 1) +
          2 * px(row + 1, col) +
          px(row + 1, col + 1);

      final int mag = sqrt((gx * gx + gy * gy).toDouble()).toInt();
      focusMap[row * sw + col] = mag > 80 ? 255 : 0;
    }
  }

  final falseColor = Uint8List(sw * sh * 4);

  for (int row = 0; row < sh; row++) {
    for (int col = 0; col < sw; col++) {
      final int oi = row * 4 * stride + col * 4;
      final int lum = oi < y.length ? y[oi] : 0;
      final int base = (row * sw + col) * 4;

      if (lum <= 20) {
        falseColor[base] = 30;
        falseColor[base + 1] = 80;
        falseColor[base + 2] = 200;
        falseColor[base + 3] = 160;
      } else if (lum <= 80) {
        falseColor[base] = 0;
        falseColor[base + 1] = 180;
        falseColor[base + 2] = 180;
        falseColor[base + 3] = 100;
      } else if (lum <= 180) {
        falseColor[base] = 0;
        falseColor[base + 1] = 0;
        falseColor[base + 2] = 0;
        falseColor[base + 3] = 0;
      } else if (lum <= 210) {
        falseColor[base] = 240;
        falseColor[base + 1] = 220;
        falseColor[base + 2] = 0;
        falseColor[base + 3] = 120;
      } else if (lum <= 234) {
        falseColor[base] = 255;
        falseColor[base + 1] = 120;
        falseColor[base + 2] = 0;
        falseColor[base + 3] = 150;
      } else {
        final bool zebraRow = (row % 4) < 2;
        falseColor[base] = zebraRow ? 255 : 0;
        falseColor[base + 1] = 0;
        falseColor[base + 2] = 0;
        falseColor[base + 3] = zebraRow ? 200 : 0;
      }
    }
  }

  return _FrameAnalysisResult(
    histogram: histogram,
    averageLuminance: avgLum,
    isClipping: clipRatio > 0.02,
    isUnderexposed: darkRatio > 0.15,
    focusPeakingMap: focusMap,
    falseColorMap: falseColor,
  );
}

class ProMonitoringNotifier extends StateNotifier<ProMonitoringState> {
  final Ref ref;

  bool _isProcessing = false;
  bool _enabled = true;
  bool histogramEnabled = true;
  bool focusPeakingEnabled = false;
  bool falseColorEnabled = false;
  double _currentFps = 30.0;

  ProMonitoringNotifier(this.ref) : super(const ProMonitoringState());

  Future<void> processFrame(CameraImage image) async {
    if (!_enabled || _isProcessing) return;
    if (!histogramEnabled && !focusPeakingEnabled && !falseColorEnabled) return;

    _isProcessing = true;
    try {
      final yPlane = image.planes[0];
      final payload = _FrameAnalysisPayload(
        yPlane: Uint8List.fromList(yPlane.bytes),
        width: image.width,
        height: image.height,
        strideBytes: yPlane.bytesPerRow,
      );

      final result = await compute(_analyseFrame, payload);

      state = state.copyWith(
        histogram: histogramEnabled ? result.histogram : state.histogram,
        histogramReady: histogramEnabled,
        focusPeakingMap: focusPeakingEnabled
            ? result.focusPeakingMap
            : state.focusPeakingMap,
        focusMapWidth: image.width ~/ 4,
        focusMapHeight: image.height ~/ 4,
        falseColorMap:
            falseColorEnabled ? result.falseColorMap : state.falseColorMap,
        averageLuminance: result.averageLuminance,
        isClipping: result.isClipping,
        isUnderexposed: result.isUnderexposed,
      );
    } catch (e) {
      debugPrint('[ProMonitoring] frame error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  void updateFps(double fps) {
    _currentFps = fps;
    final int recommendedUs = (1000000 / (fps * 2)).round();
    final bool violated =
        state.averageLuminance > 210 || state.averageLuminance < 30;
    state = state.copyWith(
      currentFps: fps,
      recommendedShutterUs: recommendedUs,
      shutterRuleViolated: violated,
    );
  }

  void updateAudioLevel(double level) {
    state = state.copyWith(
      audioLevel: level.clamp(0.0, 1.0),
      audioClipping: level >= 0.95,
    );
  }

  void toggleHistogram() {
    histogramEnabled = !histogramEnabled;
    if (!histogramEnabled) state = state.copyWith(histogramReady: false);
  }

  void toggleFocusPeaking() {
    focusPeakingEnabled = !focusPeakingEnabled;
  }

  void toggleFalseColor() {
    falseColorEnabled = !falseColorEnabled;
  }

  void setEnabled(bool value) => _enabled = value;
}

final proMonitoringProvider =
    StateNotifierProvider<ProMonitoringNotifier, ProMonitoringState>(
  (ref) => ProMonitoringNotifier(ref),
);
