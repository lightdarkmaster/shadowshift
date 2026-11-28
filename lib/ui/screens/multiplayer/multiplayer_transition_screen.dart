import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadowshift/core/constants.dart';
import 'package:shadowshift/state/app_providers.dart';
import 'package:shadowshift/ui/widgets/app_scaffold.dart';
import 'package:shadowshift/ui/widgets/design.dart';

/// Hot-seat hand-off screen. Pops with `true` when the next player is ready.
class MultiplayerTransitionScreen extends ConsumerStatefulWidget {
  const MultiplayerTransitionScreen({
    super.key,
    required this.playerName,
    required this.round,
    required this.totalRounds,
    this.onStart,
  });

  final String playerName;
  final int round;
  final int totalRounds;

  /// When supplied by an inline hot-seat flow, replaces the default pop.
  final VoidCallback? onStart;

  @override
  ConsumerState<MultiplayerTransitionScreen> createState() =>
      _MultiplayerTransitionScreenState();
}

class _MultiplayerTransitionScreenState
    extends ConsumerState<MultiplayerTransitionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _animate = true;

  @override
  void initState() {
    super.initState();
    // MediaQuery cannot be read before initState finishes; didChangeDependencies
    // applies the device animation preference immediately after this.
    _animate = !ref.read(settingsProvider.select((s) => s.reducedMotion));
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (_animate) {
      _controller.repeat(reverse: true);
    } else {
      _controller.value = 1;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = ref.watch(settingsProvider.select((s) => s.reducedMotion)) ||
        MediaQuery.disableAnimationsOf(context);
    final shouldAnimate = !reduced;
    if (shouldAnimate == _animate) return;
    if (mounted) {
      setState(() => _animate = shouldAnimate);
    }
    if (shouldAnimate) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startTurn() {
    final callback = widget.onStart;
    if (callback != null) {
      callback();
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.playerName.trim().isEmpty
        ? 'Player'
        : widget.playerName.trim();
    final headline = '$name, you are up'.toUpperCase();

    return AppScaffold(
      title: 'NEXT PLAYER',
      subtitle: 'Round ${widget.round} of ${widget.totalRounds}',
      showBack: false,
      showCoins: false,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 360;
          final orbSize = compact ? 118.0 : 150.0;
          return SingleChildScrollView(
            padding: AppLayout.pagePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: compact ? AppLayout.md : AppLayout.xl),
                Center(
                  child: _Pulse(
                    controller: _controller,
                    enabled: _animate,
                    child: Container(
                      width: orbSize,
                      height: orbSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.cyan.withValues(alpha: 0.34),
                            AppColors.violet.withValues(alpha: 0.12),
                            Colors.transparent,
                          ],
                          stops: const [0, 0.55, 1],
                        ),
                        border: Border.all(
                          color: AppColors.cyan.withValues(alpha: 0.45),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.cyan.withValues(alpha: 0.22),
                            blurRadius: 34,
                            spreadRadius: -6,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.person,
                        size: compact ? 54 : 70,
                        color: AppColors.cyan,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: compact ? AppLayout.lg : AppLayout.xxl),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    headline,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: compact ? 21 : 27,
                      fontWeight: FontWeight.w900,
                      letterSpacing: compact ? 1.2 : 2.4,
                      color: AppColors.cyan,
                      shadows: [
                        Shadow(
                          color: AppColors.cyan.withValues(alpha: 0.55),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppLayout.md),
                Center(
                  child: StatChip(
                    icon: Icons.repeat,
                    value: 'ROUND ${widget.round} / ${widget.totalRounds}',
                    color: AppColors.violet,
                  ),
                ),
                SizedBox(height: compact ? AppLayout.lg : AppLayout.xxl),
                GlassCard(
                  borderColor: AppColors.violet.withValues(alpha: 0.32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.violet.withValues(alpha: 0.14),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.iconTile),
                            ),
                            child: const Icon(Icons.swap_horiz,
                                color: AppColors.violet, size: 22),
                          ),
                          const SizedBox(width: AppLayout.md),
                          Expanded(
                            child: Text(
                              'PASS THE DEVICE',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppLayout.md),
                      Text(
                        'Hand the device to $name. Make sure nobody else can '
                        'see the screen before starting the turn.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppLayout.sectionGap),
                NeonButton(
                  label: 'START TURN',
                  icon: Icons.play_arrow_rounded,
                  onPressed: _startTurn,
                ),
                const SizedBox(height: AppLayout.lg),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Pulse extends StatelessWidget {
  const _Pulse({
    required this.controller,
    required this.enabled,
    required this.child,
  });

  final AnimationController controller;
  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    final scale = Tween<double>(begin: 0.93, end: 1.07).animate(controller);
    final opacity = Tween<double>(begin: 0.78, end: 1).animate(controller);
    return ScaleTransition(
      scale: scale,
      child: FadeTransition(opacity: opacity, child: child),
    );
  }
}
