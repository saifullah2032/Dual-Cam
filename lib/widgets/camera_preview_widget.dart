import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../theme/ocean_colors.dart';

/// Widget to display camera preview with error handling
class CameraPreviewWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    // Check if controller is initialized
    if (!controller.value.isInitialized) {
      return Container(
        color: OceanColors.deepSeaBlue,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: OceanColors.aquamarine),
              SizedBox(height: 16),
              Text(
                'Initializing camera...',
                style: TextStyle(color: OceanColors.pearlWhite),
              ),
            ],
          ),
        ),
      );
    }

    // Check for errors
    if (controller.value.hasError) {
      return Container(
        color: OceanColors.deepSeaBlue,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: OceanColors.error, size: 48),
              const SizedBox(height: 16),
              Text(
                'Camera Error',
                style: const TextStyle(color: OceanColors.error, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                controller.value.errorDescription ?? 'Unknown error',
                style: const TextStyle(color: OceanColors.pearlWhite, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.center,
        child: FittedBox(
          fit: fit,
          child: SizedBox(
            width: controller.value.previewSize?.height ?? 480,
            height: controller.value.previewSize?.width ?? 640,
            child: CameraPreview(controller),
          ),
        ),
      ),
    );
  }
}
