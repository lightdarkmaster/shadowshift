import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadowshift/core/constants.dart';
import 'package:shadowshift/domain/progression/catalog.dart';
import 'package:shadowshift/domain/services/audio_service.dart';
import 'package:shadowshift/state/app_providers.dart';
import 'package:shadowshift/ui/widgets/app_scaffold.dart';
import 'package:shadowshift/ui/widgets/design.dart';
import 'package:shadowshift/ui/widgets/notice_dialog.dart';

class CharacterSelectionScreen extends ConsumerWidget {
  const CharacterSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final active = Catalog.find(Catalog.characters, profile.character);
    return AppScaffold(
      title: 'RUNNERS',
      subtitle: 'Every runner changes how you play',
      body: SingleChildScrollView(
        padding: AppLayout.pagePadding,
        child: Column(
          children: [
            GlassCard(
              borderColor: AppColors.violet.withValues(alpha: 0.35),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: active.color.withValues(alpha: 0.14),
                      border: Border.all(
                        color: active.color.withValues(alpha: 0.55),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: active.color.withValues(alpha: 0.35),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Icon(active.icon, size: 32, color: active.color),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          active.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 19,
                            letterSpacing: 2,
                            color: active.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text('ACTIVE RUNNER',
                            style: TextStyle(fontSize: 10, color: AppColors.muted, letterSpacing: 1.5)),
                        const SizedBox(height: 2),
                        Text(
                          active.description,
                          style: const TextStyle(fontSize: 11, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            ...Catalog.characters.map((character) {
              final owned = profile.unlockedCharacters.contains(character.id);
              final selected = profile.character == character.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassCard(
                  borderColor: selected
                      ? character.color.withValues(alpha: 0.7)
                      : AppColors.surfaceLight,
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: character.color.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: character.color.withValues(alpha: 0.45)),
                        ),
                        child: Icon(character.icon, color: character.color),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(character.name,
                                style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.4,
                                    color: character.color)),
                            const SizedBox(height: 4),
                            Text(character.description,
                                style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 100,
                        child: NeonButton(
                          label: selected
                              ? 'ACTIVE'
                              : owned
                                  ? 'SELECT'
                                  : '${character.price}',
                          compact: true,
                          secondary: selected,
                          color: character.color,
                          selected: selected,
                          onPressed: () {
                            if (selected) return;
                            if (owned) {
                              ref.read(profileProvider.notifier).selectCharacter(character.id);
                              AudioService.instance.ui();
                            } else if (ref
                                .read(profileProvider.notifier)
                                .purchaseAndSelect(character.id, character.price, 'character')) {
                              AudioService.instance.achievement();
                            } else {
                              _notEnough(context, character);
                            }
                          },
                        ),
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

void _notEnough(BuildContext context, ShopItem character) {
  showNoticeDialog(
    context,
    title: 'INSUFFICIENT COINS',
    message: 'You need ${character.price} energy coins for ${character.name}. '
        'Play a run to earn more.',
    tone: NoticeTone.error,
    icon: Icons.sentiment_dissatisfied,
    badgeIcon: Icons.monetization_on,
  );
}
