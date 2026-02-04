import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';

import 'theme/ocean_theme.dart';
import 'providers/camera_provider.dart';
import 'screens/home_screen.dart';
import 'utils/logger.dart';

void main() async {
  // Initialize logging
  AppLogger.info('App starting...');

  runApp(const DualRecorderApp());
}

class DualRecorderApp extends StatelessWidget {
  const DualRecorderApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CameraProvider()),
      ],
      child: GetMaterialApp(
        title: 'Dual Recorder',
        debugShowCheckedModeBanner: false,
        theme: OceanTheme.lightTheme,
        darkTheme: OceanTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
      ),
    );
  }
}
