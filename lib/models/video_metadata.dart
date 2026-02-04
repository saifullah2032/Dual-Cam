/// Model representing video metadata
class VideoMetadata {
  /// Video file path
  final String filePath;

  /// Video duration in milliseconds
  final Duration duration;

  /// Video resolution (e.g., "1920x1080")
  final String resolution;

  /// Video bitrate in kbps
  final int bitrate;

  /// Recording layout type ("pip" or "split_screen")
  final String layout;

  /// Recording date and time
  final DateTime recordingDate;

  /// File size in bytes
  final int fileSize;

  VideoMetadata({
    required this.filePath,
    required this.duration,
    required this.resolution,
    required this.bitrate,
    required this.layout,
    required this.recordingDate,
    required this.fileSize,
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'filePath': filePath,
      'duration': duration.inMilliseconds,
      'resolution': resolution,
      'bitrate': bitrate,
      'layout': layout,
      'recordingDate': recordingDate.toIso8601String(),
      'fileSize': fileSize,
    };
  }

  /// Create from JSON
  factory VideoMetadata.fromJson(Map<String, dynamic> json) {
    return VideoMetadata(
      filePath: json['filePath'] as String,
      duration: Duration(milliseconds: json['duration'] as int),
      resolution: json['resolution'] as String,
      bitrate: json['bitrate'] as int,
      layout: json['layout'] as String,
      recordingDate: DateTime.parse(json['recordingDate'] as String),
      fileSize: json['fileSize'] as int,
    );
  }

  @override
  String toString() {
    return 'VideoMetadata(filePath: $filePath, duration: $duration, resolution: $resolution)';
  }
}
