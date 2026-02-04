import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';

import '../providers/camera_provider.dart';
import '../services/permission_service.dart';
import '../services/recording_service.dart';
import '../theme/ocean_colors.dart';
import '../utils/logger.dart';
import '../widgets/glassmorphic_card.dart';
import '../widgets/ocean_button.dart';
import 'recording_screen.dart';
import 'gallery_screen.dart';

/// Home/Main screen displaying device capability status and navigation
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late RecordingService _recordingService;
  bool _permissionsGranted = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
    _initializeApp();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    AppLogger.info('Initializing app...');
    
    // Request permissions
    await _requestPermissions();
    
    // Initialize camera capabilities
    if (mounted) {
      final provider = context.read<CameraProvider>();
      await provider.initializeCameraCapabilities();
    }

    // Initialize recording service
    if (!Get.isRegistered<RecordingService>()) {
      Get.put(RecordingService());
    }
    _recordingService = Get.find<RecordingService>();

    // Initialize cameras after capabilities are checked
    if (mounted && _permissionsGranted) {
      _initializeCameras();
    }
  }

   Future<void> _requestPermissions() async {
     try {
       AppLogger.info('Checking permissions...');
       
       // Check if already granted
       final cameraGranted = await PermissionService.isCameraPermissionGranted();
       final storageGranted = await PermissionService.isStoragePermissionGranted();

       if (cameraGranted && storageGranted) {
         AppLogger.info('All permissions already granted');
         setState(() {
           _permissionsGranted = true;
         });
         return;
       }

       AppLogger.info('Requesting missing permissions...');
       final granted = await PermissionService.requestAllRecordingPermissions();
       
       if (mounted) {
         setState(() {
           _permissionsGranted = granted;
         });
       }

       if (!granted) {
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(
               content: Text('❌ Camera and storage permissions are required'),
               duration: Duration(seconds: 4),
               backgroundColor: OceanColors.error,
             ),
           );
         }
       }
     } catch (e) {
       AppLogger.error('Failed to request permissions', error: e);
     }
   }

  Future<void> _initializeCameras() async {
    try {
      AppLogger.info('Initializing cameras...');
      await _recordingService.initializeCameras(
        resolution: ResolutionPreset.high,
        enableAudio: true,
      );
      AppLogger.info('Cameras initialized successfully');
    } catch (e) {
      AppLogger.error('Failed to initialize cameras', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OceanColors.deepSeaBlue,
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  OceanColors.deepSeaBlue,
                  Color(0xFF001529),
                ],
              ),
            ),
          ),
          
          // Animated Bubbles or shapes could go here
          
          SafeArea(
            child: Consumer<CameraProvider>(
              builder: (context, cameraProvider, child) {
                if (cameraProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: OceanColors.aquamarine),
                  );
                }

                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 60),
                          _buildHeader(),
                          const SizedBox(height: 60),
                          
                          if (cameraProvider.capability != null)
                            _buildCapabilityCard(context, cameraProvider),
                          
                          if (cameraProvider.error != null)
                            _buildErrorCard(context, cameraProvider),
                          
                          const SizedBox(height: 40),
                          _buildActionButtons(context, cameraProvider),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: OceanColors.aquamarine.withOpacity(0.1),
            border: Border.all(color: OceanColors.aquamarine.withOpacity(0.3), width: 2),
          ),
          child: const Icon(
            Icons.camera_rounded,
            size: 64,
            color: OceanColors.aquamarine,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'DUAL RECORDER',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: OceanColors.pearlWhite,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Capture every perspective',
          style: TextStyle(
            fontSize: 16,
            color: OceanColors.pearlWhite.withOpacity(0.7),
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildCapabilityCard(BuildContext context, CameraProvider provider) {
    final capability = provider.capability!;
    final isSupported = capability.supportsConcurrent;

    return GlassmorphicCard(
      blur: 15,
      opacity: 0.1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isSupported ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                color: isSupported ? OceanColors.success : OceanColors.warning,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'Device Status',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: OceanColors.pearlWhite,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 24),
          _buildInfoRow('Model', capability.deviceModel),
          _buildInfoRow('Concurrent', isSupported ? 'Available' : 'Limited'),
          _buildInfoRow('Cameras Found', '${capability.availableCameras.length}'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          Text(value, style: const TextStyle(color: OceanColors.pearlWhite, fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, CameraProvider provider) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OceanColors.error.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: OceanColors.error.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            provider.error!,
            style: const TextStyle(color: OceanColors.pearlWhite, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: provider.clearError,
            child: const Text('DISMISS', style: TextStyle(color: OceanColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, CameraProvider provider) {
    return Column(
      children: [
        OceanButton(
          label: 'START CAMERA',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const RecordingScreen()),
            );
          },
          icon: Icons.videocam_rounded,
        ),
        const SizedBox(height: 20),
        OceanButton(
          label: 'VIEW GALLERY',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const GalleryScreen()),
            );
          },
          icon: Icons.photo_library_rounded,
          variant: ButtonVariant.secondary,
        ),
      ],
    );
  }
}

