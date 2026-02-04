import 'package:flutter/material.dart';
import '../theme/ocean_colors.dart';

/// Widget to display recording duration
class RecordingTimer extends StatelessWidget {
  final Duration duration;
  final bool isRecording;
  final Color color;

  const RecordingTimer({
    Key? key,
    required this.duration,
    this.isRecording = true,
    this.color = OceanColors.error,
  }) : super(key: key);

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isRecording) ...[
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: OceanColors.error,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Text(
          _formatDuration(duration),
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: color,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}
