import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadowshift/core/constants.dart';
import 'package:shadowshift/core/utils.dart';
import 'package:shadowshift/domain/game/enums.dart';
import 'package:shadowshift/state/app_providers.dart';
import 'package:shadowshift/ui/widgets/app_scaffold.dart';
import 'package:shadowshift/ui/widgets/design.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final stats = <_StatTile>[
      _StatTile('TOTAL RUNS', '${profile.totalRuns}', Icons.replay),
      _StatTile('TOTAL ORBS', '${profile.totalOrbs}', Icons.bolt),
      _StatTile('DIMENSION SHIFTS', '${profile.totalShifts}', Icons.swap_horiz),
      _StatTile('TIME SURVIVED', formatDuration(Duration(seconds: profile.totalSeconds)), Icons.timer),
      _StatTile('BEST COMBO', 'x${1 + (profile.bestCombo ~/ 5).clamp(0, 7)}', Icons.link),
      _StatTile('PLAYER LEVEL', '${profile.level}', Icons.military_tech),
    ];
    return AppScaffold(
      title: 'STATISTICS',
      subtitle: 'Your complete offline career record',
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
        child: Column(
          children: [
            GlassCard(
              child: Column(
                children: [
                  const SectionTitle('LIFETIME'),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: stats
                        .map(
                          (stat) => SizedBox(
                            width: 104,
                            child: GlassCard(
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                              borderColor: AppColors.cyan.withValues(alpha: 0.18),
                              child: Column(
                                children: [
                                  Icon(stat.icon, color: AppColors.cyan, size: 21),
                                  const SizedBox(height: 7),
                                  Text(stat.value,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          fontSize: 15, fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 3),
                                  Text(stat.label,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          fontSize: 8.5,
                                          color: AppColors.muted,
                                          letterSpacing: 0.6)),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('PERSONAL BESTS'),
                  const SizedBox(height: 12),
                  ...GameMode.values.map(
                    (mode) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Row(
                        children: [
                          Icon(
                            switch (mode) {
                              GameMode.classic => Icons.all_inclusive,
                              GameMode.timeAttack => Icons.timer,
                              GameMode.challenge => Icons.extension,
                              GameMode.daily => Icons.today,
                            },
                            size: 17,
                            color: AppColors.violet,
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(mode.label,
                              style: const TextStyle(fontSize: 12, letterSpacing: 1.2))),
                          Text(formatScore(profile.bestScores[mode.name] ?? 0),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, color: AppColors.cyan)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile {
  const _StatTile(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;
}
