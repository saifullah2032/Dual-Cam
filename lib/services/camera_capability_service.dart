import 'package:flutter/services.dart';
import '../models/camera_capability.dart';
import '../utils/logger.dart';

/// Service for checking camera capabilities via native method channels
class CameraCapabilityService {
  static const platform = MethodChannel('com.example.dual_recorder/camera_capability');

  /// Check if device supports concurrent camera recording
  static Future<bool> hasConcurrentCameraSupport() async {
    try {
      final bool result = await platform.invokeMethod('hasConcurrentCameraSupport');
      AppLogger.info('Concurrent camera support: $result');
      return result;
    } on PlatformException catch (e) {
      AppLogger.warning('Failed to check concurrent camera support: ${e.message}');
      return false;
    } catch (e) {
      AppLogger.warning('Error checking concurrent camera support: $e');
      return false;
    }
  }

  /// Get list of available camera IDs
  static Future<List<String>> getCameraIds() async {
    try {
      final List<dynamic> result = await platform.invokeMethod('getCameraIds');
      final cameraIds = result.cast<String>();
      AppLogger.info('Camera IDs: $cameraIds');
      return cameraIds;
    } on PlatformException catch (e) {
      AppLogger.warning('Failed to get camera IDs: ${e.message}');
      return [];
    } catch (e) {
      AppLogger.warning('Error getting camera IDs: $e');
      return [];
    }
  }

  /// Get device model name
  static Future<String> getDeviceModel() async {
    try {
      final String result = await platform.invokeMethod('getDeviceModel');
      AppLogger.info('Device model: $result');
      return result;
    } on PlatformException catch (e) {
      AppLogger.warning('Failed to get device model: ${e.message}');
      return 'Unknown';
    } catch (e) {
      AppLogger.warning('Error getting device model: $e');
      return 'Unknown';
    }
  }

  /// Get detailed camera information
  static Future<Map<String, dynamic>> getCameraInfo() async {
    try {
      final result = await platform.invokeMethod('getCameraInfo');
      if (result is Map) {
        return Map<String, dynamic>.from(result);
      }
      return {};
    } catch (e) {
      AppLogger.warning('Error getting camera info: $e');
      return {};
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

      AppLogger.info('Camera capability: supportsConcurrent=$supportsConcurrent, cameras=${cameraIds.length}');
      return capability;
    } catch (e) {
      AppLogger.error('Failed to get camera capability', error: e);
      // Return default capability on error
      return CameraCapability(
        supportsConcurrent: false,
        availableCameras: [],
        deviceModel: 'Unknown',
      );
    }
  }
}
