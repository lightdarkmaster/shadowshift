import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadowshift/core/constants.dart';
import 'package:shadowshift/domain/progression/ranks.dart';
import 'package:shadowshift/domain/services/audio_service.dart';
import 'package:shadowshift/state/app_providers.dart';
import 'package:shadowshift/ui/widgets/design.dart';
import 'package:shadowshift/ui/widgets/rank_emblem.dart';

/// Animated congratulation dialog shown after a run report when the player
/// crossed one or more rank thresholds. One dialog is shown per new rank so a
/// large XP jump never skips a celebration.
class RankUpDialog extends ConsumerStatefulWidget {
  const RankUpDialog({
    super.key,
    required this.promotion,
    required this.index,
    required this.total,
    required this.playerName,
  });

  final RankPromotion promotion;
  final int index;
  final int total;
  final String playerName;

  @override
  ConsumerState<RankUpDialog> createState() => _RankUpDialogState();
}

class _RankUpDialogState extends ConsumerState<RankUpDialog>
    with TickerProviderStateMixin {
  late final AnimationController _entry;
  late final AnimationController _glow;
  late final Animation<Offset> _slide;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    final reducedMotion = ref.read(settingsProvider).reducedMotion;
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    final curved = CurvedAnimation(parent: _entry, curve: Curves.easeOutBack);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.22),
      end: Offset.zero,
    ).animate(curved);
    _scale = Tween<double>(begin: 0.78, end: 1).animate(curved);

    if (reducedMotion) {
      _entry.value = 1;
      _glow.value = 0;
    } else {
      _entry.forward();
      _glow.repeat(reverse: true);
    }
    unawaited(AudioService.instance.rankUp());
  }

  @override
  void dispose() {
    _entry.dispose();
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tier = widget.promotion.toTier;
    final previous = widget.promotion.fromTier;
    final isLast = widget.index == widget.total - 1;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: FadeTransition(
          opacity: _entry,
          child: SlideTransition(
            position: _slide,
            child: ScaleTransition(
              scale: _scale,
              child: GlassCard(
                borderColor: tier.color.withValues(alpha: 0.72),
                padding: const EdgeInsets.all(AppLayout.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.total > 1)
                      Text(
                        'RANK UP ${widget.index + 1} / ${widget.total}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                        ),
                      ),
                    Text(
                      'CONGRATULATIONS!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: tier.accentColor,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.2,
                        shadows: [Shadow(color: tier.color, blurRadius: 14)],
                      ),
                    ),
                    const SizedBox(height: AppLayout.md),
                    SizedBox(
                      height: 112,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: _glow,
                            builder: (context, _) => CustomPaint(
                              size: const Size(112, 112),
                              painter: _RankGlowPainter(
                                tier: tier,
                                progress: _glow.value,
                              ),
                            ),
                          ),
                          RankEmblem(tier: tier, size: 96, animate: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppLayout.sm),
                    const Text(
                      'YOU OBTAINED THE RANK',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tier.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: tier.color,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'from ${previous.name}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: AppLayout.md),
                    Text(
                      'You obtained the ${tier.name} rank!\n'
                      'Keep moving forward, ${widget.playerName}.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppLayout.lg),
                    NeonButton(
                      label: isLast ? 'CONTINUE' : 'NEXT RANK',
                      icon: Icons.arrow_forward,
                      color: tier.color,
                      compact: true,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Soft pulsing ring and orbiting sparks around the new rank logo.
class _RankGlowPainter extends CustomPainter {
  const _RankGlowPainter({required this.tier, required this.progress});

  final RankTier tier;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final pulse = 0.5 + 0.5 * math.sin(progress * math.pi * 2);

    canvas.drawCircle(
      center,
      radius * (0.72 + pulse * 0.12),
      Paint()
        ..color = tier.color.withValues(alpha: 0.10 + pulse * 0.14)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    for (var i = 0; i < 10; i++) {
      final angle = (i / 10) * math.pi * 2 + progress * 0.35;
      final distance = radius * (0.82 + pulse * 0.08);
      final dot = center + Offset(
        math.cos(angle) * distance,
        math.sin(angle) * distance,
      );
      canvas.drawCircle(
        dot,
        2 + pulse * 1.6,
        Paint()
          ..color = tier.accentColor.withValues(alpha: 0.35 + pulse * 0.5),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RankGlowPainter oldDelegate) =>
      oldDelegate.tier != tier || oldDelegate.progress != progress;
}
