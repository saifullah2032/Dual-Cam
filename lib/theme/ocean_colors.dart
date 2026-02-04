import 'package:flutter/material.dart';

/// Ocean-inspired color palette for the application
class OceanColors {
  // Primary ocean colors
  static const Color deepSeaBlue = Color(0xFF001219);
  static const Color darkOceanBlue = Color(0xFF003d5c);
  static const Color oceanBlue = Color(0xFF0066cc);
  static const Color skyBlue = Color(0xFF3399ff);
  static const Color midnightBlue = Color(0xFF001529);
  static const Color abyssBlue = Color(0xFF002040);

  // Accent colors
  static const Color aquamarine = Color(0xFF9AD1D4);
  static const Color accentTeal = Color(0xFF48A597);
  static const Color vibrantTeal = Color(0xFF00B8D4);
  static const Color seafoamGreen = Color(0xFF20C997);
  static const Color coralPink = Color(0xFFFF6B6B);
  static const Color sunsetOrange = Color(0xFFFFE66D);
  
  // Creature colors for animations
  static const Color jellyfishPink = Color(0xFFFFB5E8);
  static const Color jellyfishLavender = Color(0xFFE0BBE4);
  static const Color fishGold = Color(0xFFFFD700);
  static const Color seaweedGreen = Color(0xFF2ECC71);
  static const Color bubbleBlue = Color(0xFFB5DEFF);

  // Neutral colors
  static const Color pearlWhite = Color(0xFFF5F5F5);
  static const Color lightGray = Color(0xFFE8E8E8);
  static const Color mediumGray = Color(0xFFB0B0B0);
  static const Color darkGray = Color(0xFF424242);
  static const Color sandBeige = Color(0xFFF5DEB3);

  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Semi-transparent overlays for glassmorphism
  static const Color glassBlack = Color(0x1A000000);
  static const Color glassWhite = Color(0x1AFFFFFF);
  static const Color glassBlueOverlay = Color(0x1A0066cc);
  static const Color glassTealOverlay = Color(0x2000B8D4);

  /// Get gradient from dark ocean blue to light aquamarine
  static LinearGradient oceanGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      darkOceanBlue,
      oceanBlue,
      aquamarine,
    ],
  );

  /// Deep ocean gradient for backgrounds
  static LinearGradient deepOceanGradient = const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      deepSeaBlue,
      midnightBlue,
      abyssBlue,
    ],
  );

  /// Get gradient for buttons
  static LinearGradient buttonGradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      accentTeal,
      vibrantTeal,
    ],
  );

  /// Get gradient for loading animations
  static LinearGradient waveGradient = const LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      deepSeaBlue,
      oceanBlue,
      aquamarine,
      oceanBlue,
      deepSeaBlue,
    ],
    stops: [0.0, 0.25, 0.5, 0.75, 1.0],
  );

  /// Sunset ocean gradient
  static LinearGradient sunsetGradient = const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFF6B6B),
      Color(0xFFFFE66D),
      oceanBlue,
      deepSeaBlue,
    ],
    stops: [0.0, 0.3, 0.6, 1.0],
  );

  /// Bubble effect gradient
  static RadialGradient bubbleGradient = const RadialGradient(
    colors: [
      Color(0x40FFFFFF),
      Color(0x10FFFFFF),
    ],
    stops: [0.3, 1.0],
  );
}
