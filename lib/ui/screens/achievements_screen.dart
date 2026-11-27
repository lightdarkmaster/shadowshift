import 'package:flutter/material.dart';
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
    final unlocked = profile.achievements.length;
    return AppScaffold(
      title: 'ACHIEVEMENTS',
      subtitle: '$unlocked of ${Achievements.all.length} unlocked',
      body: SingleChildScrollView(
        padding: AppLayout.pagePadding,
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: unlocked / Achievements.all.length,
                minHeight: 7,
                backgroundColor: AppColors.surfaceLight,
                valueColor: const AlwaysStoppedAnimation(AppColors.violet),
              ),
            ),
            const SizedBox(height: 18),
            ...Achievements.all.map((achievement) {
              final done = profile.achievements.contains(achievement.id);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassCard(
                  borderColor: done ? AppColors.cyan.withValues(alpha: 0.4) : AppColors.surfaceLight,
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: (done ? AppColors.cyan : AppColors.muted).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(
                          achievement.icon,
                          color: done ? AppColors.cyan : AppColors.muted,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(achievement.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  letterSpacing: 1,
                                  color: done ? AppColors.text : AppColors.muted,
                                )),
                            const SizedBox(height: 3),
                            Text(achievement.description,
                                style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Icon(done ? Icons.check_circle : Icons.lock_outline,
                              size: 17,
                              color: done ? AppColors.cyan : AppColors.muted),
                          const SizedBox(height: 3),
                          Text('+${achievement.rewardCoins}',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: done ? AppColors.gold : AppColors.muted)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
