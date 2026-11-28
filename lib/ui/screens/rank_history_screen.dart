import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadowshift/core/constants.dart';
import 'package:shadowshift/domain/progression/catalog.dart';
import 'package:shadowshift/domain/progression/ranks.dart';
import 'package:shadowshift/state/app_providers.dart';
import 'package:shadowshift/ui/widgets/app_scaffold.dart';
import 'package:shadowshift/ui/widgets/design.dart';
import 'package:shadowshift/ui/widgets/rank_emblem.dart';

class RankHistoryScreen extends ConsumerWidget {
  const RankHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(profileProvider).rankHistory.reversed.toList();
    return AppScaffold(
      title: 'RANK HISTORY',
      subtitle: 'Every promotion on your journey',
      body: SingleChildScrollView(
        padding: AppLayout.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (history.isEmpty)
              GlassCard(
                child: Column(
                  children: const [
                    Icon(Icons.history, size: 42, color: AppColors.muted),
                    SizedBox(height: AppLayout.md),
                    Text(
                      'NO PROMOTIONS YET',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Earn XP in a run or claim a mission to reach your first rank.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              )
            else
              for (final entry in history) ...[
                GlassCard(
                  borderColor: entry.toTier.color.withValues(alpha: 0.35),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          RankEmblem(tier: entry.fromTier, size: 42, animate: false),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward,
                              size: 16, color: AppColors.muted),
                          const SizedBox(width: 8),
                          RankEmblem(tier: entry.toTier, size: 52),
                          const SizedBox(width: AppLayout.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.toTier.name,
                                  style: TextStyle(
                                    color: entry.toTier.color,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                Text(
                                  'from ${entry.fromTier.name}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppLayout.md),
                      Row(
                        children: [
                          Expanded(
                            child: _Detail(
                              label: 'PROMOTED AT',
                              value: entry.toTier.isMax
                                  ? 'MAX RANK'
                                  : '${RankConfig.xpLabel(entry.xpThreshold)} XP',
                            ),
                          ),
                          Expanded(
                            child: _Detail(
                              label: 'XP EARNED',
                              value: '+${entry.earnedXp}',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatDate(entry.achievedAt),
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.muted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      if (entry.rewardId.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.card_giftcard,
                                size: 14, color: AppColors.gold),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                RankConfig.rewardName(entry.rewardId),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.gold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (entry.achievementIds.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'ACHIEVEMENTS: ${entry.achievementIds.map(_achievementName).join(', ')}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.cyan,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppLayout.md),
              ],
            const SizedBox(height: AppLayout.xl),
          ],
        ),
      ),
    );
  }

  static String _achievementName(String id) =>
      Achievements.byId(id)?.title ?? id;

  static String _formatDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return 'DATE UNKNOWN';
    final local = parsed.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$local.year-$month-$day  $hour:$minute';
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.micro),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
