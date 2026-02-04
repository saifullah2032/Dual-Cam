import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/native_camera_service.dart';
import '../theme/ocean_colors.dart';
import '../utils/logger.dart';
import 'gallery_screen.dart';

/// Screen for recording from cameras using native Android Camera2 API
class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> with TickerProviderStateMixin {
  late NativeCameraService _cameraService;
  late AnimationController _pulseController;
  bool _isInitializing = true;
  String? _initError;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      setState(() {
        _isInitializing = true;
        _initError = null;
      });

      // Get or create native camera service
      if (!Get.isRegistered<NativeCameraService>()) {
        Get.put(NativeCameraService());
      }
      _cameraService = Get.find<NativeCameraService>();

      // Initialize and open cameras
      await _cameraService.initializeCameras();

      if (mounted) {
        setState(() {
          _isInitializing = false;
          _initError = _cameraService.errorMessage;
        });
      }
    } catch (e) {
      AppLogger.error('Failed to initialize camera', error: e);
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _initError = 'Failed to initialize camera: $e';
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: OceanColors.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: OceanColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _startRecording() async {
    try {
      await _cameraService.startRecording();
      _showSuccess('Recording started');
    } catch (e) {
      AppLogger.error('Failed to start recording', error: e);
      _showError('Failed to start recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final paths = await _cameraService.stopRecording();
      if (paths != null && paths['backVideo'] != null) {
        _showSuccess('Video saved to gallery!');
      } else {
        _showError('Failed to save video');
      }
    } catch (e) {
      AppLogger.error('Failed to stop recording', error: e);
      _showError('Failed to stop recording: $e');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final photos = await _cameraService.takePicture();
      if (photos != null && photos.isNotEmpty) {
        final count = photos.length;
        _showSuccess('$count photo(s) saved to gallery!');
      } else {
        _showError('Failed to capture photo');
      }
    } catch (e) {
      AppLogger.error('Failed to take photo', error: e);
      _showError('Failed to take photo: $e');
    }
  }

  void _showLayoutPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: OceanColors.deepSeaBlue,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildLayoutPicker(),
    );
  }

  Widget _buildLayoutPicker() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Preview Layout',
            style: TextStyle(
              color: OceanColors.pearlWhite,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Obx(() {
            final currentLayout = _cameraService.currentLayout;
            final isDualMode = _cameraService.isDualCameraMode;
            
            // Filter layouts based on dual mode availability
            final availableLayouts = isDualMode 
                ? PreviewLayout.values 
                : [PreviewLayout.singleBack, PreviewLayout.singleFront];

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: availableLayouts.map((layout) {
                final isSelected = currentLayout == layout;
                return InkWell(
                  onTap: () async {
                    await _cameraService.setLayout(layout);
                    if (mounted) Navigator.pop(context);
                  },
                  child: Container(
                    width: 100,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? OceanColors.aquamarine.withAlpha(50) 
                          : Colors.white10,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? OceanColors.aquamarine : Colors.white24,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _getLayoutIcon(layout, isSelected),
                        const SizedBox(height: 8),
                        Text(
                          layout.displayName,
                          style: TextStyle(
                            color: isSelected 
                                ? OceanColors.aquamarine 
                                : OceanColors.pearlWhite,
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _getLayoutIcon(PreviewLayout layout, bool isSelected) {
    final color = isSelected ? OceanColors.aquamarine : OceanColors.pearlWhite;
    
    switch (layout) {
      case PreviewLayout.sideBySideHorizontal:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 20, height: 30, color: color),
            const SizedBox(width: 4),
            Container(width: 20, height: 30, color: color.withAlpha(150)),
          ],
        );
      case PreviewLayout.sideBySideVertical:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 15, color: color),
            const SizedBox(height: 4),
            Container(width: 40, height: 15, color: color.withAlpha(150)),
          ],
        );
      case PreviewLayout.pipTopLeft:
        return Stack(
          children: [
            Container(width: 40, height: 30, color: color.withAlpha(150)),
            Positioned(
              top: 2,
              left: 2,
              child: Container(width: 12, height: 10, color: color),
            ),
          ],
        );
      case PreviewLayout.pipTopRight:
        return Stack(
          children: [
            Container(width: 40, height: 30, color: color.withAlpha(150)),
            Positioned(
              top: 2,
              right: 2,
              child: Container(width: 12, height: 10, color: color),
            ),
          ],
        );
      case PreviewLayout.pipBottomLeft:
        return Stack(
          children: [
            Container(width: 40, height: 30, color: color.withAlpha(150)),
            Positioned(
              bottom: 2,
              left: 2,
              child: Container(width: 12, height: 10, color: color),
            ),
          ],
        );
      case PreviewLayout.pipBottomRight:
        return Stack(
          children: [
            Container(width: 40, height: 30, color: color.withAlpha(150)),
            Positioned(
              bottom: 2,
              right: 2,
              child: Container(width: 12, height: 10, color: color),
            ),
          ],
        );
      case PreviewLayout.singleBack:
        return Icon(Icons.camera_rear, color: color, size: 30);
      case PreviewLayout.singleFront:
        return Icon(Icons.camera_front, color: color, size: 30);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OceanColors.deepSeaBlue,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Camera', style: TextStyle(color: OceanColors.pearlWhite)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: OceanColors.pearlWhite),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Layout picker button
          IconButton(
            icon: const Icon(Icons.grid_view, color: OceanColors.pearlWhite),
            onPressed: _cameraService.isRecording ? null : _showLayoutPicker,
            tooltip: 'Change Layout',
          ),
          // Swap cameras button
          Obx(() => IconButton(
            icon: Icon(
              Icons.swap_horiz,
              color: _cameraService.isDualCameraMode 
                  ? OceanColors.pearlWhite 
                  : Colors.white38,
            ),
            onPressed: _cameraService.isDualCameraMode && !_cameraService.isRecording
                ? () async {
                    await _cameraService.swapCameras();
                    _showSuccess('Cameras swapped');
                  }
                : null,
            tooltip: 'Swap Cameras',
          )),
          // Debug info button
          IconButton(
            icon: const Icon(Icons.info_outline, color: OceanColors.pearlWhite),
            onPressed: _showDebugInfo,
          ),
        ],
      ),
      body: _isInitializing ? _buildLoadingView() : _buildCameraView(),
    );
  }

  Future<void> _showDebugInfo() async {
    final cameraInfo = await _cameraService.getCameraInfo();
    final deviceInfo = await _cameraService.getDeviceInfo();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: OceanColors.deepSeaBlue,
        title: const Text('Debug Info', style: TextStyle(color: OceanColors.pearlWhite)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Device:', style: TextStyle(color: OceanColors.aquamarine, fontWeight: FontWeight.bold)),
              Text('${deviceInfo['manufacturer']} ${deviceInfo['model']}',
                  style: const TextStyle(color: OceanColors.pearlWhite)),
              Text('Android ${deviceInfo['release']} (API ${deviceInfo['androidVersion']})',
                  style: const TextStyle(color: OceanColors.pearlWhite)),
              const SizedBox(height: 16),
              const Text('Camera:', style: TextStyle(color: OceanColors.aquamarine, fontWeight: FontWeight.bold)),
              Text('Front: ${cameraInfo['frontCameraId']}',
                  style: const TextStyle(color: OceanColors.pearlWhite)),
              Text('Back: ${cameraInfo['backCameraId']}',
                  style: const TextStyle(color: OceanColors.pearlWhite)),
              Text('Dual Supported: ${cameraInfo['isDualCameraSupported']}',
                  style: TextStyle(
                    color: cameraInfo['isDualCameraSupported'] == true
                        ? OceanColors.success
                        : OceanColors.error,
                  )),
              const SizedBox(height: 16),
              const Text('Layout:', style: TextStyle(color: OceanColors.aquamarine, fontWeight: FontWeight.bold)),
              Text('Current: ${cameraInfo['currentLayout']}',
                  style: const TextStyle(color: OceanColors.pearlWhite)),
              Text('Swapped: ${cameraInfo['camerasSwapped']}',
                  style: const TextStyle(color: OceanColors.pearlWhite)),
              const SizedBox(height: 16),
              const Text('Texture IDs:', style: TextStyle(color: OceanColors.aquamarine, fontWeight: FontWeight.bold)),
              Text('Front: ${_cameraService.frontTextureId}',
                  style: const TextStyle(color: OceanColors.pearlWhite)),
              Text('Back: ${_cameraService.backTextureId}',
                  style: const TextStyle(color: OceanColors.pearlWhite)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: OceanColors.aquamarine)),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: OceanColors.aquamarine),
          SizedBox(height: 24),
          Text(
            'Initializing cameras...',
            style: TextStyle(color: OceanColors.pearlWhite, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    return Column(
      children: [
        Expanded(child: _buildPreviewArea()),
        _buildControlsArea(),
      ],
    );
  }

  Widget _buildPreviewArea() {
    return Obx(() {
      final frontTextureId = _cameraService.frontTextureId;
      final backTextureId = _cameraService.backTextureId;
      final isDualMode = _cameraService.isDualCameraMode;
      final errorMessage = _cameraService.errorMessage ?? _initError;
      final currentLayout = _cameraService.currentLayout;
      final camerasSwapped = _cameraService.camerasSwapped;

      // Show error if any
      if (errorMessage != null) {
        return _buildErrorView(errorMessage);
      }

      // Check if we have valid texture IDs
      final hasBackTexture = backTextureId != null && backTextureId >= 0;
      final hasFrontTexture = frontTextureId != null && frontTextureId >= 0;

      if (!hasBackTexture && !hasFrontTexture) {
        return _buildNoPreviewView();
      }

      // Determine which texture is primary/secondary based on swap state
      final primaryTextureId = camerasSwapped 
          ? (hasFrontTexture ? frontTextureId : backTextureId)
          : (hasBackTexture ? backTextureId : frontTextureId);
      final secondaryTextureId = camerasSwapped 
          ? (hasBackTexture ? backTextureId : frontTextureId)
          : (hasFrontTexture ? frontTextureId : backTextureId);
      final primaryLabel = camerasSwapped ? 'FRONT' : 'BACK';
      final secondaryLabel = camerasSwapped ? 'BACK' : 'FRONT';
      final hasSecondary = isDualMode && hasFrontTexture && hasBackTexture;

      // Build preview based on layout
      switch (currentLayout) {
        case PreviewLayout.sideBySideHorizontal:
          return _buildSideBySideHorizontal(
            primaryTextureId!, secondaryTextureId, 
            primaryLabel, secondaryLabel, hasSecondary
          );
        case PreviewLayout.sideBySideVertical:
          return _buildSideBySideVertical(
            primaryTextureId!, secondaryTextureId, 
            primaryLabel, secondaryLabel, hasSecondary
          );
        case PreviewLayout.pipTopLeft:
          return _buildPiP(
            primaryTextureId!, secondaryTextureId, 
            primaryLabel, secondaryLabel, hasSecondary, 
            Alignment.topLeft
          );
        case PreviewLayout.pipTopRight:
          return _buildPiP(
            primaryTextureId!, secondaryTextureId, 
            primaryLabel, secondaryLabel, hasSecondary, 
            Alignment.topRight
          );
        case PreviewLayout.pipBottomLeft:
          return _buildPiP(
            primaryTextureId!, secondaryTextureId, 
            primaryLabel, secondaryLabel, hasSecondary, 
            Alignment.bottomLeft
          );
        case PreviewLayout.pipBottomRight:
          return _buildPiP(
            primaryTextureId!, secondaryTextureId, 
            primaryLabel, secondaryLabel, hasSecondary, 
            Alignment.bottomRight
          );
        case PreviewLayout.singleBack:
          return _buildSinglePreview(
            hasBackTexture ? backTextureId! : frontTextureId!, 
            hasBackTexture ? 'BACK' : 'FRONT'
          );
        case PreviewLayout.singleFront:
          return _buildSinglePreview(
            hasFrontTexture ? frontTextureId! : backTextureId!, 
            hasFrontTexture ? 'FRONT' : 'BACK'
          );
      }
    });
  }

  Widget _buildErrorView(String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: OceanColors.error, size: 64),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              style: const TextStyle(color: OceanColors.pearlWhite),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _initializeCamera,
              style: ElevatedButton.styleFrom(
                backgroundColor: OceanColors.aquamarine,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoPreviewView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.videocam_off, color: OceanColors.pearlWhite, size: 64),
          SizedBox(height: 16),
          Text(
            'No camera preview available',
            style: TextStyle(color: OceanColors.pearlWhite),
          ),
        ],
      ),
    );
  }

  Widget _buildSideBySideHorizontal(
    int primaryId, int? secondaryId, 
    String primaryLabel, String secondaryLabel,
    bool hasSecondary
  ) {
    if (!hasSecondary || secondaryId == null) {
      return _buildSinglePreview(primaryId, primaryLabel);
    }

    return Row(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildTexturePreview(secondaryId),
              _buildCameraLabel(secondaryLabel, Alignment.topLeft),
            ],
          ),
        ),
        Container(width: 2, color: OceanColors.deepSeaBlue),
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildTexturePreview(primaryId),
              _buildCameraLabel(primaryLabel, Alignment.topRight),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSideBySideVertical(
    int primaryId, int? secondaryId, 
    String primaryLabel, String secondaryLabel,
    bool hasSecondary
  ) {
    if (!hasSecondary || secondaryId == null) {
      return _buildSinglePreview(primaryId, primaryLabel);
    }

    return Column(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildTexturePreview(primaryId),
              _buildCameraLabel(primaryLabel, Alignment.topRight),
            ],
          ),
        ),
        Container(height: 2, color: OceanColors.deepSeaBlue),
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildTexturePreview(secondaryId),
              _buildCameraLabel(secondaryLabel, Alignment.bottomRight),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPiP(
    int primaryId, int? secondaryId, 
    String primaryLabel, String secondaryLabel,
    bool hasSecondary,
    Alignment pipPosition
  ) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Main camera (full screen)
        _buildTexturePreview(primaryId),
        _buildCameraLabel(primaryLabel, Alignment.topLeft),
        
        // PiP camera (small overlay)
        if (hasSecondary && secondaryId != null)
          Positioned(
            top: pipPosition == Alignment.topLeft || pipPosition == Alignment.topRight ? 16 : null,
            bottom: pipPosition == Alignment.bottomLeft || pipPosition == Alignment.bottomRight ? 16 : null,
            left: pipPosition == Alignment.topLeft || pipPosition == Alignment.bottomLeft ? 16 : null,
            right: pipPosition == Alignment.topRight || pipPosition == Alignment.bottomRight ? 16 : null,
            child: GestureDetector(
              onTap: () async {
                await _cameraService.swapCameras();
              },
              child: Container(
                width: 120,
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: OceanColors.aquamarine, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(100),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Texture(textureId: secondaryId),
                      Positioned(
                        bottom: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            secondaryLabel,
                            style: const TextStyle(
                              color: OceanColors.aquamarine,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSinglePreview(int textureId, String label) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildTexturePreview(textureId),
        _buildCameraLabel(label, Alignment.topCenter),
        // Show mode indicator
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Single Camera Mode',
                style: TextStyle(color: OceanColors.pearlWhite, fontSize: 12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTexturePreview(int textureId) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Texture(textureId: textureId),
      ),
    );
  }

  Widget _buildCameraLabel(String label, Alignment alignment) {
    return Positioned(
      top: alignment.y < 0 ? 8 : null,
      bottom: alignment.y > 0 ? 8 : null,
      left: alignment.x < 0 ? 8 : (alignment.x == 0 ? 0 : null),
      right: alignment.x > 0 ? 8 : (alignment.x == 0 ? 0 : null),
      child: alignment.x == 0
          ? Center(child: _buildLabelContainer(label))
          : _buildLabelContainer(label),
    );
  }

  Widget _buildLabelContainer(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: OceanColors.aquamarine,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildControlsArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: const BoxDecoration(
        color: OceanColors.deepSeaBlue,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Obx(() {
        final isRecording = _cameraService.isRecording;
        final duration = _cameraService.recordingDuration;
        final isDualMode = _cameraService.isDualCameraMode;
        final currentLayout = _cameraService.currentLayout;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mode and layout indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDualMode ? OceanColors.success.withAlpha(50) : OceanColors.warning.withAlpha(50),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDualMode ? OceanColors.success : OceanColors.warning,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isDualMode ? Icons.check_circle : Icons.info,
                        color: isDualMode ? OceanColors.success : OceanColors.warning,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isDualMode ? 'Dual' : 'Single',
                        style: TextStyle(
                          color: isDualMode ? OceanColors.success : OceanColors.warning,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    currentLayout.displayName,
                    style: const TextStyle(
                      color: OceanColors.pearlWhite,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Recording status
            if (isRecording) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ScaleTransition(
                    scale: Tween(begin: 0.8, end: 1.0).animate(_pulseController),
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: OceanColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDuration(duration),
                    style: const TextStyle(
                      color: OceanColors.pearlWhite,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Control buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Photo button
                _buildControlButton(
                  icon: Icons.camera_alt,
                  label: 'Photo',
                  onPressed: isRecording ? null : _takePhoto,
                  color: OceanColors.aquamarine,
                ),

                // Record button
                _buildRecordButton(isRecording),

                // Gallery button
                _buildControlButton(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onPressed: isRecording
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const GalleryScreen()),
                          );
                        },
                  color: OceanColors.pearlWhite,
                ),
              ],
            ),
          ],
        );
      }),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    final isDisabled = onPressed == null;
    final displayColor = isDisabled ? color.withAlpha(77) : color;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(icon, color: displayColor, size: 28),
          style: IconButton.styleFrom(
            side: BorderSide(color: displayColor, width: 2),
            padding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: displayColor, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildRecordButton(bool isRecording) {
    return GestureDetector(
      onTap: isRecording ? _stopRecording : _startRecording,
      child: Container(
        width: 72,
        height: 72,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: OceanColors.pearlWhite, width: 3),
        ),
        child: Container(
          decoration: BoxDecoration(
            shape: isRecording ? BoxShape.rectangle : BoxShape.circle,
            borderRadius: isRecording ? BorderRadius.circular(8) : null,
            color: OceanColors.error,
          ),
          child: isRecording ? const Icon(Icons.stop, color: OceanColors.pearlWhite, size: 32) : null,
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
}
