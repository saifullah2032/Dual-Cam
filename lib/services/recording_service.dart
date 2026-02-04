import 'dart:async';
import 'dart:io';
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
          // Try to get cameras again
          try {
            _cameras = await availableCameras();
          } catch (e) {
            final error = 'No cameras available';
            _initializationError.value = error;
            throw CameraOperationException(message: error);
          }
          
          if (_cameras == null || _cameras!.isEmpty) {
            final error = 'No cameras available on device';
            _initializationError.value = error;
            throw CameraOperationException(message: error);
          }
        }

        AppLogger.info('Available cameras: ${_cameras?.length}');
        for (var i = 0; i < _cameras!.length; i++) {
          final camera = _cameras![i];
          AppLogger.info('Camera $i: ${camera.lensDirection} - ${camera.name}');
        }

        // Get front and back cameras
        CameraDescription? frontCamera;
        CameraDescription? backCamera;

        for (var camera in _cameras!) {
          if (camera.lensDirection == CameraLensDirection.front && frontCamera == null) {
            frontCamera = camera;
            AppLogger.info('Found front camera: ${camera.name}');
          } else if (camera.lensDirection == CameraLensDirection.back && backCamera == null) {
            backCamera = camera;
            AppLogger.info('Found back camera: ${camera.name}');
          }
        }

        // Initialize front camera with better error handling
        if (frontCamera != null) {
          try {
            AppLogger.info('Initializing front camera...');
            _frontController = CameraController(
              frontCamera,
              resolution,
              enableAudio: false, // Disable audio for front camera to avoid conflicts
            );
            await _frontController!.initialize();
            AppLogger.info('✅ Front camera initialized successfully');
          } catch (e) {
            AppLogger.warning('Failed to initialize front camera: $e');
            _frontController?.dispose();
            _frontController = null; // Set to null if initialization fails
          }
        } else {
          AppLogger.warning('⚠ Front camera not available on this device');
        }

        // Initialize back camera (required)
        if (backCamera != null) {
          try {
            AppLogger.info('Initializing back camera...');
            _backController = CameraController(
              backCamera,
              resolution,
              enableAudio: enableAudio,
            );
            await _backController!.initialize();
            AppLogger.info('✅ Back camera initialized successfully');
          } catch (e) {
            final error = 'Failed to initialize back camera: $e';
            _initializationError.value = error;
            AppLogger.error(error);
            _backController?.dispose();
            _backController = null;
            throw CameraOperationException(message: error);
          }
        } else {
          final error = 'Back camera not available on this device';
          _initializationError.value = error;
          AppLogger.warning(error);
          throw CameraOperationException(message: error);
        }

        _isInitialized.value = true;
        AppLogger.info('✅ All cameras initialized successfully');
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
           message: 'Back camera not initialized',
         );
       }

       AppLogger.info('Starting video recording to: $outputPath');

       // Start recording on back camera
       try {
         await _backController!.startVideoRecording();
         _backVideoPath = outputPath;
         AppLogger.info('✅ Back camera recording started');
       } catch (e) {
         AppLogger.error('Failed to start back camera recording: $e');
         throw RecordingException(
           message: 'Failed to start back camera recording: $e',
         );
       }

       // If front camera is available, start recording there too
       if (_frontController != null && _frontController!.value.isInitialized) {
         try {
           await _frontController!.startVideoRecording();
           _frontVideoPath = outputPath.replaceFirst('.mp4', '_front.mp4');
           AppLogger.info('✅ Front camera recording started: $_frontVideoPath');
         } catch (e) {
           AppLogger.warning('Could not start front camera recording: $e');
           // Don't fail the entire recording if front camera fails
         }
       } else {
         AppLogger.warning('Front camera not available for recording');
       }

       _isRecording.value = true;
       _isPaused.value = false;
       _recordingDuration.value = const Duration();
       _startDurationTimer();

       AppLogger.info('✅ Recording session started');
     } catch (e) {
       AppLogger.error('Failed to start recording', error: e);
       throw RecordingException(
         message: 'Failed to start recording: $e',
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

        AppLogger.info('Stopping recording...');

        // Stop recording on back camera
        if (_backController != null && _backController!.value.isRecordingVideo) {
          try {
            AppLogger.info('Stopping back camera recording...');
            backVideoFile = await _backController!.stopVideoRecording();
            AppLogger.info('✅ Back camera recording stopped: ${backVideoFile.path}');
            
            // Verify file exists and get size
            try {
              final file = File(backVideoFile.path);
              if (await file.exists()) {
                final fileSize = await file.length();
                AppLogger.info('✅ Video file verified - Size: ${fileSize / 1024 / 1024} MB');
              } else {
                AppLogger.warning('⚠ Video file does not exist at: ${backVideoFile.path}');
              }
            } catch (e) {
              AppLogger.warning('Could not verify video file: $e');
            }
          } catch (e) {
            AppLogger.error('Error stopping back camera: $e');
            throw RecordingException(
              message: 'Failed to stop back camera recording: $e',
            );
          }
        } else {
          AppLogger.warning('Back camera is not recording');
        }

        // Stop recording on front camera if it was recording
        if (_frontController != null && 
            _frontController!.value.isRecordingVideo && 
            _frontVideoPath != null) {
          try {
            AppLogger.info('Stopping front camera recording...');
            frontVideoFile = await _frontController!.stopVideoRecording();
            AppLogger.info('✅ Front camera recording stopped: ${frontVideoFile.path}');
          } catch (e) {
            AppLogger.warning('Error stopping front camera: $e');
            // Don't fail the entire operation if front camera fails
          }
        }

        _isRecording.value = false;
        _isPaused.value = false;
        _recordingDuration.value = const Duration();
        
        // Important: Clear these AFTER use
        _frontVideoPath = null;
        _backVideoPath = null;

        AppLogger.info('✅ Recording session stopped and state reset');
        return backVideoFile;
      } catch (e) {
        // Even on error, try to reset state
        _isRecording.value = false;
        _isPaused.value = false;
        _durationTimer?.cancel();
        _frontVideoPath = null;
        _backVideoPath = null;
        AppLogger.error('Failed to stop recording', error: e);
        throw RecordingException(
          message: 'Failed to stop recording: $e',
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
