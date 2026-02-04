import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/file_storage_service.dart';
import '../theme/ocean_colors.dart';
import '../utils/logger.dart';

/// Screen for viewing recorded videos
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({Key? key}) : super(key: key);

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  late Future<List<File>> _recordingsFuture;

  @override
  void initState() {
    super.initState();
    _loadRecordings();
  }

  void _loadRecordings() {
    _recordingsFuture = FileStorageService.getRecordings();
  }

  Future<void> _deleteRecording(String filePath) async {
    try {
      await FileStorageService.deleteRecording(filePath);
      setState(() {
        _loadRecordings();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recording deleted')),
        );
      }
    } catch (e) {
      AppLogger.error('Failed to delete recording', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallery'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<File>>(
        future: _recordingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final recordings = snapshot.data ?? [];

          if (recordings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.videocam_off,
                    size: 48,
                    color: OceanColors.mediumGray,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No recordings yet',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start recording to see your videos here',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: recordings.length,
            itemBuilder: (context, index) {
              final file = recordings[index];
              return _buildRecordingTile(context, file);
            },
          );
        },
      ),
    );
  }

  Widget _buildRecordingTile(BuildContext context, File file) {
    final stat = file.statSync();
    final size = stat.size / (1024 * 1024); // Convert to MB
    final modified = stat.modified;
    final formatter = DateFormat('yyyy-MM-dd HH:mm');
    final filename = file.path.split('/').last;

    return Card(
      child: ListTile(
        leading: Icon(
          Icons.video_library,
          color: OceanColors.accentTeal,
        ),
        title: Text(filename),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${formatter.format(modified)} • ${size.toStringAsFixed(2)} MB',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.play_arrow),
                  SizedBox(width: 8),
                  Text('Play'),
                ],
              ),
              onTap: () {
                // TODO: Implement video playback
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Video playback coming soon'),
                  ),
                );
              },
            ),
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.share),
                  SizedBox(width: 8),
                  Text('Share'),
                ],
              ),
              onTap: () {
                // TODO: Implement sharing
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sharing feature coming soon'),
                  ),
                );
              },
            ),
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.delete, color: OceanColors.error),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: OceanColors.error)),
                ],
              ),
              onTap: () {
                _showDeleteConfirmation(context, file);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, File file) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recording'),
        content: const Text('Are you sure you want to delete this recording?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteRecording(file.path);
            },
            style: TextButton.styleFrom(
              foregroundColor: OceanColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
