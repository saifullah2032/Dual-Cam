import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/settings_service.dart';
import '../utils/logger.dart';

/// Service for managing camera layout (PiP vs Split-Screen)
class LayoutService extends GetxService {
  final _currentLayout = Rx<RecordingLayout>(RecordingLayout.pip);
  final _pipPosition = Rx<PiPPosition>(PiPPosition.bottomRight);
  late SettingsService _settingsService;

  RecordingLayout get currentLayout => _currentLayout.value;
  PiPPosition get pipPosition => _pipPosition.value;

  @override
  void onInit() {
    super.onInit();
    _initializeLayout();
  }

  Future<void> _initializeLayout() async {
    try {
      _settingsService = Get.find<SettingsService>();
      _currentLayout.value = _settingsService.getRecordingLayout();
      _pipPosition.value = _settingsService.getPiPPosition();
      AppLogger.info('Layout initialized: ${_currentLayout.value.label}');
    } catch (e) {
      AppLogger.error('Failed to initialize layout service', error: e);
    }
  }

  /// Change recording layout
  Future<void> changeLayout(RecordingLayout layout) async {
    try {
      await _settingsService.setRecordingLayout(layout);
      _currentLayout.value = layout;
      AppLogger.info('Layout changed to: ${layout.label}');
    } catch (e) {
      AppLogger.error('Failed to change layout', error: e);
      rethrow;
    }
  }

  /// Change PiP position
  Future<void> changePiPPosition(PiPPosition position) async {
    try {
      await _settingsService.setPiPPosition(position);
      _pipPosition.value = position;
      AppLogger.info('PiP position changed to: ${position.label}');
    } catch (e) {
      AppLogger.error('Failed to change PiP position', error: e);
      rethrow;
    }
  }

  /// Get PiP widget constraints based on position and parent size
  Offset getPiPOffset(Size parentSize, Size pipSize) {
    const padding = 16.0;
    const pipWidth = 120.0;
    const pipHeight = 160.0;

    switch (_pipPosition.value) {
      case PiPPosition.topLeft:
        return const Offset(padding, padding);
      case PiPPosition.topRight:
        return Offset(parentSize.width - pipWidth - padding, padding);
      case PiPPosition.bottomLeft:
        return Offset(padding, parentSize.height - pipHeight - padding);
      case PiPPosition.bottomRight:
        return Offset(
          parentSize.width - pipWidth - padding,
          parentSize.height - pipHeight - padding,
        );
    }
  }

  /// Check if layout supports dual cameras
  bool isConcurrentLayout() {
    return _currentLayout.value == RecordingLayout.pip ||
        _currentLayout.value == RecordingLayout.splitScreen;
  }
}
