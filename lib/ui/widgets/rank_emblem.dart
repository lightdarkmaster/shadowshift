import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadowshift/core/constants.dart';
import 'package:shadowshift/domain/progression/ranks.dart';
import 'package:shadowshift/state/app_providers.dart';

/// Reusable rank badge. Higher ranks get a subtle animated ray ring; the
/// animation is disabled when reduced motion is on.
class RankEmblem extends ConsumerWidget {
  const RankEmblem({
    super.key,
    required this.tier,
    this.size = 64,
    this.animate = true,
  });

  final RankTier tier;
  final double size;
  final bool animate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reducedMotion = ref.watch(settingsProvider).reducedMotion;
    return SizedBox(
      width: size,
      height: size,
      child: animate && tier.hasSpecialEffect && !reducedMotion
          ? _AnimatedEmblem(tier: tier, size: size)
          : CustomPaint(
              painter: _EmblemPainter(tier: tier, phase: 0),
              child: Center(
                child: Icon(tier.icon, color: tier.accentColor, size: size * 0.44),
              ),
            ),
    );
  }
}

class _AnimatedEmblem extends StatefulWidget {
  const _AnimatedEmblem({required this.tier, required this.size});

  final RankTier tier;
  final double size;

  @override
  State<_AnimatedEmblem> createState() => _AnimatedEmblemState();
}

class _AnimatedEmblemState extends State<_AnimatedEmblem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
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
      builder: (context, _) => CustomPaint(
        painter: _EmblemPainter(tier: widget.tier, phase: _controller.value),
        child: Center(
          child: Icon(
            widget.tier.icon,
            color: widget.tier.accentColor,
            size: widget.size * 0.44,
          ),
        ),
      ),
    );
  }
}

class _EmblemPainter extends CustomPainter {
  const _EmblemPainter({required this.tier, required this.phase});

  final RankTier tier;
  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = tier.color.withValues(alpha: 0.16)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawCircle(
      center,
      radius - 2,
      Paint()..color = AppColors.surfaceLight.withValues(alpha: 0.9),
    );
    canvas.drawCircle(
      center,
      radius - 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = tier.color
        ..strokeWidth = 2.2,
    );

    if (!tier.hasSpecialEffect) return;
    final spin = phase * math.pi * 2;
    for (var i = 0; i < 8; i++) {
      final angle = spin + i * math.pi / 4;
      final inner = radius * 0.88;
      final outer = radius * (0.96 + math.sin(phase * math.pi) * 0.06);
      canvas.drawLine(
        center + Offset(math.cos(angle) * inner, math.sin(angle) * inner),
        center + Offset(math.cos(angle) * outer, math.sin(angle) * outer),
        Paint()
          ..color = tier.accentColor.withValues(alpha: 0.75)
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _EmblemPainter oldDelegate) =>
      oldDelegate.tier != tier || oldDelegate.phase != phase;
}
