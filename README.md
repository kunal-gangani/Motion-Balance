# MotionBalance

### The AI-Powered Software Gimbal for Mobile Filmmakers

**MotionBalance** is a high-performance Flutter application that bridges the gap between handheld mobile filming and professional stabilized cinematography. By fusing **Real-time Computer Vision (ML Kit)**, **Hardware IMU Sensors**, and a **Kalman Filter stabilization pipeline**, MotionBalance delivers an intelligent cinematography HUD that adapts to how you move — without any physical gimbal hardware.

---

## Key Features

### Active Subject Tracking (AI)
- **Face-Lock Technology** — Google ML Kit identifies and tracks subjects in real-time using a persistent detector with zero per-frame allocation
- **Intelligent Framing** — calculates normalized offsets and provides live directional coaching: Pan Left, Tilt Up, Oversteer Warning
- **Isolate Optimization** — ML processing is offloaded to a background isolate via `compute()` with a plain-data `_IsolatePayload` to maintain a smooth 60 FPS preview
- **Haptic Confirmation** — single pulse on subject lock, double pulse on signal loss

### Stabilization Intelligence
- **Kalman Filter** — replaces the complementary filter for roll/pitch estimation; dynamically adjusts trust between gyroscope and accelerometer, produces angular velocity alongside angle
- **Shot Type Classifier** — analyses a 30-sample rolling sensor window and classifies movement as `Static`, `Pan`, `Tilt`, `Dolly`, `Walk`, or `Freehand` using RMS gyro rates and zero-crossing frequency analysis
- **Auto-Adjust** — automatically switches `ResolutionPreset` and OIS mode based on detected shot type; debounced at 2 seconds to avoid controller thrashing
- **Oversteer Detection** — compares subject offset against motion intensity to warn when the filmmaker is overcorrecting

### Pro Monitoring Tools
- **False Color Overlay** — exposure zones rendered as a semi-transparent RGBA overlay: blue (crushed blacks), teal (underexposed), transparent (correct), yellow (slightly hot), orange (overexposed), red+zebra (clipping)
- **Focus Peaking** — Sobel edge detection on the luma plane highlights sharp regions in cyan; processed at 1/4 resolution for performance
- **Luminance Histogram** — 256-bucket live histogram with zone-matched bar colors; border turns red on clipping, blue on underexposure
- **Audio Level Meter** — vertical bar with clip indicator; color shifts green → orange → red by level
- **180° Shutter Rule Enforcer** — displays recommended shutter speed at current FPS; turns red when violated

### Sensor Fusion HUD
- **Dynamic Horizon Leveler** — Kalman-filtered roll converted to radians drives a `Transform.rotate` overlay; color lerps white → amber as tilt increases
- **Stability Meter** — real-time shake intensity from `UserAccelerometerEvent`; color shifts green → red above threshold
- **Guidance Text** — live coaching: Stable / Smooth Panning / Move Slower / Reduce Sudden Pans
- **Shot Type Badge** — live indicator showing current shot type with stabilization aggressiveness bar

### Filmmaker Workflow
- **Side-by-Side Comparison Mode** — toggleable divider showing Raw Feed vs AI-Enhanced view; toggle button in top bar
- **Gallery** — sorted recording library with formatted dates, file sizes, delete, and share
- **Video Playback** — `video_player` integration with play/pause and share via `share_plus`
- **Splash Screen** — animated scale + fade intro with `RussoOne` typography

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.x (Dart) |
| State Management | Riverpod 2.x — `NotifierProvider`, `StateNotifierProvider` |
| AI / ML | Google ML Kit Face Detection + Object Detection |
| Hardware | `camera`, `sensors_plus` (Gyroscope, Accelerometer) |
| Signal Processing | Custom Kalman Filter, Sobel edge detection, RMS classifier |
| Performance | Flutter Isolates via `compute()` for ML and frame analysis |
| Haptics | `vibration` with `hasVibrator()` capability guard |
| Video | `video_player`, `share_plus`, `video_thumbnail` |
| Architecture | MVC — Models / Views / Controllers strictly separated |

---

## Project Architecture

