import 'package:flutter_test/flutter_test.dart';
import 'package:dual_recorder/models/camera_capability.dart';
import 'package:dual_recorder/utils/exceptions.dart';

void main() {
  group('CameraCapability Tests', () {
    test('CameraCapability should initialize with correct values', () {
      final capability = CameraCapability(
        supportsConcurrent: true,
        availableCameras: ['0', '1'],
        deviceModel: 'iPhone 13',
      );

      expect(capability.supportsConcurrent, true);
      expect(capability.availableCameras.length, 2);
      expect(capability.deviceModel, 'iPhone 13');
      expect(capability.detectedAt, isNotNull);
    });

    test('CameraCapability toString should be formatted correctly', () {
      final capability = CameraCapability(
        supportsConcurrent: true,
        availableCameras: ['0'],
        deviceModel: 'Pixel 6',
      );

      final toString = capability.toString();
      expect(toString, contains('supportsConcurrent'));
      expect(toString, contains('Pixel 6'));
    });

    test('CameraCapability with no concurrent support', () {
      final capability = CameraCapability(
        supportsConcurrent: false,
        availableCameras: [],
        deviceModel: 'Old Device',
      );

      expect(capability.supportsConcurrent, false);
      expect(capability.availableCameras.isEmpty, true);
    });
  });

  group('Exception Tests', () {
    test('DualRecorderException should have correct message and code', () {
      final exception = DualRecorderException(
        message: 'Test error',
        code: 'TEST_ERROR',
      );

      expect(exception.message, 'Test error');
      expect(exception.code, 'TEST_ERROR');
      expect(exception.toString(), contains('Test error'));
    });

    test('CameraOperationException should have correct code', () {
      final exception = CameraOperationException(
        message: 'Camera failed',
      );

      expect(exception.code, 'CAMERA_ERROR');
      expect(exception.message, 'Camera failed');
    });

    test('ConcurrentCameraNotSupportedException should have correct code', () {
      final exception = ConcurrentCameraNotSupportedException();

      expect(exception.code, 'CONCURRENT_CAMERA_NOT_SUPPORTED');
      expect(exception.message, contains('concurrent'));
    });

    test('RecordingException should have correct code', () {
      final exception = RecordingException(
        message: 'Recording failed',
      );

      expect(exception.code, 'RECORDING_ERROR');
    });

    test('PermissionException should have correct code', () {
      final exception = PermissionException(
        message: 'Permission denied',
      );

      expect(exception.code, 'PERMISSION_ERROR');
    });

    test('FileException should have correct code', () {
      final exception = FileException(
        message: 'File not found',
      );

      expect(exception.code, 'FILE_ERROR');
    });
  });
}
