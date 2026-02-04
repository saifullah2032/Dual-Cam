import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/ocean_colors.dart';

/// Animated bubbles that float upward
class AnimatedBubbles extends StatefulWidget {
  final int bubbleCount;
  final double maxBubbleSize;
  final double minBubbleSize;

  const AnimatedBubbles({
    super.key,
    this.bubbleCount = 15,
    this.maxBubbleSize = 20,
    this.minBubbleSize = 6,
  });

  @override
  State<AnimatedBubbles> createState() => _AnimatedBubblesState();
}

class _AnimatedBubblesState extends State<AnimatedBubbles>
    with TickerProviderStateMixin {
  late List<BubbleData> bubbles;
  final Random random = Random();

  @override
  void initState() {
    super.initState();
    bubbles = List.generate(widget.bubbleCount, (_) => _createBubble());
  }

  BubbleData _createBubble() {
    final controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 3000 + random.nextInt(4000)),
    );

    final size = widget.minBubbleSize +
        random.nextDouble() * (widget.maxBubbleSize - widget.minBubbleSize);

    controller.repeat();

    return BubbleData(
      controller: controller,
      startX: random.nextDouble(),
      size: size,
      delay: random.nextDouble(),
      wobbleSpeed: 1 + random.nextDouble() * 2,
      wobbleAmount: 10 + random.nextDouble() * 20,
    );
  }

  @override
  void dispose() {
    for (var bubble in bubbles) {
      bubble.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: bubbles.map((bubble) {
        return AnimatedBuilder(
          animation: bubble.controller,
          builder: (context, child) {
            final progress = (bubble.controller.value + bubble.delay) % 1.0;
            final y = 1.0 - progress;
            final wobble = sin(progress * bubble.wobbleSpeed * 2 * pi) *
                bubble.wobbleAmount;

            return Positioned(
              left: MediaQuery.of(context).size.width * bubble.startX +
                  wobble -
                  bubble.size / 2,
              bottom: MediaQuery.of(context).size.height * y - bubble.size,
              child: Opacity(
                opacity: (1 - progress) * 0.6,
                child: Container(
                  width: bubble.size,
                  height: bubble.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        OceanColors.aquamarine.withOpacity(0.4),
                        OceanColors.aquamarine.withOpacity(0.1),
                      ],
                      stops: const [0.3, 1.0],
                    ),
                    border: Border.all(
                      color: OceanColors.aquamarine.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }
}

class BubbleData {
  final AnimationController controller;
  final double startX;
  final double size;
  final double delay;
  final double wobbleSpeed;
  final double wobbleAmount;

  BubbleData({
    required this.controller,
    required this.startX,
    required this.size,
    required this.delay,
    required this.wobbleSpeed,
    required this.wobbleAmount,
  });
}

/// Animated fish swimming across the screen
class SwimmingFish extends StatefulWidget {
  final int fishCount;
  final bool reverse;

  const SwimmingFish({
    super.key,
    this.fishCount = 3,
    this.reverse = false,
  });

  @override
  State<SwimmingFish> createState() => _SwimmingFishState();
}

class _SwimmingFishState extends State<SwimmingFish>
    with TickerProviderStateMixin {
  late List<FishData> fishes;
  final Random random = Random();

  @override
  void initState() {
    super.initState();
    fishes = List.generate(widget.fishCount, (_) => _createFish());
  }

  FishData _createFish() {
    final controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 8000 + random.nextInt(6000)),
    );

    controller.repeat();

    return FishData(
      controller: controller,
      startY: 0.1 + random.nextDouble() * 0.7,
      size: 20 + random.nextDouble() * 25,
      delay: random.nextDouble(),
      color: _getRandomFishColor(),
      wobbleSpeed: 2 + random.nextDouble() * 3,
    );
  }

  Color _getRandomFishColor() {
    final colors = [
      OceanColors.aquamarine,
      OceanColors.vibrantTeal,
      OceanColors.seafoamGreen,
      OceanColors.skyBlue,
      const Color(0xFFFF6B6B), // Coral
      const Color(0xFFFFE66D), // Yellow fish
    ];
    return colors[random.nextInt(colors.length)];
  }

  @override
  void dispose() {
    for (var fish in fishes) {
      fish.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: fishes.map((fish) {
        return AnimatedBuilder(
          animation: fish.controller,
          builder: (context, child) {
            final progress = (fish.controller.value + fish.delay) % 1.0;
            double x;
            if (widget.reverse) {
              x = 1.0 - progress;
            } else {
              x = progress;
            }
            final wobble =
                sin(progress * fish.wobbleSpeed * 2 * pi) * 15;

            return Positioned(
              left: widget.reverse
                  ? MediaQuery.of(context).size.width * x - fish.size
                  : MediaQuery.of(context).size.width * x - fish.size / 2,
              top: MediaQuery.of(context).size.height * fish.startY + wobble,
              child: Opacity(
                opacity: 0.7,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..scale(widget.reverse ? -1.0 : 1.0, 1.0),
                  child: CustomPaint(
                    size: Size(fish.size, fish.size * 0.6),
                    painter: FishPainter(color: fish.color),
                  ),
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }
}

class FishData {
  final AnimationController controller;
  final double startY;
  final double size;
  final double delay;
  final Color color;
  final double wobbleSpeed;

  FishData({
    required this.controller,
    required this.startY,
    required this.size,
    required this.delay,
    required this.color,
    required this.wobbleSpeed,
  });
}

class FishPainter extends CustomPainter {
  final Color color;

  FishPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    // Fish body (ellipse)
    path.addOval(Rect.fromLTWH(
      size.width * 0.2,
      size.height * 0.15,
      size.width * 0.6,
      size.height * 0.7,
    ));

    // Tail
    path.moveTo(size.width * 0.1, size.height * 0.5);
    path.lineTo(0, size.height * 0.1);
    path.lineTo(0, size.height * 0.9);
    path.close();

    canvas.drawPath(path, paint);

    // Eye
    final eyePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width * 0.65, size.height * 0.4),
      size.width * 0.08,
      eyePaint,
    );

    final pupilPaint = Paint()
      ..color = OceanColors.deepSeaBlue
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width * 0.67, size.height * 0.4),
      size.width * 0.04,
      pupilPaint,
    );

    // Fin
    final finPath = Path();
    finPath.moveTo(size.width * 0.5, size.height * 0.15);
    finPath.quadraticBezierTo(
      size.width * 0.55,
      -size.height * 0.1,
      size.width * 0.4,
      size.height * 0.25,
    );
    canvas.drawPath(
        finPath, paint..color = color.withOpacity(0.8));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Animated jellyfish floating
class FloatingJellyfish extends StatefulWidget {
  final int count;

  const FloatingJellyfish({super.key, this.count = 2});

  @override
  State<FloatingJellyfish> createState() => _FloatingJellyfishState();
}

class _FloatingJellyfishState extends State<FloatingJellyfish>
    with TickerProviderStateMixin {
  late List<JellyfishData> jellyfish;
  final Random random = Random();

  @override
  void initState() {
    super.initState();
    jellyfish = List.generate(widget.count, (_) => _createJellyfish());
  }

  JellyfishData _createJellyfish() {
    final moveController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 12000 + random.nextInt(8000)),
    );

    final pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    moveController.repeat();
    pulseController.repeat(reverse: true);

    return JellyfishData(
      moveController: moveController,
      pulseController: pulseController,
      startX: 0.1 + random.nextDouble() * 0.8,
      size: 40 + random.nextDouble() * 30,
      delay: random.nextDouble(),
      color: _getRandomJellyfishColor(),
    );
  }

  Color _getRandomJellyfishColor() {
    final colors = [
      const Color(0xFFE0BBE4), // Lavender
      const Color(0xFFFFB5E8), // Pink
      OceanColors.aquamarine,
      const Color(0xFFB5DEFF), // Light blue
    ];
    return colors[random.nextInt(colors.length)];
  }

  @override
  void dispose() {
    for (var j in jellyfish) {
      j.moveController.dispose();
      j.pulseController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: jellyfish.map((j) {
        return AnimatedBuilder(
          animation: Listenable.merge([j.moveController, j.pulseController]),
          builder: (context, child) {
            final moveProgress = (j.moveController.value + j.delay) % 1.0;
            final y = 0.9 - moveProgress * 0.8;
            final wobble = sin(moveProgress * 4 * pi) * 20;
            final pulse = 0.9 + j.pulseController.value * 0.2;

            return Positioned(
              left: MediaQuery.of(context).size.width * j.startX +
                  wobble -
                  j.size / 2,
              top: MediaQuery.of(context).size.height * y,
              child: Opacity(
                opacity: 0.6,
                child: Transform.scale(
                  scale: pulse,
                  child: CustomPaint(
                    size: Size(j.size, j.size * 1.5),
                    painter: JellyfishPainter(
                      color: j.color,
                      pulseValue: j.pulseController.value,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }
}

class JellyfishData {
  final AnimationController moveController;
  final AnimationController pulseController;
  final double startX;
  final double size;
  final double delay;
  final Color color;

  JellyfishData({
    required this.moveController,
    required this.pulseController,
    required this.startX,
    required this.size,
    required this.delay,
    required this.color,
  });
}

class JellyfishPainter extends CustomPainter {
  final Color color;
  final double pulseValue;

  JellyfishPainter({required this.color, required this.pulseValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    // Bell/dome
    final bellPath = Path();
    bellPath.moveTo(0, size.height * 0.35);
    bellPath.quadraticBezierTo(
      size.width * 0.5,
      -size.height * 0.1,
      size.width,
      size.height * 0.35,
    );
    bellPath.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.45,
      0,
      size.height * 0.35,
    );
    canvas.drawPath(bellPath, paint);

    // Tentacles
    final tentaclePaint = Paint()
      ..color = color.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i < 5; i++) {
      final startX = size.width * (0.15 + i * 0.175);
      final tentaclePath = Path();
      tentaclePath.moveTo(startX, size.height * 0.35);

      final wave = sin(pulseValue * pi + i * 0.5) * 8;
      tentaclePath.quadraticBezierTo(
        startX + wave,
        size.height * 0.6,
        startX - wave * 0.5,
        size.height * (0.8 + i * 0.03),
      );
      canvas.drawPath(tentaclePath, tentaclePaint);
    }
  }

  @override
  bool shouldRepaint(covariant JellyfishPainter oldDelegate) =>
      pulseValue != oldDelegate.pulseValue;
}

/// Animated ocean waves at the bottom or top of screen
class OceanWaves extends StatefulWidget {
  final bool isTop;
  final double height;
  final Color? color;

  const OceanWaves({
    super.key,
    this.isTop = false,
    this.height = 100,
    this.color,
  });

  @override
  State<OceanWaves> createState() => _OceanWavesState();
}

class _OceanWavesState extends State<OceanWaves>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(MediaQuery.of(context).size.width, widget.height),
          painter: WavePainter(
            animationValue: _controller.value,
            isTop: widget.isTop,
            color: widget.color ?? OceanColors.oceanBlue,
          ),
        );
      },
    );
  }
}

class WavePainter extends CustomPainter {
  final double animationValue;
  final bool isTop;
  final Color color;

  WavePainter({
    required this.animationValue,
    required this.isTop,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // First wave (darker, background)
    _drawWave(
      canvas,
      size,
      color.withOpacity(0.3),
      animationValue,
      20,
      0.4,
    );

    // Second wave (medium)
    _drawWave(
      canvas,
      size,
      color.withOpacity(0.5),
      animationValue + 0.33,
      25,
      0.6,
    );

    // Third wave (lighter, foreground)
    _drawWave(
      canvas,
      size,
      color.withOpacity(0.7),
      animationValue + 0.66,
      30,
      0.8,
    );
  }

  void _drawWave(
    Canvas canvas,
    Size size,
    Color waveColor,
    double phase,
    double amplitude,
    double heightFactor,
  ) {
    final paint = Paint()
      ..color = waveColor
      ..style = PaintingStyle.fill;

    final path = Path();

    if (isTop) {
      path.moveTo(0, 0);
      for (double x = 0; x <= size.width; x++) {
        final y = amplitude *
                sin((x / size.width * 2 * pi) + (phase * 2 * pi)) +
            size.height * heightFactor;
        path.lineTo(x, y);
      }
      path.lineTo(size.width, 0);
      path.close();
    } else {
      path.moveTo(0, size.height);
      for (double x = 0; x <= size.width; x++) {
        final y = size.height -
            (amplitude *
                    sin((x / size.width * 2 * pi) + (phase * 2 * pi)) +
                size.height * heightFactor);
        path.lineTo(x, y);
      }
      path.lineTo(size.width, size.height);
      path.close();
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) =>
      animationValue != oldDelegate.animationValue;
}

/// Combined ocean background with all animations
class OceanAnimatedBackground extends StatelessWidget {
  final bool showBubbles;
  final bool showFish;
  final bool showJellyfish;
  final bool showWaves;
  final Widget? child;

  const OceanAnimatedBackground({
    super.key,
    this.showBubbles = true,
    this.showFish = true,
    this.showJellyfish = true,
    this.showWaves = true,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                OceanColors.deepSeaBlue,
                Color(0xFF001529),
                Color(0xFF002040),
              ],
            ),
          ),
        ),

        // Ocean waves at bottom
        if (showWaves)
          const Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: OceanWaves(height: 120),
          ),

        // Bubbles
        if (showBubbles) const AnimatedBubbles(bubbleCount: 12),

        // Swimming fish (both directions)
        if (showFish) ...[
          const SwimmingFish(fishCount: 2),
          const SwimmingFish(fishCount: 2, reverse: true),
        ],

        // Jellyfish
        if (showJellyfish) const FloatingJellyfish(count: 2),

        // Child content
        if (child != null) child!,
      ],
    );
  }
}

/// Seaweed animation for decorative purposes
class AnimatedSeaweed extends StatefulWidget {
  final double height;
  final Color color;

  const AnimatedSeaweed({
    super.key,
    this.height = 100,
    this.color = OceanColors.seafoamGreen,
  });

  @override
  State<AnimatedSeaweed> createState() => _AnimatedSeaweedState();
}

class _AnimatedSeaweedState extends State<AnimatedSeaweed>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(30, widget.height),
          painter: SeaweedPainter(
            animationValue: _controller.value,
            color: widget.color,
          ),
        );
      },
    );
  }
}

class SeaweedPainter extends CustomPainter {
  final double animationValue;
  final Color color;

  SeaweedPainter({required this.animationValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final sway = sin(animationValue * pi) * 10;

    path.moveTo(size.width / 2, size.height);

    // Create wavy seaweed
    for (double y = size.height; y > 0; y -= 10) {
      final progress = 1 - (y / size.height);
      final x = size.width / 2 + sin(progress * 3 * pi + animationValue * pi) * (10 + sway * progress);
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant SeaweedPainter oldDelegate) =>
      animationValue != oldDelegate.animationValue;
}
