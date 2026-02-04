import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../theme/ocean_colors.dart';

/// A glassmorphic card widget with blur effect and semi-transparent background
class GlassmorphicCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final BorderRadius borderRadius;
  final Color backgroundColor;

  const GlassmorphicCard({
    super.key,
    required this.child,
    this.blur = 10,
    this.opacity = 0.1,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.all(0),
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.backgroundColor = OceanColors.glassWhite,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor.withAlpha((opacity * 255).toInt()),
              borderRadius: borderRadius,
              border: Border.all(
                color: OceanColors.pearlWhite.withAlpha((0.2 * 255).toInt()),
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
