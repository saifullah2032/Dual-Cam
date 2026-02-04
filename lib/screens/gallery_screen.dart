import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/file_storage_service.dart';
import '../theme/ocean_colors.dart';
import '../utils/logger.dart';
import '../widgets/ocean_app_bar.dart';
import '../widgets/glassmorphic_card.dart';
import 'video_player_screen.dart';

/// Screen for viewing recorded videos and captured photos
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  late Future<List<File>> _filesFuture;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  void _loadFiles() {
    _filesFuture = FileStorageService.getFiles();
  }

  Future<void> _deleteFile(String filePath) async {
    try {
      await FileStorageService.deleteRecording(filePath);
      setState(() {
        _loadFiles();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item deleted'),
            backgroundColor: OceanColors.success,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Failed to delete file', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OceanColors.deepSeaBlue,
      extendBodyBehindAppBar: true,
      appBar: OceanAppBar(
        title: 'Gallery',
        onBackPressed: () => Navigator.pop(context),
        showGradient: false,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [OceanColors.deepSeaBlue, Color(0xFF001529)],
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<List<File>>(
            future: _filesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: OceanColors.aquamarine),
                );
              }

              final files = snapshot.data ?? [];

              if (files.isEmpty) {
                return _buildEmptyState();
              }

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: files.length,
                itemBuilder: (context, index) => _buildFileCard(context, files[index]),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined, size: 80, color: Colors.white24),
          const SizedBox(height: 24),
          const Text(
            'Your gallery is empty',
            style: TextStyle(color: OceanColors.pearlWhite, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Captured media will appear here',
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildFileCard(BuildContext context, File file) {
    final isVideo = file.path.endsWith('.mp4');
    final stat = file.statSync();
    final modified = stat.modified;
    final formatter = DateFormat('MMM dd, HH:mm');
    final filename = file.path.split(Platform.pathSeparator).last;

    return GlassmorphicCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () {
          if (isVideo) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => VideoPlayerScreen(videoFile: file)),
            );
          } else {
            _showImagePreview(context, file);
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isVideo)
                      const Icon(Icons.play_circle_outline, color: OceanColors.aquamarine, size: 48)
                    else
                      const Icon(Icons.image_outlined, color: OceanColors.accentTeal, size: 48),
                    
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => _showDeleteConfirmation(context, file),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                          child: const Icon(Icons.delete_outline, color: OceanColors.error, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    filename,
                    style: const TextStyle(color: OceanColors.pearlWhite, fontSize: 12, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatter.format(modified),
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImagePreview(BuildContext context, File file) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(file),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
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
        backgroundColor: OceanColors.deepSeaBlue,
        title: const Text('Delete Item', style: TextStyle(color: OceanColors.pearlWhite)),
        content: const Text('Are you sure you want to delete this item?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteFile(file.path);
            },
            child: const Text('DELETE', style: TextStyle(color: OceanColors.error)),
          ),
        ],
      ),
    );
  }
}

