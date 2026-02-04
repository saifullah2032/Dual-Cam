# Dual-Cam Video Recorder (Flutter) - Detailed Implementation Plan

## Project Overview
A Flutter application for simultaneous front and back camera recording with PiP or Split-Screen layout, outputting a single merged video file with an ocean-inspired aesthetic and professional UI/UX.

---

## Phase 1: Project Setup & Environment Configuration (Week 1)

### 1.1 Flutter Project Initialization
- **Step 1.1.1:** Create a new Flutter project
  ```bash
  flutter create dual_recorder --platforms=android,ios
  cd dual_recorder
  ```
- **Step 1.1.2:** Verify Flutter and Dart SDK versions
  - Minimum Flutter: 3.0+
  - Minimum Dart: 3.0+
- **Step 1.1.3:** Update `pubspec.yaml` with initial dependencies
  ```yaml
  dependencies:
    flutter:
      sdk: flutter
    camera: ^0.10.0
    video_player: ^2.4.0
    ffmpeg_kit_flutter: ^6.0.0
    animations: ^2.0.0
    lottie: ^2.0.0
    provider: ^6.0.0
    get: ^4.6.0
  ```

### 1.2 Android Native Setup
- **Step 1.2.1:** Update `android/app/build.gradle`
  - Set `minSdkVersion: 21` (Camera2 API support)
  - Set `targetSdkVersion: 33+`
- **Step 1.2.2:** Add Android permissions in `AndroidManifest.xml`
  ```xml
  <uses-permission android:name="android.permission.CAMERA" />
  <uses-permission android:name="android.permission.RECORD_AUDIO" />
  <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
  <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
  ```
- **Step 1.2.3:** Create Kotlin Method Channel bridge
  - File: `android/app/src/main/kotlin/com/example/dual_recorder/CameraChannel.kt`
  - Implement native method channel for camera capability checks
- **Step 1.2.4:** Add Camera2 API imports
  - `android.hardware.camera2.CameraManager`
  - `android.hardware.camera2.CameraCharacteristics`

### 1.3 iOS Native Setup
- **Step 1.3.1:** Update `ios/Podfile`
  - Ensure iOS deployment target: 13.0+
- **Step 1.3.2:** Add iOS permissions in `Info.plist`
  ```xml
  <key>NSCameraUsageDescription</key>
  <string>We need camera access to record video from both cameras</string>
  <key>NSMicrophoneUsageDescription</key>
  <string>We need microphone access to record audio</string>
  ```
- **Step 1.3.3:** Create Swift Method Channel bridge
  - File: `ios/Runner/CameraChannel.swift`
  - Implement native method channel for camera capability checks
- **Step 1.3.4:** Add AVFoundation imports
  - `AVFoundation`
  - `AVCaptureMultiCamSession`

### 1.4 Git Repository Setup
- **Step 1.4.1:** Initialize git repository
  ```bash
  git init
  ```
- **Step 1.4.2:** Create `.gitignore` with Flutter-specific ignores
- **Step 1.4.3:** Create initial commit
  ```bash
  git add .
  git commit -m "Initial Flutter project setup"
  ```

---

## Phase 2: Hardware Capability Detection & Native Integration (Week 2)

### 2.1 Android Camera Capability Detection
- **Step 2.1.1:** Implement `CameraManager.getConcurrentCameraIds()` check in Kotlin
  - File: `android/app/src/main/kotlin/com/example/dual_recorder/CameraManager.kt`
  - Create function: `hasConcurrentCameraSupport(): Boolean`
  - Check for available concurrent camera pairs
- **Step 2.1.2:** Implement device model mapping
  - Store supported device models in local database/SharedPreferences
  - Cache concurrent camera capability checks
- **Step 2.1.3:** Create exception handling for camera initialization
  - Handle `CameraAccessException`
  - Fallback to sequential recording if concurrent not available

