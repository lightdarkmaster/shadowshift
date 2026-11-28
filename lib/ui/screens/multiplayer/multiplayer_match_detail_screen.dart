import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadowshift/core/constants.dart';
import 'package:shadowshift/core/utils.dart';
import 'package:shadowshift/domain/multiplayer/multiplayer_models.dart';
import 'package:shadowshift/state/app_providers.dart';
import 'package:shadowshift/ui/widgets/app_scaffold.dart';
import 'package:shadowshift/ui/widgets/design.dart';

/// Full report for one archived local match. Mirrors the results screen's
/// visual language without awarding anything again.
class MultiplayerMatchDetailScreen extends ConsumerWidget {
  const MultiplayerMatchDetailScreen({
    super.key,
    required this.match,
  });

  final MultiplayerMatchRecord match;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final careerGames = ref.watch(
      multiplayerProfileProvider.select((profile) => profile.gamesPlayed),
    );
    final winners = match.winnerNames;
    final title = winners.isEmpty
        ? 'NO WINNER YET'
        : winners.length == 1
            ? '${winners.first.toUpperCase()} WINS!'
            : 'TIE: ${winners.join(' & ')}';

    return AppScaffold(
      title: 'MATCH DETAIL',
      subtitle: _formatDate(match.playedAt),
      showCoins: false,
      actions: [
        StatChip(
          icon: Icons.history,
          value: '$careerGames MP GAMES',
          color: AppColors.violet,
        ),
      ],
      body: SingleChildScrollView(
        padding: AppLayout.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlassCard(
              borderColor: AppColors.gold.withValues(alpha: 0.42),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: AppColors.gold.withValues(alpha: 0.12),
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.5),
                          ),
                        ),
                        child: const Icon(Icons.emoji_events,
                            color: AppColors.gold, size: 28),
                      ),
                      const SizedBox(width: AppLayout.md),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.4,
                              color: AppColors.gold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppLayout.md),
                  Text(
                    '${formatScore(match.winningScore)} winning points · '
                    '${match.isCompleted ? 'completed' : 'in progress'}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: AppLayout.md),
                  Wrap(
                    spacing: AppLayout.sm,
                    runSpacing: AppLayout.sm,
                    children: [
                      StatChip(
                        icon: Icons.repeat,
                        value: '${match.rounds} rounds',
                        color: AppColors.cyan,
                      ),
                      StatChip(
                        icon: Icons.people_outline,
                        value: '${match.players.length} players',
                        color: AppColors.violet,
                      ),
                      StatChip(
                        icon: Icons.stacked_bar_chart,
                        value: formatScore(match.totalPoints),
                        color: AppColors.blue,
                      ),
                      StatChip(
                        icon: Icons.bolt,
                        value: 'best ${formatScore(match.highestTurnScore)}',
                        color: AppColors.pink,
                      ),
                      StatChip(
                        icon: Icons.paid,
                        value: '+${formatScore(match.goldAwarded)}',
                        color: AppColors.gold,
                      ),
                      StatChip(
                        icon: Icons.stars,
                        value: '+${formatScore(match.xpAwarded)} XP',
                        color: AppColors.violet,
                      ),
                    ],
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
                    _DetailStandingRow(standing: match.standings[i]),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppLayout.sectionGap),
            const SectionTitle('ROUND BREAKDOWN'),
            const SizedBox(height: AppLayout.md),
            GlassCard(
              child: _DetailRoundTable(match: match),
            ),
            const SizedBox(height: AppLayout.md),
            const Text(
              'This is a read-only local report. Rewards were saved when '
              'the match was first completed.',
              textAlign: TextAlign.center,
              style: AppTextStyles.micro,
            ),
            const SizedBox(height: AppLayout.lg),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$month-$day  $hour:$minute';
  }
}

class _DetailStandingRow extends StatelessWidget {
  const _DetailStandingRow({required this.standing});

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
                  const Text(
                    'WINNER',
                    style: TextStyle(
                      fontSize: 9,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w900,
                      color: AppColors.gold,
                    ),
                  ),
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

class _DetailRoundTable extends StatelessWidget {
  const _DetailRoundTable({required this.match});

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
          color: color ?? (header ? AppColors.muted : AppColors.text),
        ),
      ),
    );
  }
}
