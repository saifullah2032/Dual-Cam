import 'dart:async';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../utils/logger.dart';

/// Preview layout modes for dual camera
enum PreviewLayout {
  sideBySideHorizontal,  // Left-Right
  sideBySideVertical,    // Top-Bottom
  pipTopLeft,            // Picture-in-picture top left
  pipTopRight,           // Picture-in-picture top right
  pipBottomLeft,         // Picture-in-picture bottom left
  pipBottomRight,        // Picture-in-picture bottom right
  singleBack,            // Only back camera
  singleFront,           // Only front camera
}

/// Video quality presets
enum VideoQuality {
  low,      // 640x480 @ 24fps
  medium,   // 1280x720 @ 30fps
  high,     // 1920x1080 @ 30fps
  ultra,    // 1920x1080 @ 60fps
}

extension PreviewLayoutExtension on PreviewLayout {
  String get nativeName {
    switch (this) {
      case PreviewLayout.sideBySideHorizontal:
        return 'SIDE_BY_SIDE_HORIZONTAL';
      case PreviewLayout.sideBySideVertical:
        return 'SIDE_BY_SIDE_VERTICAL';
      case PreviewLayout.pipTopLeft:
        return 'PIP_TOP_LEFT';
      case PreviewLayout.pipTopRight:
        return 'PIP_TOP_RIGHT';
      case PreviewLayout.pipBottomLeft:
        return 'PIP_BOTTOM_LEFT';
      case PreviewLayout.pipBottomRight:
        return 'PIP_BOTTOM_RIGHT';
      case PreviewLayout.singleBack:
        return 'SINGLE_BACK';
      case PreviewLayout.singleFront:
        return 'SINGLE_FRONT';
    }
  }

  String get displayName {
    switch (this) {
      case PreviewLayout.sideBySideHorizontal:
        return 'Side by Side';
      case PreviewLayout.sideBySideVertical:
        return 'Top & Bottom';
      case PreviewLayout.pipTopLeft:
        return 'PiP Top Left';
      case PreviewLayout.pipTopRight:
        return 'PiP Top Right';
      case PreviewLayout.pipBottomLeft:
        return 'PiP Bottom Left';
      case PreviewLayout.pipBottomRight:
        return 'PiP Bottom Right';
      case PreviewLayout.singleBack:
        return 'Back Only';
      case PreviewLayout.singleFront:
        return 'Front Only';
    }
  }

  String get icon {
    switch (this) {
      case PreviewLayout.sideBySideHorizontal:
        return '⬛⬛';
      case PreviewLayout.sideBySideVertical:
        return '⬛\n⬛';
      case PreviewLayout.pipTopLeft:
        return '◰';
      case PreviewLayout.pipTopRight:
        return '◳';
      case PreviewLayout.pipBottomLeft:
        return '◱';
      case PreviewLayout.pipBottomRight:
        return '◲';
      case PreviewLayout.singleBack:
        return '📷';
      case PreviewLayout.singleFront:
        return '🤳';
    }
  }

  static PreviewLayout fromNativeName(String name) {
    switch (name) {
      case 'SIDE_BY_SIDE_HORIZONTAL':
        return PreviewLayout.sideBySideHorizontal;
      case 'SIDE_BY_SIDE_VERTICAL':
        return PreviewLayout.sideBySideVertical;
      case 'PIP_TOP_LEFT':
        return PreviewLayout.pipTopLeft;
      case 'PIP_TOP_RIGHT':
        return PreviewLayout.pipTopRight;
      case 'PIP_BOTTOM_LEFT':
        return PreviewLayout.pipBottomLeft;
      case 'PIP_BOTTOM_RIGHT':
        return PreviewLayout.pipBottomRight;
      case 'SINGLE_BACK':
        return PreviewLayout.singleBack;
      case 'SINGLE_FRONT':
        return PreviewLayout.singleFront;
      default:
        return PreviewLayout.sideBySideHorizontal;
    }
  }
}