### 2.2 iOS Camera Capability Detection
- **Step 2.2.1:** Implement `AVCaptureMultiCamSession.isMultiCamSupported` check in Swift
  - File: `ios/Runner/CameraManager.swift`
  - Create function: `hasConcurrentCameraSupport() -> Bool`
  - Check iOS version requirements (iOS 13.0+)
- **Step 2.2.2:** Implement device model validation
  - Verify iPhone model supports dual camera recording
  - Supported models: iPhone XS+, iPhone 12+
- **Step 2.2.3:** Create exception handling for AVCapture setup
  - Handle `AVError`
  - Implement fallback recording mode

### 2.3 Flutter Method Channel Implementation
- **Step 2.3.1:** Create `lib/services/camera_capability_service.dart`
  - Define MethodChannel: `com.example.dual_recorder/camera_capability`
  - Implement `checkConcurrentCameraSupport()` method
  - Implement `getCameraIds()` method
- **Step 2.3.2:** Create camera capability model
  - File: `lib/models/camera_capability.dart`
  - Properties: `supportsConcurrent`, `availableCameras`, `deviceModel`
- **Step 2.3.3:** Implement error handling and fallback logic
  - Create custom exceptions: `CameraException`, `ConcurrentCameraNotSupportedException`
  - Implement retry logic with exponential backoff

### 2.4 State Management Setup
- **Step 2.4.1:** Create provider for camera capabilities
  - File: `lib/providers/camera_provider.dart`
  - Manage camera state using Provider package
  - Handle async capability checks
- **Step 2.4.2:** Create app-level state management
  - File: `lib/providers/app_provider.dart`
  - Track app initialization state
  - Handle permission requests

---

## Phase 3: Ocean-Themed UI/UX Design System (Week 3)

### 3.1 Design System Foundation
- **Step 3.1.1:** Create Ocean color palette
  - File: `lib/theme/ocean_colors.dart`
  - Deep Sea Blue: `#001219`
  - Aquamarine: `#9AD1D4`
  - Pearl White: `#F5F5F5`
  - Accent Teal: `#48A597`
  - Gradient Dark Blue: `#003d5c`
  - Semi-transparent overlays for glassmorphism
- **Step 3.1.2:** Implement theme data
  - File: `lib/theme/ocean_theme.dart`
  - Create `oceanLightTheme` with ocean colors
  - Define typography using Google Fonts (Raleway, Poppins)
  - Set up component styling (buttons, cards, text fields)
- **Step 3.1.3:** Create glassmorphism utilities
  - File: `lib/theme/glassmorphism.dart`
  - Implement `GlassmorphicContainer` widget
  - Define blur effects and transparency levels
- **Step 3.1.4:** Setup responsive design utilities
  - File: `lib/theme/responsive.dart`
  - Create breakpoints for mobile/tablet
  - Implement responsive padding and sizing helpers

### 3.2 Custom Widget Library
- **Step 3.2.1:** Create ocean-themed button components
  - File: `lib/widgets/ocean_button.dart`
  - Primary button with ripple effect
  - Secondary button with outline style
  - Floating action button with wave animation
- **Step 3.2.2:** Create ocean-themed cards and containers
  - File: `lib/widgets/ocean_card.dart`
  - Implement glassmorphic card design
  - Add shadow and blur effects
- **Step 3.2.3:** Create loading indicators
  - File: `lib/widgets/ocean_loader.dart`
  - Implement shimmer wave gradient loader
  - Implement circular progress indicator with wave pattern
- **Step 3.2.4:** Create custom app bar
  - File: `lib/widgets/ocean_app_bar.dart`
  - Implement transparent/glassmorphic app bar
  - Add animated gradient background

### 3.3 Animation System
- **Step 3.3.1:** Create hero animation transitions
  - File: `lib/animations/hero_animations.dart`
  - Implement screen transition animations
  - Create custom hero animation builders
