import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadowshift/core/constants.dart';
import 'package:shadowshift/core/utils.dart';
import 'package:shadowshift/domain/multiplayer/multiplayer_models.dart';
import 'package:shadowshift/state/app_providers.dart';
import 'package:shadowshift/ui/navigation.dart';
import 'package:shadowshift/ui/screens/multiplayer/multiplayer_home_screen.dart';
import 'package:shadowshift/ui/screens/multiplayer/multiplayer_match_detail_screen.dart';
import 'package:shadowshift/ui/screens/multiplayer/multiplayer_setup_screen.dart';
import 'package:shadowshift/ui/widgets/app_scaffold.dart';
import 'package:shadowshift/ui/widgets/design.dart';

/// End-of-match celebration. All rewards shown here were committed by the
/// multiplayer provider; this screen never touches single-player progression.
class MultiplayerResultsScreen extends ConsumerStatefulWidget {
  const MultiplayerResultsScreen({
    super.key,
    required this.match,
  });

  final MultiplayerMatchRecord match;

  @override
  ConsumerState<MultiplayerResultsScreen> createState() =>
      _MultiplayerResultsScreenState();
}

class _MultiplayerResultsScreenState extends ConsumerState<MultiplayerResultsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _animate = true;

  @override
  void initState() {
    super.initState();
    // MediaQuery is unavailable until initState completes; the device motion
    // setting is applied in didChangeDependencies right after this.
    _animate = !ref.read(settingsProvider.select((s) => s.reducedMotion));
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
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

  @override
  Widget build(BuildContext context) {
    final match = widget.match;
    final winners = match.winners;
    final headline = winners.length == 1
        ? '${winners.first.name.toUpperCase()} WINS!'
        : 'TIE GAME';
    const accent = AppColors.gold;

    return AppScaffold(
      title: 'MATCH RESULTS',
      subtitle: 'All ${match.rounds} ${match.rounds == 1 ? 'round' : 'rounds'} complete',
      showBack: false,
      showCoins: false,
      actions: const [
        StatChip(icon: Icons.phonelink, value: 'LOCAL', color: AppColors.violet),
      ],
      body: SingleChildScrollView(
        padding: AppLayout.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlassCard(
              borderColor: accent.withValues(alpha: 0.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 132,
                    child: _TrophyCelebration(
                      controller: _controller,
                      enabled: _animate,
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      headline,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: accent,
                        shadows: [
                          Shadow(color: accent, blurRadius: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppLayout.sm),
                  Text(
                    winners.length == 1
                        ? '${formatScore(match.winningScore)} points · '
                            '${match.players.length} players'
                        : '${winners.map((w) => w.name).join(' & ')} · '
                            '${formatScore(match.winningScore)} points',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppLayout.md),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SectionTitle('MATCH REWARDS'),
                  const SizedBox(height: AppLayout.md),
                  ResponsiveTileWrap(
                    minTileWidth: 84,
                    tileHeight: 82,
                    children: [
                      StatChip(
                        icon: Icons.paid,
                        value: '+${formatScore(match.goldAwarded)}',
                        color: AppColors.gold,
                        fill: true,
                      ),
                      StatChip(
                        icon: Icons.stars,
                        value: '+${formatScore(match.xpAwarded)} XP',
                        color: AppColors.violet,
                        fill: true,
                      ),
                      StatChip(
                        icon: Icons.repeat,
                        value: '${match.rounds} rounds',
                        color: AppColors.cyan,
                        fill: true,
                      ),
                      StatChip(
                        icon: Icons.bolt,
                        value: formatScore(match.highestTurnScore),
                        color: AppColors.pink,
                        fill: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppLayout.sm),
                  const Text(
                    'Rewarded to your separate multiplayer wallet.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.micro,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppLayout.sectionGap),
            const SectionTitle('FINAL RANKINGS'),
            const SizedBox(height: AppLayout.md),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < match.standings.length; i++) ...[
                    if (i > 0) const SizedBox(height: AppLayout.sm),
                    _ResultsStandingRow(standing: match.standings[i]),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppLayout.sectionGap),
            const SectionTitle('ROUND BREAKDOWN'),
            const SizedBox(height: AppLayout.md),
            GlassCard(
              child: _ResultsRoundTable(match: match),
            ),
            const SizedBox(height: AppLayout.sectionGap),
            LayoutBuilder(
              builder: (context, constraints) {
                final again = NeonButton(
                  label: 'PLAY AGAIN',
                  icon: Icons.replay,
                  color: AppColors.violet,
                  onPressed: () =>
                      pushScreen(context, const MultiplayerSetupScreen()),
                );
                final details = NeonButton(
                  label: 'DETAILS',
                  icon: Icons.article_outlined,
                  secondary: true,
                  color: AppColors.cyan,
                  onPressed: () => pushScreen(
                    context,
                    MultiplayerMatchDetailScreen(match: match),
                  ),
                );
                final home = NeonButton(
                  label: 'MULTIPLAYER HOME',
                  icon: Icons.home_outlined,
                  secondary: true,
                  color: AppColors.gold,
                  onPressed: () =>
                      resetToScreen(context, const MultiplayerHomeScreen()),
                );
                if (constraints.maxWidth < 360) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      again,
                      const SizedBox(height: AppLayout.sm),
                      details,
                      const SizedBox(height: AppLayout.sm),
                      home,
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(child: again),
                        const SizedBox(width: AppLayout.sm),
                        Expanded(child: details),
                      ],
                    ),
                    const SizedBox(height: AppLayout.sm),
                    home,
                  ],
                );
              },
            ),
            const SizedBox(height: AppLayout.lg),
          ],
        ),
      ),
    );
  }
}