```
lib/
├── Controllers/
│   ├── camera_controller.dart          # Camera lifecycle, image stream, ML isolate
│   ├── sensor_controller.dart          # Shake intensity, guidance text
│   ├── stabilization_intelligence_controller.dart  # Kalman filter, shot classifier, auto-adjust
│   ├── tracking_controller.dart        # Face coordinate mapping, oversteer detection
│   ├── gallery_controller.dart         # Video library state
│   ├── video_player_controller.dart    # Playback state
│   └── pro_monitoring_controller.dart  # Histogram, focus peaking, false color, audio, shutter
│
├── Services/
│   ├── camera_service.dart             # CameraController lifecycle, InputImage conversion
│   ├── permission_service.dart         # Camera, mic, storage — Android 13+ aware
│   ├── gallery_service.dart            # File I/O for recordings directory
│   ├── haptic_services.dart            # Vibration patterns with capability guard
│   ├── ml_service.dart                 # ObjectDetector (face detection is isolate-owned)
│   ├── kalman_filter.dart              # 1D Kalman filter — angle + bias estimation
│   ├── shot_classifier_service.dart    # Rolling window shot type classification
│   └── stabilization_service.dart     # Motion analysis, smoothness scoring
│
├── Models/
│   ├── tracking_state.dart             # Face box, offset, lock status
│   ├── recorded_video.dart             # Path, date, size, duration helpers
│   ├── motion_data.dart                # Sensor snapshot for stabilization analysis
│   └── shot_type.dart                  # ShotType enum with aggressiveness + preset metadata
│
└── Views/
    ├── Screens/
    │   ├── camera_screen.dart          # Main viewfinder — all overlays composed here
    │   ├── gallery_screen.dart         # Video list with refresh and delete
    │   └── splash_screen.dart          # Animated intro
    ├── VideoPlayerView/
    │   └── video_player_view.dart      # Playback with share
    ├── SplashScreen/
    │   └── splash_screen.dart
    └── Widgets/
        ├── camera_error_view.dart
        ├── false_color_overlay.dart
        ├── focus_peaking_overlay.dart
        ├── histogram_overlay.dart
        ├── horizon_leveler.dart
        ├── pro_monitoring_widgets.dart  # AudioLevelMeter, ShutterRuleBadge, ProMonitoringToolbar
        ├── recording_button.dart
        ├── recording_timer.dart
        ├── shot_type_badge.dart         # ShotTypeBadge, ShotTypePill
        ├── stability_meter.dart
        ├── stabilization_badge.dart
        └── tracking_overlay.dart
```

---

## Getting Started

1. **Clone the repo:**
   ```bash
   git clone https://github.com/kunal-gangani/Motion-Balance.git
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Android** — ensure `android/app/build.gradle` has:
   ```gradle
   minSdkVersion 21
   ```

4. **iOS** — ensure `ios/Podfile` has:
   ```ruby
   platform :ios, '13.0'
   ```

5. **Add assets** — place your app icon at:
   ```
   lib/Assets/Icons/Motion_Balance.png
   assets/fonts/RussoOne-Regular.ttf
   ```

6. **Run on a physical device:**
   ```bash
   flutter run --release
   ```
   > ML Kit face detection, sensor fusion, and haptics require a physical device. The emulator does not provide gyroscope or camera image streams.

---

## Tuning Guide

| Parameter | File | Default | Adjust when |
|---|---|---|---|
| `_gyroThreshold` | `shot_classifier_service.dart` | `2.0 deg/s` | Shot type flickers — increase |
| `_walkFreqMin/Max` | `shot_classifier_service.dart` | `1.4–3.2 Hz` | Walk not detected — widen range |
| `processNoise` | `kalman_filter.dart` | `0.001` | Horizon too sluggish — increase |
| `measurementNoise` | `kalman_filter.dart` | `0.1` | Horizon drifts — increase |
| `oversteerThreshold` | `tracking_controller.dart` | `3.0` | Too many false warnings — increase |

---

## Roadmap

- [x] Phase 1 — MVP Foundation (camera, permissions, recording, gallery)
- [x] Phase 2 — Live Stabilization Assistant (sensor fusion, horizon leveler, shake meter)
- [x] Phase 3 — Stabilization Intelligence (Kalman filter, shot classifier, auto-adjust)
- [x] Phase 4 — Pro Monitoring (false color, focus peaking, histogram, audio meter, 180° rule)
- [ ] Phase 5 — Cinematic Control (manual ISO/shutter, frame rate profiles, log picture profile)
- [ ] Phase 6 — AI Subject Intelligence (subject reframing, eye tracking lock, scene detection)
- [ ] Phase 7 — Filmmaker Workflow (digital slate, SMPTE timecode, shot log, CSV export)
- [ ] Phase 8 — Advanced Post (rolling shutter correction, FFmpeg stabilization pipeline)

---

## Author

**Kunal Gangani**
*Master of Computer Applications (MCA) Student & Flutter Developer*

[LinkedIn](https://www.linkedin.com/in/kunal-gangani/) | [GitHub](https://github.com/kunal-gangani)