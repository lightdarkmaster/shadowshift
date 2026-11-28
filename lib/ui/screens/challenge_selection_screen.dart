import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadowshift/core/constants.dart';
import 'package:shadowshift/domain/game/enums.dart';
import 'package:shadowshift/domain/progression/catalog.dart';
import 'package:shadowshift/domain/services/launch_service.dart';
import 'package:shadowshift/state/app_providers.dart';
import 'package:shadowshift/ui/navigation.dart';
import 'package:shadowshift/ui/screens/gameplay_screen.dart';
import 'package:shadowshift/ui/widgets/app_scaffold.dart';
import 'package:shadowshift/ui/widgets/design.dart';

/// Dedicated challenge roster. Challenges unlock in order; completed runs can
/// be replayed for score but only award their reward coins once.
class ChallengeSelectionScreen extends ConsumerWidget {
  const ChallengeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    return AppScaffold(
      title: 'CHALLENGES',
      subtitle: 'Complete in order to unlock the next',
      body: SingleChildScrollView(
        padding: AppLayout.pagePadding,
        child: Column(
          children: [
            for (final challenge in Challenges.all)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ChallengeCard(
                  challenge: challenge,
                  unlocked: LaunchService.isChallengeUnlocked(
                    profile,
                    challenge,
                  ),
                  done: profile.completedChallenges.contains(challenge.id),
                  onTap: () => pushScreen(
                    context,
                    GameplayScreen(
                      launch: LaunchService.create(
                        GameMode.challenge,
                        challengeId: challenge.id,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({
    required this.challenge,
    required this.unlocked,
    required this.done,
    required this.onTap,
  });

  final ChallengeDef challenge;
  final bool unlocked;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: unlocked ? onTap : null,
      borderColor: done
          ? AppColors.cyan.withValues(alpha: 0.5)
          : AppColors.surfaceLight,
      child: Row(
        children: [
          Icon(
            done
                ? Icons.check_circle
                : unlocked
                    ? Icons.play_circle_outline
                    : Icons.lock_outline,
            color: done ? AppColors.cyan : AppColors.muted,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  challenge.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  challenge.description,
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const Icon(Icons.bolt, size: 14, color: AppColors.gold),
          Text(
            '${challenge.rewardCoins}',
            style: const TextStyle(color: AppColors.gold, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