- **Step 3.3.2:** Create liquid swipe animations
  - File: `lib/animations/liquid_animations.dart`
  - Implement custom liquid swipe page route
  - Create wave-based page transitions
- **Step 3.3.3:** Create micro-interactions
  - File: `lib/animations/micro_interactions.dart`
  - Implement record button ripple animation
  - Create PiP window drag animation with weight/physics
  - Implement tap feedback animations
- **Step 3.3.4:** Setup Lottie animations
  - File: `assets/lottie/` directory
  - Create or import wave loading animation
  - Create or import recording indicator animation

### 3.4 Screen Layouts
- **Step 3.4.1:** Create home/main screen
  - File: `lib/screens/home_screen.dart`
  - Display camera preview(s)
  - Show device capability status
  - Implement navigation to recording screen
- **Step 3.4.2:** Create recording screen
  - File: `lib/screens/recording_screen.dart`
  - Display dual camera feeds (PiP or split-screen)
  - Implement recording controls (start/stop/pause)
  - Show recording time and file size
  - Add manual PiP window dragging
- **Step 3.4.3:** Create settings screen
  - File: `lib/screens/settings_screen.dart`
  - Configure video quality (480p, 720p, 1080p)
  - Configure layout (PiP or split-screen)
  - Configure PiP window position
  - Configure audio recording settings
- **Step 3.4.4:** Create gallery/playback screen
  - File: `lib/screens/gallery_screen.dart`
  - Display recorded videos
  - Implement video preview/playback
  - Implement video sharing and deletion

---

## Phase 4: Dual Camera Recording Implementation

### 4.1 Android Native Camera Implementation
- **Step 4.1.1:** Create camera controller
  - File: `android/app/src/main/kotlin/com/example/dual_recorder/DualCameraController.kt`
  - Implement `CameraDevice.StateCallback` for both cameras
  - Create dual `CameraCaptureSession` setup
- **Step 4.1.2:** Implement surface texture rendering
  - Create `SurfaceTexture` composition
  - Implement OpenGL ES for real-time video composition
  - Create frame buffer objects for combining streams
- **Step 4.1.3:** Implement MediaRecorder integration
  - Configure MediaRecorder with composed surface
  - Handle audio recording from microphone
  - Implement file output and rotation handling

### 4.2 iOS Native Camera Implementation
- **Step 4.2.1:** Create camera controller
  - File: `ios/Runner/DualCameraController.swift`
  - Implement `AVCaptureMultiCamSession` setup
  - Create dual camera input/output configuration
- **Step 4.2.2:** Implement Metal/Core Graphics rendering
  - Create Metal compute shaders for video composition
  - Implement real-time frame composition
  - Handle Metal texture rendering
- **Step 4.2.3:** Implement AVAssetWriter integration
  - Configure video and audio input
  - Handle file writing with proper codecs (H.264)
  - Implement orientation and rotation handling

### 4.3 Flutter Camera Service Layer
- **Step 4.3.1:** Create recording service
  - File: `lib/services/recording_service.dart`
  - Implement `startRecording()` method
  - Implement `stopRecording()` method
  - Implement `pauseRecording()` method
  - Handle file path management and cleanup
- **Step 4.3.2:** Create preview service
  - File: `lib/services/preview_service.dart`
  - Implement camera preview rendering
  - Handle texture updates from native layer
  - Manage preview scaling and positioning
- **Step 4.3.3:** Implement layout management
  - File: `lib/services/layout_service.dart`
  - PiP window position calculations
  - Split-screen layout management
  - Handle device rotation and reorientation

### 4.4 Recording UI Integration
- **Step 4.4.1:** Implement camera preview widget
  - File: `lib/widgets/camera_preview.dart`
  - Use `Texture` widget for native texture rendering
  - Implement gesture detection for PiP dragging
  - Handle preview scaling
- **Step 4.4.2:** Implement recording controls widget
  - File: `lib/widgets/recording_controls.dart`
  - Record/pause/stop buttons with state feedback
  - Recording timer display
  - File size indicator
