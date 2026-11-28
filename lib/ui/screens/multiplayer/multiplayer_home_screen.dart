import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadowshift/core/constants.dart';
import 'package:shadowshift/core/utils.dart';
import 'package:shadowshift/domain/multiplayer/multiplayer_models.dart';
import 'package:shadowshift/state/app_providers.dart';
import 'package:shadowshift/ui/navigation.dart';
import 'package:shadowshift/ui/screens/multiplayer/multiplayer_gameplay_screen.dart';
import 'package:shadowshift/ui/screens/multiplayer/multiplayer_history_screen.dart';
import 'package:shadowshift/ui/screens/multiplayer/multiplayer_setup_screen.dart';
import 'package:shadowshift/ui/widgets/app_scaffold.dart';
import 'package:shadowshift/ui/widgets/design.dart';

/// Command deck for the isolated, local-only multiplayer save.
///
/// Everything on this screen reads [multiplayerProfileProvider], never the
/// single-player [profileProvider], so solo rewards cannot leak in here.
class MultiplayerHomeScreen extends ConsumerWidget {
  const MultiplayerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(multiplayerProfileProvider);
    final recent = profile.recentMatch;
    final players = profile.playerStats.values.toList()
      ..sort((a, b) => b.totalPoints.compareTo(a.totalPoints));

    final recentLine = recent == null
        ? 'No matches recorded yet'
        : '${recent.winnerNames.join(' & ')} · '
            '${formatScore(recent.winningScore)} pts · '
            '${recent.rounds} ${recent.rounds == 1 ? 'round' : 'rounds'}';

