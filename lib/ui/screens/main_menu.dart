import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadowshift/core/constants.dart';
import 'package:shadowshift/core/utils.dart';
import 'package:shadowshift/domain/game/enums.dart';
import 'package:shadowshift/domain/services/audio_service.dart';
import 'package:shadowshift/domain/services/launch_service.dart';
import 'package:shadowshift/domain/services/progression_service.dart';
import 'package:shadowshift/state/app_providers.dart';
import 'package:shadowshift/ui/navigation.dart';
import 'package:shadowshift/ui/screens/achievements_screen.dart';
import 'package:shadowshift/ui/screens/character_selection.dart';
import 'package:shadowshift/ui/screens/gameplay_screen.dart';
import 'package:shadowshift/ui/screens/missions_screen.dart';
import 'package:shadowshift/ui/screens/mode_selection.dart';
import 'package:shadowshift/ui/screens/multiplayer/multiplayer_home_screen.dart';
import 'package:shadowshift/ui/screens/rank_screen.dart';
import 'package:shadowshift/ui/screens/settings_screen.dart';
import 'package:shadowshift/ui/screens/shop_screen.dart';
import 'package:shadowshift/ui/screens/statistics_screen.dart';
import 'package:shadowshift/ui/widgets/about_dialog.dart';
import 'package:shadowshift/ui/widgets/design.dart';
import 'package:shadowshift/ui/widgets/notice_dialog.dart';
import 'package:shadowshift/ui/widgets/rank_emblem.dart';
import 'package:shadowshift/ui/widgets/space_background.dart';