- **Step 4.4.3:** Implement PiP window widget
  - File: `lib/widgets/pip_window.dart`
  - Draggable PiP container with animation
  - Resize handles (optional)
  - Visual feedback for drag operations

---

## Phase 5: Video Processing & Export (Week 4)

### 5.1 FFmpeg Integration
- **Step 5.1.1:** Setup FFmpeg Kit Flutter
  - Add `ffmpeg_kit_flutter` to pubspec.yaml
  - Configure for both Android and iOS
  - Create FFmpeg command builders
- **Step 5.1.2:** Create video composition service
  - File: `lib/services/video_composition_service.dart`
  - Implement `composeVideos()` for sequential recording fallback
  - Handle video concatenation
  - Implement video merging with PiP layout
- **Step 5.1.3:** Implement video encoding optimization
  - Create preset encoding profiles (quality levels)
  - Implement bitrate calculation based on resolution
  - Add audio encoding configuration
- **Step 5.1.4:** Create progress tracking
  - Implement `onProgress` callback
  - Display processing status in UI
  - Handle cancellation during processing

### 5.2 File Management
- **Step 5.2.1:** Implement file storage service
  - File: `lib/services/file_storage_service.dart`
  - Configure app-specific directory usage
  - Implement temporary file cleanup
  - Handle external storage permissions
- **Step 5.2.2:** Create file naming convention
  - Timestamp-based naming
  - Metadata storage in JSON sidecar files
  - Implement file compression/archival
- **Step 5.2.3:** Implement backup and sync
  - Optional cloud storage integration
  - Local backup management
  - Implement file sharing APIs

### 5.3 Video Metadata Management
- **Step 5.3.1:** Create metadata model
  - File: `lib/models/video_metadata.dart`
  - Properties: `duration`, `resolution`, `bitrate`, `layout`, `recordingDate`
  - Implement JSON serialization
- **Step 5.3.2:** Implement metadata storage
  - File: `lib/services/metadata_service.dart`
  - Store metadata with video files
  - Implement database for metadata (Hive/SQLite)
  - Create metadata querying interface

---

## Phase 6: Testing & Quality Assurance (Week 5)

### 6.1 Unit Testing
- **Step 6.1.1:** Create unit tests for services
  - File: `test/services/` directory
  - Test camera capability detection
  - Test file management logic
  - Test metadata serialization
- **Step 6.1.2:** Create unit tests for utilities
  - File: `test/theme/` directory
  - Test responsive layout calculations
  - Test color utilities

### 6.2 Widget Testing
- **Step 6.2.1:** Create widget tests
  - File: `test/widgets/` directory
  - Test custom ocean widgets
  - Test recording screen layout
  - Test camera preview rendering
- **Step 6.2.2:** Test animation interactions
  - Test hero animations
  - Test micro-interactions
  - Test state transitions

### 6.3 Integration Testing
- **Step 6.3.1:** Create integration tests
  - File: `integration_test/` directory
  - Test end-to-end recording flow
  - Test permission handling
  - Test video export process
- **Step 6.3.2:** Create device-specific tests
  - Test on various Android versions (API 21+)
  - Test on various iOS versions (13.0+)
  - Test with different device hardware specs

### 6.4 Performance Testing
- **Step 6.4.1:** Profile memory usage
  - Monitor dual camera streaming memory
  - Check texture management
  - Profile rendering performance
- **Step 6.4.2:** Profile CPU/GPU usage
  - Monitor processing during recording
  - Check frame drop rates
  - Optimize rendering pipeline as needed
- **Step 6.4.3:** Battery drain testing
  - Test battery consumption during recording
  - Optimize for power efficiency
  - Implement power-saving modes

### 6.5 Manual Testing Protocol
- **Step 6.5.1:** Test on supported devices
  - Minimum 3 Android devices with Camera2 support
  - Minimum 3 iOS devices with multi-cam support
  - Test on low-end devices for fallback behavior
