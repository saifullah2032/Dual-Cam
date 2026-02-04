import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/settings_service.dart';
import '../theme/ocean_colors.dart';
import '../utils/logger.dart';

/// Settings screen for app configuration
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late SettingsService _settingsService;
  late VideoQuality _selectedQuality;
  late RecordingLayout _selectedLayout;
  late PiPPosition _selectedPosition;
  late bool _audioEnabled;
  late int _frameRate;

  @override
  void initState() {
    super.initState();
    _initializeSettings();
  }

  Future<void> _initializeSettings() async {
    try {
      if (!Get.isRegistered<SettingsService>()) {
        _settingsService = SettingsService();
        await _settingsService.init();
        Get.put(_settingsService);
      } else {
        _settingsService = Get.find<SettingsService>();
      }

      setState(() {
        _selectedQuality = _settingsService.getVideoQuality();
        _selectedLayout = _settingsService.getRecordingLayout();
        _selectedPosition = _settingsService.getPiPPosition();
        _audioEnabled = _settingsService.isAudioRecordingEnabled();
        _frameRate = _settingsService.getFrameRate();
      });
    } catch (e) {
      AppLogger.error('Failed to initialize settings', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle('Video Quality'),
          _buildQualitySettings(),
          const SizedBox(height: 24),
          _buildSectionTitle('Layout'),
          _buildLayoutSettings(),
          const SizedBox(height: 24),
          _buildSectionTitle('Picture in Picture'),
          _buildPiPSettings(),
          const SizedBox(height: 24),
          _buildSectionTitle('Audio'),
          _buildAudioSettings(),
          const SizedBox(height: 24),
          _buildSectionTitle('Frame Rate'),
          _buildFrameRateSettings(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: OceanColors.deepSeaBlue,
        ),
      ),
    );
  }

  Widget _buildQualitySettings() {
    return Card(
      child: Column(
        children: VideoQuality.values.map((quality) {
          return RadioListTile<VideoQuality>(
            title: Text(quality.label),
            value: quality,
            groupValue: _selectedQuality,
            onChanged: (value) async {
              if (value != null) {
                setState(() => _selectedQuality = value);
                await _settingsService.setVideoQuality(value);
              }
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLayoutSettings() {
    return Card(
      child: Column(
        children: RecordingLayout.values.map((layout) {
          return RadioListTile<RecordingLayout>(
            title: Text(layout.label),
            value: layout,
            groupValue: _selectedLayout,
            onChanged: (value) async {
              if (value != null) {
                setState(() => _selectedLayout = value);
                await _settingsService.setRecordingLayout(value);
              }
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPiPSettings() {
    return Card(
      child: Column(
        children: PiPPosition.values.map((position) {
          return RadioListTile<PiPPosition>(
            title: Text(position.label),
            value: position,
            groupValue: _selectedPosition,
            onChanged: (value) async {
              if (value != null) {
                setState(() => _selectedPosition = value);
                await _settingsService.setPiPPosition(value);
              }
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAudioSettings() {
    return Card(
      child: SwitchListTile(
        title: const Text('Record Audio'),
        subtitle: const Text('Include microphone audio in recordings'),
        value: _audioEnabled,
        onChanged: (value) async {
          setState(() => _audioEnabled = value);
          await _settingsService.setAudioRecording(value);
        },
      ),
    );
  }

  Widget _buildFrameRateSettings() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Frame Rate: $_frameRate fps',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Slider(
              value: _frameRate.toDouble(),
              min: 15,
              max: 60,
              divisions: 9,
              label: '$_frameRate fps',
              onChanged: (value) async {
                final newValue = value.toInt();
                setState(() => _frameRate = newValue);
                await _settingsService.setFrameRate(newValue);
              },
            ),
            Text(
              'Recommended: 30 fps for balance between quality and performance',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: OceanColors.mediumGray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
