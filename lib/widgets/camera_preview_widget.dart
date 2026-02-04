import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../theme/ocean_colors.dart';
import '../utils/logger.dart';

/// Widget to display camera preview
class CameraPreviewWidget extends StatefulWidget {
  final CameraController controller;
  final BoxFit fit;
  final Function(Exception)? onError;

  const CameraPreviewWidget({
    super.key,
    required this.controller,
    this.fit = BoxFit.cover,
    this.onError,
  });

  @override
  State<CameraPreviewWidget> createState() => _CameraPreviewWidgetState();
}

class _CameraPreviewWidgetState extends State<CameraPreviewWidget> {
  @override
  void initState() {
    super.initState();
    _initializePreview();
  }

  Future<void> _initializePreview() async {
    try {
      if (!widget.controller.value.isInitialized) {
        await widget.controller.initialize();
        if (mounted) {
          setState(() {});
        }
        AppLogger.info('Camera preview initialized');
      }
    } catch (e) {
      AppLogger.error('Failed to initialize camera preview', error: e);
      if (widget.onError != null) {
        widget.onError!(Exception('Failed to initialize camera: $e'));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.controller.value.isInitialized) {
      return Container(
        color: OceanColors.deepSeaBlue,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return SizedBox.expand(
      child: Stack(
        children: [
          // Camera preview
          CameraPreview(widget.controller),
          // Recording indicator overlay
          if (widget.controller.value.isRecordingVideo)
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: OceanColors.error.withAlpha((0.9 * 255).toInt()),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: OceanColors.pearlWhite,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'REC',
                      style: TextStyle(
                        color: OceanColors.pearlWhite,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
