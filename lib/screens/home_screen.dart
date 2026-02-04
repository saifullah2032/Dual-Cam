import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/camera_provider.dart';
import '../theme/ocean_colors.dart';
import '../utils/logger.dart';
import 'recording_screen.dart';
import 'gallery_screen.dart';

/// Home/Main screen displaying device capability status and navigation
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    AppLogger.info('Initializing camera capabilities...');
    if (mounted) {
      final provider = context.read<CameraProvider>();
      await provider.initializeCameraCapabilities();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dual Recorder'),
      ),
      body: Consumer<CameraProvider>(
        builder: (context, cameraProvider, child) {
          if (cameraProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  // Header
                  _buildHeader(),
                  const SizedBox(height: 32),

                  // Camera capability status card
                  if (cameraProvider.capability != null) ...[
                    _buildCapabilityCard(context, cameraProvider),
                    const SizedBox(height: 24),
                  ],

                  // Error message
                  if (cameraProvider.error != null) ...[
                    _buildErrorCard(context, cameraProvider),
                    const SizedBox(height: 24),
                  ],

                  // Start recording button
                  _buildStartButton(context, cameraProvider),
                  const SizedBox(height: 16),

                  // Settings button
                  _buildSettingsButton(context),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Icon(
          Icons.videocam,
          size: 48,
          color: OceanColors.accentTeal,
        ),
        const SizedBox(height: 16),
        Text(
          'Dual Camera Recorder',
          style: Theme.of(context).textTheme.displaySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Record from both cameras simultaneously',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCapabilityCard(
    BuildContext context,
    CameraProvider provider,
  ) {
    final capability = provider.capability!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  capability.supportsConcurrent
                      ? Icons.check_circle
                      : Icons.info,
                  color: capability.supportsConcurrent
                      ? OceanColors.success
                      : OceanColors.warning,
                ),
                const SizedBox(width: 12),
                Text(
                  'Device Capability',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildCapabilityItem(
              'Device Model',
              capability.deviceModel,
            ),
            const SizedBox(height: 8),
            _buildCapabilityItem(
              'Concurrent Recording',
              capability.supportsConcurrent ? 'Supported' : 'Not Supported',
            ),
            const SizedBox(height: 8),
            _buildCapabilityItem(
              'Available Cameras',
              '${capability.availableCameras.length}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapabilityItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorCard(BuildContext context, CameraProvider provider) {
    return Card(
      color: OceanColors.error.withAlpha((0.1 * 255).toInt()),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.error,
                  color: OceanColors.error,
                ),
                const SizedBox(width: 12),
                Text(
                  'Error',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: OceanColors.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              provider.error ?? 'Unknown error',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: provider.clearError,
              style: ElevatedButton.styleFrom(
                backgroundColor: OceanColors.error,
              ),
              child: const Text('Dismiss'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartButton(BuildContext context, CameraProvider provider) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: provider.supportsConcurrentRecording ||
                provider.capability != null
            ? () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const RecordingScreen(),
            ),
          );
        }
            : null,
        icon: const Icon(Icons.videocam),
        label: const Text('Start Recording'),
      ),
    );
  }

  Widget _buildSettingsButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const GalleryScreen(),
            ),
          );
        },
        icon: const Icon(Icons.photo_library),
        label: const Text('Gallery'),
      ),
    );
  }
}