- **Step 6.5.2:** Test edge cases
  - App backgrounding/resuming
  - Permission denial scenarios
  - Storage full scenarios
  - Camera unavailability (USB debug, etc.)
- **Step 6.5.3:** Test audio recording
  - Verify audio levels
  - Test microphone routing
  - Test audio sync with video

---

## Additional Considerations

### A1. Error Handling Strategy
- **File: `lib/utils/error_handler.dart`**
  - Create centralized error handling
  - Implement user-friendly error messages
  - Create error recovery flows
  - Log errors for debugging

### A2. Logging & Debugging
- **File: `lib/utils/logger.dart`**
  - Implement comprehensive logging
  - Log camera events
  - Log recording lifecycle events
  - Create debug information export

### A3. Documentation
- **Create `docs/` directory with:**
  - Architecture overview
  - API documentation
  - Testing guide
  - Deployment guide
  - Troubleshooting guide

### A4. Performance Optimization Checklist
- [ ] Implement lazy loading for screens
- [ ] Use const constructors where applicable
- [ ] Implement image caching
- [ ] Optimize widget rebuilds with Provider selectivity
- [ ] Profile and optimize native code
- [ ] Implement proper texture cleanup
- [ ] Configure appropriate codec settings

### A5. Security Considerations
- [ ] Validate all file paths to prevent directory traversal
- [ ] Implement runtime permission verification
- [ ] Encrypt sensitive metadata
- [ ] Secure temporary file handling
- [ ] Implement proper exception handling to avoid information disclosure

---

## Deployment Roadmap

### Phase 6.1: Beta Testing (Post-Development)
- [ ] Internal testing with team
- [ ] TestFlight deployment (iOS)
- [ ] Google Play beta testing (Android)
- [ ] Collect user feedback

### Phase 6.2: Production Release
- [ ] Final bug fixes
- [ ] Optimization passes
- [ ] App Store submission (iOS)
- [ ] Google Play Store submission (Android)
- [ ] Release notes preparation

### Phase 6.3: Post-Launch Support
- [ ] Monitor crash reports
- [ ] Implement feature requests
- [ ] Optimize performance based on real-world usage
- [ ] Plan for future features (effects, filters, etc.)

---

## Estimated Timeline Summary
| Phase | Task | Estimated Time |
| :--- | :--- | :--- |
| 1 | Project Setup & Environment | Week 1 |
| 2 | Hardware Detection & Native Integration | Week 2 |
| 3 | Ocean-Themed UI/UX Design System | Week 3 |
| 4 | Dual Camera Recording Implementation | Week 3-4 |
| 5 | Video Processing & Export | Week 4 |
| 6 | Testing & QA | Week 5 |
| | **Total** | **~5-6 Weeks** |

---

## Success Criteria

- ✅ App successfully records from both cameras simultaneously on supported devices
- ✅ Video output is properly composed (PiP or split-screen) and playable
- ✅ Ocean-inspired UI is visually appealing and responsive
- ✅ App gracefully handles unsupported devices with sequential recording fallback
- ✅ All tests pass (unit, widget, integration)
- ✅ Performance meets targets (no excessive battery drain, <100ms latency)
- ✅ Zero critical bugs on launch
- ✅ User documentation is comprehensive

---

## References & Resources

- [Flutter Camera Plugin](https://pub.dev/packages/camera)
- [FFmpeg Kit Flutter](https://pub.dev/packages/ffmpeg_kit_flutter)
- [Android Camera2 API](https://developer.android.com/reference/android/hardware/camera2/package-summary)
- [iOS AVFoundation](https://developer.apple.com/documentation/avfoundation)
- [Flutter Method Channels](https://flutter.dev/docs/development/platform-integration/platform-channels)
- [Material Design 3](https://m3.material.io/)
- [Flutter Animations](https://flutter.dev/docs/development/ui/animations)
