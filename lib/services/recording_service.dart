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
  String? _currentVideoPath;
  final _isRecording = false.obs;
  final _isPaused = false.obs;
  final _recordingDuration = const Duration().obs;
  Timer? _durationTimer;

  List<CameraDescription>? get cameras => _cameras;
  bool get isRecording => _isRecording.value;
  bool get isPaused => _isPaused.value;
  Duration get recordingDuration => _recordingDuration.value;
  CameraController? get frontCamera => _frontController;
  CameraController? get backCamera => _backController;

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
      if (_cameras == null || _cameras!.isEmpty) {
        throw CameraOperationException(
          message: 'No cameras available',
        );
      }

      // Initialize front camera
      if (frontCameraIndex < _cameras!.length) {
        _frontController = CameraController(
          _cameras![frontCameraIndex],
          resolution,
          enableAudio: enableAudio,
        );
        await _frontController!.initialize();
        AppLogger.info('Front camera initialized');
      }

      // Initialize back camera
      if (backCameraIndex < _cameras!.length) {
        _backController = CameraController(
          _cameras![backCameraIndex],
          resolution,
          enableAudio: enableAudio,
        );
        await _backController!.initialize();
        AppLogger.info('Back camera initialized');
      }
    } catch (e) {
      AppLogger.error('Failed to initialize cameras', error: e);
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

      // Start recording on back camera (main recording)
      await _backController!.startVideoRecording();

      // If front camera is available, you can add synchronization logic here
      if (_frontController != null && _frontController!.value.isInitialized) {
        // For now, just log that front camera is available
        AppLogger.info('Front camera is available for composition');
      }

      _currentVideoPath = outputPath;
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
      XFile? videoFile;

      if (_backController != null) {
        videoFile = await _backController!.stopVideoRecording();
        AppLogger.info('Recording stopped: ${videoFile?.path}');
      }

      _isRecording.value = false;
      _isPaused.value = false;
      _recordingDuration.value = const Duration();
      _currentVideoPath = null;

      return videoFile;
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