    return AppScaffold(
      title: 'MULTIPLAYER',
      subtitle: 'Local hot-seat · separate progress',
      showCoins: false,
      actions: const [
        StatChip(icon: Icons.phonelink, value: 'LOCAL ONLY', color: AppColors.violet),
      ],
      body: SingleChildScrollView(
        padding: AppLayout.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlassCard(
              borderColor: AppColors.violet.withValues(alpha: 0.38),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: AppColors.violet.withValues(alpha: 0.14),
                          border: Border.all(
                            color: AppColors.violet.withValues(alpha: 0.5),
                          ),
                        ),
                        child: const Icon(Icons.groups,
                            color: AppColors.violet, size: 28),
                      ),
                      const SizedBox(width: AppLayout.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'MULTIPLAYER',
                              style: TextStyle(
                                color: AppColors.violet,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.6,
                              ),
                            ),
                            const SizedBox(height: AppLayout.xs),
                            Text(
                              'Challenge your friends and compete for the '
                              'highest score.',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.muted,
                                height: 1.35,
                              ),
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppLayout.md),
                  Wrap(
                    spacing: AppLayout.sm,
                    runSpacing: AppLayout.sm,
                    children: [
                      StatChip(
                        icon: Icons.replay,
                        value: '${profile.gamesPlayed} games',
                        color: AppColors.cyan,
                      ),
                      StatChip(
                        icon: Icons.emoji_events,
                        value: '${profile.wins} wins',
                        color: AppColors.gold,
                      ),
                      StatChip(
                        icon: Icons.paid,
                        value: formatScore(profile.gold),
                        color: AppColors.gold,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppLayout.md),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppLayout.md,
                      vertical: AppLayout.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                      border: Border.all(
                        color: AppColors.cyan.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('MOST RECENT RESULT',
                            style: AppTextStyles.micro),
                        const SizedBox(height: 3),
                        Text(
                          recentLine,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (profile.activeMatch != null) ...[
                    const SizedBox(height: AppLayout.md),
                    Container(
                      padding: const EdgeInsets.all(AppLayout.md),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.38),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.restore, size: 15, color: AppColors.gold),
                              SizedBox(width: AppLayout.sm),
                              Text(
                                'MATCH IN PROGRESS',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                  color: AppColors.gold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppLayout.sm),
                          Text(
                            '${profile.activeMatch!.players.length} players · '
                            '${profile.activeMatch!.rounds} rounds · '
                            '${MultiplayerSession.fromRecord(profile.activeMatch!).currentRound} in progress',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.muted,
                            ),
                          ),
                          const SizedBox(height: AppLayout.sm),
                          NeonButton(
                            label: 'RESUME MATCH',
                            icon: Icons.play_arrow_rounded,
                            color: AppColors.gold,
                            onPressed: () => pushScreen(
                              context,
                              MultiplayerGameplayScreen(
                                match: profile.activeMatch!,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppLayout.md),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final button = NeonButton(
                        label: 'NEW MATCH',
                        icon: Icons.play_arrow_rounded,
                        onPressed: () =>
                            pushScreen(context, const MultiplayerSetupScreen()),
                      );
                      final history = NeonButton(
                        label: 'HISTORY',
                        icon: Icons.history,
                        color: AppColors.violet,
                        secondary: true,
                        onPressed: () => pushScreen(
                          context,
                          const MultiplayerHistoryScreen(),
                        ),
                      );
                      if (constraints.maxWidth < 340) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            button,
                            const SizedBox(height: AppLayout.sm),
                            history,
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: button),
                          const SizedBox(width: AppLayout.sm),
                          Expanded(child: history),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppLayout.sectionGap),
            const SectionTitle(
              'COMMAND DECK',
              subtitle: 'Pass the device. Keep the scores honest.',
            ),
            const SizedBox(height: AppLayout.md),
            ResponsiveTileWrap(
              minTileWidth: 96,
              tileHeight: 96,
              children: [
                _DeckTile(
                  icon: Icons.play_arrow_rounded,
                  label: 'NEW MATCH',
                  color: AppColors.cyan,
                  onTap: () =>
                      pushScreen(context, const MultiplayerSetupScreen()),
                ),
                _DeckTile(
                  icon: Icons.history,
                  label: 'HISTORY',
                  color: AppColors.violet,
                  onTap: () =>
                      pushScreen(context, const MultiplayerHistoryScreen()),
                ),
                _DeckTile(
                  icon: Icons.bar_chart,
                  label: 'PLAYER STATS',
                  color: AppColors.gold,
                  onTap: () =>
                      pushScreen(context, const MultiplayerHistoryScreen()),
                ),
              ],
            ),
            const SizedBox(height: AppLayout.sectionGap),
            const SectionTitle(
              'PLAYER STATS',
              subtitle: 'Career records in multiplayer only',
            ),
            const SizedBox(height: AppLayout.md),
            GlassCard(
              child: players.isEmpty
                  ? const Column(
                      children: [
                        Icon(Icons.people_outline,
                            size: 32, color: AppColors.muted),
                        SizedBox(height: AppLayout.sm),
                        Text(
                          'No player records yet. Finish a match to '
                          'start the leaderboard.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.muted,
                            height: 1.35,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < players.length && i < 4; i++) ...[
                          if (i > 0) const SizedBox(height: AppLayout.sm),
                          Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: AppColors.violet.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.chip,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '${i + 1}',
                                    style: const TextStyle(
                                      color: AppColors.violet,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppLayout.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      players[i].name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(
                                      '${players[i].wins}W · ${players[i].losses}L '
                                      '· best ${formatScore(players[i].bestScore)}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                formatScore(players[i].totalPoints),
                                style: const TextStyle(
                                  color: AppColors.cyan,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
            ),
            const SizedBox(height: AppLayout.md),
            const Text(
              'Multiplayer gold, XP and stats are stored separately from '
              'your single-player profile.',
              textAlign: TextAlign.center,
              style: AppTextStyles.micro,
            ),
            const SizedBox(height: AppLayout.lg),
          ],
        ),
      ),
    );
  }
}

class _DeckTile extends StatelessWidget {
  const _DeckTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppLayout.sm,
        vertical: AppLayout.md,
      ),
      borderColor: color.withValues(alpha: 0.28),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppLayout.sm),
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.7,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