extension VideoQualityExtension on VideoQuality {
  String get nativeName {
    switch (this) {
      case VideoQuality.low:
        return 'LOW';
      case VideoQuality.medium:
        return 'MEDIUM';
      case VideoQuality.high:
        return 'HIGH';
      case VideoQuality.ultra:
        return 'ULTRA';
    }
  }

  String get displayName {
    switch (this) {
      case VideoQuality.low:
        return 'Low (480p)';
      case VideoQuality.medium:
        return 'Medium (720p)';
      case VideoQuality.high:
        return 'High (1080p)';
      case VideoQuality.ultra:
        return 'Ultra (1080p 60fps)';
    }
  }

  String get description {
    switch (this) {
      case VideoQuality.low:
        return '640x480 @ 24fps - Smaller files';
      case VideoQuality.medium:
        return '1280x720 @ 30fps - Balanced';
      case VideoQuality.high:
        return '1920x1080 @ 30fps - High quality';
      case VideoQuality.ultra:
        return '1920x1080 @ 60fps - Best quality';
    }
  }

  static VideoQuality fromNativeName(String name) {
    switch (name) {
      case 'LOW':
        return VideoQuality.low;
      case 'MEDIUM':
        return VideoQuality.medium;
      case 'HIGH':
        return VideoQuality.high;
      case 'ULTRA':
        return VideoQuality.ultra;
      default:
        return VideoQuality.medium;
    }
  }
}

/// Service that communicates with native Android camera code
/// This provides dual camera support using the Camera2 API
class NativeCameraService extends GetxService {
  static const _channel = MethodChannel('com.example.dual_recorder/camera');
  static const _eventChannel = EventChannel('com.example.dual_recorder/camera_events');

  // State observables
  final _isInitialized = false.obs;
  final _isRecording = false.obs;
  final _isDualCameraMode = false.obs;
  final _errorMessage = Rx<String?>(null);
  final _frontTextureId = Rx<int?>(-1);
  final _backTextureId = Rx<int?>(-1);
  final _recordingDuration = Duration.zero.obs;
  final _currentLayout = PreviewLayout.sideBySideHorizontal.obs;
  final _currentQuality = VideoQuality.medium.obs;
  final _audioEnabled = true.obs;
  final _camerasSwapped = false.obs;

  // Recording paths
  String? _backVideoPath;
  String? _frontVideoPath;
  String? _composedVideoPath;

  // Timer for recording duration
  Timer? _durationTimer;

  // Event subscription
  StreamSubscription? _eventSubscription;

  // Getters
  bool get isInitialized => _isInitialized.value;
  bool get isRecording => _isRecording.value;
  bool get isDualCameraMode => _isDualCameraMode.value;
  String? get errorMessage => _errorMessage.value;
  int? get frontTextureId => _frontTextureId.value;
  int? get backTextureId => _backTextureId.value;
  Duration get recordingDuration => _recordingDuration.value;
  String? get backVideoPath => _backVideoPath;
  String? get frontVideoPath => _frontVideoPath;
  String? get composedVideoPath => _composedVideoPath;
  PreviewLayout get currentLayout => _currentLayout.value;
  VideoQuality get currentQuality => _currentQuality.value;
  bool get audioEnabled => _audioEnabled.value;
  bool get camerasSwapped => _camerasSwapped.value;

  // For compatibility with existing code
  bool get isPaused => false;
  bool get isComposing => false;
  dynamic get compositionLayout => null;
  set compositionLayout(dynamic _) {}
  dynamic get backCamera => _backTextureId.value != null && _backTextureId.value! >= 0 ? true : null;
  dynamic get frontCamera => _frontTextureId.value != null && _frontTextureId.value! >= 0 ? true : null;

  @override
  void onInit() {
    super.onInit();
    _setupEventChannel();
  }

