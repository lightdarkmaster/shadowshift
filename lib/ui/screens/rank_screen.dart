import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadowshift/core/constants.dart';
import 'package:shadowshift/domain/progression/ranks.dart';
import 'package:shadowshift/state/app_providers.dart';
import 'package:shadowshift/ui/navigation.dart';
import 'package:shadowshift/ui/screens/rank_history_screen.dart';
import 'package:shadowshift/ui/widgets/app_scaffold.dart';
import 'package:shadowshift/ui/widgets/design.dart';
import 'package:shadowshift/ui/widgets/rank_emblem.dart';

/// A single, scrollable ladder: highest rank at the top, lowest at the bottom.
/// Every tier keeps its own emblem, XP band and the XP needed for the next one.
class RankScreen extends ConsumerWidget {
  const RankScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final ladder = RankConfig.all.reversed.toList();
    final current = profile.rankTier;

    return AppScaffold(
      title: 'RANKS',
      subtitle: 'Earn XP. Rise through the darkness.',
      showCoins: false,
      actions: [
        StatChip(
          icon: Icons.stars,
          value: '${RankConfig.xpLabel(profile.xp)} XP',
          color: current.color,
        ),
      ],
      body: SingleChildScrollView(
        padding: AppLayout.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionTitle(
              'RANK LADDER',
              subtitle: 'From the highest rank down to the first step',
            ),
            const SizedBox(height: AppLayout.md),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('TOP RANK', style: AppTextStyles.micro),
            ),
            const SizedBox(height: 6),
            for (var i = 0; i < ladder.length; i++) ...[
              _LadderRow(
                tier: ladder[i],
                xp: profile.xp,
                isCurrent: ladder[i].id == current.id,
              ),
              if (i != ladder.length - 1)
                Center(
                  child: Container(
                    width: 2,
                    height: 14,
                    color: ladder[i].color.withValues(alpha: 0.35),
                  ),
                ),
            ],
            const SizedBox(height: 6),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('LOWEST RANK', style: AppTextStyles.micro),
            ),
            const SizedBox(height: AppLayout.lg),
            Row(
              children: [
                Expanded(
                  child: NeonButton(
                    label: 'HISTORY',
                    icon: Icons.history,
                    color: current.accentColor,
                    secondary: true,
                    compact: true,
                    onPressed: () =>
                        pushScreen(context, const RankHistoryScreen()),
                  ),
                ),
                const SizedBox(width: AppLayout.sm),
                Expanded(
                  child: NeonButton(
                    label: 'TITLES',
                    icon: Icons.palette_outlined,
                    color: current.color,
                    secondary: true,
                    compact: true,
                    onPressed: () => _showTitlesDialog(context, ref),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppLayout.md),
            GlassCard(
              borderColor: AppColors.violet.withValues(alpha: 0.22),
              padding: const EdgeInsets.symmetric(
                horizontal: AppLayout.md,
                vertical: AppLayout.sm,
              ),
              onTap: () => _showNameDialog(context, ref, profile.playerName),
              child: Row(
                children: [
                  const Icon(Icons.person_outline,
                      size: 16, color: AppColors.muted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.playerName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          profile.equippedTitleName,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.edit, size: 14, color: AppColors.violet),
                ],
              ),
            ),
            const SizedBox(height: AppLayout.xl),
          ],
        ),
      ),
    );
  }

  void _showNameDialog(BuildContext context, WidgetRef ref, String current) {
    final controller = TextEditingController(text: current);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: AppColors.violet.withValues(alpha: 0.4)),
        ),
        title: const Text('PLAYER NAME',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        content: TextField(
          controller: controller,
          maxLength: 14,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(color: AppColors.text),
          decoration: const InputDecoration(
            hintText: 'SHADOW',
            border: UnderlineInputBorder(),
          ),
          onSubmitted: (_) => _save(dialogContext, ref, controller.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('CANCEL'),
          ),
          NeonButton(
            label: 'SAVE',
            icon: Icons.check,
            compact: true,
            onPressed: () => _save(dialogContext, ref, controller.text),
          ),
        ],
      ),
    );
  }

  void _save(BuildContext dialogContext, WidgetRef ref, String value) {
    ref.read(profileProvider.notifier).setPlayerName(value);
    Navigator.of(dialogContext).pop();
  }

  void _showTitlesDialog(BuildContext context, WidgetRef ref) {
    final profile = ref.read(profileProvider);
    final unlocked = RankConfig.all
        .where((tier) => profile.unlockedTitles.contains(tier.titleId))
        .toList();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: AppColors.violet.withValues(alpha: 0.4)),
        ),
        title: const Text('PLAYER TITLES',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final tier in unlocked) ...[
                  const SizedBox(height: 4),
                  NeonButton(
                    label: tier.titleName,
                    icon: profile.equippedTitle == tier.titleId
                        ? Icons.check
                        : Icons.palette,
                    color: tier.color,
                    secondary: profile.equippedTitle != tier.titleId,
                    selected: profile.equippedTitle == tier.titleId,
                    compact: true,
                    onPressed: profile.equippedTitle == tier.titleId
                        ? null
                        : () {
                            ref
                                .read(profileProvider.notifier)
                                .equipTitle(tier.titleId);
                            Navigator.of(dialogContext).pop();
                          },
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }
}

