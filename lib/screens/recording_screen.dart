import 'package:flutter/material.dart';

import '../theme/ocean_colors.dart';

/// Screen for recording from dual cameras
class RecordingScreen extends StatefulWidget {
  const RecordingScreen({Key? key}) : super(key: key);

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  bool _isRecording = false;

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
            child: Container(
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
                      'Camera Preview (Coming Soon)',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: OceanColors.aquamarine,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Controls area
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Recording timer and info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recording Status:',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      _isRecording ? 'RECORDING' : 'PAUSED',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _isRecording
                            ? OceanColors.error
                            : OceanColors.warning,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Control buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Record/Pause button
                    FloatingActionButton(
                      onPressed: () {
                        setState(() => _isRecording = !_isRecording);
                      },
                      backgroundColor: _isRecording
                          ? OceanColors.warning
                          : OceanColors.success,
                      child: Icon(
                        _isRecording ? Icons.pause : Icons.play_arrow,
                      ),
                    ),
                    // Stop button
                    FloatingActionButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      backgroundColor: OceanColors.error,
                      child: const Icon(Icons.stop),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
