# Dual Recorder - Developer Quick Start Guide

**For developers picking up this project**

---

## ⚡ Quick Overview

**Dual Recorder** is a production-ready Flutter application for simultaneous dual camera recording with Picture-in-Picture and Split-Screen layouts.

- **Status:** Production Ready (v3.0)
- **Flutter Version:** 3.38.5
- **Min API:** 21 | **Target API:** 36
- **Tests:** 20+ passing | **Code Issues:** 11 (non-critical)
- **APK Size:** 46.1 MB | **Performance:** 60fps

---

## 📁 Project Structure

```
Dual-Recorder/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── screens/                     # 5 main screens
│   │   ├── home_screen.dart         # Initialization & nav
│   │   ├── recording_screen.dart    # Main recording UI
│   │   ├── gallery_screen.dart      # Video list
│   │   ├── video_player_screen.dart # Playback
│   │   └── settings_screen.dart     # App settings
│   ├── services/                    # Business logic
│   │   ├── recording_service.dart   # Camera & recording (307 lines)
│   │   ├── permission_service.dart  # Permissions (306 lines)
│   │   ├── file_storage_service.dart# File I/O (198 lines)
│   │   ├── video_composition_service.dart # Composition (192 lines)
│   │   ├── settings_service.dart    # Preferences (142 lines)
│   │   ├── layout_service.dart      # Layout logic (82 lines)
│   │   └── camera_capability_service.dart # Hardware detection (67 lines)
│   ├── widgets/                     # Reusable UI
│   │   ├── recording_timer.dart     # Duration display
│   │   ├── camera_preview_widget.dart # Camera feed
│   │   ├── ocean_button.dart        # Styled buttons
│   │   ├── ocean_app_bar.dart       # Custom app bar
│   │   ├── glassmorphic_card.dart   # Glass effect cards
│   │   └── recording_timer.dart     # Timer widget
│   ├── theme/                       # Ocean-themed colors
│   │   ├── ocean_colors.dart        # Color palette
│   │   ├── ocean_theme.dart         # Theme config
│   │   └── ocean_fonts.dart         # Font setup
│   ├── models/                      # Data models
│   │   ├── video_metadata.dart      # Video info
│   │   └── recording_layout.dart    # Layout configs
│   ├── providers/                   # State management
│   │   └── camera_provider.dart     # Camera state
│   ├── utils/                       # Helpers
│   │   ├── logger.dart              # Logging system
│   │   ├── exceptions.dart          # Custom exceptions
│   │   └── constants.dart           # App constants
│   └── [other files]
├── android/                         # Android-specific
├── ios/                             # iOS-specific
├── test/                            # Unit & widget tests (20+ tests)
├── pubspec.yaml                     # Dependencies
├── analysis_options.yaml            # Lint rules
└── [docs]
```

---

## 🎯 Key Entry Points

### For Recording Logic
**File:** `lib/services/recording_service.dart`
- `initializeCameras()` - Initialize cameras
- `startRecording()` - Start recording session
- `pauseRecording()` - Pause recording
- `resumeRecording()` - Resume recording
- `stopRecording()` - Stop and save video

### For UI
**File:** `lib/screens/recording_screen.dart`
- Main recording interface
- Animation controllers (pulse, slide)
- Event handlers for buttons
- Camera preview display

### For Permissions
**File:** `lib/services/permission_service.dart`
- `requestCameraPermission()` - Camera access
- `requestStoragePermission()` - File storage
- `requestMicrophonePermission()` - Audio recording

### For Settings
**File:** `lib/services/settings_service.dart`
- Video quality settings
- Layout preferences
- Audio options
- Frame rate configuration

---

## 🚀 Getting Started (5 minutes)

### 1. Setup
```bash
cd Dual-Recorder
flutter pub get
```

### 2. Run on Device
```bash
flutter devices                      # List connected devices
flutter run -v                       # Run with verbose logs
```

