import 'dart:async';
import 'package:camera/camera.dart';
import 'package:get/get.dart';
import '../services/camera_capability_service.dart';
import '../utils/logger.dart';

/// Service for managing camera recording
/// Supports dual camera on compatible devices, falls back to single camera otherwise
class RecordingService extends GetxService {
  // Camera controllers
  CameraController? _primaryController;
  CameraController? _secondaryController;
  
  // Camera descriptions
  List<CameraDescription> _cameras = [];
  CameraDescription? _frontCamera;
  CameraDescription? _backCamera;
  
  // State observables
  final _isInitialized = false.obs;
  final _isRecording = false.obs;
  final _isPaused = false.obs;
  final _recordingDuration = Duration.zero.obs;
  final _errorMessage = Rx<String?>(null);
  final _isDualCameraMode = false.obs;
  
  // Recording paths
  String? _primaryVideoPath;
  String? _secondaryVideoPath;
  
  Timer? _durationTimer;

  // Getters
  bool get isInitialized => _isInitialized.value;
  bool get isRecording => _isRecording.value;
  bool get isPaused => _isPaused.value;
  bool get isDualCameraMode => _isDualCameraMode.value;
  Duration get recordingDuration => _recordingDuration.value;
  String? get errorMessage => _errorMessage.value;
  
  CameraController? get backCamera => _primaryController;
  CameraController? get frontCamera => _secondaryController;
  
  // For compatibility with existing code
  bool get isComposing => false;
  dynamic get compositionLayout => null;
  set compositionLayout(dynamic _) {}

  @override
  void onInit() {
    super.onInit();
    _loadCameras();
  }

  Future<void> _loadCameras() async {
    try {
      _cameras = await availableCameras();
      AppLogger.info('Found ${_cameras.length} cameras');
      
      for (var camera in _cameras) {
        AppLogger.info('Camera: ${camera.name}, direction: ${camera.lensDirection}');
        if (camera.lensDirection == CameraLensDirection.front) {
          _frontCamera = camera;
        } else if (camera.lensDirection == CameraLensDirection.back) {
          _backCamera = camera;
        }
      }
    } catch (e) {
      AppLogger.error('Failed to load cameras', error: e);
      _errorMessage.value = 'Failed to access cameras: $e';
    }
  }

  /// Initialize cameras for preview and recording
  Future<void> initializeCameras({
    ResolutionPreset resolution = ResolutionPreset.medium,
    bool enableAudio = true,
  }) async {
    try {
      _isInitialized.value = false;
      _errorMessage.value = null;
      
      // Dispose existing controllers
      await _disposeControllers();
      
      // Ensure cameras are loaded
      if (_cameras.isEmpty) {
        await _loadCameras();
      }
      
      if (_cameras.isEmpty) {
        _errorMessage.value = 'No cameras found on device';
        _isInitialized.value = true;
        return;
      }

      // Check concurrent camera support
      bool supportsConcurrent = false;
      try {
        supportsConcurrent = await CameraCapabilityService.hasConcurrentCameraSupport();
      } catch (e) {
        AppLogger.warning('Could not check concurrent support: $e');
      }
      
      AppLogger.info('Concurrent camera support: $supportsConcurrent');
      
      // Initialize primary camera (back camera preferred)
      if (_backCamera != null) {
        await _initializePrimaryCamera(_backCamera!, resolution, enableAudio);
      } else if (_frontCamera != null) {
        await _initializePrimaryCamera(_frontCamera!, resolution, enableAudio);
      }
      
      // Try to initialize secondary camera only if concurrent is supported
      if (supportsConcurrent && _frontCamera != null && _backCamera != null) {
        await _initializeSecondaryCamera(
          _primaryController?.description == _backCamera ? _frontCamera! : _backCamera!,
          resolution,
        );
      }
      
      _isDualCameraMode.value = _primaryController != null && _secondaryController != null;
      _isInitialized.value = true;
      
      AppLogger.info('Camera initialization complete. Dual mode: ${_isDualCameraMode.value}');
      
    } catch (e) {
      AppLogger.error('Failed to initialize cameras', error: e);
      _errorMessage.value = 'Camera initialization failed: $e';
      _isInitialized.value = true;
    }
  }

