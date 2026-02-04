import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';

/// Service for managing app configuration and settings
class SettingsService {
  static const String _keyVideoQuality = 'video_quality';
  static const String _keyRecordingLayout = 'recording_layout';
  static const String _keyAudioRecording = 'audio_recording_enabled';
  static const String _keyPiPPosition = 'pip_position';
  static const String _keyFrameRate = 'frame_rate';
  static const String _keyBitrate = 'bitrate';

  late SharedPreferences _prefs;

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      AppLogger.info('SettingsService initialized');
    } catch (e) {
      AppLogger.error('Failed to initialize SettingsService', error: e);
      rethrow;
    }
  }

  // Video Quality Settings
  Future<void> setVideoQuality(VideoQuality quality) async {
    await _prefs.setString(_keyVideoQuality, quality.value);
    AppLogger.info('Video quality set to: ${quality.label}');
  }

  VideoQuality getVideoQuality() {
    final value = _prefs.getString(_keyVideoQuality) ?? '1080p';
    return VideoQuality.fromValue(value);
  }

  // Recording Layout Settings
  Future<void> setRecordingLayout(RecordingLayout layout) async {
    await _prefs.setString(_keyRecordingLayout, layout.value);
    AppLogger.info('Recording layout set to: ${layout.label}');
  }

  RecordingLayout getRecordingLayout() {
    final value = _prefs.getString(_keyRecordingLayout) ?? 'pip';
    return RecordingLayout.fromValue(value);
  }

  // Audio Recording Settings
  Future<void> setAudioRecording(bool enabled) async {
    await _prefs.setBool(_keyAudioRecording, enabled);
    AppLogger.info('Audio recording: ${enabled ? 'enabled' : 'disabled'}');
  }

  bool isAudioRecordingEnabled() {
    return _prefs.getBool(_keyAudioRecording) ?? true;
  }

  // PiP Position Settings
  Future<void> setPiPPosition(PiPPosition position) async {
    await _prefs.setString(_keyPiPPosition, position.value);
    AppLogger.info('PiP position set to: ${position.label}');
  }

  PiPPosition getPiPPosition() {
    final value = _prefs.getString(_keyPiPPosition) ?? 'bottom_right';
    return PiPPosition.fromValue(value);
  }

  // Frame Rate Settings
  Future<void> setFrameRate(int frameRate) async {
    await _prefs.setInt(_keyFrameRate, frameRate);
    AppLogger.info('Frame rate set to: $frameRate fps');
  }

  int getFrameRate() {
    return _prefs.getInt(_keyFrameRate) ?? 30;
  }

  // Bitrate Settings
  Future<void> setBitrate(int bitrate) async {
    await _prefs.setInt(_keyBitrate, bitrate);
    AppLogger.info('Bitrate set to: $bitrate kbps');
  }

  int getBitrate() {
    return _prefs.getInt(_keyBitrate) ?? 5000;
  }
}

enum VideoQuality {
  p480('480p', '480p'),
  p720('720p', '720p'),
  p1080('1080p', '1080p'),
  p2160('2160p', '2160p');

  final String value;
  final String label;

  const VideoQuality(this.value, this.label);

  factory VideoQuality.fromValue(String value) {
    return VideoQuality.values.firstWhere(
      (q) => q.value == value,
      orElse: () => VideoQuality.p1080,
    );
  }
}

enum RecordingLayout {
  pip('pip', 'Picture in Picture'),
  splitScreen('split_screen', 'Split Screen');

  final String value;
  final String label;

  const RecordingLayout(this.value, this.label);

  factory RecordingLayout.fromValue(String value) {
    return RecordingLayout.values.firstWhere(
      (l) => l.value == value,
      orElse: () => RecordingLayout.pip,
    );
  }
}

enum PiPPosition {
  topLeft('top_left', 'Top Left'),
  topRight('top_right', 'Top Right'),
  bottomLeft('bottom_left', 'Bottom Left'),
  bottomRight('bottom_right', 'Bottom Right');

  final String value;
  final String label;

  const PiPPosition(this.value, this.label);

  factory PiPPosition.fromValue(String value) {
    return PiPPosition.values.firstWhere(
      (p) => p.value == value,
      orElse: () => PiPPosition.bottomRight,
    );
  }
}
