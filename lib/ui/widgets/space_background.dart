import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shadowshift/core/constants.dart';

class _Star {
  const _Star(this.x, this.y, this.radius, this.speed, this.color);

  final double x;
  final double y;
  final double radius;
  final double speed;
  final Color color;
}

// Stars are deterministic, so generate and colour them once instead of once
// per animation tick (the old painter rebuilt all 64 on every frame).
final List<_Star> _stars = List<_Star>.generate(64, (i) {
  final random = math.Random(i * 7919 + 13);
  final x = random.nextDouble();
  final y = random.nextDouble();
  final radius = 0.6 + random.nextDouble() * 1.9;
  final speed = 0.25 + random.nextDouble() * 0.85;
  final alpha = 0.18 + random.nextDouble() * 0.62;
  final base = radius > 1.6 ? AppColors.violet : AppColors.cyan;
  return _Star(x, y, radius, speed, base.withValues(alpha: alpha));
});

class StarPainter extends CustomPainter {
  StarPainter(this.progress, {required this.reducedMotion});

  final double progress;
  final bool reducedMotion;

  static final Paint _paint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    final offset = reducedMotion ? 0.0 : progress;
    for (final star in _stars) {
      final y = ((star.y + offset * star.speed) % 1) * size.height;
      _paint.color = star.color;
      canvas.drawCircle(Offset(star.x * size.width, y), star.radius, _paint);
    }
  }

  @override
  bool shouldRepaint(covariant StarPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.reducedMotion != reducedMotion;
}

class SpaceBackground extends StatefulWidget {
  const SpaceBackground({super.key, this.reducedMotion = false});

  final bool reducedMotion;

  @override
  State<SpaceBackground> createState() => _SpaceBackgroundState();
}

class _SpaceBackgroundState extends State<SpaceBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    );
    if (!widget.reducedMotion) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant SpaceBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reducedMotion == widget.reducedMotion) return;
    if (widget.reducedMotion) {
      _controller.stop();
    } else {
      _controller.repeat();
    }
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
          painter: StarPainter(
            _controller.value,
            reducedMotion: widget.reducedMotion,
          ),
          child: child,
        );
      },
      child: const DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.2, -0.35),
            radius: 1.15,
            colors: [Color(0xFF142044), Color(0xFF080B1B), Color(0xFF04050D)],
          ),
        ),
      ),
    );
  }
}