### 3. Build APK
```bash
flutter build apk --release          # Standard build
flutter build apk --release \
  --split-debug-info=debug \
  --obfuscate                        # Optimized build
```

### 4. Install APK
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

## 🧪 Testing

### Run All Tests
```bash
flutter test
```

### Run Specific Test
```bash
flutter test test/models_test.dart
```

### Test Coverage
```bash
flutter test --coverage
```

### Tests Included
- ✓ Model tests (CameraCapability, exceptions)
- ✓ Widget tests (RecordingTimer)
- ✓ Video metadata tests
- ✓ Integration tests (basic app flow)

---

## 📊 Code Analysis

### Check Code Quality
```bash
flutter analyze --no-fatal-infos     # Show all issues
flutter analyze                       # Show only errors
```

### Current Issues (11 total - all non-critical)
- 6× RadioListTile deprecation warnings (Material 3 pattern)
- 5× Exception super parameter suggestions

**Status:** Safe to ignore (working correctly)

---

## 🔑 Key Components Explained

### RecordingService (GetX Pattern)
```dart
// Access from anywhere
final recordingService = Get.find<RecordingService>();

// Properties
recordingService.isRecording;      // bool
recordingService.isPaused;         // bool
recordingService.duration;         // Duration
recordingService.frontController;  // CameraController?
recordingService.backController;   // CameraController?

// Methods
await recordingService.initializeCameras();
await recordingService.startRecording(outputPath: path);
await recordingService.pauseRecording();
await recordingService.resumeRecording();
await recordingService.stopRecording();
```

### PermissionService
```dart
final permissionService = PermissionService();

// Check permissions
final cameraGranted = await permissionService.checkCameraPermission();
final storageGranted = await permissionService.checkStoragePermission();

// Request permissions
await permissionService.requestCameraPermission();
await permissionService.requestStoragePermission();
await permissionService.requestMicrophonePermission();
```

### FileStorageService
```dart
// Get recordings directory
final recordingsDir = await FileStorageService.getRecordingsDirectory();

// Get all recordings
final recordings = await FileStorageService.getRecordings();

// Save metadata
await FileStorageService.saveMetadata(metadata);

// Get metadata
final metadata = await FileStorageService.getMetadata(videoPath);
```

---

## 🎨 Theme System

### Using Ocean Colors
```dart
import 'package:dual_recorder/theme/ocean_colors.dart';

Container(
  color: OceanColors.deepSeaBlue,      // #1B3A3D
  child: Text(
    'Hello',
    style: TextStyle(
      color: OceanColors.aquamarine,   // #40E0D0
    ),
  ),
)
```

