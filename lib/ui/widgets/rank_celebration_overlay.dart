import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadowshift/core/constants.dart';
import 'package:shadowshift/domain/progression/ranks.dart';
import 'package:shadowshift/domain/services/audio_service.dart';
import 'package:shadowshift/state/app_providers.dart';
import 'package:shadowshift/state/rank_providers.dart';
import 'package:shadowshift/ui/widgets/design.dart';
import 'package:shadowshift/ui/widgets/rank_emblem.dart';

/// Global, one-shot celebration. It consumes queued promotions and never
/// modifies profile state, so duplicates cannot be replayed after a restart.
class RankCelebrationOverlay extends ConsumerStatefulWidget {
  const RankCelebrationOverlay({super.key});

  @override
  ConsumerState<RankCelebrationOverlay> createState() =>
      _RankCelebrationOverlayState();
}

class _RankCelebrationOverlayState extends ConsumerState<RankCelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _dismissTimer;
  RankPromotion? _current;
  bool _scheduled = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) _scheduleDismiss();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _showNextIfNeeded();
  }

  @override
  void didUpdateWidget(covariant RankCelebrationOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _showNextIfNeeded();
  }

  void _showNextIfNeeded() {
    if (_current != null || !mounted) return;
    final next = ref.read(pendingRankUpsProvider.notifier).peek();
    if (next == null) return;
    setState(() => _current = next);
    AudioService.instance.rankUp();
    final reducedMotion = ref.read(settingsProvider).reducedMotion;
    if (reducedMotion) {
      _controller.value = 1;
      _scheduleDismiss(const Duration(milliseconds: 1200));
    } else {
      _controller.forward(from: 0);
    }
  }

  void _scheduleDismiss([Duration delay = const Duration(milliseconds: 600)]) {
    _dismissTimer?.cancel();
    _dismissTimer = Timer(delay, () {
      if (!mounted) return;
      ref.read(pendingRankUpsProvider.notifier).dismiss();
      _dismissTimer = null;
      setState(() => _current = null);
      _controller.reset();
      _showNextIfNeeded();
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watching the queue lets a promotion earned on another screen appear
    // immediately without passing callbacks through every route. Riverpod
    // rebuilds this widget without calling didUpdateWidget, so schedule the
    // hand-off after the frame instead of calling setState during build.
    final queue = ref.watch(pendingRankUpsProvider);
    if (_current == null && queue.isNotEmpty && !_scheduled) {
      _scheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _scheduled = false;
        _showNextIfNeeded();
      });
    }
    final promotion = _current;
    if (promotion == null) return const IgnorePointer(child: SizedBox.shrink());

    final tier = promotion.toTier;
    final previous = promotion.fromTier;
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final progress = Curves.easeOutCubic.transform(_controller.value);
          return Container(
            color: AppColors.background.withValues(alpha: 0.72 * progress),
            alignment: Alignment.center,
            child: FadeTransition(
              opacity: _controller,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.12),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _controller,
                  curve: const Interval(0, 0.6, curve: Curves.easeOutBack),
                )),
                child: FractionallySizedBox(
                  widthFactor: 0.92,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: GlassCard(
                      borderColor: tier.color.withValues(alpha: 0.7),
                      padding: const EdgeInsets.all(AppLayout.lg),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(double.infinity, 260),
                            painter: _CelebrationPainter(
                              color: tier.color,
                              accent: tier.accentColor,
                              progress: progress,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'RANK UP!',
                                style: TextStyle(
                                  color: tier.color,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 5,
                                  shadows: [
                                    Shadow(color: tier.color, blurRadius: 18),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppLayout.md),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  RankEmblem(tier: previous, size: 58, animate: false),
                                  const SizedBox(width: AppLayout.md),
                                  Icon(Icons.arrow_forward,
                                      color: tier.accentColor, size: 22),
                                  const SizedBox(width: AppLayout.md),
                                  RankEmblem(tier: tier, size: 72),
                                ],
                              ),
                              const SizedBox(height: AppLayout.sm),
                              Text(
                                previous.name,
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 11,
                                  letterSpacing: 1.6,
                                ),
                              ),
                              Text(
                                tier.name,
                                style: TextStyle(
                                  color: tier.color,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2.4,
                                ),
                              ),
                              const SizedBox(height: AppLayout.md),
                              Text(
                                'You have evolved from ${previous.name} to ${tier.name}!',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Your journey through the darkness continues.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.muted,
                                ),
                              ),
                              if (tier.rewardId.isNotEmpty) ...[
                                const SizedBox(height: AppLayout.sm),
                                Text(
                                  'UNLOCKED: ${RankConfig.rewardName(tier.rewardId)}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: tier.accentColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CelebrationPainter extends CustomPainter {
  const _CelebrationPainter({
    required this.color,
    required this.accent,
    required this.progress,
  });

  final Color color;
  final Color accent;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.42 * progress;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withValues(alpha: 0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    for (var i = 0; i < 18; i++) {
      final angle = i * math.pi * 2 / 18 + progress * 0.6;
      final distance = radius * (0.72 + (i % 3) * 0.12);
      canvas.drawCircle(
        center + Offset(math.cos(angle) * distance, math.sin(angle) * distance),
        2 + (i % 3),
        Paint()..color = accent.withValues(alpha: 0.35 + progress * 0.4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CelebrationPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
