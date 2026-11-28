import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadowshift/core/constants.dart';
import 'package:shadowshift/core/utils.dart';
import 'package:shadowshift/domain/game/enums.dart';
import 'package:shadowshift/domain/progression/catalog.dart';
import 'package:shadowshift/domain/services/daily_service.dart';
import 'package:shadowshift/domain/services/launch_service.dart';
import 'package:shadowshift/state/app_providers.dart';
import 'package:shadowshift/ui/navigation.dart';
import 'package:shadowshift/ui/screens/challenge_selection_screen.dart';
import 'package:shadowshift/ui/screens/gameplay_screen.dart';
import 'package:shadowshift/ui/widgets/app_scaffold.dart';
import 'package:shadowshift/ui/widgets/design.dart';

class ModeSelectionScreen extends ConsumerWidget {
  const ModeSelectionScreen({super.key, this.initialMode = 0});

  final int initialMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final now = DateTime.now();
    final daily = DailyService.challengeFor(now);
    final modes = GameMode.values;
    return AppScaffold(
      title: 'SELECT MODE',
      subtitle: 'Choose your protocol',
      body: SingleChildScrollView(
        padding: AppLayout.pagePadding,
        child: Column(
          children: [
            for (final mode in modes)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ModeCard(
                  mode: mode,
                  best: profile.bestScores[mode.name] ?? 0,
                  subtitle: mode == GameMode.daily
                      ? '${daily.title} · ${dateKey(now)}'
                      : mode == GameMode.challenge
                          ? Challenges.nextUncompleted(profile.completedChallenges) == null
                              ? '${profile.completedChallenges.length}/${Challenges.all.length} complete · replay'
                              : '${profile.completedChallenges.length}/${Challenges.all.length} complete'
                          : mode.description,
                  onTap: () => _launch(context, mode),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _launch(BuildContext context, GameMode mode) {
    if (mode == GameMode.challenge) {
      pushScreen(context, const ChallengeSelectionScreen());
      return;
    }
    final launch = LaunchService.create(mode);
    pushScreen(context, GameplayScreen(launch: launch));
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.mode,
    required this.best,
    required this.subtitle,
    required this.onTap,
  });

  final GameMode mode;
  final int best;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = switch (mode) {
      GameMode.classic => AppColors.cyan,
      GameMode.timeAttack => AppColors.pink,
      GameMode.challenge => AppColors.violet,
      GameMode.daily => AppColors.gold,
    };
    final icon = switch (mode) {
      GameMode.classic => Icons.all_inclusive,
      GameMode.timeAttack => Icons.timer,
      GameMode.challenge => Icons.extension,
      GameMode.daily => Icons.today,
    };
    return GlassCard(
      borderColor: color.withValues(alpha: 0.35),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: color.withValues(alpha: 0.14),
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mode.label,
                    style: TextStyle(
                        fontWeight: FontWeight.w900, letterSpacing: 1.5, color: color)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(fontSize: 11, color: AppColors.muted),
                    maxLines: 2),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('BEST', style: TextStyle(fontSize: 9, color: AppColors.muted)),
              Text(formatScore(best),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ],
          ),
        ],
      ),
    );
  }
}
