import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';

import '../services/recording_service.dart';
import '../services/file_storage_service.dart';
import '../theme/ocean_colors.dart';
import '../utils/logger.dart';
import '../widgets/recording_timer.dart';
import '../widgets/camera_preview_widget.dart';
import '../widgets/ocean_app_bar.dart';
import 'gallery_screen.dart';

/// Screen for recording from dual cameras
class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen>
    with TickerProviderStateMixin {
  late RecordingService _recordingService;
  late AnimationController _pulseController;
  late AnimationController _slideController;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // Pulse animation for recording indicator
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();

    // Slide animation for control buttons
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideController.forward();
  }

  Future<void> _initializeServices() async {
    try {
      if (!Get.isRegistered<RecordingService>()) {
        Get.put(RecordingService());
      }
      _recordingService = Get.find<RecordingService>();

      // Initialize cameras - use ResolutionPreset.medium to avoid bandwidth issues on dual capture
      await _recordingService.initializeCameras(resolution: ResolutionPreset.medium);
    } catch (e) {
      AppLogger.error('Failed to initialize recording services', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize cameras: $e')),
        );
      }
    }
  }

  Future<void> _startRecording() async {
    try {
      // First ensure no recording is in progress
      if (_recordingService.isRecording) {
        AppLogger.warning('Recording is already in progress');
        return;
      }

      // Get the recordings directory
      final recordingsDir = await FileStorageService.getRecordingsDirectory();
      
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'recording_$timestamp.mp4';
      final outputPath = '${recordingsDir.path}/$filename';

      AppLogger.info('Starting recording to: $outputPath');
      await _recordingService.startRecording(outputPath: outputPath);
      AppLogger.info('Recording started successfully');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎥 Recording started'),
            duration: Duration(seconds: 2),
            backgroundColor: OceanColors.success,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Failed to start recording', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start recording: $e'),
            duration: const Duration(seconds: 3),
            backgroundColor: OceanColors.error,
          ),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      AppLogger.info('Stopping recording...');
      final videoFile = await _recordingService.stopRecording();
      
      if (videoFile != null) {
        AppLogger.info('Video file saved: ${videoFile.path}');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Video saved: ${videoFile.name}'),
              duration: const Duration(seconds: 3),
              backgroundColor: OceanColors.success,
              action: SnackBarAction(
                label: 'Gallery',
                textColor: Colors.white,
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
          );
        }
      } else {
        AppLogger.warning('Video file is null');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save video'),
              duration: Duration(seconds: 3),
              backgroundColor: OceanColors.error,
            ),
          );
        }
      }
    } catch (e) {
      AppLogger.error('Failed to stop recording', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to stop recording: $e'),
            duration: const Duration(seconds: 3),
            backgroundColor: OceanColors.error,
          ),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final recordingsDir = await FileStorageService.getRecordingsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      final pictures = await _recordingService.takePicture();
      
      for (var i = 0; i < pictures.length; i++) {
        final prefix = i == 0 ? 'back' : 'front';
        final filename = 'photo_${prefix}_$timestamp.jpg';
        final outputPath = '${recordingsDir.path}/$filename';
        await pictures[i].saveTo(outputPath);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📸 ${pictures.length} Photo(s) captured'),
            duration: const Duration(seconds: 2),
            backgroundColor: OceanColors.success,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Failed to take photo', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to take photo: $e'),
            backgroundColor: OceanColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: OceanAppBar(
        title: 'Dual Camera',
        onBackPressed: () => Navigator.pop(context),
        showGradient: false, // Let the background show through
      ),
      body: Container(
        color: OceanColors.deepSeaBlue,
        child: Column(
          children: [
            // Camera preview area
            Expanded(
              child: _buildCameraPreview(),
            ),
            // Controls area
            _buildControlsArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    return Container(
      color: OceanColors.deepSeaBlue,
      child: Obx(() {
        final isInitialized = _recordingService.isInitialized;
        final frontCamera = _recordingService.frontCamera;
        final backCamera = _recordingService.backCamera;

        if (!isInitialized || (frontCamera == null && backCamera == null)) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 1500),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 0.5 + (value * 0.5),
                      child: Opacity(
                        opacity: value,
                        child: child,
                      ),
                    );
                  },
                  child: Icon(
                    Icons.videocam,
                    size: 64,
                    color: OceanColors.aquamarine,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Initializing Cameras...',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: OceanColors.aquamarine,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: 200,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      minHeight: 4,
                      backgroundColor: OceanColors.deepSeaBlue,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        OceanColors.aquamarine.withAlpha((0.6 * 255).toInt()),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // Display dual camera preview in split-screen layout
        return Stack(
          children: [
            Row(
              children: [
                // Front camera (if available)
                if (frontCamera != null)
                  Expanded(
                    child: Stack(
                      children: [
                        CameraPreviewWidget(
                          controller: frontCamera,
                          onError: (e) {
                            AppLogger.error('Front camera error', error: e);
                          },
                        ),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: OceanColors.deepSeaBlue.withAlpha(
                                (0.7 * 255).toInt(),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'FRONT',
                              style: TextStyle(
                                color: OceanColors.aquamarine,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Expanded(
                    child: Container(
                      color: OceanColors.deepSeaBlue,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.videocam_off,
                              size: 40,
                              color: OceanColors.mediumGray,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Front Camera\nNot Available',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: OceanColors.mediumGray,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                // Back camera
                if (backCamera != null)
                  Expanded(
                    child: Stack(
                      children: [
                        CameraPreviewWidget(
                          controller: backCamera,
                          onError: (e) {
                            AppLogger.error('Back camera error', error: e);
                          },
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: OceanColors.deepSeaBlue.withAlpha(
                                (0.7 * 255).toInt(),
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'BACK',
                              style: TextStyle(
                                color: OceanColors.aquamarine,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            // Recording timer overlay
            Obx(
              () => _recordingService.isRecording
                  ? Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: OceanColors.error,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: OceanColors.error.withAlpha((0.3 * 255).toInt()),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ScaleTransition(
                              scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                                CurvedAnimation(
                                  parent: _pulseController,
                                  curve: Curves.easeInOut,
                                ),
                              ),
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: OceanColors.pearlWhite,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            RecordingTimer(
                              duration: _recordingService.recordingDuration,
                              isRecording: true,
                            ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildControlsArea() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
        decoration: BoxDecoration(
          color: OceanColors.deepSeaBlue,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status Indicator
            Obx(() => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _recordingService.isRecording ? OceanColors.error.withOpacity(0.1) : Colors.white10,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_recordingService.isRecording && !_recordingService.isPaused)
                    ScaleTransition(
                      scale: Tween<double>(begin: 1, end: 1.2).animate(
                        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
                      ),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(color: OceanColors.error, shape: BoxShape.circle),
                      ),
                    ),
                  if (_recordingService.isRecording && !_recordingService.isPaused) const SizedBox(width: 8),
                  Text(
                    _recordingService.isRecording
                        ? (_recordingService.isPaused ? 'PAUSED' : 'RECORDING')
                        : 'READY',
                    style: TextStyle(
                      color: _recordingService.isRecording ? OceanColors.error : Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 32),
            // Control buttons
            Obx(
              () => Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Photo button (only if not recording)
                  _buildControlButton(
                    onPressed: _recordingService.isRecording ? null : _takePhoto,
                    icon: Icons.camera_alt,
                    label: 'PHOTO',
                    color: _recordingService.isRecording ? Colors.white24 : OceanColors.aquamarine,
                  ),
                  
                  // Start/Stop Record button
                  _buildMainActionButton(),

                  // Pause/Resume/Gallery button
                  if (_recordingService.isRecording)
                    _buildControlButton(
                      onPressed: _recordingService.isPaused 
                          ? () => _recordingService.resumeRecording() 
                          : () => _recordingService.pauseRecording(),
                      icon: _recordingService.isPaused ? Icons.play_arrow : Icons.pause,
                      label: _recordingService.isPaused ? 'RESUME' : 'PAUSE',
                      color: OceanColors.warning,
                    )
                  else
                    _buildControlButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const GalleryScreen()),
                        );
                      },
                      icon: Icons.photo_library,
                      label: 'GALLERY',
                      color: OceanColors.pearlWhite,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(30),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.5), width: 2),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildMainActionButton() {
    final isRecording = _recordingService.isRecording;
    return GestureDetector(
      onTap: isRecording ? _stopRecording : _startRecording,
      child: Container(
        width: 80,
        height: 80,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isRecording ? OceanColors.error : OceanColors.success,
          ),
          child: Icon(
            isRecording ? Icons.stop : Icons.fiber_manual_record,
            color: Colors.white,
            size: 40,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }
}
