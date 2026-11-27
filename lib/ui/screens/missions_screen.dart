import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadowshift/core/constants.dart';
import 'package:shadowshift/core/utils.dart';
import 'package:shadowshift/domain/game/enums.dart';
import 'package:shadowshift/domain/services/daily_service.dart';
import 'package:shadowshift/state/app_providers.dart';
import 'package:shadowshift/ui/widgets/app_scaffold.dart';
import 'package:shadowshift/ui/widgets/design.dart';

class MissionsScreen extends ConsumerWidget {
  const MissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final profile = ref.watch(profileProvider);
    final missions = DailyService.missionsFor(now);
    final daily = DailyService.challengeFor(now);
    return AppScaffold(
      title: 'MISSIONS',
      subtitle: 'Local date · ${dateKey(now)}',
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
        child: Column(
          children: [
            GlassCard(
              borderColor: AppColors.gold.withValues(alpha: 0.42),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.calendar_today, color: AppColors.gold),
                      SizedBox(width: 10),
                      Text('DAILY CHALLENGE',
                          style: TextStyle(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.8,
                              color: AppColors.gold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(daily.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(
                    'Seed ${DailyService.seedFor(now)} · Same challenge for everyone on this date. '
                    'Best today: ${formatScore(profile.dailyBestScore)}',
                    style: const TextStyle(fontSize: 11, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const SectionTitle('DAILY MISSIONS', subtitle: 'Reset at local midnight'),
            const SizedBox(height: 12),
            ...missions.map((mission) {
              final progress = profile.daily.missionProgress[mission.id] ?? 0;
              final claimed = profile.daily.claimedMissions.contains(mission.id);
              final complete = progress >= mission.target;
              final ratio = (progress / mission.target).clamp(0.0, 1.0);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassCard(
                  borderColor: claimed
                      ? AppColors.cyan.withValues(alpha: 0.4)
                      : complete
                          ? AppColors.gold.withValues(alpha: 0.4)
                          : AppColors.surfaceLight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(mission.title,
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w800)),
                          ),
                          Text('${mission.rewardCoins} coins · ${mission.rewardXp} XP',
                              style: const TextStyle(fontSize: 10, color: AppColors.gold)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 6,
                          backgroundColor: AppColors.surfaceLight,
                          valueColor: AlwaysStoppedAnimation(
                              claimed ? AppColors.cyan : AppColors.violet),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('$progress / ${mission.target}',
                              style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                          if (claimed)
                            const Text('CLAIMED',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.cyan)),
                          if (!claimed && complete)
                            SizedBox(
                              width: 100,
                              child: NeonButton(
                                label: 'CLAIM',
                                compact: true,
                                color: AppColors.gold,
                                onPressed: () {
                                  final earned = ref
                                      .read(profileProvider.notifier)
                                      .claimMission(
                                        mission.id,
                                        mission.rewardCoins,
                                        mission.rewardXp,
                                      );
                                  if (earned > 0) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Mission claimed: +$earned coins'),
                                        backgroundColor: AppColors.surfaceLight,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
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

extension ObjectiveKindX on ObjectiveKind {
  bool get isAccumulative => this == ObjectiveKind.orbs || this == ObjectiveKind.switches;
}
