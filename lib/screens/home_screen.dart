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
import '../widgets/ocean_animations.dart';
import 'recording_screen.dart';

/// Home/Main screen displaying device capability status and navigation
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late RecordingService _recordingService;
  bool _permissionsGranted = false;
  late AnimationController _fadeController;
  late AnimationController _floatController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
    _initializeApp();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _floatController.dispose();
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
               content: Text('Camera and storage permissions are required'),
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
          // Animated Ocean Background with creatures
          const OceanAnimatedBackground(
            showBubbles: true,
            showFish: true,
            showJellyfish: true,
            showWaves: true,
          ),

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
    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -_floatAnimation.value),
          child: Column(
            children: [
              // Animated camera icon with glow effect
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: OceanColors.aquamarine.withOpacity(0.1),
                  border: Border.all(
                    color: OceanColors.aquamarine.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: OceanColors.aquamarine.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      OceanColors.aquamarine,
                      OceanColors.vibrantTeal,
                    ],
                  ).createShader(bounds),
                  child: const Icon(
                    Icons.camera_rounded,
                    size: 64,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Title with gradient
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [
                    OceanColors.pearlWhite,
                    OceanColors.aquamarine,
                  ],
                ).createShader(bounds),
                child: const Text(
                  'DUAL RECORDER',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 4,
                  ),
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
              const SizedBox(height: 4),
              // Decorative wave line
              SizedBox(
                width: 100,
                height: 20,
                child: CustomPaint(
                  painter: _WaveLinePainter(
                    color: OceanColors.aquamarine.withOpacity(0.5),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isSupported ? OceanColors.success : OceanColors.warning)
                      .withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isSupported ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                  color: isSupported ? OceanColors.success : OceanColors.warning,
                  size: 24,
                ),
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
          _buildInfoRow('Model', capability.deviceModel, Icons.phone_android),
          _buildInfoRow(
            'Concurrent',
            isSupported ? 'Available' : 'Limited',
            isSupported ? Icons.check : Icons.warning_amber,
            valueColor: isSupported ? OceanColors.success : OceanColors.warning,
          ),
          _buildInfoRow(
            'Cameras Found',
            '${capability.availableCameras.length}',
            Icons.camera_alt,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: OceanColors.aquamarine.withOpacity(0.7)),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? OceanColors.pearlWhite,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
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
      ],
    );
  }
}

/// Custom painter for decorative wave line
class _WaveLinePainter extends CustomPainter {
  final Color color;

  _WaveLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height / 2);

    for (double x = 0; x <= size.width; x += 1) {
      final y = size.height / 2 +
          (size.height / 4) * 
          (x / size.width < 0.5 
            ? (x / size.width) * 2 
            : 2 - (x / size.width) * 2) *
          (0.5 + 0.5 * (1 - (2 * (x / size.width) - 1).abs()));
      path.lineTo(x, size.height / 2 + 
          8 * (0.5 - (x / size.width - 0.5).abs()) * 
          (x % 20 < 10 ? 1 : -1));
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