class _TrophyCelebration extends StatelessWidget {
  const _TrophyCelebration({
    required this.controller,
    required this.enabled,
  });

  final AnimationController controller;
  final bool enabled;

  static const List<Color> _confettiColors = [
    AppColors.cyan,
    AppColors.violet,
    AppColors.gold,
    AppColors.pink,
  ];

  @override
  Widget build(BuildContext context) {
    final trophy = Icon(
      Icons.emoji_events,
      size: 72,
      color: AppColors.gold,
      shadows: const [Shadow(color: AppColors.gold, blurRadius: 26)],
    );
    return Stack(
      alignment: Alignment.center,
      children: [
        if (enabled)
          AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              final phase = controller.value * math.pi * 2;
              return Stack(
                alignment: Alignment.center,
                children: [
                  for (var i = 0; i < 10; i++)
                    Transform.translate(
                      offset: Offset(
                        math.cos(phase + i * 0.7) * 5 +
                            (i.isEven ? -1 : 1) * (54.0 + (i % 3) * 18),
                        math.sin(phase + i * 1.1) * 7 +
                            (i.isOdd ? -1 : 1) * (20.0 + (i % 4) * 12),
                      ),
                      child: Container(
                        width: i % 2 == 0 ? 6 : 4,
                        height: i % 2 == 0 ? 6 : 10,
                        decoration: BoxDecoration(
                          color: _confettiColors[i % _confettiColors.length]
                              .withValues(alpha: 0.35 + 0.45 * controller.value),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        enabled
            ? ScaleTransition(
                scale: Tween<double>(begin: 0.94, end: 1.06).animate(controller),
                child: trophy,
              )
            : trophy,
      ],
    );
  }
}

class _ResultsStandingRow extends StatelessWidget {
  const _ResultsStandingRow({required this.standing});

  final MultiplayerStanding standing;

  @override
  Widget build(BuildContext context) {
    final color = standing.isWinner ? AppColors.gold : AppColors.cyan;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppLayout.sm,
        vertical: AppLayout.sm,
      ),
      decoration: BoxDecoration(
        color: standing.isWinner
            ? AppColors.gold.withValues(alpha: 0.09)
            : AppColors.surfaceLight.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppRadius.chip),
        border: Border.all(
          color: color.withValues(alpha: standing.isWinner ? 0.5 : 0.16),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.16),
              border: Border.all(color: color.withValues(alpha: 0.6)),
            ),
            child: Center(
              child: Text(
                '${standing.rank}',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppLayout.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  standing.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: standing.isWinner ? AppColors.gold : AppColors.text,
                  ),
                ),
                if (standing.isWinner)
                  const Text('WINNER',
                      style: TextStyle(
                        fontSize: 9,
                        letterSpacing: 1.2,
                        color: AppColors.gold,
                        fontWeight: FontWeight.w900,
                      )),
              ],
            ),
          ),
          Text(
            formatScore(standing.total),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultsRoundTable extends StatelessWidget {
  const _ResultsRoundTable({required this.match});

  final MultiplayerMatchRecord match;

  static const double _nameWidth = 92;
  static const double _roundWidth = 48;
  static const double _totalWidth = 58;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (match.rounds > 2)
          const Padding(
            padding: EdgeInsets.only(bottom: AppLayout.sm),
            child: Text('SWIPE TO SEE EVERY ROUND →', style: AppTextStyles.micro),
          ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _cell('PLAYER', width: _nameWidth, header: true),
                  for (var round = 0; round < match.rounds; round++)
                    _cell('R${round + 1}', width: _roundWidth, header: true),
                  _cell('TOTAL', width: _totalWidth, header: true),
                ],
              ),
              Container(height: 1, color: AppColors.surfaceLight),
              for (var player = 0; player < match.players.length; player++)
                Row(
                  children: [
                    _cell(
                      '${player + 1}. ${match.players[player]}',
                      width: _nameWidth,
                      alignLeft: true,
                    ),
                    for (var round = 0; round < match.rounds; round++)
                      _cell(
                        match.scores[round][player] == null
                            ? '—'
                            : '${match.scores[round][player]}',
                        width: _roundWidth,
                      ),
                    _cell(
                      '${match.totalFor(player)}',
                      width: _totalWidth,
                      bold: true,
                      color: AppColors.cyan,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _cell(
    String text, {
    required double width,
    bool header = false,
    bool bold = false,
    bool alignLeft = false,
    Color? color,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
      alignment: alignLeft ? Alignment.centerLeft : Alignment.center,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: alignLeft ? TextAlign.left : TextAlign.center,
        style: TextStyle(
          fontSize: header ? 9 : 11,
          fontWeight: header || bold ? FontWeight.w900 : FontWeight.w700,
          letterSpacing: header ? 0.8 : 0,
          color: color ??
              (header ? AppColors.muted : AppColors.text),
        ),
      ),
    );
  }
}