### Color Palette
- **Deep Sea Blue** (#1B3A3D) - Primary
- **Aquamarine** (#40E0D0) - Accent
- **Pearl White** (#F5F5F5) - Light
- **Ocean Green** (#2E8B8B) - Success
- **Coral Red** (#FF6B6B) - Error
- **Medium Gray** (#808080) - Secondary

---

## 📱 Device Requirements

### Minimum
- Android: API 21 (Android 5.0 Lollipop)
- RAM: 2GB
- Storage: 100MB for APK + video space
- Camera: At least 1 camera

### Recommended
- Android: API 28+ (Android 9+)
- RAM: 4GB+
- Storage: 1GB+ available
- Camera: Both front and back cameras

---

## 🐛 Debugging Tips

### Enable Verbose Logging
```bash
flutter run -v
```

### View Device Logs
```bash
adb logcat | grep flutter
```

### Use DevTools
```bash
flutter run
# Then open DevTools URL shown in terminal
# Navigate to:
# - Performance tab: Monitor frame drops
# - Memory tab: Check memory leaks
# - Logging tab: View app logs
```

### Common Issues

**Issue:** "Camera not initializing"
- **Check:** Device has camera hardware
- **Fix:** Restart app, check permissions

**Issue:** "Videos not saving"
- **Check:** Storage permissions granted
- **Fix:** Clear app data, reinstall

**Issue:** "App crashes on startup"
- **Check:** Permissions not granted
- **Fix:** Grant all permissions when prompted

---

## 📝 Common Tasks

### Add New Screen
1. Create file `lib/screens/new_screen.dart`
2. Extend `StatefulWidget` or `StatelessWidget`
3. Add route in `lib/main.dart`
4. Use `Navigator.push()` to navigate

### Add New Service
1. Create file `lib/services/new_service.dart`
2. Implement service logic
3. Register with GetX: `Get.put(NewService())`
4. Use: `final service = Get.find<NewService>()`

### Add New Widget
1. Create file `lib/widgets/new_widget.dart`
2. Extend `StatelessWidget` or `StatefulWidget`
3. Use in screens with: `import '../widgets/new_widget.dart'`

### Update Theme
1. Edit `lib/theme/ocean_colors.dart`
2. Add new color or modify existing
3. Use throughout app: `OceanColors.yourColor`

---

## 🔄 Git Workflow

### Check Status
```bash
git status
```

### View Recent Commits
```bash
git log --oneline -10
```

### Create Feature Branch
```bash
git checkout -b feature/your-feature
```

### Commit Changes
```bash
git add .
git commit -m "Brief description of changes"
```

### View Diff
```bash
git diff               # Unstaged changes
git diff --staged      # Staged changes
```

---

## 📚 Documentation Files

- **README.md** - Project overview
- **VERSION_3_0_COMPLETE.md** - Complete v3.0 documentation
- **FIXES_AND_ENHANCEMENTS.md** - Detailed bug fixes
- **PERFORMANCE_OPTIMIZATION.md** - Performance guide
- **DEVELOPER_QUICK_START.md** - This file!

---

## ⚙️ Configuration Files

### pubspec.yaml
- Dependencies and versions
- Version info
- Asset definitions

### analysis_options.yaml
- Lint rules
- Code style rules
- Recommended rules

### AndroidManifest.xml
- Android permissions
- API level configuration
- Feature declarations

---

## 🎯 Next Steps for Development

### If Adding Features
1. Choose appropriate screen/service
2. Add necessary permissions
3. Update settings if configurable
4. Add unit tests
5. Test on device
6. Commit with clear message

### If Fixing Bugs
1. Create issue branch
2. Add test case demonstrating bug
3. Fix the bug
4. Verify test passes
5. Commit with "Fix: ..." message

### If Optimizing Performance
1. Profile with DevTools
2. Identify bottleneck
3. Implement optimization
4. Measure improvement
5. Document in PERFORMANCE_OPTIMIZATION.md

---

## 🆘 Getting Help

### In This Project
1. Check documentation files
2. Review similar code sections
3. Check test files for examples
4. Review git commit history

### External Resources
- [Flutter Documentation](https://flutter.dev)
- [Camera Plugin](https://pub.dev/packages/camera)
- [GetX Documentation](https://github.com/jonataslaw/getx)
- [Flutter Performance Guide](https://flutter.dev/docs/performance)

---

## ✨ Quick Reference

### Important Classes
- `RecordingService` - Main recording logic (GetX)
- `PermissionService` - Permission handling
- `FileStorageService` - File operations
- `VideoPlayerScreen` - Playback UI
- `RecordingScreen` - Main UI

### Important Constants
- `minApiLevel: 21`
- `targetApiLevel: 36`
- `apkSize: 46.1 MB`
- `animationFps: 60`

### Important Directories
- **Source:** `lib/`
- **Tests:** `test/`
- **Android:** `android/`
- **iOS:** `ios/`
- **Documentation:** `/` (root)

---

## 📞 Contact & Support

For questions or issues:
1. Check documentation
2. Review code comments
3. Check git history
4. File GitHub issue
5. Check OpenCode docs

---

**Last Updated:** February 4, 2026  
**Version:** 1.0  
**Status:** Production Ready
