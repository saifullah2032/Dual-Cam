import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/video_metadata.dart';
import '../utils/logger.dart';
import '../utils/exceptions.dart';

/// Service for managing file storage and metadata
class FileStorageService {
  static const String _metadataDir = 'video_metadata';
  static const String _recordingsDir = 'recordings';
  static const String _tempDir = 'temp';

  /// Get recordings directory
  static Future<Directory> getRecordingsDirectory() async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final recordingsDir = Directory('${appDocDir.path}/$_recordingsDir');

      if (!await recordingsDir.exists()) {
        await recordingsDir.create(recursive: true);
        AppLogger.info('Recordings directory created: ${recordingsDir.path}');
      }

      return recordingsDir;
    } catch (e) {
      AppLogger.error('Failed to get recordings directory', error: e);
      throw FileException(
        message: 'Failed to get recordings directory',
        originalException: e,
      );
    }
  }

  /// Get metadata directory
  static Future<Directory> getMetadataDirectory() async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final metadataDir = Directory('${appDocDir.path}/$_metadataDir');

      if (!await metadataDir.exists()) {
        await metadataDir.create(recursive: true);
        AppLogger.info('Metadata directory created: ${metadataDir.path}');
      }

      return metadataDir;
    } catch (e) {
      AppLogger.error('Failed to get metadata directory', error: e);
      throw FileException(
        message: 'Failed to get metadata directory',
        originalException: e,
      );
    }
  }

  /// Get temporary directory for video processing
  static Future<Directory> getTempDirectory() async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final tempDir = Directory('${appDocDir.path}/$_tempDir');

      if (!await tempDir.exists()) {
        await tempDir.create(recursive: true);
        AppLogger.info('Temp directory created: ${tempDir.path}');
      }

      return tempDir;
    } catch (e) {
      AppLogger.error('Failed to get temp directory', error: e);
      throw FileException(
        message: 'Failed to get temp directory',
        originalException: e,
      );
    }
  }

  /// Generate a unique filename for recording
  static String generateFilename({String prefix = 'video'}) {
    final now = DateTime.now();
    final formatter = DateFormat('yyyy-MM-dd_HH-mm-ss');
    final timestamp = formatter.format(now);
    return '${prefix}_$timestamp.mp4';
  }

  /// Get full path for a new recording
  static Future<String> getRecordingPath({String prefix = 'video'}) async {
    try {
      final recordingsDir = await getRecordingsDirectory();
      final filename = generateFilename(prefix: prefix);
      return '${recordingsDir.path}/$filename';
    } catch (e) {
      AppLogger.error('Failed to get recording path', error: e);
      rethrow;
    }
  }

  /// Save video metadata
  static Future<void> saveMetadata(VideoMetadata metadata) async {
    try {
      final metadataDir = await getMetadataDirectory();
      final filename = '${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${metadataDir.path}/$filename');

      final json = metadata.toJson();
      await file.writeAsString(json.toString());

      AppLogger.info('Metadata saved: ${file.path}');
    } catch (e) {
      AppLogger.error('Failed to save metadata', error: e);
      throw FileException(
        message: 'Failed to save metadata',
        originalException: e,
      );
    }
  }

  /// Delete a recording file
  static Future<void> deleteRecording(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        AppLogger.info('Recording deleted: $filePath');
      }
    } catch (e) {
      AppLogger.error('Failed to delete recording', error: e);
      throw FileException(
        message: 'Failed to delete recording',
        originalException: e,
      );
    }
  }

  /// Get file size in MB
  static Future<double> getFileSizeInMB(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final bytes = await file.length();
        return bytes / (1024 * 1024); // Convert to MB
      }
      return 0;
    } catch (e) {
      AppLogger.error('Failed to get file size', error: e);
      return 0;
    }
  }

  /// List all recordings
  static Future<List<File>> getRecordings() async {
    try {
      final recordingsDir = await getRecordingsDirectory();
      final files = recordingsDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.mp4'))
          .toList();

      // Sort by modified time (newest first)
      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

      return files;
    } catch (e) {
      AppLogger.error('Failed to list recordings', error: e);
      return [];
    }
  }

  /// Clean up temporary files
  static Future<void> cleanupTempDirectory() async {
    try {
      final tempDir = await getTempDirectory();
      if (await tempDir.exists()) {
        final files = tempDir.listSync();
        for (var file in files) {
          if (file is File) {
            await file.delete();
          }
        }
        AppLogger.info('Temp directory cleaned');
      }
    } catch (e) {
      AppLogger.error('Failed to clean temp directory', error: e);
    }
  }

  /// Get available storage space in MB
  static Future<double> getAvailableStorage() async {
    try {
      // This is a simplified implementation
      // In production, you might use a package like disk_space
      return 0; // Placeholder
    } catch (e) {
      AppLogger.error('Failed to get available storage', error: e);
      return 0;
    }
  }
}
