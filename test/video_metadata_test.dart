import 'package:flutter_test/flutter_test.dart';
import 'package:dual_recorder/models/video_metadata.dart';

void main() {
  group('VideoMetadata Tests', () {
    test('VideoMetadata should initialize with correct values', () {
      final now = DateTime.now();
      final metadata = VideoMetadata(
        filePath: '/path/to/video.mp4',
        duration: const Duration(seconds: 60),
        resolution: '1920x1080',
        bitrate: 5000,
        layout: 'pip',
        recordingDate: now,
        fileSize: 1024000,
      );

      expect(metadata.filePath, '/path/to/video.mp4');
      expect(metadata.duration.inSeconds, 60);
      expect(metadata.resolution, '1920x1080');
      expect(metadata.bitrate, 5000);
      expect(metadata.layout, 'pip');
      expect(metadata.recordingDate, now);
      expect(metadata.fileSize, 1024000);
    });

    test('VideoMetadata toJson should serialize correctly', () {
      final metadata = VideoMetadata(
        filePath: '/path/to/video.mp4',
        duration: const Duration(seconds: 30),
        resolution: '1280x720',
        bitrate: 3000,
        layout: 'split_screen',
        recordingDate: DateTime(2024, 1, 1, 12, 0, 0),
        fileSize: 512000,
      );

      final json = metadata.toJson();

      expect(json['filePath'], '/path/to/video.mp4');
      expect(json['duration'], 30000); // milliseconds
      expect(json['resolution'], '1280x720');
      expect(json['bitrate'], 3000);
      expect(json['layout'], 'split_screen');
      expect(json['fileSize'], 512000);
      expect(json['recordingDate'], isNotNull);
    });

    test('VideoMetadata fromJson should deserialize correctly', () {
      final jsonData = {
        'filePath': '/path/to/video.mp4',
        'duration': 45000,
        'resolution': '1920x1080',
        'bitrate': 5000,
        'layout': 'pip',
        'recordingDate': '2024-01-01T12:00:00.000Z',
        'fileSize': 2048000,
      };

      final metadata = VideoMetadata.fromJson(jsonData);

      expect(metadata.filePath, '/path/to/video.mp4');
      expect(metadata.duration.inSeconds, 45);
      expect(metadata.resolution, '1920x1080');
      expect(metadata.bitrate, 5000);
      expect(metadata.layout, 'pip');
      expect(metadata.fileSize, 2048000);
    });

    test('VideoMetadata toString should format correctly', () {
      final metadata = VideoMetadata(
        filePath: '/recordings/video.mp4',
        duration: const Duration(minutes: 2),
        resolution: '1920x1080',
        bitrate: 5000,
        layout: 'pip',
        recordingDate: DateTime.now(),
        fileSize: 10000000,
      );

      final toString = metadata.toString();
      expect(toString, contains('video.mp4'));
      expect(toString, contains('0:02:00')); // duration format
      expect(toString, contains('1920x1080'));
    });

    test('VideoMetadata serialization round-trip should be lossless', () {
      final original = VideoMetadata(
        filePath: '/path/to/video.mp4',
        duration: const Duration(seconds: 90),
        resolution: '2560x1440',
        bitrate: 8000,
        layout: 'split_screen',
        recordingDate: DateTime(2024, 6, 15, 14, 30, 45),
        fileSize: 5242880,
      );

      final json = original.toJson();
      final deserialized = VideoMetadata.fromJson(json);

      expect(deserialized.filePath, original.filePath);
      expect(deserialized.duration, original.duration);
      expect(deserialized.resolution, original.resolution);
      expect(deserialized.bitrate, original.bitrate);
      expect(deserialized.layout, original.layout);
      expect(deserialized.fileSize, original.fileSize);
    });
  });
}