  Future<void> _initializePrimaryCamera(
    CameraDescription camera,
    ResolutionPreset resolution,
    bool enableAudio,
  ) async {
    try {
      AppLogger.info('Initializing primary camera: ${camera.lensDirection}');
      
      _primaryController = CameraController(
        camera,
        resolution,
        enableAudio: enableAudio,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      
      await _primaryController!.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Primary camera initialization timed out');
        },
      );
      
      AppLogger.info('Primary camera initialized successfully');
    } catch (e) {
      AppLogger.error('Primary camera initialization failed', error: e);
      _primaryController?.dispose();
      _primaryController = null;
      rethrow;
    }
  }

  Future<void> _initializeSecondaryCamera(
    CameraDescription camera,
    ResolutionPreset resolution,
  ) async {
    try {
      AppLogger.info('Initializing secondary camera: ${camera.lensDirection}');
      
      // Small delay to allow hardware to settle
      await Future.delayed(const Duration(milliseconds: 300));
      
      _secondaryController = CameraController(
        camera,
        resolution,
        enableAudio: false, // Only primary captures audio
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      
      await _secondaryController!.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Secondary camera initialization timed out');
        },
      );
      
      AppLogger.info('Secondary camera initialized successfully');
    } catch (e) {
      AppLogger.warning('Secondary camera initialization failed (device may not support dual cameras): $e');
      _secondaryController?.dispose();
      _secondaryController = null;
      // Don't rethrow - secondary camera failure is acceptable
    }
  }

  /// Start video recording
  Future<void> startRecording({required String outputPath}) async {
    if (_isRecording.value) {
      AppLogger.warning('Already recording');
      return;
    }
    
    if (_primaryController == null || !_primaryController!.value.isInitialized) {
      throw Exception('Camera not initialized');
    }
    
    try {
      AppLogger.info('Starting recording to: $outputPath');
      
      // Start primary camera recording
      await _primaryController!.startVideoRecording();
      _primaryVideoPath = outputPath;
      
      // Start secondary camera recording if available
      if (_secondaryController != null && _secondaryController!.value.isInitialized) {
        try {
          await _secondaryController!.startVideoRecording();
          _secondaryVideoPath = outputPath.replaceFirst('.mp4', '_secondary.mp4');
          AppLogger.info('Secondary camera recording started');
        } catch (e) {
          AppLogger.warning('Could not start secondary camera recording: $e');
        }
      }
      
      _isRecording.value = true;
      _isPaused.value = false;
      _recordingDuration.value = Duration.zero;
      _startDurationTimer();
      
      AppLogger.info('Recording started');
    } catch (e) {
      AppLogger.error('Failed to start recording', error: e);
      rethrow;
    }
  }

  /// Stop video recording
  Future<XFile?> stopRecording() async {
    if (!_isRecording.value) {
      AppLogger.warning('Not recording');
      return null;
    }
    
    _durationTimer?.cancel();
    XFile? primaryFile;
    
    try {
      // Stop primary camera
      if (_primaryController != null && _primaryController!.value.isRecordingVideo) {
        final tempFile = await _primaryController!.stopVideoRecording();
        
        if (_primaryVideoPath != null) {
          await tempFile.saveTo(_primaryVideoPath!);
          primaryFile = XFile(_primaryVideoPath!);
          AppLogger.info('Primary video saved to: $_primaryVideoPath');
        } else {
          primaryFile = tempFile;
        }
      }
      
      // Stop secondary camera
      if (_secondaryController != null && _secondaryController!.value.isRecordingVideo) {
        try {
          final tempFile = await _secondaryController!.stopVideoRecording();
          if (_secondaryVideoPath != null) {
            await tempFile.saveTo(_secondaryVideoPath!);
            AppLogger.info('Secondary video saved to: $_secondaryVideoPath');
          }
        } catch (e) {
          AppLogger.warning('Error stopping secondary camera: $e');
        }
      }
      
    } catch (e) {
      AppLogger.error('Error stopping recording', error: e);
    } finally {
      _isRecording.value = false;
      _isPaused.value = false;
      _recordingDuration.value = Duration.zero;
      _primaryVideoPath = null;
      _secondaryVideoPath = null;
    }
    
    return primaryFile;
  }

  /// Pause recording
  Future<void> pauseRecording() async {
    if (!_isRecording.value || _isPaused.value) return;
    
    try {
      await _primaryController?.pauseVideoRecording();
      _isPaused.value = true;
      _durationTimer?.cancel();
      AppLogger.info('Recording paused');
    } catch (e) {
      AppLogger.error('Failed to pause recording', error: e);
    }
  }

  /// Resume recording
  Future<void> resumeRecording() async {
    if (!_isRecording.value || !_isPaused.value) return;
    
    try {
      await _primaryController?.resumeVideoRecording();
      _isPaused.value = false;
      _startDurationTimer();
      AppLogger.info('Recording resumed');
    } catch (e) {
      AppLogger.error('Failed to resume recording', error: e);
    }
  }

  /// Take pictures from available cameras
  Future<List<XFile>> takePicture() async {
    List<XFile> pictures = [];
    
    if (_primaryController != null && _primaryController!.value.isInitialized) {
      try {
        final pic = await _primaryController!.takePicture();
        pictures.add(pic);
        AppLogger.info('Primary camera picture taken');
      } catch (e) {
        AppLogger.error('Failed to take primary picture', error: e);
      }
    }
    
    if (_secondaryController != null && _secondaryController!.value.isInitialized) {
      try {
        final pic = await _secondaryController!.takePicture();
        pictures.add(pic);
        AppLogger.info('Secondary camera picture taken');
      } catch (e) {
        AppLogger.error('Failed to take secondary picture', error: e);
      }
    }
    
    if (pictures.isEmpty) {
      throw Exception('Failed to capture any pictures');
    }
    
    return pictures;
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _recordingDuration.value = _recordingDuration.value + const Duration(seconds: 1);
    });
  }

  Future<void> _disposeControllers() async {
    try {
      await _primaryController?.dispose();
      await _secondaryController?.dispose();
    } catch (e) {
      AppLogger.warning('Error disposing controllers: $e');
    }
    _primaryController = null;
    _secondaryController = null;
  }

  @override
  void onClose() {
    _durationTimer?.cancel();
    _disposeControllers();
    super.onClose();
  }

  Future<void> dispose() async {
    _durationTimer?.cancel();
    await _disposeControllers();
  }
}