  void _setupEventChannel() {
    _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
      (event) {
        if (event is Map) {
          final eventName = event['event'] as String?;
          final data = event['data'];
          _handleEvent(eventName, data);
        }
      },
      onError: (error) {
        AppLogger.error('Event channel error', error: error);
      },
    );
  }

  void _handleEvent(String? eventName, dynamic data) {
    AppLogger.info('Received event: $eventName');
    switch (eventName) {
      case 'recordingStarted':
        _isRecording.value = true;
        _startDurationTimer();
        break;
      case 'recordingStopped':
        _isRecording.value = false;
        _durationTimer?.cancel();
        if (data is Map) {
          _composedVideoPath = data['composedVideo'] as String?;
          _backVideoPath = data['backVideo'] as String?;
          _frontVideoPath = data['frontVideo'] as String?;
        }
        break;
      case 'photoTaken':
        AppLogger.info('Photo taken: $data');
        break;
      case 'layoutChanged':
        if (data is String) {
          _currentLayout.value = PreviewLayoutExtension.fromNativeName(data);
        }
        break;
      case 'qualityChanged':
        if (data is String) {
          _currentQuality.value = VideoQualityExtension.fromNativeName(data);
        }
        break;
      case 'audioEnabledChanged':
        if (data is bool) {
          _audioEnabled.value = data;
        }
        break;
      case 'camerasSwapped':
        if (data is bool) {
          _camerasSwapped.value = data;
        }
        break;
      case 'error':
        _errorMessage.value = data?.toString();
        break;
    }
  }

  /// Initialize the native camera system
  Future<bool> initialize() async {
    try {
      _errorMessage.value = null;
      AppLogger.info('Initializing native camera service');

      final result = await _channel.invokeMethod<Map>('initialize');
      final success = result?['success'] as bool? ?? false;

      if (!success) {
        _errorMessage.value = result?['error'] as String? ?? 'Initialization failed';
        AppLogger.error('Native camera initialization failed: ${_errorMessage.value}');
        return false;
      }

      _isInitialized.value = true;
      AppLogger.info('Native camera service initialized');
      return true;
    } catch (e) {
      _errorMessage.value = 'Failed to initialize: $e';
      AppLogger.error('Native camera initialization error', error: e);
      return false;
    }
  }

  /// Open cameras and get texture IDs for preview
  Future<bool> openCameras() async {
    try {
      _errorMessage.value = null;
      AppLogger.info('Opening cameras');

      final result = await _channel.invokeMethod<Map>('openCameras');
      final success = result?['success'] as bool? ?? false;

      if (!success) {
        _errorMessage.value = result?['error'] as String? ?? 'Failed to open cameras';
        AppLogger.error('Failed to open cameras: ${_errorMessage.value}');
        return false;
      }

      // Get texture IDs
      final textureIds = result?['textureIds'] as Map?;
      if (textureIds != null) {
        _frontTextureId.value = (textureIds['frontTextureId'] as num?)?.toInt() ?? -1;
        _backTextureId.value = (textureIds['backTextureId'] as num?)?.toInt() ?? -1;
        AppLogger.info('Texture IDs - Front: ${_frontTextureId.value}, Back: ${_backTextureId.value}');
      }

      // Get camera info
      final cameraInfo = result?['cameraInfo'] as Map?;
      if (cameraInfo != null) {
        _isDualCameraMode.value = cameraInfo['isDualCameraSupported'] as bool? ?? false;
        AppLogger.info('Dual camera mode: ${_isDualCameraMode.value}');
      }

      return true;
    } catch (e) {
      _errorMessage.value = 'Failed to open cameras: $e';
      AppLogger.error('Open cameras error', error: e);
      return false;
    }
  }

  /// Initialize and open cameras (combined for convenience)
  Future<void> initializeCameras({
    dynamic resolution,
    bool enableAudio = true,
  }) async {
    final initialized = await initialize();
    if (initialized) {
      await setAudioEnabled(enableAudio);
      await openCameras();
    }
  }

  /// Start video recording
  Future<void> startRecording({String? outputPath}) async {
    if (_isRecording.value) {
      AppLogger.warning('Already recording');
      return;
    }

    try {
      _errorMessage.value = null;
      AppLogger.info('Starting recording');

      final result = await _channel.invokeMethod<Map>('startRecording');
      final success = result?['success'] as bool? ?? false;

      if (!success) {
        _errorMessage.value = result?['error'] as String? ?? 'Failed to start recording';
        AppLogger.error('Failed to start recording: ${_errorMessage.value}');
        throw Exception(_errorMessage.value);
      }

      _isRecording.value = true;
      _recordingDuration.value = Duration.zero;
      _startDurationTimer();
      AppLogger.info('Recording started');
    } catch (e) {
      _errorMessage.value = 'Failed to start recording: $e';
      AppLogger.error('Start recording error', error: e);
      rethrow;
    }
  }

  /// Stop video recording
  Future<Map<String, String?>?> stopRecording() async {
    if (!_isRecording.value) {
      AppLogger.warning('Not recording');
      return null;
    }

    try {
      AppLogger.info('Stopping recording');
      _durationTimer?.cancel();

      final result = await _channel.invokeMethod<Map>('stopRecording');
      final success = result?['success'] as bool? ?? false;
      final paths = result?['paths'] as Map?;

      _isRecording.value = false;
      _recordingDuration.value = Duration.zero;

      if (success && paths != null) {
        // Handle composed video (single merged file)
        final composedVideo = paths['composedVideo'] as String?;
        if (composedVideo != null) {
          _composedVideoPath = composedVideo;
          AppLogger.info('Composed video saved: $composedVideo');
          return {'composedVideo': composedVideo};
        }
        
        // Fallback to separate videos if composition not available
        _backVideoPath = paths['backVideo'] as String?;
        _frontVideoPath = paths['frontVideo'] as String?;
        AppLogger.info('Recording stopped - Back: $_backVideoPath, Front: $_frontVideoPath');
        return {
          'backVideo': _backVideoPath,
          'frontVideo': _frontVideoPath,
        };
      }

      return null;
    } catch (e) {
      _errorMessage.value = 'Failed to stop recording: $e';
      AppLogger.error('Stop recording error', error: e);
      _isRecording.value = false;
      return null;
    }
  }

  /// Take pictures from cameras
  Future<Map<String, String?>?> takePicture() async {
    try {
      AppLogger.info('Taking picture');

      final result = await _channel.invokeMethod<Map>('takePicture');
      final success = result?['success'] as bool? ?? false;
      final paths = result?['paths'] as Map?;

      if (!success || paths == null) {
        AppLogger.warning('Photo capture returned no paths');
        return null;
      }

      final photoResult = <String, String?>{};
      if (paths['backPhoto'] != null) {
        photoResult['backPhoto'] = paths['backPhoto'] as String;
      }
      if (paths['frontPhoto'] != null) {
        photoResult['frontPhoto'] = paths['frontPhoto'] as String;
      }
      // Handle composed photo from native dual-camera capture
      if (paths['composedPhoto'] != null) {
        photoResult['composedPhoto'] = paths['composedPhoto'] as String;
      }

      AppLogger.info('Photos captured: $photoResult');
      return photoResult.isNotEmpty ? photoResult : null;
    } catch (e) {
      AppLogger.error('Take picture error', error: e);
      rethrow;
    }
  }

  /// Set preview layout
  Future<bool> setLayout(PreviewLayout layout) async {
    try {
      AppLogger.info('Setting layout to: ${layout.displayName}');

      final result = await _channel.invokeMethod<Map>('setLayout', {
        'layout': layout.nativeName,
      });
      
      final success = result?['success'] as bool? ?? false;
      if (success) {
        _currentLayout.value = layout;
      }
      return success;
    } catch (e) {
      AppLogger.error('Set layout error', error: e);
      return false;
    }
  }

  /// Set video quality
  Future<bool> setQuality(VideoQuality quality) async {
    try {
      AppLogger.info('Setting quality to: ${quality.displayName}');

      final result = await _channel.invokeMethod<Map>('setQuality', {
        'quality': quality.nativeName,
      });
      
      final success = result?['success'] as bool? ?? false;
      if (success) {
        _currentQuality.value = quality;
      }
      return success;
    } catch (e) {
      AppLogger.error('Set quality error', error: e);
      return false;
    }
  }

  /// Enable or disable audio recording
  Future<bool> setAudioEnabled(bool enabled) async {
    try {
      AppLogger.info('Setting audio enabled: $enabled');

      final result = await _channel.invokeMethod<Map>('setAudioEnabled', {
        'enabled': enabled,
      });
      
      final success = result?['success'] as bool? ?? false;
      if (success) {
        _audioEnabled.value = enabled;
      }
      return success;
    } catch (e) {
      AppLogger.error('Set audio enabled error', error: e);
      return false;
    }
  }

  /// Get available layouts
  Future<List<PreviewLayout>> getAvailableLayouts() async {
    try {
      final result = await _channel.invokeMethod<Map>('getAvailableLayouts');
      final layouts = result?['layouts'] as List?;
      
      if (layouts != null) {
        return layouts
            .map((name) => PreviewLayoutExtension.fromNativeName(name as String))
            .toList();
      }
      return PreviewLayout.values.toList();
    } catch (e) {
      AppLogger.error('Get available layouts error', error: e);
      return PreviewLayout.values.toList();
    }
  }

  /// Get available quality settings
  Future<List<VideoQuality>> getAvailableQualities() async {
    try {
      final result = await _channel.invokeMethod<Map>('getAvailableQualities');
      final qualities = result?['qualities'] as List?;
      
      if (qualities != null) {
        return qualities
            .map((name) => VideoQualityExtension.fromNativeName(name as String))
            .toList();
      }
      return VideoQuality.values.toList();
    } catch (e) {
      AppLogger.error('Get available qualities error', error: e);
      return VideoQuality.values.toList();
    }
  }

  /// Swap front and back camera positions
  Future<bool> swapCameras() async {
    try {
      AppLogger.info('Swapping cameras');

      final result = await _channel.invokeMethod<Map>('swapCameras');
      final swapped = result?['camerasSwapped'] as bool? ?? false;
      _camerasSwapped.value = swapped;
      
      return swapped;
    } catch (e) {
      AppLogger.error('Swap cameras error', error: e);
      return _camerasSwapped.value;
    }
  }

  /// Get camera info from native side
  Future<Map<String, dynamic>> getCameraInfo() async {
    try {
      final result = await _channel.invokeMethod<Map>('getCameraInfo');
      return Map<String, dynamic>.from(result ?? {});
    } catch (e) {
      AppLogger.error('Get camera info error', error: e);
      return {};
    }
  }

  /// Get device info
  Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      final result = await _channel.invokeMethod<Map>('getDeviceInfo');
      return Map<String, dynamic>.from(result ?? {});
    } catch (e) {
      AppLogger.error('Get device info error', error: e);
      return {};
    }
  }

  /// Get layout info
  Future<Map<String, dynamic>> getLayoutInfo() async {
    try {
      final result = await _channel.invokeMethod<Map>('getLayoutInfo');
      return Map<String, dynamic>.from(result ?? {});
    } catch (e) {
      AppLogger.error('Get layout info error', error: e);
      return {};
    }
  }

  /// Get quality info
  Future<Map<String, dynamic>> getQualityInfo() async {
    try {
      final result = await _channel.invokeMethod<Map>('getQualityInfo');
      return Map<String, dynamic>.from(result ?? {});
    } catch (e) {
      AppLogger.error('Get quality info error', error: e);
      return {};
    }
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _recordingDuration.value = _recordingDuration.value + const Duration(seconds: 1);
    });
  }

  /// Close cameras
  Future<void> closeCameras() async {
    try {
      await _channel.invokeMethod('closeCameras');
      _frontTextureId.value = -1;
      _backTextureId.value = -1;
      AppLogger.info('Cameras closed');
    } catch (e) {
      AppLogger.error('Close cameras error', error: e);
    }
  }

  /// Pause recording (not supported in native implementation)
  Future<void> pauseRecording() async {
    AppLogger.warning('Pause not supported in native implementation');
  }

  /// Resume recording (not supported in native implementation)
  Future<void> resumeRecording() async {
    AppLogger.warning('Resume not supported in native implementation');
  }

  @override
  void onClose() {
    _durationTimer?.cancel();
    _eventSubscription?.cancel();
    _channel.invokeMethod('dispose');
    super.onClose();
  }

  Future<void> dispose() async {
    _durationTimer?.cancel();
    _eventSubscription?.cancel();
    await _channel.invokeMethod('dispose');
  }
}
