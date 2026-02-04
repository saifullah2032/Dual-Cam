import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import '../models/camera_capability.dart';

/// Service for checking camera capabilities via native method channels
class CameraCapabilityService {
  static const platform = MethodChannel('com.example.dual_recorder/camera_capability');
  static final logger = Logger();

  /// Check if device supports concurrent camera recording
  static Future<bool> hasConcurrentCameraSupport() async {
    try {
      final bool result = await platform.invokeMethod('hasConcurrentCameraSupport');
      logger.i('Concurrent camera support: $result');
      return result;
    } on PlatformException catch (e) {
      logger.e('Failed to check concurrent camera support: ${e.message}');
      return false;
    }
  }

  /// Get list of available camera IDs
  static Future<List<String>> getCameraIds() async {
    try {
      final List<dynamic> result = await platform.invokeMethod('getCameraIds');
      final cameraIds = result.cast<String>();
      logger.i('Camera IDs: $cameraIds');
      return cameraIds;
    } on PlatformException catch (e) {
      logger.e('Failed to get camera IDs: ${e.message}');
      return [];
    }
  }

  /// Get device model name
  static Future<String> getDeviceModel() async {
    try {
      final String result = await platform.invokeMethod('getDeviceModel');
      logger.i('Device model: $result');
      return result;
    } on PlatformException catch (e) {
      logger.e('Failed to get device model: ${e.message}');
      return 'Unknown';
    }
  }

  /// Get complete camera capability information
  static Future<CameraCapability> getCameraCapability() async {
    try {
      final supportsConcurrent = await hasConcurrentCameraSupport();
      final cameraIds = await getCameraIds();
      final deviceModel = await getDeviceModel();

      final capability = CameraCapability(
        supportsConcurrent: supportsConcurrent,
        availableCameras: cameraIds,
        deviceModel: deviceModel,
      );

      logger.i('Camera capability: $capability');
      return capability;
    } catch (e) {
      logger.e('Failed to get camera capability: $e');
      rethrow;
    }
  }
}
