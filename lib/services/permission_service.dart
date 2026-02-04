import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';
import '../utils/logger.dart';
import '../utils/exceptions.dart';

/// Service for managing app permissions
class PermissionService extends GetxService {
  /// Check and request camera permission
  static Future<bool> requestCameraPermission() async {
    try {
      AppLogger.info('Requesting camera permission...');
      final status = await Permission.camera.request();
      
      if (status.isGranted) {
        AppLogger.info('Camera permission granted');
        return true;
      } else if (status.isDenied) {
        AppLogger.warning('Camera permission denied');
        return false;
      } else if (status.isPermanentlyDenied) {
        AppLogger.error('Camera permission permanently denied');
        openAppSettings();
        return false;
      }
      return false;
    } catch (e) {
      AppLogger.error('Failed to request camera permission', error: e);
      throw PermissionException(
        message: 'Failed to request camera permission',
        originalException: e,
      );
    }
  }

  /// Check and request microphone permission
  static Future<bool> requestMicrophonePermission() async {
    try {
      AppLogger.info('Requesting microphone permission...');
      final status = await Permission.microphone.request();
      
      if (status.isGranted) {
        AppLogger.info('Microphone permission granted');
        return true;
      } else if (status.isDenied) {
        AppLogger.warning('Microphone permission denied');
        return false;
      } else if (status.isPermanentlyDenied) {
        AppLogger.error('Microphone permission permanently denied');
        openAppSettings();
        return false;
      }
      return false;
    } catch (e) {
      AppLogger.error('Failed to request microphone permission', error: e);
      throw PermissionException(
        message: 'Failed to request microphone permission',
        originalException: e,
      );
    }
  }

  /// Check and request storage permission
  static Future<bool> requestStoragePermission() async {
    try {
      AppLogger.info('Requesting storage permission...');
      final status = await Permission.storage.request();
      
      if (status.isGranted) {
        AppLogger.info('Storage permission granted');
        return true;
      } else if (status.isDenied) {
        AppLogger.warning('Storage permission denied');
        return false;
      } else if (status.isPermanentlyDenied) {
        AppLogger.error('Storage permission permanently denied');
        openAppSettings();
        return false;
      }
      return false;
    } catch (e) {
      AppLogger.error('Failed to request storage permission', error: e);
      throw PermissionException(
        message: 'Failed to request storage permission',
        originalException: e,
      );
    }
  }

  /// Request all necessary permissions for recording
  static Future<bool> requestAllRecordingPermissions() async {
    try {
      AppLogger.info('Requesting all recording permissions...');
      
      final cameraGranted = await requestCameraPermission();
      if (!cameraGranted) {
        AppLogger.error('Camera permission required for recording');
        return false;
      }

      final micGranted = await requestMicrophonePermission();
      if (!micGranted) {
        AppLogger.warning('Microphone permission not granted');
        // Continue anyway - recording can work without audio
      }

      final storageGranted = await requestStoragePermission();
      if (!storageGranted) {
        AppLogger.error('Storage permission required for saving videos');
        return false;
      }

      AppLogger.info('All recording permissions granted');
      return true;
    } catch (e) {
      AppLogger.error('Failed to request recording permissions', error: e);
      return false;
    }
  }

  /// Check if permission is granted
  static Future<bool> isPermissionGranted(Permission permission) async {
    try {
      final status = await permission.status;
      return status.isGranted;
    } catch (e) {
      AppLogger.error('Failed to check permission status', error: e);
      return false;
    }
  }

  /// Check camera permission status
  static Future<bool> isCameraPermissionGranted() async {
    return isPermissionGranted(Permission.camera);
  }

  /// Check microphone permission status
  static Future<bool> isMicrophonePermissionGranted() async {
    return isPermissionGranted(Permission.microphone);
  }

  /// Check storage permission status
  static Future<bool> isStoragePermissionGranted() async {
    return isPermissionGranted(Permission.storage);
  }

  /// Request permission and handle the result with user feedback
  static Future<bool> requestPermissionWithDialog(
    Permission permission,
    String title,
    String message,
  ) async {
    try {
      final isGranted = await isPermissionGranted(permission);
      if (isGranted) {
        return true;
      }

      AppLogger.info('Requesting permission: $title');
      final status = await permission.request();

      if (status.isGranted) {
        AppLogger.info('Permission granted: $title');
        return true;
      } else if (status.isDenied) {
        AppLogger.warning('Permission denied: $title');
        return false;
      } else if (status.isPermanentlyDenied) {
        AppLogger.error('Permission permanently denied: $title');
        _showPermissionDialog(title, message);
        return false;
      }
      return false;
    } catch (e) {
      AppLogger.error('Failed to request permission: $title', error: e);
      return false;
    }
  }

  /// Show dialog for permission denied
  static void _showPermissionDialog(String title, String message) {
    Get.dialog(
      AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              openAppSettings();
              Get.back();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
