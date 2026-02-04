import 'dart:async';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import '../utils/logger.dart';
import '../utils/exceptions.dart';

/// Service for handling video processing and composition
class VideoCompositionService {
  /// Compose two videos side by side (split screen)
  static Future<String> composeSplitScreen({
    required String frontVideoPath,
    required String backVideoPath,
    required String outputPath,
    String resolution = '1920x1080',
  }) async {
    try {
      AppLogger.info('Starting split-screen composition...');

      // FFmpeg command for side-by-side video composition
      final command = '-i $frontVideoPath -i $backVideoPath '
          '-filter_complex "[0:v]scale=960:1080[v0];[1:v]scale=960:1080[v1];[v0][v1]hstack=inputs=2[v]" '
          '-map "[v]" -map 0:a -shortest '
          '-c:v libx264 -preset medium -crf 23 '
          '-c:a aac -b:a 128k '
          '$outputPath';

      AppLogger.info('FFmpeg command: ffmpeg $command');

      final session = await FFmpegKit.executeAsync(command, (dynamic log) {
        AppLogger.info('FFmpeg: ${log.message}');
      });

      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        AppLogger.info('Split-screen composition completed: $outputPath');
        return outputPath;
      } else {
        final failStackTrace = await session.getFailStackTrace();
        throw Exception('FFmpeg composition failed: $failStackTrace');
      }
    } catch (e) {
      AppLogger.error('Failed to compose split-screen video', error: e);
      throw Exception('Video composition failed: $e');
    }
  }

  /// Compose videos with Picture-in-Picture layout
  static Future<String> composePiP({
    required String mainVideoPath,
    required String pipVideoPath,
    required String outputPath,
    String mainResolution = '1920x1080',
    String pipSize = '320x240',
    String pipPosition = 'bottom_right',
  }) async {
    try {
      AppLogger.info('Starting PiP composition...');

      // Parse position
      String positionFilter;
      switch (pipPosition) {
        case 'top_left':
          positionFilter = 'overlay=10:10';
        case 'top_right':
          positionFilter = 'overlay=W-w-10:10';
        case 'bottom_left':
          positionFilter = 'overlay=10:H-h-10';
        case 'bottom_right':
        default:
          positionFilter = 'overlay=W-w-10:H-h-10';
      }

      // FFmpeg command for PiP composition
      final command = '-i $mainVideoPath -i $pipVideoPath '
          '-filter_complex "[1:v]scale=$pipSize[pip];[0:v][pip]$positionFilter[v]" '
          '-map "[v]" -map 0:a '
          '-c:v libx264 -preset medium -crf 23 '
          '-c:a aac -b:a 128k '
          '-shortest '
          '$outputPath';

      AppLogger.info('FFmpeg command: ffmpeg $command');

      final session = await FFmpegKit.executeAsync(command, (dynamic log) {
        AppLogger.info('FFmpeg: ${log.message}');
      });

      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        AppLogger.info('PiP composition completed: $outputPath');
        return outputPath;
      } else {
        final failStackTrace = await session.getFailStackTrace();
        throw Exception('FFmpeg composition failed: $failStackTrace');
      }
    } catch (e) {
      AppLogger.error('Failed to compose PiP video', error: e);
      throw Exception('Video composition failed: $e');
    }
  }

  /// Get video information (duration, bitrate, resolution)
  static Future<Map<String, dynamic>> getVideoInfo(String videoPath) async {
    try {
      AppLogger.info('Getting video info for: $videoPath');

      final session = await FFmpegKit.executeAsync(
        '-i $videoPath',
        (dynamic log) {
          AppLogger.debug('FFprobe: ${log.message}');
        },
      );

      final output = await session.getOutput();
      AppLogger.info('Video info retrieved');

      // Parse output to extract metadata
      return {
        'path': videoPath,
        'output': output,
      };
    } catch (e) {
      AppLogger.error('Failed to get video info', error: e);
      return {'error': e.toString()};
    }
  }

  /// Optimize video for sharing (compress while maintaining quality)
  static Future<String> optimizeVideo({
    required String inputPath,
    required String outputPath,
    String preset = 'medium', // fast, medium, slow
    int bitrate = 2500, // kbps
  }) async {
    try {
      AppLogger.info('Optimizing video: $inputPath');

      final command = '-i $inputPath '
          '-c:v libx264 -preset $preset '
          '-b:v ${bitrate}k '
          '-c:a aac -b:a 128k '
          '-shortest '
          '$outputPath';

      AppLogger.info('FFmpeg command: ffmpeg $command');

      final session = await FFmpegKit.executeAsync(command, (dynamic log) {
        AppLogger.info('FFmpeg: ${log.message}');
      });

      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        AppLogger.info('Video optimization completed: $outputPath');
        return outputPath;
      } else {
        final failStackTrace = await session.getFailStackTrace();
        throw Exception('FFmpeg optimization failed: $failStackTrace');
      }
    } catch (e) {
      AppLogger.error('Failed to optimize video', error: e);
      throw Exception('Video optimization failed: $e');
    }
  }

  /// Cancel ongoing FFmpeg operation
  static Future<void> cancelProcessing() async {
    try {
      await FFmpegKit.cancel();
      AppLogger.info('FFmpeg processing cancelled');
    } catch (e) {
      AppLogger.error('Failed to cancel FFmpeg processing', error: e);
    }
  }
}
