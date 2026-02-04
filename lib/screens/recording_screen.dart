import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

import '../services/recording_service.dart';
import '../services/layout_service.dart';
import '../theme/ocean_colors.dart';
import '../utils/logger.dart';
import '../widgets/recording_timer.dart';

/// Screen for recording from dual cameras
class RecordingScreen extends StatefulWidget {
  const RecordingScreen({Key? key}) : super(key: key);

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  late RecordingService _recordingService;
  late LayoutService _layoutService;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      // Initialize recording service if not already initialized
      if (!Get.isRegistered<RecordingService>()) {
        Get.put(RecordingService());
      }
      _recordingService = Get.find<RecordingService>();

      if (!Get.isRegistered<LayoutService>()) {
        Get.put(LayoutService());
      }
      _layoutService = Get.find<LayoutService>();

      // Initialize cameras
      await _recordingService.initializeCameras();
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
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = '${directory.path}/recording_$timestamp.mp4';

      await _recordingService.startRecording(outputPath: outputPath);
      AppLogger.info('Recording started: $outputPath');
    } catch (e) {
      AppLogger.error('Failed to start recording', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start recording: $e')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      final videoFile = await _recordingService.stopRecording();
      AppLogger.info('Recording stopped: ${videoFile?.path}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Video saved: ${videoFile?.name}')),
        );
        Navigator.pop(context, videoFile?.path);
      }
    } catch (e) {
      AppLogger.error('Failed to stop recording', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to stop recording: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recording'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Camera preview area
          Expanded(
            child: _buildCameraPreview(),
          ),
          // Controls area
          _buildControlsArea(),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    return Container(
      color: OceanColors.deepSeaBlue,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam,
              size: 48,
              color: OceanColors.aquamarine,
            ),
            const SizedBox(height: 16),
            Text(
              'Camera Preview (Native Integration Coming Soon)',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: OceanColors.aquamarine,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Obx(() {
              if (_recordingService.isRecording) {
                return RecordingTimer(
                  duration: _recordingService.recordingDuration,
                  isRecording: true,
                );
              }
              return const SizedBox();
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsArea() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: OceanColors.pearlWhite,
        boxShadow: [
          BoxShadow(
            color: OceanColors.deepSeaBlue.withAlpha((0.1 * 255).toInt()),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Recording status
          Obx(
            () => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Status:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  _recordingService.isRecording
                      ? (_recordingService.isPaused ? 'PAUSED' : 'RECORDING')
                      : 'STOPPED',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _recordingService.isRecording
                        ? OceanColors.error
                        : OceanColors.mediumGray,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Start/Stop Record button
              Obx(
                () => FloatingActionButton.extended(
                  onPressed: _recordingService.isRecording
                      ? null
                      : _startRecording,
                  backgroundColor: _recordingService.isRecording
                      ? OceanColors.mediumGray
                      : OceanColors.success,
                  icon: const Icon(Icons.fiber_manual_record),
                  label: const Text('Record'),
                ),
              ),
              // Pause/Resume button
              Obx(
                () => FloatingActionButton.extended(
                  onPressed: !_recordingService.isRecording
                      ? null
                      : (_recordingService.isPaused
                      ? () async {
                    try {
                      await _recordingService.resumeRecording();
                    } catch (e) {
                      AppLogger.error('Failed to resume', error: e);
                    }
                  }
                      : () async {
                    try {
                      await _recordingService.pauseRecording();
                    } catch (e) {
                      AppLogger.error('Failed to pause', error: e);
                    }
                  }),
                  backgroundColor: !_recordingService.isRecording
                      ? OceanColors.mediumGray
                      : (_recordingService.isPaused
                      ? OceanColors.success
                      : OceanColors.warning),
                  icon: Icon(
                    _recordingService.isPaused
                        ? Icons.play_arrow
                        : Icons.pause,
                  ),
                  label: Text(
                    _recordingService.isPaused ? 'Resume' : 'Pause',
                  ),
                ),
              ),
              // Stop button
              Obx(
                () => FloatingActionButton.extended(
                  onPressed: !_recordingService.isRecording
                      ? null
                      : _stopRecording,
                  backgroundColor: !_recordingService.isRecording
                      ? OceanColors.mediumGray
                      : OceanColors.error,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
