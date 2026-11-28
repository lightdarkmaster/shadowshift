import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadowshift/core/constants.dart';
import 'package:shadowshift/domain/progression/catalog.dart';
import 'package:shadowshift/state/app_providers.dart';
import 'package:shadowshift/ui/widgets/app_scaffold.dart';
import 'package:shadowshift/ui/widgets/design.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    // Only catalog entries count. This keeps an old save with removed IDs from
    // showing impossible progress, and the unique list prevents repeat cards.
    final achievements = Achievements.unique;
    final unlockedIds = profile.achievements.toSet();
    final unlocked = achievements
        .where((achievement) => unlockedIds.contains(achievement.id))
        .length;
    final progress = achievements.isEmpty ? 0.0 : unlocked / achievements.length;

    return AppScaffold(
      title: 'ACHIEVEMENTS',
      subtitle: '$unlocked of ${achievements.length} unlocked',
      body: SingleChildScrollView(
        padding: AppLayout.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AchievementProgress(unlocked: unlocked, total: achievements.length, progress: progress),
            const SizedBox(height: AppLayout.sectionGap),
            ResponsiveTileWrap(
              minTileWidth: 260,
              children: [
                for (final achievement in achievements)
                  _AchievementCard(
                    achievement: achievement,
                    unlocked: unlockedIds.contains(achievement.id),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementProgress extends StatelessWidget {
  const _AchievementProgress({
    required this.unlocked,
    required this.total,
    required this.progress,
  });

  final int unlocked;
  final int total;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppLayout.md),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.violet.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOTAL UNLOCKED',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$unlocked / $total',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppColors.violet,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppLayout.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.progress),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: AppColors.surfaceLight,
              valueColor: const AlwaysStoppedAnimation(AppColors.violet),
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.achievement, required this.unlocked});

  final AchievementDef achievement;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final accent = unlocked ? AppColors.cyan : AppColors.muted;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 92),
      child: GlassCard(
        padding: const EdgeInsets.all(AppLayout.md),
        borderColor: unlocked
            ? AppColors.cyan.withValues(alpha: 0.42)
            : AppColors.surfaceLight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.iconTile),
              ),
              child: Icon(achievement.icon, color: accent),
            ),
            const SizedBox(width: AppLayout.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    achievement.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      letterSpacing: 1,
                      color: unlocked ? AppColors.text : AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    achievement.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: AppColors.muted),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Icon(
                        Icons.monetization_on,
                        size: 12,
                        color: unlocked ? AppColors.gold : AppColors.muted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '+${achievement.rewardCoins}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: unlocked ? AppColors.gold : AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppLayout.sm),
            Icon(
              unlocked ? Icons.check_circle : Icons.lock_outline,
              size: 18,
              color: accent,
            ),
          ],
        ),
      ),
    );
  }
}
