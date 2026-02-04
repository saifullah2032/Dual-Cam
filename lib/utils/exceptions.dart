/// Base exception for the application
class DualRecorderException implements Exception {
  final String message;
  final String? code;
  final dynamic originalException;

  DualRecorderException({
    required this.message,
    this.code,
    this.originalException,
  });

  @override
  String toString() => 'DualRecorderException: $message${code != null ? ' ($code)' : ''}';
}

/// Exception for camera-related errors
class CameraOperationException extends DualRecorderException {
  CameraOperationException({
    required String message,
    String? code,
    dynamic originalException,
  }) : super(
    message: message,
    code: code ?? 'CAMERA_ERROR',
    originalException: originalException,
  );
}

/// Exception when concurrent camera recording is not supported
class ConcurrentCameraNotSupportedException extends CameraOperationException {
  ConcurrentCameraNotSupportedException({
    String? message,
    dynamic originalException,
  }) : super(
    message: message ?? 'This device does not support concurrent camera recording',
    code: 'CONCURRENT_CAMERA_NOT_SUPPORTED',
    originalException: originalException,
  );
}

/// Exception for recording-related errors
class RecordingException extends DualRecorderException {
  RecordingException({
    required String message,
    String? code,
    dynamic originalException,
  }) : super(
    message: message,
    code: code ?? 'RECORDING_ERROR',
    originalException: originalException,
  );
}

/// Exception for file-related errors
class FileException extends DualRecorderException {
  FileException({
    required String message,
    String? code,
    dynamic originalException,
  }) : super(
    message: message,
    code: code ?? 'FILE_ERROR',
    originalException: originalException,
  );
}

/// Exception for permission-related errors
class PermissionException extends DualRecorderException {
  PermissionException({
    required String message,
    String? code,
    dynamic originalException,
  }) : super(
    message: message,
    code: code ?? 'PERMISSION_ERROR',
    originalException: originalException,
  );
}
