import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadowshift/core/constants.dart';
import 'package:shadowshift/domain/progression/catalog.dart';
import 'package:shadowshift/domain/services/audio_service.dart';
import 'package:shadowshift/state/app_providers.dart';
import 'package:shadowshift/ui/widgets/app_scaffold.dart';
import 'package:shadowshift/ui/widgets/design.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    return DefaultTabController(
      length: 3,
      child: AppScaffold(
        title: 'SHOP',
        subtitle: 'Earned through gameplay only',
        actions: [
          StatChip(icon: Icons.bolt, value: '${profile.coins}', color: AppColors.gold),
        ],
        body: Column(
          children: [
            const TabBar(
              indicatorColor: AppColors.cyan,
              labelColor: AppColors.cyan,
              unselectedLabelColor: AppColors.muted,
              tabs: [
                Tab(text: 'SKINS'),
                Tab(text: 'EFFECTS'),
                Tab(text: 'CORES'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _ItemList(
                    items: Catalog.skins,
                    owned: profile.unlockedSkins,
                    selectedId: profile.skin,
                    category: 'skin',
                  ),
                  _ItemList(
                    items: Catalog.effects,
                    owned: profile.unlockedEffects,
                    selectedId: profile.effect,
                    category: 'effect',
                  ),
                  _ItemList(
                    items: Catalog.abilities,
                    owned: profile.unlockedAbilities,
                    selectedId: profile.ability,
                    category: 'ability',
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

class _ItemList extends ConsumerWidget {
  const _ItemList({
    required this.items,
    required this.owned,
    required this.selectedId,
    required this.category,
  });

  final List<ShopItem> items;
  final Set<String> owned;
  final String selectedId;
  final String category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
      child: Column(
        children: items.map((item) {
          final isOwned = owned.contains(item.id);
          final selected = selectedId == item.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassCard(
              borderColor: selected ? item.color.withValues(alpha: 0.65) : AppColors.surfaceLight,
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: item.color.withValues(alpha: 0.45)),
                    ),
                    child: Icon(item.icon, color: item.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.4,
                              color: item.color,
                            )),
                        const SizedBox(height: 4),
                        Text(item.description,
                            style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 86,
                    child: NeonButton(
                      label: selected ? 'EQUIPPED' : isOwned ? 'EQUIP' : '${item.price}',
                      compact: true,
                      secondary: selected,
                      color: item.color,
                      enabled: !selected,
                      onPressed: () {
                        final profile = ref.read(profileProvider);
                        final notifier = ref.read(profileProvider.notifier);
                        if (isOwned) {
                          switch (category) {
                            case 'skin':
                              notifier.selectSkin(item.id);
                            case 'effect':
                              notifier.selectEffect(item.id);
                            case 'ability':
                              notifier.selectAbility(item.id);
                          }
                          AudioService.instance.ui();
                          return;
                        }
                        if (notifier.purchaseAndSelect(item.id, item.price, category)) {
                          AudioService.instance.achievement();
                        } else if (profile.coins < item.price) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Not enough coins. Play a run to earn more.'),
                              backgroundColor: AppColors.surfaceLight,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
