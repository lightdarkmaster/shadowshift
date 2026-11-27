import 'package:flutter/material.dart';
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
import 'package:shadowshift/ui/screens/settings_screen.dart';
import 'package:shadowshift/ui/screens/shop_screen.dart';
import 'package:shadowshift/ui/screens/statistics_screen.dart';
import 'package:shadowshift/ui/widgets/design.dart';
import 'package:shadowshift/ui/widgets/space_background.dart';

class MainMenu extends ConsumerWidget {
  const MainMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final reducedMotion = ref.watch(settingsProvider.select((s) => s.reducedMotion));
    final best = profile.bestScores.values.isEmpty
        ? 0
        : profile.bestScores.values.reduce((a, b) => a > b ? a : b);
    final dailyReward = ProgressionService.dailyRewardAmount(profile, DateTime.now());

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: SpaceBackground(reducedMotion: reducedMotion)),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth > 620;
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 620),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: wide ? 22 : 8),
                          GradientLabel(AppStrings.appName,
                              fontSize: wide ? 48 : 36, letterSpacing: wide ? 7 : 4),
                          const SizedBox(height: 6),
                          const Center(
                            child: Text(AppStrings.tagline,
                                style: TextStyle(
                                    fontSize: 11,
                                    letterSpacing: 3,
                                    color: AppColors.muted)),
                          ),
                          const SizedBox(height: 20),
                          GlassCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    StatChip(
                                      icon: Icons.bolt,
                                      value: formatScore(profile.coins),
                                      color: AppColors.gold,
                                    ),
                                    StatChip(
                                      icon: Icons.emoji_events,
                                      value: formatScore(best),
                                      color: AppColors.cyan,
                                    ),
                                    StatChip(
                                      icon: Icons.person,
                                      value: 'LV ${profile.level}',
                                      color: AppColors.violet,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                LevelBar(
                                  level: profile.level,
                                  current: profile.xpInLevel,
                                  total: profile.xpForNextLevel,
                                ),
                              ],
                            ),
                          ),
                          if (!profile.daily.rewardClaimed) ...[
                            const SizedBox(height: 12),
                            GlassCard(
                              borderColor: AppColors.gold.withValues(alpha: 0.5),
                              onTap: () {
                                final coins = ref
                                    .read(profileProvider.notifier)
                                    .claimDailyReward();
                                if (coins <= 0) return;
                                AudioService.instance.achievement();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Daily reward claimed: +$coins coins'),
                                    backgroundColor: AppColors.surfaceLight,
                                  ),
                                );
                              },
                              child: Row(
                                children: [
                                  const Icon(Icons.card_giftcard, color: AppColors.gold, size: 26),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text('DAILY REWARD READY',
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 1.4)),
                                  ),
                                  Text('+$dailyReward',
                                      style: const TextStyle(
                                          color: AppColors.gold, fontWeight: FontWeight.w800)),
                                  const Icon(Icons.chevron_right, color: AppColors.gold),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 18),
                          NeonButton(
                            label: 'ENTER THE SHIFT',
                            icon: Icons.play_arrow_rounded,
                            onPressed: () {
                              AudioService.instance.ui();
                              pushScreen(context, const ModeSelectionScreen());
                            },
                          ),
                          const SizedBox(height: 12),
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
                          const SizedBox(height: 22),
                          const SectionTitle('COMMAND DECK',
                              subtitle: 'Everything is available offline'),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _MenuTile(
                                icon: Icons.person_outline,
                                label: 'CHARACTERS',
                                color: AppColors.cyan,
                                onTap: () => pushScreen(context, const CharacterSelectionScreen()),
                              ),
                              _MenuTile(
                                icon: Icons.shopping_bag_outlined,
                                label: 'SHOP',
                                color: AppColors.gold,
                                onTap: () => pushScreen(context, const ShopScreen()),
                              ),
                              _MenuTile(
                                icon: Icons.emoji_events_outlined,
                                label: 'ACHIEVEMENTS',
                                color: AppColors.violet,
                                onTap: () => pushScreen(context, const AchievementsScreen()),
                              ),
                              _MenuTile(
                                icon: Icons.assignment_outlined,
                                label: 'MISSIONS',
                                color: AppColors.pink,
                                onTap: () => pushScreen(context, const MissionsScreen()),
                              ),
                              _MenuTile(
                                icon: Icons.bar_chart,
                                label: 'STATS',
                                color: AppColors.blue,
                                onTap: () => pushScreen(context, const StatisticsScreen()),
                              ),
                              _MenuTile(
                                icon: Icons.settings_outlined,
                                label: 'SETTINGS',
                                color: AppColors.muted,
                                onTap: () => pushScreen(context, const SettingsScreen()),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
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
    return SizedBox(
      width: 104,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        borderColor: color.withValues(alpha: 0.24),
        onTap: () {
          AudioService.instance.ui();
          onTap();
        },
        child: Column(
          children: [
            Icon(icon, color: color, size: 25),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
          ],
        ),
      ),
    );
  }
}