class MainMenu extends ConsumerWidget {
  const MainMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    // Read-only peek at the isolated multiplayer save for the home card. It
    // never feeds coins/XP/stats back into this single-player menu.
    final multiplayer = ref.watch(multiplayerProfileProvider);
    final reducedMotion = ref.watch(settingsProvider.select((s) => s.reducedMotion));
    final best = profile.bestScores.values.isEmpty
        ? 0
        : profile.bestScores.values.reduce((a, b) => a > b ? a : b);
    final dailyReward = ProgressionService.dailyRewardAmount(profile, DateTime.now());

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: SpaceBackground(
              reducedMotion: reducedMotion,
              skinId: profile.skin,
              effectId: profile.effect,
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final contentWidth = (constraints.maxWidth - AppLayout.gutter * 2)
                    .clamp(0.0, AppLayout.maxContentWidth)
                    .toDouble();
                final compact = contentWidth < 360;
                final wide = contentWidth >= 520;

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppLayout.gutter,
                    vertical: AppLayout.md,
                  ),
                  child: Center(
                    child: SizedBox(
                      width: contentWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: wide ? AppLayout.xl : AppLayout.sm),
                          Center(
                            child: Tooltip(
                              message: 'About ${AppStrings.appName}',
                              child: Semantics(
                                button: true,
                                label: 'About ${AppStrings.appName}',
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      AudioService.instance.ui();
                                      showDialog(
                                        context: context,
                                        builder: (_) => const AppAboutDialog(),
                                      );
                                    },
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.card),
                                    child: Image.asset(
                                      'assets/images/shadowshift_neon_logo.png',
                                      width: wide ? 104 : compact ? 72 : 88,
                                      height: wide ? 104 : compact ? 72 : 88,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppLayout.sm),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.center,
                            child: GradientLabel(
                              AppStrings.appName,
                              fontSize: compact ? 28 : wide ? 46 : 36,
                              letterSpacing: compact ? 2 : wide ? 7 : 4,
                            ),
                          ),
                          const SizedBox(height: AppLayout.xs),
                          const Text(
                            AppStrings.tagline,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              letterSpacing: 3,
                              color: AppColors.muted,
                            ),
                          ),
                          const SizedBox(height: AppLayout.xl),
                          GlassCard(
                            padding: const EdgeInsets.all(AppLayout.lg),
                            borderColor: profile.rankTier.color.withValues(alpha: 0.42),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: StatChip(
                                        icon: Icons.paid,
                                        value: formatScore(profile.coins),
                                        color: AppColors.gold,
                                        fill: true,
                                      ),
                                    ),
                                    const SizedBox(width: AppLayout.sm),
                                    Expanded(
                                      child: StatChip(
                                        icon: Icons.emoji_events,
                                        value: formatScore(best),
                                        color: AppColors.cyan,
                                        fill: true,
                                      ),
                                    ),
                                    const SizedBox(width: AppLayout.sm),
                                    Expanded(
                                      child: StatChip(
                                        icon: Icons.person,
                                        value: 'LV ${profile.level}',
                                        color: AppColors.violet,
                                        fill: true,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppLayout.md),
                                LevelBar(
                                  level: profile.level,
                                  current: profile.xpInLevel,
                                  total: profile.xpForNextLevel,
                                ),
                                const SizedBox(height: AppLayout.sm),
                                Row(
                                  children: [
                                    RankEmblem(
                                      tier: profile.rankTier,
                                      size: 30,
                                      animate: false,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  profile.playerName,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w900,
                                                    letterSpacing: 0.8,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Flexible(
                                                child: Text(
                                                  profile.rankTier.name,
                                                  textAlign: TextAlign.end,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color:
                                                        profile.rankTier.color,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w900,
                                                    letterSpacing: 0.8,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            profile.equippedTitleName,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: AppColors.muted,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (!profile.daily.rewardClaimed) ...[
                            const SizedBox(height: AppLayout.md),
                            GlassCard(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppLayout.lg,
                                vertical: AppLayout.md,
                              ),
                              borderColor: AppColors.gold.withValues(alpha: 0.5),
                              onTap: () {
                                final coins = ref
                                    .read(profileProvider.notifier)
                                    .claimDailyReward();
                                if (coins <= 0) return;
                                AudioService.instance.achievement();
                                showNoticeDialog(
                                  context,
                                  title: 'DAILY REWARD CLAIMED',
                                  message: 'You collected +$coins energy coins. '
                                      'Come back tomorrow for more.',
                                  tone: NoticeTone.success,
                                  badgeIcon: Icons.monetization_on,
                                );
                              },
                              child: Row(
                                children: [
                                  const Icon(Icons.card_giftcard,
                                      color: AppColors.gold, size: 24),
                                  const SizedBox(width: AppLayout.md),
                                  const Expanded(
                                    child: Text(
                                      'DAILY REWARD READY',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '+$dailyReward',
                                    style: const TextStyle(
                                      color: AppColors.gold,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right,
                                      color: AppColors.gold, size: 20),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: AppLayout.xl),
                          NeonButton(
                            label: 'ENTER THE SHIFT',
                            icon: Icons.play_arrow_rounded,
                            onPressed: () {
                              AudioService.instance.ui();
                              pushScreen(context, const ModeSelectionScreen());
                            },
                          ),
                          const SizedBox(height: AppLayout.md),
                          NeonButton(
                            label: 'DAILY CHALLENGE',
                            icon: Icons.calendar_today,
                            secondary: true,
                            color: AppColors.violet,
                            onPressed: () {
                              AudioService.instance.ui();
                              pushScreen(
                                context,
                                GameplayScreen(
                                  launch: LaunchService.create(GameMode.daily),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: AppLayout.sectionGap),
                          _MultiplayerCard(
                            gamesPlayed: multiplayer.gamesPlayed,
                            recentResult: multiplayer.recentMatch == null
                                ? 'No matches yet — start the first one.'
                                : '${multiplayer.recentMatch!.winnerNames.join(' & ')}'
                                    ' won with ${formatScore(multiplayer.recentMatch!.winningScore)} pts',
                            onTap: () => pushScreen(
                              context,
                              const MultiplayerHomeScreen(),
                            ),
                          ),
                          const SizedBox(height: AppLayout.sectionGap),
                          const SectionTitle(
                            'COMMAND DECK',
                            subtitle: 'Everything is available offline',
                          ),
                          const SizedBox(height: AppLayout.md),
                          ResponsiveTileWrap(
                            minTileWidth: 100,
                            tileHeight: wide ? 104 : 92,
                            children: [
                              _menuTile(
                                icon: Icons.person_outline,
                                label: 'CHARACTERS',
                                color: AppColors.cyan,
                                onTap: () => pushScreen(
                                  context,
                                  const CharacterSelectionScreen(),
                                ),
                              ),
                              _menuTile(
                                icon: Icons.shopping_bag_outlined,
                                label: 'SHOP',
                                color: AppColors.gold,
                                onTap: () => pushScreen(context, const ShopScreen()),
                              ),
                              _menuTile(
                                icon: Icons.emoji_events_outlined,
                                label: 'ACHIEVEMENTS',
                                color: AppColors.violet,
                                onTap: () => pushScreen(
                                  context,
                                  const AchievementsScreen(),
                                ),
                              ),
                              _menuTile(
                                icon: Icons.emoji_events,
                                label: 'RANKS',
                                color: const Color(0xFF7DFFB2),
                                onTap: () => pushScreen(
                                  context,
                                  const RankScreen(),
                                ),
                              ),
                              _menuTile(
                                icon: Icons.assignment_outlined,
                                label: 'MISSIONS',
                                color: AppColors.pink,
                                onTap: () =>
                                    pushScreen(context, const MissionsScreen()),
                              ),
                              _menuTile(
                                icon: Icons.bar_chart,
                                label: 'STATS',
                                color: AppColors.blue,
                                onTap: () =>
                                    pushScreen(context, const StatisticsScreen()),
                              ),
                              _menuTile(
                                icon: Icons.settings_outlined,
                                label: 'SETTINGS',
                                color: AppColors.muted,
                                onTap: () =>
                                    pushScreen(context, const SettingsScreen()),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppLayout.sectionGap),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return _MenuTile(
      icon: icon,
      label: label,
      color: color,
      onTap: onTap,
    );
  }
}

/// Dedicated home entry point for the entirely separate local multiplayer
/// mode. Its stats come from [multiplayerProfileProvider], never [profileProvider].
class _MultiplayerCard extends StatelessWidget {
  const _MultiplayerCard({
    required this.gamesPlayed,
    required this.recentResult,
    required this.onTap,
  });

  final int gamesPlayed;
  final String recentResult;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppLayout.lg),
      borderColor: AppColors.blue.withValues(alpha: 0.38),
      onTap: () {
        AudioService.instance.ui();
        onTap();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.violet.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.iconTile),
                  border: Border.all(color: AppColors.violet.withValues(alpha: 0.42)),
                ),
                child: const Icon(Icons.groups, color: AppColors.violet, size: 23),
              ),
              const SizedBox(width: AppLayout.md),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MULTIPLAYER',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.6,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'LOCAL TURN-BASED MATCH',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: AppColors.cyan,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.blue.withValues(alpha: 0.32)),
                ),
                child: Text(
                  '$gamesPlayed PLAYED',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: AppColors.blue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppLayout.md),
          const Text(
            'Challenge your friends and compete for the highest score.',
            style: TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          const SizedBox(height: AppLayout.sm),
          Row(
            children: [
              const Icon(Icons.emoji_events, size: 13, color: AppColors.gold),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  recentResult,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: AppColors.text),
                ),
              ),
              const Icon(Icons.chevron_right, size: 18, color: AppColors.muted),
            ],
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
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
      borderColor: color.withValues(alpha: 0.24),
      onTap: () {
        AudioService.instance.ui();
        onTap();
      },
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
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
