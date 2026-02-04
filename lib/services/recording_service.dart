import 'dart:async';
import 'package:camera/camera.dart' hide CameraException;
import 'package:get/get.dart';
import '../utils/logger.dart';
import '../utils/exceptions.dart';

/// Service for managing camera recording
class RecordingService extends GetxService {
  List<CameraDescription>? _cameras;
  CameraController? _frontController;
  CameraController? _backController;
  String? _frontVideoPath;
  String? _backVideoPath;
  final _isRecording = false.obs;
  final _isPaused = false.obs;
  final _recordingDuration = const Duration().obs;
  final _isInitialized = false.obs;
  final _initializationError = Rx<String?>(null);
  Timer? _durationTimer;

  List<CameraDescription>? get cameras => _cameras;
  bool get isRecording => _isRecording.value;
  bool get isPaused => _isPaused.value;
  Duration get recordingDuration => _recordingDuration.value;
  bool get isInitialized => _isInitialized.value;
  String? get initializationError => _initializationError.value;
  CameraController? get frontCamera => _frontController;
  CameraController? get backCamera => _backController;
  String? get frontVideoPath => _frontVideoPath;
  String? get backVideoPath => _backVideoPath;

  @override
  void onInit() {
    super.onInit();
    _initializeCameras();
  }

  Future<void> _initializeCameras() async {
    try {
      _cameras = await availableCameras();
      AppLogger.info('Available cameras: ${_cameras?.length}');
    } catch (e) {
      AppLogger.error('Failed to get available cameras', error: e);
      throw CameraOperationException(
        message: 'Failed to get available cameras',
        originalException: e,
      );
    }
  }

  /// Initialize camera controllers for both front and back cameras
  Future<void> initializeCameras({
    int frontCameraIndex = 0,
    int backCameraIndex = 1,
    ResolutionPreset resolution = ResolutionPreset.high,
    bool enableAudio = true,
  }) async {
    try {
      _initializationError.value = null;
      
      if (_cameras == null || _cameras!.isEmpty) {
        final error = 'No cameras available';
        _initializationError.value = error;
        throw CameraOperationException(
          message: error,
        );
      }

      // Get front and back cameras
      CameraDescription? frontCamera;
      CameraDescription? backCamera;

      for (var camera in _cameras!) {
        if (camera.lensDirection == CameraLensDirection.front && frontCamera == null) {
          frontCamera = camera;
        } else if (camera.lensDirection == CameraLensDirection.back && backCamera == null) {
          backCamera = camera;
        }
      }

      // Initialize front camera
      if (frontCamera != null) {
        _frontController = CameraController(
          frontCamera,
          resolution,
          enableAudio: enableAudio,
        );
        await _frontController!.initialize();
        AppLogger.info('Front camera initialized');
      } else {
        AppLogger.warning('Front camera not available');
      }

      // Initialize back camera
      if (backCamera != null) {
        _backController = CameraController(
          backCamera,
          resolution,
          enableAudio: enableAudio,
        );
        await _backController!.initialize();
        AppLogger.info('Back camera initialized');
      } else {
        final error = 'Back camera not available';
        _initializationError.value = error;
        AppLogger.warning(error);
      }

      _isInitialized.value = true;
      AppLogger.info('Cameras initialized successfully');
    } catch (e) {
      final errorMsg = 'Failed to initialize cameras: $e';
      _initializationError.value = errorMsg;
      AppLogger.error(errorMsg);
      await dispose();
      throw CameraOperationException(
        message: 'Failed to initialize cameras',
        originalException: e,
      );
    }
  }

  /// Start recording video
  Future<void> startRecording({
    required String outputPath,
  }) async {
    try {
      if (_isRecording.value) {
        AppLogger.warning('Recording is already in progress');
        return;
      }

      if (_backController == null || !_backController!.value.isInitialized) {
        throw RecordingException(
          message: 'Camera not initialized',
        );
      }

       // Start recording on both cameras
       await _backController!.startVideoRecording();

       // If front camera is available, start recording there too
       if (_frontController != null && _frontController!.value.isInitialized) {
         // Record front camera as well for dual composition
         try {
           await _frontController!.startVideoRecording();
           _frontVideoPath = outputPath.replaceFirst('.mp4', '_front.mp4');
           AppLogger.info('Front camera recording started: $_frontVideoPath');
         } catch (e) {
           AppLogger.warning('Could not start front camera recording: $e');
         }
       }

       _backVideoPath = outputPath;
       _isRecording.value = true;
       _isPaused.value = false;
       _startDurationTimer();

       AppLogger.info('Recording started: $outputPath');
    } catch (e) {
      AppLogger.error('Failed to start recording', error: e);
      throw RecordingException(
        message: 'Failed to start recording',
        originalException: e,
      );
    }
  }

  /// Pause recording
  Future<void> pauseRecording() async {
    try {
      if (!_isRecording.value) {
        AppLogger.warning('No recording in progress');
        return;
      }

      if (_backController != null) {
        await _backController!.pauseVideoRecording();
        _isPaused.value = true;
        _durationTimer?.cancel();
        AppLogger.info('Recording paused');
      }
    } catch (e) {
      AppLogger.error('Failed to pause recording', error: e);
      throw RecordingException(
        message: 'Failed to pause recording',
        originalException: e,
      );
    }
  }

  /// Resume recording
  Future<void> resumeRecording() async {
    try {
      if (!_isRecording.value) {
        AppLogger.warning('No recording in progress');
        return;
      }

      if (_backController != null) {
        await _backController!.resumeVideoRecording();
        _isPaused.value = false;
        _startDurationTimer();
        AppLogger.info('Recording resumed');
      }
    } catch (e) {
      AppLogger.error('Failed to resume recording', error: e);
      throw RecordingException(
        message: 'Failed to resume recording',
        originalException: e,
      );
    }
  }

  /// Stop recording and return the file path
  Future<XFile?> stopRecording() async {
    try {
      if (!_isRecording.value) {
        AppLogger.warning('No recording in progress');
        return null;
      }

       _durationTimer?.cancel();
       XFile? backVideoFile;
       XFile? frontVideoFile;

       // Stop recording on back camera
       if (_backController != null) {
         backVideoFile = await _backController!.stopVideoRecording();
         AppLogger.info('Back camera recording stopped: ${backVideoFile.path}');
       }

       // Stop recording on front camera if it was recording
       if (_frontController != null && _frontVideoPath != null) {
         try {
           frontVideoFile = await _frontController!.stopVideoRecording();
           AppLogger.info('Front camera recording stopped: ${frontVideoFile.path}');
         } catch (e) {
           AppLogger.warning('Error stopping front camera: $e');
         }
       }

       _isRecording.value = false;
       _isPaused.value = false;
       _recordingDuration.value = const Duration();
       _frontVideoPath = null;
       _backVideoPath = null;

       // Return the back camera file as primary
       return backVideoFile;
    } catch (e) {
      AppLogger.error('Failed to stop recording', error: e);
      throw RecordingException(
        message: 'Failed to stop recording',
        originalException: e,
      );
    }
  }

  /// Start the duration timer
  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _recordingDuration.value = _recordingDuration.value + const Duration(seconds: 1);
    });
  }

  @override
  void onClose() {
    _durationTimer?.cancel();
    _frontController?.dispose();
    _backController?.dispose();
    super.onClose();
  }

  Future<void> dispose() async {
    _durationTimer?.cancel();
    await _frontController?.dispose();
    await _backController?.dispose();
  }
}
