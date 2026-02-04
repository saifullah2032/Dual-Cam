# Dual-Cam Video Recorder - Flutter Application

A professional Flutter application for simultaneous dual camera recording with Picture-in-Picture (PiP) or Split-Screen layout, featuring an ocean-inspired aesthetic and comprehensive UI/UX.

## Features

### Core Functionality
- **Dual Camera Recording**: Simultaneously record from front and back cameras on supported devices
- **Flexible Layouts**: 
  - Picture-in-Picture (PiP) with 4 position options
  - Split-Screen (side-by-side) layout
- **Video Composition**: FFmpeg-powered video merging and export
- **Recording Controls**: Start, pause, resume, and stop recording with real-time duration tracking
- **Gallery Management**: Browse, preview, and delete recorded videos
- **Settings Management**: Configurable video quality, layout, audio, and frame rate

### Design
- **Ocean-Inspired UI**: Professional theme with aquamarine, teal, and ocean blue colors
- **Glassmorphism**: Modern frosted glass effects throughout the interface
- **Responsive Design**: Optimized for various screen sizes and orientations
- **Custom Widgets**: Purpose-built components including OceanButton, RecordingTimer, and GlassmorphicCard

### Platform Support
- **Android**: API 21+ (Camera2 API support)
- **iOS**: iOS 13.0+ (AVFoundation with Multi-camera support)
- **Concurrent Recording**: Automatic fallback for unsupported devices

## Project Structure

```
lib/
├── main.dart                          # Application entry point
├── models/
│   ├── camera_capability.dart        # Camera capability data model
│   └── video_metadata.dart           # Video metadata model
├── providers/
│   └── camera_provider.dart          # State management for camera
├── screens/
│   ├── home_screen.dart              # Main screen with device info
│   ├── recording_screen.dart         # Recording interface
│   ├── gallery_screen.dart           # Video gallery and management
│   └── settings_screen.dart          # App configuration
├── services/
│   ├── camera_capability_service.dart    # Camera capability detection
│   ├── recording_service.dart            # Recording logic
│   ├── layout_service.dart               # Layout management
│   ├── settings_service.dart             # Persistent settings
│   ├── file_storage_service.dart         # File management
│   └── video_composition_service.dart    # FFmpeg video processing
├── theme/
│   ├── ocean_colors.dart             # Color palette
│   ├── ocean_theme.dart              # Material theme configuration
│   └── responsive.dart               # Responsive utilities
├── widgets/
│   ├── ocean_button.dart             # Custom button widget
│   ├── ocean_app_bar.dart            # Custom app bar
│   ├── glassmorphic_card.dart        # Glassmorphic container
│   └── recording_timer.dart          # Recording duration display
└── utils/
    ├── logger.dart                   # Application logging
    └── exceptions.dart               # Custom exception classes
```

## Getting Started

### Prerequisites
- Flutter 3.0+
- Dart 3.0+
- Android SDK (API 21+) / iOS SDK (13.0+)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd dual_recorder
   ```

2. **Get dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the application**
   ```bash
   flutter run
   ```

### Build Targets

**Android:**
```bash
flutter build apk      # Build APK
flutter build appbundle  # Build App Bundle for Play Store
```

**iOS:**
```bash
flutter build ios       # Build iOS app
flutter build ipa       # Build IPA for App Store
```

## Key Dependencies

- **camera**: ^0.10.5 - Camera access and control
- **video_player**: ^2.8.1 - Video playback functionality
- **ffmpeg_kit_flutter**: ^6.0.0 - Video composition and processing
- **provider**: ^6.1.0 - State management
- **get**: ^4.6.6 - Service locator and navigation
- **google_fonts**: ^6.1.0 - Custom typography
- **shared_preferences**: ^2.2.2 - Persistent local storage
- **path_provider**: ^2.1.1 - File system access
- **permission_handler**: ^12.0.1 - Permission management
- **logger**: ^2.0.2 - Structured logging

## Usage

### Basic Recording Flow

1. **Launch App**: Opens to HomeScreen showing device capabilities
2. **Start Recording**: Navigate to RecordingScreen and tap "Record"
3. **Control Recording**: Use Pause/Resume/Stop buttons as needed
4. **Save Video**: Upon stopping, video is automatically saved with metadata
5. **Manage Videos**: Access Gallery to view, share, or delete recordings

### Configuration

Access the Settings screen to customize:
- Video quality (480p, 720p, 1080p, 2160p)
- Recording layout (PiP or Split-Screen)
- PiP position (Top-left, Top-right, Bottom-left, Bottom-right)
- Audio recording enable/disable
- Frame rate (15-60 fps)

## Testing

The project includes comprehensive tests:

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/models_test.dart

# Run with coverage
flutter test --coverage
```

### Test Coverage

- **Unit Tests**: Models, exceptions, utilities
- **Widget Tests**: Custom UI components
- **Integration Tests**: End-to-end recording workflows

## Architecture

### State Management
- **Provider**: Camera capability and app state
- **GetX**: Recording service and layout management
- **SharedPreferences**: Persistent user settings

### Native Integration
- **Android (Kotlin)**: Method channels for Camera2 API
- **iOS (Swift)**: Method channels for AVFoundation

### Video Processing
- **FFmpeg**: Video composition, encoding, and optimization
- **Async Processing**: Non-blocking video operations with progress tracking

## Performance Considerations

1. **Memory Management**: Proper cleanup of camera controllers and video resources
2. **Battery Efficiency**: Optimized video quality and frame rates
3. **Storage**: Automatic cleanup of temporary files
4. **Concurrent Operations**: Async/await patterns for non-blocking operations

## Known Limitations

- Requires devices with multiple cameras for concurrent recording
- iOS multi-camera support limited to newer devices (iPhone XS+)
- FFmpeg processing requires sufficient disk space
- Audio sync between cameras depends on device hardware

## Future Enhancements

- [ ] Real-time video effects and filters
- [ ] Automatic cloud backup integration
- [ ] Advanced video editing capabilities
- [ ] Social media sharing integration
- [ ] Custom branding and watermarks
- [ ] Batch video processing
- [ ] Live streaming support

## Troubleshooting

### Camera Not Initializing
- Check device camera permissions
- Verify device supports dual camera recording
- Restart the application

### Recording Failures
- Ensure sufficient disk space
- Check camera and microphone permissions
- Verify device isn't in low-power mode

### Video Composition Errors
- Validate FFmpeg installation
- Check video file format compatibility
- Review system storage availability

## Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see LICENSE file for details.

## Support

For issues, feature requests, or questions, please open an issue on GitHub.

## Changelog

### v1.0.0 (Initial Release)
- Dual camera recording functionality
- PiP and split-screen layouts
- Video composition with FFmpeg
- Gallery and settings screens
- Ocean-themed UI design
- Comprehensive testing suite

## Acknowledgments

- Flutter team for the amazing framework
- FFmpeg project for video processing
- Material Design 3 specifications
- Community contributions and feedback

---

**Last Updated**: February 2026
**Status**: Active Development
