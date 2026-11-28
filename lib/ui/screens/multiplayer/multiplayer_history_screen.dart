import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadowshift/core/constants.dart';
import 'package:shadowshift/core/utils.dart';
import 'package:shadowshift/domain/multiplayer/multiplayer_models.dart';
import 'package:shadowshift/state/app_providers.dart';
import 'package:shadowshift/ui/navigation.dart';
import 'package:shadowshift/ui/screens/multiplayer/multiplayer_match_detail_screen.dart';
import 'package:shadowshift/ui/widgets/app_scaffold.dart';
import 'package:shadowshift/ui/widgets/design.dart';

/// Local match archive plus per-player career records, all from the
/// multiplayer-only profile.
class MultiplayerHistoryScreen extends ConsumerWidget {
  const MultiplayerHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(multiplayerProfileProvider);
    final stats = profile.playerStats.values.toList()
      ..sort((a, b) => b.totalPoints.compareTo(a.totalPoints));

    return AppScaffold(
      title: 'MULTIPLAYER HISTORY',
      subtitle: 'Matches and records on this device',
      showCoins: false,
      actions: [
        StatChip(
          icon: Icons.history,
          value: '${profile.history.length} MATCHES',
          color: AppColors.violet,
        ),
      ],
      body: SingleChildScrollView(
        padding: AppLayout.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionTitle('CAREER STATS'),
            const SizedBox(height: AppLayout.md),
            GlassCard(
              child: ResponsiveTileWrap(
                minTileWidth: 84,
                tileHeight: 80,
                children: [
                  StatChip(
                    icon: Icons.replay,
                    value: '${profile.gamesPlayed} games',
                    color: AppColors.cyan,
                    fill: true,
                  ),
                  StatChip(
                    icon: Icons.emoji_events,
                    value: '${profile.wins} wins',
                    color: AppColors.gold,
                    fill: true,
                  ),
                  StatChip(
                    icon: Icons.question_mark,
                    value: '${profile.losses} losses',
                    color: AppColors.pink,
                    fill: true,
                  ),
                  StatChip(
                    icon: Icons.stacked_bar_chart,
                    value: formatScore(profile.totalPoints),
                    color: AppColors.violet,
                    fill: true,
                  ),
                  StatChip(
                    icon: Icons.bolt,
                    value: formatScore(profile.highestScore),
                    color: AppColors.cyan,
                    fill: true,
                  ),
                  StatChip(
                    icon: Icons.paid,
                    value: formatScore(profile.gold),
                    color: AppColors.gold,
                    fill: true,
                  ),
                  StatChip(
                    icon: Icons.stars,
                    value: '${formatScore(profile.xp)} XP',
                    color: AppColors.violet,
                    fill: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppLayout.sectionGap),
            const SectionTitle(
              'PLAYER STATS',
              subtitle: 'Wins, losses and best turn per player',
            ),
            const SizedBox(height: AppLayout.md),
            GlassCard(
              child: stats.isEmpty
                  ? const Column(
                      children: [
                        Icon(Icons.people_outline,
                            size: 32, color: AppColors.muted),
                        SizedBox(height: AppLayout.sm),
                        Text(
                          'Finish a match to build player records.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.caption,
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < stats.length; i++) ...[
                          if (i > 0) const SizedBox(height: AppLayout.sm),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      stats[i].name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(
                                      '${stats[i].games} games · '
                                      '${stats[i].wins}W / ${stats[i].losses}L',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppLayout.sm),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    formatScore(stats[i].totalPoints),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.cyan,
                                    ),
                                  ),
                                  Text(
                                    'best ${formatScore(stats[i].bestScore)}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
            ),
            const SizedBox(height: AppLayout.sectionGap),
            const SectionTitle(
              'MATCH HISTORY',
              subtitle: 'Tap a match for the full breakdown',
            ),
            const SizedBox(height: AppLayout.md),
            if (profile.history.isEmpty)
              GlassCard(
                child: Column(
                  children: const [
                    Icon(Icons.history, size: 40, color: AppColors.muted),
                    SizedBox(height: AppLayout.md),
                    Text(
                      'NO MATCHES YET',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Your finished local matches will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              )
            else
              for (final match in profile.history) ...[
                _HistoryCard(match: match),
                const SizedBox(height: AppLayout.md),
              ],
            const SizedBox(height: AppLayout.lg),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.match});

  final MultiplayerMatchRecord match;

  @override
  Widget build(BuildContext context) {
    final winner = match.winnerNames.join(' & ');
    return GlassCard(
      borderColor: AppColors.gold.withValues(alpha: 0.24),
      onTap: () => pushScreen(
        context,
        MultiplayerMatchDetailScreen(match: match),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.iconTile),
                  color: AppColors.gold.withValues(alpha: 0.12),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
                ),
                child: const Icon(Icons.emoji_events,
                    color: AppColors.gold, size: 23),
              ),
              const SizedBox(width: AppLayout.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('WINNER', style: AppTextStyles.micro),
                    const SizedBox(height: 2),
                    Text(
                      winner.isEmpty ? 'TIE GAME' : winner,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppColors.gold,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.muted, size: 20),
            ],
          ),
          const SizedBox(height: AppLayout.md),
          Text(
            match.players.join(' · '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.text,
              height: 1.3,
            ),
          ),
          const SizedBox(height: AppLayout.sm),
          Text(_formatDate(match.playedAt), style: AppTextStyles.micro),
          const SizedBox(height: AppLayout.md),
          Wrap(
            spacing: AppLayout.sm,
            runSpacing: AppLayout.sm,
            children: [
              StatChip(
                icon: Icons.stacked_bar_chart,
                value: '${formatScore(match.winningScore)} pts',
                color: AppColors.cyan,
              ),
              StatChip(
                icon: Icons.repeat,
                value: '${match.rounds} rounds',
                color: AppColors.violet,
              ),
              StatChip(
                icon: Icons.people_outline,
                value: '${match.players.length} players',
                color: AppColors.blue,
              ),
              StatChip(
                icon: Icons.paid,
                value: '+${formatScore(match.goldAwarded)}',
                color: AppColors.gold,
              ),
            ],
          ),
        ],
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