class _LadderRow extends StatelessWidget {
  const _LadderRow({
    required this.tier,
    required this.xp,
    required this.isCurrent,
  });

  final RankTier tier;
  final int xp;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final unlocked = xp >= tier.minXp;
    final next = RankConfig.next(tier);
    final progress = isCurrent ? RankConfig.progressForXp(xp) : null;
    final strength = unlocked ? 1.0 : 0.55;

    return GlassCard(
      borderColor: isCurrent
          ? tier.color.withValues(alpha: 0.85)
          : tier.color.withValues(alpha: 0.22),
      padding: const EdgeInsets.all(AppLayout.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              RankEmblem(
                tier: tier,
                size: 54,
                animate: isCurrent || (unlocked && tier.hasSpecialEffect),
              ),
              const SizedBox(width: AppLayout.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            tier.name,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: tier.color.withValues(alpha: strength),
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.3,
                            ),
                          ),
                        ),
                        if (isCurrent) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: tier.color.withValues(alpha: 0.18),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.chip),
                              border: Border.all(
                                  color: tier.color.withValues(alpha: 0.6)),
                            ),
                            child: Text(
                              'YOU',
                              style: TextStyle(
                                color: tier.color,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      tier.xpRange,
                      style: TextStyle(
                        color: tier.color.withValues(alpha: strength * 0.9),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.7,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tier.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: unlocked
                            ? AppColors.muted
                            : AppColors.muted.withValues(alpha: 0.6),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppLayout.sm),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: tier.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.chip),
              border: Border.all(color: tier.color.withValues(alpha: 0.24)),
            ),
            child: Row(
              children: [
                Icon(
                  unlocked ? Icons.flag_outlined : Icons.lock_outline,
                  size: 12,
                  color: tier.color.withValues(alpha: strength),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    next == null
                        ? 'TOP RANK · ${RankConfig.xpLabel(tier.minXp)}+ XP'
                        : '${unlocked ? 'REACH' : 'ENTER'} ${RankConfig.xpLabel(tier.minXp)} XP',
                    style: TextStyle(
                      color: tier.color.withValues(alpha: strength),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                if (next != null) ...[
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'NEXT: ${next.name} · ${RankConfig.xpLabel(next.minXp)} XP',
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isCurrent && progress != null && !progress.isMax && next != null) ...[
            const SizedBox(height: AppLayout.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.progress),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(
                    begin: 0, end: progress.progress.clamp(0.0, 1.0)),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 7,
                  backgroundColor: AppColors.surfaceLight,
                  valueColor: AlwaysStoppedAnimation(tier.color),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${RankConfig.xpLabel(xp)} XP',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.muted,
                  ),
                ),
                Text(
                  '${RankConfig.xpLabel(progress.remainingXp)} XP TO ${next.name}',
                  style: TextStyle(
                    fontSize: 10,
                    color: tier.color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
