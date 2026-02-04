import 'package:flutter/material.dart';
import '../theme/ocean_colors.dart';

/// Custom ocean-themed app bar with glassmorphic design
class OceanAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final bool showGradient;
  final bool showBlur;
  final double elevation;

  const OceanAppBar({
    super.key,
    required this.title,
    this.onBackPressed,
    this.actions,
    this.showGradient = true,
    this.showBlur = true,
    this.elevation = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: showGradient
            ? LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            OceanColors.deepSeaBlue,
            OceanColors.oceanBlue,
          ],
        )
            : null,
        color: showGradient ? null : OceanColors.deepSeaBlue,
        boxShadow: [
          if (elevation > 0)
            BoxShadow(
              color: OceanColors.deepSeaBlue.withAlpha((0.3 * 255).toInt()),
              blurRadius: elevation,
              offset: Offset(0, elevation / 2),
            ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (onBackPressed != null)
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  color: OceanColors.pearlWhite,
                  onPressed: onBackPressed,
                )
              else
                const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: OceanColors.pearlWhite,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (actions != null)
                Row(
                  children: actions!,
                )
              else
                const SizedBox(width: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
