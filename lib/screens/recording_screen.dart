import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/native_camera_service.dart';
import '../theme/ocean_colors.dart';
import '../utils/logger.dart';
import '../widgets/ocean_animations.dart';

/// Screen for recording from cameras using native Android Camera2 API
class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> with TickerProviderStateMixin {
  late NativeCameraService _cameraService;
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late AnimationController _glowController;
  bool _isInitializing = true;
  String? _initError;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _waveController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
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
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: OceanColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: OceanColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
      if (paths != null && paths.isNotEmpty) {
        final hasValidPath = paths['composedVideo'] != null || 
                             paths['backVideo'] != null || 
                             paths['frontVideo'] != null;
        if (hasValidPath) {
          _showSuccess('Video saved successfully!');
        } else {
          _showError('Failed to save video');
        }
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
        final hasValidPath = photos['composedPhoto'] != null || 
                             photos['backPhoto'] != null || 
                             photos['frontPhoto'] != null;
        if (hasValidPath) {
          _showSuccess('Photo saved successfully!');
        } else {
          _showError('Failed to save photo');
        }
      } else {
        _showError('Failed to save photo');
      }
    } catch (e) {
      AppLogger.error('Failed to take photo', error: e);
      _showError('Failed to take photo: $e');
    }
  }

  void _showLayoutPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildLayoutPicker(),
    );
  }

  Widget _buildLayoutPicker() {
    return Container(
      decoration: BoxDecoration(
        color: OceanColors.deepSeaBlue,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: OceanColors.aquamarine.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: OceanColors.aquamarine.withOpacity(0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: OceanColors.aquamarine.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.grid_view,
                        color: OceanColors.aquamarine,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Preview Layout',
                      style: TextStyle(
                        color: OceanColors.pearlWhite,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
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
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 100,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? LinearGradient(
                                    colors: [
                                      OceanColors.aquamarine.withOpacity(0.3),
                                      OceanColors.vibrantTeal.withOpacity(0.1),
                                    ],
                                  )
                                : null,
                            color: isSelected ? null : Colors.white10,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? OceanColors.aquamarine : Colors.white24,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: OceanColors.aquamarine.withOpacity(0.3),
                                      blurRadius: 8,
                                    ),
                                  ]
                                : null,
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
          ),
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
            Container(width: 20, height: 30, decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            )),
            const SizedBox(width: 4),
            Container(width: 20, height: 30, decoration: BoxDecoration(
              color: color.withAlpha(150),
              borderRadius: BorderRadius.circular(4),
            )),
          ],
        );
      case PreviewLayout.sideBySideVertical:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 15, decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            )),
            const SizedBox(height: 4),
            Container(width: 40, height: 15, decoration: BoxDecoration(
              color: color.withAlpha(150),
              borderRadius: BorderRadius.circular(4),
            )),
          ],
        );
      case PreviewLayout.pipTopLeft:
        return Stack(
          children: [
            Container(width: 40, height: 30, decoration: BoxDecoration(
              color: color.withAlpha(150),
              borderRadius: BorderRadius.circular(4),
            )),
            Positioned(
              top: 2,
              left: 2,
              child: Container(width: 12, height: 10, decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              )),
            ),
          ],
        );
      case PreviewLayout.pipTopRight:
        return Stack(
          children: [
            Container(width: 40, height: 30, decoration: BoxDecoration(
              color: color.withAlpha(150),
              borderRadius: BorderRadius.circular(4),
            )),
            Positioned(
              top: 2,
              right: 2,
              child: Container(width: 12, height: 10, decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              )),
            ),
          ],
        );
      case PreviewLayout.pipBottomLeft:
        return Stack(
          children: [
            Container(width: 40, height: 30, decoration: BoxDecoration(
              color: color.withAlpha(150),
              borderRadius: BorderRadius.circular(4),
            )),
            Positioned(
              bottom: 2,
              left: 2,
              child: Container(width: 12, height: 10, decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              )),
            ),
          ],
        );
      case PreviewLayout.pipBottomRight:
        return Stack(
          children: [
            Container(width: 40, height: 30, decoration: BoxDecoration(
              color: color.withAlpha(150),
              borderRadius: BorderRadius.circular(4),
            )),
            Positioned(
              bottom: 2,
              right: 2,
              child: Container(width: 12, height: 10, decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              )),
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                OceanColors.deepSeaBlue.withOpacity(0.8),
                Colors.transparent,
              ],
            ),
          ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _glowController,
              builder: (context, child) {
                return Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: OceanColors.aquamarine.withOpacity(0.3 + _glowController.value * 0.2),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.videocam,
                    color: OceanColors.aquamarine,
                    size: 20,
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            const Text('Camera', style: TextStyle(color: OceanColors.pearlWhite, fontWeight: FontWeight.w600)),
          ],
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back, color: OceanColors.pearlWhite, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Layout picker button
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.grid_view, color: OceanColors.pearlWhite, size: 20),
            ),
            onPressed: _cameraService.isRecording ? null : _showLayoutPicker,
            tooltip: 'Change Layout',
          ),
          // Swap cameras button
          Obx(() => IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.swap_horiz,
                color: _cameraService.isDualCameraMode 
                    ? OceanColors.pearlWhite 
                    : Colors.white38,
                size: 20,
              ),
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
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.info_outline, color: OceanColors.pearlWhite, size: 20),
            ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: OceanColors.aquamarine.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.info, color: OceanColors.aquamarine, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Debug Info', style: TextStyle(color: OceanColors.pearlWhite)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDebugSection('Device', [
                '${deviceInfo['manufacturer']} ${deviceInfo['model']}',
                'Android ${deviceInfo['release']} (API ${deviceInfo['androidVersion']})',
              ]),
              const SizedBox(height: 16),
              _buildDebugSection('Camera', [
                'Front: ${cameraInfo['frontCameraId']}',
                'Back: ${cameraInfo['backCameraId']}',
              ]),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    cameraInfo['isDualCameraSupported'] == true
                        ? Icons.check_circle
                        : Icons.cancel,
                    color: cameraInfo['isDualCameraSupported'] == true
                        ? OceanColors.success
                        : OceanColors.error,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Dual Camera: ${cameraInfo['isDualCameraSupported']}',
                    style: TextStyle(
                      color: cameraInfo['isDualCameraSupported'] == true
                          ? OceanColors.success
                          : OceanColors.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDebugSection('Layout', [
                'Current: ${cameraInfo['currentLayout']}',
                'Swapped: ${cameraInfo['camerasSwapped']}',
              ]),
              const SizedBox(height: 16),
              _buildDebugSection('Texture IDs', [
                'Front: ${_cameraService.frontTextureId}',
                'Back: ${_cameraService.backTextureId}',
              ]),
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

  Widget _buildDebugSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: OceanColors.aquamarine,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(left: 8, top: 2),
          child: Text(
            item,
            style: const TextStyle(color: OceanColors.pearlWhite, fontSize: 13),
          ),
        )),
      ],
    );
  }

  Widget _buildLoadingView() {
    return Stack(
      children: [
        // Animated ocean background
        const OceanAnimatedBackground(
          showBubbles: true,
          showFish: false,
          showJellyfish: true,
          showWaves: true,
        ),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated loading indicator
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: OceanColors.aquamarine.withOpacity(0.1),
                      boxShadow: [
                        BoxShadow(
                          color: OceanColors.aquamarine.withOpacity(0.2 + _pulseController.value * 0.2),
                          blurRadius: 20 + _pulseController.value * 10,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const CircularProgressIndicator(
                      color: OceanColors.aquamarine,
                      strokeWidth: 3,
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Initializing cameras...',
                style: TextStyle(
                  color: OceanColors.pearlWhite.withOpacity(0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please wait',
                style: TextStyle(
                  color: OceanColors.aquamarine.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
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
    return Stack(
      children: [
        const OceanAnimatedBackground(
          showBubbles: true,
          showFish: false,
          showJellyfish: false,
          showWaves: true,
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: OceanColors.error.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.error_outline, color: OceanColors.error, size: 48),
                ),
                const SizedBox(height: 16),
                Text(
                  errorMessage,
                  style: const TextStyle(color: OceanColors.pearlWhite),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _initializeCamera,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: OceanColors.aquamarine,
                    foregroundColor: OceanColors.deepSeaBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNoPreviewView() {
    return Stack(
      children: [
        const OceanAnimatedBackground(
          showBubbles: true,
          showFish: true,
          showJellyfish: false,
          showWaves: true,
        ),
        const Center(
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
        ),
      ],
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
            top: pipPosition == Alignment.topLeft || pipPosition == Alignment.topRight ? 80 : null,
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
                      color: OceanColors.aquamarine.withOpacity(0.3),
                      blurRadius: 12,
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
                border: Border.all(color: OceanColors.aquamarine.withOpacity(0.3)),
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
      top: alignment.y < 0 ? 80 : null,
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
        border: Border.all(color: OceanColors.aquamarine.withOpacity(0.3)),
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            OceanColors.deepSeaBlue.withOpacity(0.9),
            OceanColors.deepSeaBlue,
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: OceanColors.aquamarine.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
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
                _buildModeChip(
                  isDualMode ? 'Dual' : 'Single',
                  isDualMode ? Icons.check_circle : Icons.info,
                  isDualMode ? OceanColors.success : OceanColors.warning,
                ),
                const SizedBox(width: 8),
                _buildModeChip(
                  currentLayout.displayName,
                  Icons.grid_view,
                  OceanColors.aquamarine,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Recording status
            if (isRecording) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: OceanColors.error,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: OceanColors.error.withOpacity(0.5 + _pulseController.value * 0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      );
                    },
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

                // Placeholder for symmetry (removed gallery button)
                _buildControlButton(
                  icon: Icons.settings,
                  label: 'Settings',
                  onPressed: isRecording ? null : _showLayoutPicker,
                  color: OceanColors.pearlWhite,
                ),
              ],
            ),
          ],
        );
      }),
    );
  }

  Widget _buildModeChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
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
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(30),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: displayColor, width: 2),
                boxShadow: !isDisabled
                    ? [
                        BoxShadow(
                          color: displayColor.withOpacity(0.2),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
              child: Icon(icon, color: displayColor, size: 24),
            ),
          ),
        ),
        const SizedBox(height: 6),
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
      child: AnimatedBuilder(
        animation: _glowController,
        builder: (context, child) {
          return Container(
            width: 76,
            height: 76,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: OceanColors.pearlWhite, width: 3),
              boxShadow: isRecording
                  ? [
                      BoxShadow(
                        color: OceanColors.error.withOpacity(0.4 + _glowController.value * 0.2),
                        blurRadius: 16,
                        spreadRadius: 4,
                      ),
                    ]
                  : null,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                shape: isRecording ? BoxShape.rectangle : BoxShape.circle,
                borderRadius: isRecording ? BorderRadius.circular(8) : null,
                color: OceanColors.error,
              ),
              child: isRecording
                  ? const Icon(Icons.stop, color: OceanColors.pearlWhite, size: 32)
                  : null,
            ),
          );
        },
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
    _waveController.dispose();
    _glowController.dispose();
    super.dispose();
  }
}
