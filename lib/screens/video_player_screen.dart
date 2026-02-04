import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../theme/ocean_colors.dart';

/// Screen for playing recorded videos
class VideoPlayerScreen extends StatefulWidget {
  final File videoFile;

  const VideoPlayerScreen({
    super.key,
    required this.videoFile,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _videoPlayerController;
  late Future<void> _initializeVideoPlayerFuture;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _videoPlayerController = VideoPlayerController.file(widget.videoFile);
    _initializeVideoPlayerFuture = _videoPlayerController.initialize();

    _videoPlayerController.addListener(() {
      setState(() {
        _isPlaying = _videoPlayerController.value.isPlaying;
      });
    });
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return [if (duration.inHours > 0) hours, minutes, seconds].join(':');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.videoFile.path.split('/').last),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: OceanColors.deepSeaBlue,
      body: FutureBuilder<void>(
        future: _initializeVideoPlayerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Column(
              children: [
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: _videoPlayerController.value.aspectRatio,
                      child: VideoPlayer(_videoPlayerController),
                    ),
                  ),
                ),
                _buildPlayerControls(),
              ],
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error,
                    color: OceanColors.error,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load video: ${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }

  Widget _buildPlayerControls() {
    return Container(
      color: OceanColors.deepSeaBlue,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar
          VideoProgressIndicator(
            _videoPlayerController,
            allowScrubbing: true,
            colors: VideoProgressColors(
              playedColor: OceanColors.accentTeal,
              bufferedColor: OceanColors.accentTeal.withAlpha((0.3 * 255).toInt()),
              backgroundColor: OceanColors.mediumGray.withAlpha((0.3 * 255).toInt()),
            ),
          ),
          const SizedBox(height: 12),
          // Time display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(_videoPlayerController.value.position),
                style: const TextStyle(
                  color: OceanColors.pearlWhite,
                  fontSize: 12,
                ),
              ),
              Text(
                _formatDuration(_videoPlayerController.value.duration),
                style: const TextStyle(
                  color: OceanColors.pearlWhite,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Rewind button
              IconButton(
                icon: const Icon(Icons.replay_10),
                color: OceanColors.pearlWhite,
                onPressed: () {
                  final currentPosition = _videoPlayerController.value.position;
                  final newPosition = currentPosition - const Duration(seconds: 10);
                  _videoPlayerController.seekTo(
                    newPosition.isNegative ? Duration.zero : newPosition,
                  );
                },
              ),
              const SizedBox(width: 24),
              // Play/Pause button
              FloatingActionButton(
                onPressed: () {
                  if (_isPlaying) {
                    _videoPlayerController.pause();
                  } else {
                    _videoPlayerController.play();
                  }
                  setState(() {
                    _isPlaying = !_isPlaying;
                  });
                },
                backgroundColor: OceanColors.accentTeal,
                child: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                ),
              ),
              const SizedBox(width: 24),
              // Forward button
              IconButton(
                icon: const Icon(Icons.forward_10),
                color: OceanColors.pearlWhite,
                onPressed: () {
                  final currentPosition = _videoPlayerController.value.position;
                  final duration = _videoPlayerController.value.duration;
                  final newPosition = currentPosition + const Duration(seconds: 10);
                  _videoPlayerController.seekTo(
                    newPosition > duration ? duration : newPosition,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
