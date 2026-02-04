import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart' hide CameraException;
import 'package:get/get.dart';
import '../services/camera_capability_service.dart';
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

  /// Take pictures from both cameras
  Future<List<XFile>> takePicture() async {
    List<XFile> pictures = [];
    
    // Take picture from back camera
    if (_backController != null && _backController!.value.isInitialized) {
      try {
        final XFile pic = await _backController!.takePicture();
        pictures.add(pic);
        AppLogger.info('✅ Back camera picture taken: ${pic.path}');
      } catch (e) {
        AppLogger.error('Failed to take picture from back camera', error: e);
      }
    }

    // Take picture from front camera
    if (_frontController != null && _frontController!.value.isInitialized) {
      try {
        final XFile pic = await _frontController!.takePicture();
        pictures.add(pic);
        AppLogger.info('✅ Front camera picture taken: ${pic.path}');
      } catch (e) {
        AppLogger.error('Failed to take picture from front camera', error: e);
      }
    }

    if (pictures.isEmpty) {
      throw CameraOperationException(message: 'Failed to take any picture');
    }

    return pictures;
  }

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
      ResolutionPreset resolution = ResolutionPreset.medium, // Lower resolution for dual capture
      bool enableAudio = true,
    }) async {
      try {
        _initializationError.value = null;
        _isInitialized.value = false;
        
        // Dispose existing controllers first
        await dispose();

        if (_cameras == null || _cameras!.isEmpty) {
          _cameras = await availableCameras();
          if (_cameras == null || _cameras!.isEmpty) {
            throw CameraOperationException(message: 'No cameras available');
          }
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

        // Check for concurrent support from our service
        final supportsConcurrent = await CameraCapabilityService.hasConcurrentCameraSupport();
        AppLogger.info('Device concurrent support: $supportsConcurrent');

        if (supportsConcurrent) {
          // Attempt concurrent initialization with lower resolution to reduce bandwidth
          await _initializeDualCameras(backCamera, frontCamera, resolution, enableAudio);
        } else {
          // Fallback to single camera if concurrent is not supported
          AppLogger.warning('Concurrent cameras not supported. Falling back to back camera.');
          if (backCamera != null) {
            await _initializeSingleCamera(backCamera, resolution, enableAudio);
          } else if (frontCamera != null) {
            await _initializeSingleCamera(frontCamera, resolution, enableAudio);
          }
        }

        _isInitialized.value = true;
      } catch (e) {
        final errorMsg = 'Failed to initialize: $e';
        _initializationError.value = errorMsg;
        AppLogger.error(errorMsg);
        _isInitialized.value = true; // Still set to true so UI stops loading
      }
    }

    Future<void> _initializeDualCameras(
      CameraDescription? back, 
      CameraDescription? front, 
      ResolutionPreset res, 
      bool audio
    ) async {
      // Initialize back
      if (back != null) {
        try {
          AppLogger.info('Initializing back camera in dual mode...');
          _backController = CameraController(back, res, enableAudio: audio);
          await _backController!.initialize().timeout(const Duration(seconds: 5));
          AppLogger.info('✅ Back camera initialized');
        } catch (e) {
          AppLogger.error('Back camera init failed: $e');
          _backController = null;
        }
      }
      
      // Delay to allow hardware to settle
      await Future.delayed(const Duration(milliseconds: 500));

      // Initialize front
      if (front != null) {
        try {
          AppLogger.info('Initializing front camera in dual mode...');
          _frontController = CameraController(front, res, enableAudio: false);
          await _frontController!.initialize().timeout(const Duration(seconds: 5));
          AppLogger.info('✅ Front camera initialized');
        } catch (e) {
          AppLogger.warning('Front camera init failed (this is common if hardware doesn\'t support concurrent): $e');
          _frontController = null;
        }
      }
    }

    Future<void> _initializeSingleCamera(CameraDescription camera, ResolutionPreset res, bool audio) async {
      final controller = CameraController(camera, res, enableAudio: audio);
      await controller.initialize().timeout(const Duration(seconds: 5));
      if (camera.lensDirection == CameraLensDirection.back) {
        _backController = controller;
      } else {
        _frontController = controller;
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
            final tempFile = await _backController!.stopVideoRecording();
            AppLogger.info('✅ Back camera recording stopped temp: ${tempFile.path}');
            
            if (_backVideoPath != null) {
              await tempFile.saveTo(_backVideoPath!);
              backVideoFile = XFile(_backVideoPath!);
              AppLogger.info('✅ Back camera video saved to: $_backVideoPath');
            } else {
              backVideoFile = tempFile;
            }
            
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
            _frontController!.value.isRecordingVideo) {
          try {
            AppLogger.info('Stopping front camera recording...');
            final tempFile = await _frontController!.stopVideoRecording();
            AppLogger.info('✅ Front camera recording stopped temp: ${tempFile.path}');
            
            if (_frontVideoPath != null) {
              await tempFile.saveTo(_frontVideoPath!);
              frontVideoFile = XFile(_frontVideoPath!);
              AppLogger.info('✅ Front camera video saved to: $_frontVideoPath');
            } else {
              frontVideoFile = tempFile;
            }
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
