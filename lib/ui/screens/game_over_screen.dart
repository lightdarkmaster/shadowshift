import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadowshift/core/constants.dart';
import 'package:shadowshift/core/utils.dart';
import 'package:shadowshift/domain/game/entities.dart';
import 'package:shadowshift/domain/game/difficulty.dart';
import 'package:shadowshift/domain/game/enums.dart';
import 'package:shadowshift/domain/progression/catalog.dart';
import 'package:shadowshift/domain/services/launch_service.dart';
import 'package:shadowshift/domain/services/progression_service.dart';
import 'package:shadowshift/ui/navigation.dart';
import 'package:shadowshift/ui/screens/gameplay_screen.dart';
import 'package:shadowshift/ui/screens/main_menu.dart';
import 'package:shadowshift/ui/screens/mode_selection.dart';
import 'package:shadowshift/ui/widgets/app_scaffold.dart';
import 'package:shadowshift/ui/widgets/design.dart';

class GameOverScreen extends ConsumerWidget {
  const GameOverScreen({
    super.key,
    required this.result,
    required this.summary,
    required this.launch,
  });

  final RunResult result;
  final RewardSummary summary;
  final GameLaunch launch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final success = result.objectiveMet;
    final title = switch (result.reason) {
      RunEndReason.collision => 'SIGNAL LOST',
      RunEndReason.timeUp => 'TIME UP',
      RunEndReason.objectiveComplete => 'OBJECTIVE COMPLETE',
      RunEndReason.quit => 'RUN ENDED',
    };
    final accent = success ? AppColors.cyan : AppColors.pink;
    return AppScaffold(
      title: 'RUN REPORT',
      showBack: false,
      showCoins: false,
      actions: [
        StatChip(icon: Icons.bolt, value: '${summary.coins}', color: AppColors.gold),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Text(title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                  color: accent,
                )),
            if (launch.title != null)
              Center(
                child: Text(launch.title!,
                    style: const TextStyle(fontSize: 11, color: AppColors.muted, letterSpacing: 1.6)),
              ),
            const SizedBox(height: 16),
            GlassCard(
              borderColor: accent.withValues(alpha: 0.4),
              child: Column(
                children: [
                  Text(formatScore(result.score),
                      style: const TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w900,
                        shadows: [Shadow(color: AppColors.cyan, blurRadius: 20)],
                      )),
                  const Text('FINAL SCORE',
                      style: TextStyle(
                          fontSize: 11, letterSpacing: 3, color: AppColors.muted)),
                  if (summary.isNewBest)
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
                      ),
                      child: const Text('NEW PERSONAL BEST',
                          style: TextStyle(
                            color: AppColors.gold,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          )),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            GlassCard(
              child: Column(
                children: [
                  _StatRow([
                    _Stat('TIME', formatDuration(Duration(seconds: result.seconds.round())), Icons.timer),
                    _Stat('ORBS', '${result.orbs}', Icons.bolt),
                    _Stat('MAX COMBO', 'x${ScoreCalculator.multiplierForCombo(result.maxCombo)}', Icons.link),
                    _Stat('SHIFTS', '${result.switches}', Icons.swap_horiz),
                    _Stat('DODGES', '${result.dodges}', Icons.shield_outlined),
                    _Stat('SEED', '${result.seed % 100000}', Icons.numbers),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 14),
            GlassCard(
              borderColor: AppColors.gold.withValues(alpha: 0.25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('REWARDS', subtitle: 'Saved locally to your profile'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _RewardTile(icon: Icons.bolt, label: '+${summary.coins}', color: AppColors.gold)),
                      Expanded(child: _RewardTile(icon: Icons.stars, label: '+${summary.xp} XP', color: AppColors.violet)),
                      if (summary.levelAfter > summary.levelBefore)
                        Expanded(
                          child: _RewardTile(
                            icon: Icons.arrow_upward,
                            label: 'LV ${summary.levelAfter}',
                            color: AppColors.cyan,
                          ),
                        ),
                    ],
                  ),
                  if (summary.challengeCompleted != null) ...[
                    const SizedBox(height: 12),
                    _RewardLine(
                      icon: Icons.check_circle,
                      text: 'Challenge: ${summary.challengeCompleted!.title}',
                      detail: '+${summary.challengeCompleted!.rewardCoins} coins',
                    ),
                  ],
                  if (summary.completedMissionIds.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _RewardLine(
                        icon: Icons.assignment_turned_in,
                        text: '${summary.completedMissionIds.length} mission(s) ready to claim',
                      ),
                    ),
                  ...summary.newAchievements.map(
                    (id) => Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _RewardLine(
                        icon: Achievements.byId(id)?.icon ?? Icons.emoji_events,
                        text: 'Achievement: ${Achievements.byId(id)?.title ?? id}',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            NeonButton(
              label: 'RUN AGAIN',
              icon: Icons.replay,
              onPressed: () {
                final next = LaunchService.create(
                  launch.mode,
                  challengeId: launch.challengeId,
                );
                resetAndPush(context, GameplayScreen(launch: next));
              },
            ),
            const SizedBox(height: 10),
            NeonButton(
              label: 'CHANGE MODE',
              icon: Icons.apps,
              secondary: true,
              onPressed: () => resetAndPush(context, const ModeSelectionScreen()),
            ),
            const SizedBox(height: 10),
            NeonButton(
              label: 'MAIN MENU',
              secondary: true,
              color: AppColors.violet,
              onPressed: () => resetToScreen(context, const MainMenu()),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat {
  const _Stat(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;
}

class _StatRow extends StatelessWidget {
  const _StatRow(this.stats);

  final List<_Stat> stats;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 14,
      alignment: WrapAlignment.center,
      children: stats
          .map(
            (stat) => SizedBox(
              width: 88,
              child: Column(
                children: [
                  Icon(stat.icon, size: 19, color: AppColors.cyan),
                  const SizedBox(height: 5),
                  Text(stat.value,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  Text(stat.label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 9, color: AppColors.muted, letterSpacing: 0.6)),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _RewardTile extends StatelessWidget {
  const _RewardTile({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 5),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13)),
        ],
      ),
    );
  }
}

class _RewardLine extends StatelessWidget {
  const _RewardLine({required this.icon, required this.text, this.detail});

  final IconData icon;
  final String text;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.gold),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
        if (detail != null)
          Text(detail!, style: const TextStyle(fontSize: 11, color: AppColors.gold)),
      ],
    );
  }
}
