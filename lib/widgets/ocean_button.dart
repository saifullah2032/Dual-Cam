import 'package:flutter/material.dart';
import '../theme/ocean_colors.dart';

/// Ocean-themed custom button with gradient background
class OceanButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String label;
  final IconData? icon;
  final bool isLoading;
  final bool isEnabled;
  final double? width;
  final double height;
  final ButtonVariant variant;

  const OceanButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.isLoading = false,
    this.isEnabled = true,
    this.width,
    this.height = 56,
    this.variant = ButtonVariant.primary,
  });

  @override
  State<OceanButton> createState() => _OceanButtonState();
}

class _OceanButtonState extends State<OceanButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPointerDown() {
    if (widget.isEnabled && !widget.isLoading) {
      _controller.forward();
    }
  }

  void _onPointerUp() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.width ?? double.infinity;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: MouseRegion(
        onEnter: (_) => _onPointerDown(),
        onExit: (_) => _onPointerUp(),
        child: GestureDetector(
          onTapDown: (_) => _onPointerDown(),
          onTapUp: (_) => _onPointerUp(),
          onTapCancel: _onPointerUp,
          onTap: widget.isEnabled && !widget.isLoading
              ? widget.onPressed
              : null,
          child: Container(
            width: width,
            height: widget.height,
            decoration: BoxDecoration(
              gradient: widget.variant == ButtonVariant.primary
                  ? OceanColors.buttonGradient
                  : null,
              color: widget.variant == ButtonVariant.secondary
                  ? OceanColors.pearlWhite
                  : null,
              borderRadius: BorderRadius.circular(12),
              border: widget.variant == ButtonVariant.secondary
                  ? Border.all(
                color: OceanColors.oceanBlue,
                width: 2,
              )
                  : null,
              boxShadow: [
                if (widget.isEnabled && !widget.isLoading)
                  BoxShadow(
                    color: (widget.variant == ButtonVariant.primary
                        ? OceanColors.accentTeal
                        : OceanColors.oceanBlue)
                        .withAlpha((0.3 * 255).toInt()),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Center(
              child: widget.isLoading
                  ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.variant == ButtonVariant.primary
                        ? OceanColors.pearlWhite
                        : OceanColors.oceanBlue,
                  ),
                ),
              )
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      color: widget.variant == ButtonVariant.primary
                          ? OceanColors.pearlWhite
                          : OceanColors.oceanBlue,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: widget.variant == ButtonVariant.primary
                          ? OceanColors.pearlWhite
                          : OceanColors.oceanBlue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum ButtonVariant {
  primary,
  secondary,
}
