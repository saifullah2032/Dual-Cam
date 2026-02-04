import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';
import 'dart:io';
import '../utils/logger.dart';
import '../utils/exceptions.dart';

/// Service for managing app permissions
class PermissionService extends GetxService {
  /// Check and request camera permission
  static Future<bool> requestCameraPermission() async {
    try {
      AppLogger.info('Checking camera permission status...');
      
      // First check if already granted
      if (await Permission.camera.isGranted) {
        AppLogger.info('Camera permission already granted');
        return true;
      }

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
      AppLogger.info('Checking microphone permission status...');
      
      // First check if already granted
      if (await Permission.microphone.isGranted) {
        AppLogger.info('Microphone permission already granted');
        return true;
      }

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
      AppLogger.info('Checking storage permission status...');
      
      // Android 13+ uses scoped storage (Photos and Videos permissions)
      if (Platform.isAndroid) {
        final androidInfo = await _getAndroidVersion();
        
        if (androidInfo >= 33) {
          // Android 13+ - use new permissions
          AppLogger.info('Android 13+ detected, using scoped storage permissions');
          
          // Check if photos/videos permission is already granted
          if (await Permission.photos.isGranted) {
            AppLogger.info('Photos permission already granted');
            return true;
          }

          AppLogger.info('Requesting photos and videos permission...');
          final status = await Permission.photos.request();
          
          if (status.isGranted) {
            AppLogger.info('Photos/Videos permission granted');
            return true;
          } else if (status.isPermanentlyDenied) {
            AppLogger.error('Photos permission permanently denied');
            openAppSettings();
            return false;
          }
          return false;
        } else {
          // Android 12 and below - use WRITE_EXTERNAL_STORAGE
          AppLogger.info('Android 12 and below, using legacy storage permission');
          
          if (await Permission.storage.isGranted) {
            AppLogger.info('Storage permission already granted');
            return true;
          }

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
        }
      } else if (Platform.isIOS) {
        AppLogger.info('iOS detected, using photos permission');
        
        if (await Permission.photos.isGranted) {
          AppLogger.info('Photos permission already granted');
          return true;
        }

        final status = await Permission.photos.request();
        if (status.isGranted) {
          AppLogger.info('Photos permission granted');
          return true;
        }
        return false;
      }

      return true; // For other platforms
    } catch (e) {
      AppLogger.error('Failed to request storage permission', error: e);
      throw PermissionException(
        message: 'Failed to request storage permission',
        originalException: e,
      );
    }
  }

  /// Get Android API version
  static Future<int> _getAndroidVersion() async {
    try {
      // This is a simple check - in production you'd use device_info_plus
      // For now, we'll assume if photos permission exists, it's Android 13+
      return 33;
    } catch (e) {
      return 31; // Default to lower version
    }
  }

  /// Request all necessary permissions for recording
  static Future<bool> requestAllRecordingPermissions() async {
    try {
      AppLogger.info('Checking all recording permissions...');
      
      // First, check if all permissions are already granted
      final cameraGranted = await Permission.camera.isGranted;
      final storageGranted = Platform.isAndroid 
          ? await Permission.photos.isGranted || await Permission.storage.isGranted
          : await Permission.photos.isGranted;

      if (cameraGranted && storageGranted) {
        AppLogger.info('All permissions already granted');
        return true;
      }

      AppLogger.info('Requesting recording permissions...');
      
      final cameraOk = await requestCameraPermission();
      if (!cameraOk) {
        AppLogger.error('Camera permission required for recording');
        return false;
      }

      final micOk = await requestMicrophonePermission();
      if (!micOk) {
        AppLogger.warning('Microphone permission not granted, recording without audio');
        // Continue anyway - recording can work without audio
      }

      final storageOk = await requestStoragePermission();
      if (!storageOk) {
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
      AppLogger.debug('Permission ${permission.toString()} status: ${status.toString()}');
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
    if (Platform.isAndroid) {
      // Check both old and new permissions
      return (await Permission.storage.isGranted) || 
             (await Permission.photos.isGranted);
    } else if (Platform.isIOS) {
      return await Permission.photos.isGranted;
    }
    return true;
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
