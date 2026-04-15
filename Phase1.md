# MotionBalance — Phase 1 Implementation

## What's implemented in this PR

### ✅ Camera Service (`lib/services/camera_service.dart`)
- `CameraService` — full lifecycle management (init, dispose, lifecycle-aware)
- **Capability detection** — probes front/rear/ultra-wide cameras, OIS/EIS availability
- **Camera switching** — front ↔ rear, cycle through all available cameras
- **Stabilization modes** — `off`, `native` (OIS/EIS flags), `software` (ready for Phase 2 warp)
- **Stabilization fallback logic** — `bestAvailableStabilizationMode()` auto-selects based on device
- **Recording** — start/stop with `XFile` output, duration tracking
- **Torch** and **zoom** helpers
- Riverpod providers: `availableCamerasProvider`, `cameraServiceProvider`

### ✅ Permission Service (`lib/services/permission_service.dart`)
- Request camera, microphone, storage in one call
- `openSettings()` deep-link for denied permissions
- Android 13+ `READ_MEDIA_VIDEO` handled

### ✅ Camera State (`lib/providers/camera_provider.dart`)
- `CameraNotifier` (AutoDispose Riverpod Notifier)
- States: `initial → requestingPermissions → initializing → ready / error`
- Live recording duration tick (1s interval)
- Exposes: `startRecording`, `stopRecording`, `switchCamera`, `setStabilizationMode`

### ✅ Camera Screen (`lib/screens/camera_screen.dart`)
- Full-screen `CameraPreview` (cover-fit, aspect-ratio-correct)
- `AppLifecycleState` observer — pauses on background, resumes on foreground
- Wakelock enabled while recording
- Immersive full-screen mode
- `_StabilizationPicker` — Off / Native / Software pill selector
- `_SwitchCameraButton` — loading spinner while switching
- `RecordingTimer` badge on top bar
- `StabilizationBadge` showing active mode with color indicator
- `CameraErrorView` — permission vs hardware error with retry / settings CTAs

### ✅ Widgets
| Widget | File |
|--------|------|
| `RecordButton` | `lib/widgets/record_button.dart` |
| `RecordingTimer` | `lib/widgets/recording_timer.dart` |
| `StabilizationBadge` | (co-located in recording_timer.dart) |
| `CameraErrorView` | (co-located in recording_timer.dart) |

### ✅ Platform config
- **Android** `AndroidManifest.xml` — camera, audio, storage, wake lock permissions + hardware features
- **iOS** `Info.plist` — `NSCameraUsageDescription`, `NSMicrophoneUsageDescription`, photo library

---

## Setup

```bash
# 1. Copy all files into your existing Flutter project
# 2. Install dependencies
flutter pub get

# 3. Android: minSdkVersion must be ≥ 21 in android/app/build.gradle
#    android { defaultConfig { minSdkVersion 21 } }

# 4. iOS: deployment target ≥ 13.0 in ios/Podfile
#    platform :ios, '13.0'

# 5. Run
flutter run
```

---

## Phase 2 — Next Steps (Live Stabilization)

Once Phase 1 is verified on device, plug in:

1. **Sensor service** (`sensors_plus`) — gyro + accelerometer fusion → roll/pitch/yaw stream
2. **Horizon level overlay** — `CustomPainter` line on `CameraPreview`
3. **Shake meter HUD** — RMS deviation of accelerometer, animated bar
4. **Software warp** — use sensor roll angle to apply `Matrix4` transform to preview
5. **Motion smoothness scoring** — rolling window RMS → 0–100 score badge

The `StabilizationMode.software` path in `CameraService` is already wired — Phase 2 just needs to fill in the warp logic behind that flag.
