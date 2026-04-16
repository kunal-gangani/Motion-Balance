
-----
# MotionBalance

### **The AI-Powered Software Gimbal for Mobile Filmmakers**

**MotionBalance** is a high-performance Flutter application designed to bridge the gap between handheld mobile filming and professional stabilized cinematography. By fusing **Real-time Computer Vision (ML Kit)** with **Hardware IMU Sensors (Gyroscope/Accelerometer)**, MotionBalance provides an intelligent coaching HUD and digital stabilization guidance.

-----

## Key Features

### Active Subject Tracking (AI)

  * **Face-Lock Technology:** Utilizes Google ML Kit to identify and track subjects in real-time.
  * **Intelligent Framing:** Calculates normalized offsets to provide live directional coaching (e.g., "Pan Left," "Tilt Up").
  * **Isolate Optimization:** ML processing is offloaded to background threads to maintain a buttery-smooth **60 FPS** camera preview.

### Sensor Fusion & Stability

  * **Software Gimbal Logic:** Merges AI tracking data with gyroscope velocity to detect and warn against "Oversteering."
  * **Dynamic Horizon Leveler:** A cinematic HUD overlay that ensures perfectly level shots using real-time roll data.
  * **Stability Meter:** Real-time shake intensity analysis with visual alerts for high-vibration movement.

### Tactile HUD (Haptics)

  * **Lock Confirmation:** A light haptic pulse triggers the moment the AI locks onto a subject.
  * **Signal Loss Warning:** A double-pulse vibration alerts the filmmaker if the subject leaves the frame, allowing for "eyes-off" operation.

### Professional Cine-UI

  * **Glassmorphic HUD:** A futuristic, minimal interface designed for high visibility in outdoor lighting.
  * **Side-by-Side Mode:** A comparison toggle showing the "Raw Feed" vs. "AI-Enhanced" stabilized view.

-----

## Tech Stack

  * **Framework:** Flutter (Dart)
  * **State Management:** Riverpod 2.x (Notifier & StateNotifier)
  * **AI/ML:** Google ML Kit (Face Detection)
  * **Hardware:** Camera & Sensors Plus (Gyroscope, Accelerometer)
  * **Architecture:** **MVC (Model-View-Controller)** for high maintainability and decoupled logic.
  * **Performance:** Multi-threading via **Flutter Isolates** for zero-jank UI.

-----

## Project Architecture

MotionBalance follows a strict **MVC** pattern to ensure the codebase is scalable and testable:

  * **Models:** Immutable state classes for Tracking, Sensors, and Camera status.
  * **Views:** Highly optimized CustomPainters for the Reticle and Horizon Leveler.
  * **Controllers:** \* `CameraNotifier`: Manages hardware lifecycle and image streams.
      * `TrackingNotifier`: The "Brain" that performs coordinate mapping and sensor fusion.
      * `SensorController`: Handles high-frequency IMU data stream.

-----

## Getting Started

1.  **Clone the repo:**
    ```bash
    git clone https://github.com/your-username/motion-balance.git
    ```
2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```
3.  **Run the app:**
    ```bash
    flutter run --release
    ```
    *(Note: ML features and sensor fusion require a physical device for optimal performance.)*

-----

## Roadmap

  - [x] AI Subject Tracking
  - [x] Haptic Feedback Engine
  - [x] Sensor Fusion Guidance
  - [ ] FFmpeg-based Post-Process Stabilization
  - [ ] Object Tracking (TensorFlow Lite Integration)

-----

## Author

**Kunal Gangani** *Master of Computer Applications (MCA) Student & Flutter Developer* [LinkedIn](https://www.google.com/search?q=https://www.linkedin.com/in/kunal-gangani/) | [GitHub](https://www.google.com/search?q=https://github.com/kunalgangani)

-----
