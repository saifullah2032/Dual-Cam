/// Model representing camera capabilities of the device
class CameraCapability {
  /// Whether the device supports concurrent camera recording
  final bool supportsConcurrent;

  /// List of available camera IDs
  final List<String> availableCameras;

  /// Device model name
  final String deviceModel;

  /// Creation timestamp
  final DateTime detectedAt;

  CameraCapability({
    required this.supportsConcurrent,
    required this.availableCameras,
    required this.deviceModel,
    DateTime? detectedAt,
  }) : detectedAt = detectedAt ?? DateTime.now();

  @override
  String toString() {
    return 'CameraCapability(supportsConcurrent: $supportsConcurrent, '
        'availableCameras: $availableCameras, deviceModel: $deviceModel)';
  }
}
