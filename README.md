# MotionBalance 🎥✨

**MotionBalance** is a production-ready Flutter application designed to act as a **Software Gimbal Assistant**. Instead of claiming to replace motorized hardware, it bridges the gap for mobile creators by leveraging native hardware stabilization, real-time sensor guidance, and post-processing algorithms.

---

## 🚀 Core Mission
To improve handheld video stability on Android and iOS through an intelligent, phased stabilization approach:
1.  **Native Support:** Trigger high-end hardware stabilization where available.
2.  **Sensor Guidance:** Real-time IMU (Inertial Measurement Unit) monitoring to coach the user into smoother movement.
3.  **Post-Processing:** FFmpeg-based digital stabilization for "rescuing" shaky footage.

---

## 🏗 Architecture
The project follows the **MVC (Model-View-Controller)** pattern combined with **Clean Architecture** principles to ensure platform-specific hardware logic remains decoupled from the UI.

-   **Models:** Represent device capabilities, sensor data structures, and recording states.
-   **Views:** Modern, creator-focused dark UI featuring horizon levelers and stability meters.
-   **Controllers:** Manage camera lifecycles, stream IMU data, and orchestrate FFmpeg commands.
-   **Services:** Handle persistent storage, permission requests, and platform-specific capability detection.

---

## 🛠 Features

### 1. Camera & Native Stabilization
- Supports front and rear camera switching.
- Automatic detection of `VideoStabilizationMode` (Auto, Cinematic, Off).
- Graceful degradation: If native stabilization fails, the app automatically switches to **Sensor Guidance Mode**.

### 2. Live Stability Assistant (IMU)
- **Horizon Leveler:** A dynamic UI overlay using the accelerometer to help keep the phone perfectly level.
- **Shake Meter:** Real-time analysis of gyroscope data to calculate "Motion Smoothness."
- **Coaching Overlays:** Live prompts like "Move Slower," "Reduce Sudden Pans," or "Hold Level."

### 3. Recording Profiles
- **Walk Mode:** Optimized for vertical oscillation (bobbing) detection.
- **Pan Mode:** Monitors yaw/pitch to ensure smooth cinematic rotations.
- **Vlog Mode:** Prioritizes horizon stability for selfie-angle shots.

### 4. Post-Processing Engine
- Powered by `ffmpeg_kit_flutter`.
- Offers three strengths: **Light**, **Balanced**, and **Pro Gimbal**.
- Side-by-side "Before vs. After" comparison screen.

---

## 📦 Requirements & Installation

### Prerequisites
- Flutter 3.x
- Dart 3.x
- Physical device (Sensors and Camera stabilization cannot be tested on Emulators/Simulators).

### Dependencies
- `camera`: Camera hardware access.
- `sensors_plus`: Gyroscope and Accelerometer data.
- `ffmpeg_kit_flutter_full`: Video stabilization filters (`vidstab`).
- `video_player`: Post-process previewing.
- `permission_handler`: Managing hardware permissions.

### Setup Instructions

#### Android
1.  Set `minSdkVersion 24` in `android/app/build.gradle`.
2.  Add permissions to `AndroidManifest.xml`:
    ```xml
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
    ```

#### iOS
1.  Add usage descriptions to `Info.plist`:
    ```xml
    <key>NSCameraUsageDescription</key>
    <string>MotionBalance needs camera access to record stabilized video.</string>
    <key>NSMicrophoneUsageDescription</key>
    <string>MotionBalance needs microphone access for video audio.</string>
    <key>NSPhotoLibraryUsageDescription</key>
    <string>Used to save and stabilize recorded clips.</string>
    ```

---

## 🛣 Phased Roadmap

### Phase 1: MVP (Current)
- [x] Basic Camera implementation.
- [x] Live Horizon Leveler.
- [x] Real-time Shake Meter.
- [x] Device capability detection.

### Phase 2: Intelligence
- [ ] Recording profiles (Walk, Pan, Vlog).
- [ ] Dynamic guidance logic based on profile.

### Phase 3: Post-Processing
- [ ] FFmpeg vidstab integration.
- [ ] Comparison View (Before/After).

---

## ⚠️ Important Disclaimer
MotionBalance is a **software assistant**. It does not physically move the camera lens or housing. It relies on digital cropping and sensor feedback. For professional-grade cinematic stability, a physical 3-axis motorized gimbal is recommended.

---

## 📄 License
This project is licensed under the MIT License - see the LICENSE file for details.
