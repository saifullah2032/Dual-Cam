import 'package:flutter/foundation.dart';
import '../models/camera_capability.dart';
import '../services/camera_capability_service.dart';
import '../utils/logger.dart';

/// Provider for managing camera capabilities and state
class CameraProvider extends ChangeNotifier {
  CameraCapability? _capability;
  bool _isLoading = false;
  String? _error;

  CameraCapability? get capability => _capability;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get supportsConcurrentRecording => _capability?.supportsConcurrent ?? false;

  /// Initialize and check camera capabilities
  Future<void> initializeCameraCapabilities() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _capability = await CameraCapabilityService.getCameraCapability();
      AppLogger.info('Camera capabilities initialized: $_capability');
    } catch (e) {
      _error = e.toString();
      AppLogger.error('Failed to initialize camera capabilities', error: e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh camera capabilities
  Future<void> refresh() async {
    await initializeCameraCapabilities();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
