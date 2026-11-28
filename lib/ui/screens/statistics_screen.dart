import 'package:material_ui/material_ui.dart';
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
        padding: AppLayout.pagePadding,
        child: Column(
          children: [
            GlassCard(
              child: Column(
                children: [
                  const SectionTitle('LIFETIME'),
                  const SizedBox(height: AppLayout.md),
                  ResponsiveTileWrap(
                    minTileWidth: 100,
                    tileHeight: 112,
                    children: [
                      for (final stat in stats)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppLayout.sm,
                            horizontal: AppLayout.sm,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(AppRadius.iconTile),
                            border: Border.all(
                              color: AppColors.cyan.withValues(alpha: 0.18),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(stat.icon, color: AppColors.cyan, size: 21),
                              const SizedBox(height: AppLayout.sm),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  stat.value,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppLayout.xs),
                              Text(
                                stat.label,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.muted,
                                  letterSpacing: 0.6,
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
            const SizedBox(height: AppLayout.md),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('PERSONAL BESTS'),
                  const SizedBox(height: AppLayout.md),
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
                            color: switch (mode) {
                              GameMode.classic => AppColors.cyan,
                              GameMode.timeAttack => AppColors.pink,
                              GameMode.challenge => AppColors.violet,
                              GameMode.daily => AppColors.gold,
                            },
                          ),
                          const SizedBox(width: AppLayout.md),
                          Expanded(
                            child: Text(
                              mode.label,
                              style: const TextStyle(fontSize: 12, letterSpacing: 1.2),
                            ),
                          ),
                          Text(
                            formatScore(profile.bestScores[mode.name] ?? 0),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.cyan,
                            ),
                          ),
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
