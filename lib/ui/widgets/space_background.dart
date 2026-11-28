import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:shadowshift/core/constants.dart';
import 'package:shadowshift/domain/progression/catalog.dart';
import 'package:shadowshift/ui/widgets/split_gradient_background.dart';

class _Star {
  const _Star(this.x, this.y, this.radius, this.speed, this.color, this.alpha);

  final double x;
  final double y;
  final double radius;
  final double speed;
  final Color color;
  final double alpha;
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
  return _Star(x, y, radius, speed, base, alpha);
});

class StarPainter extends CustomPainter {
  StarPainter(this.progress, {
    required this.reducedMotion,
    this.skinId,
    this.effectId,
  });

  final double progress;
  final bool reducedMotion;
  final String? skinId;
  final String? effectId;

  static final Paint _paint = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    final offset = reducedMotion ? 0.0 : progress;
    // Equipped cosmetics tint the menu starfield too, so a purchase is visible
    // before starting a run. Unknown IDs fall back to the first catalogue item.
    final accent = skinId == null
        ? null
        : Catalog.find(Catalog.skins, skinId!).color;
    final tint = switch (effectId) {
      'void' => AppColors.pink,
      'blizzard' => const Color(0xFF9DEBFF),
      _ => null,
    };
    for (final star in _stars) {
      final y = ((star.y + offset * star.speed) % 1) * size.height;
      final base = tint ?? accent ?? star.color;
      final glitched = effectId == 'glitch' && star.radius > 1.5;
      _paint.color = glitched
          ? AppColors.pink.withValues(alpha: star.alpha)
          : base.withValues(alpha: star.alpha);
      canvas.drawCircle(Offset(star.x * size.width, y), star.radius, _paint);
    }
  }

  @override
  bool shouldRepaint(covariant StarPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.reducedMotion != reducedMotion ||
      oldDelegate.skinId != skinId ||
      oldDelegate.effectId != effectId;
}

class SpaceBackground extends StatefulWidget {
  const SpaceBackground({
    super.key,
    this.reducedMotion = false,
    this.skinId,
    this.effectId,
  });

  final bool reducedMotion;
  final String? skinId;
  final String? effectId;

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
          // Stars go in the foreground so the gradient behind them stays visible.
          foregroundPainter: StarPainter(
            _controller.value,
            reducedMotion: widget.reducedMotion,
            skinId: widget.skinId,
            effectId: widget.effectId,
          ),
          child: child,
        );
      },
      child: const SplitGradientBackground(),
    );
  }
}
