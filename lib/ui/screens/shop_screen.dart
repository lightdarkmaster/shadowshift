import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadowshift/core/constants.dart';
import 'package:shadowshift/domain/progression/catalog.dart';
import 'package:shadowshift/domain/services/audio_service.dart';
import 'package:shadowshift/state/app_providers.dart';
import 'package:shadowshift/ui/widgets/app_scaffold.dart';
import 'package:shadowshift/ui/widgets/design.dart';
import 'package:shadowshift/ui/widgets/notice_dialog.dart';
import 'package:shadowshift/ui/widgets/shop_item_dialog.dart';

class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    return DefaultTabController(
      length: 4,
      child: AppScaffold(
        title: 'SHOP',
        subtitle: 'Earned through gameplay only',
        body: Column(
          children: [
            const TabBar(
              indicatorColor: AppColors.cyan,
              labelColor: AppColors.cyan,
              unselectedLabelColor: AppColors.muted,
              labelPadding: EdgeInsets.symmetric(horizontal: 6),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
              tabs: [
                Tab(text: 'SKINS'),
                Tab(text: 'EFFECTS'),
                Tab(text: 'CORES'),
                Tab(text: 'COMPANIONS'),
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
                  _ItemList(
                    items: Catalog.companions,
                    owned: profile.unlockedCompanions,
                    selectedId: profile.companion,
                    category: 'companion',
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
      padding: AppLayout.pagePadding,
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
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      onTap: () => _showDetails(context, ref, item, isOwned, selected),
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
                                const SizedBox(height: 3),
                                Text(
                                  'TAP FOR EXAMPLE',
                                  style: TextStyle(
                                    fontSize: 9,
                                    letterSpacing: 0.8,
                                    color: item.color.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 100,
                    child: NeonButton(
                      label: selected ? 'EQUIPPED' : isOwned ? 'EQUIP' : '${item.price}',
                      compact: true,
                      secondary: selected,
                      color: item.color,
                      selected: selected,
                      onPressed: () => _applyItem(context, ref, item, isOwned),
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

  void _showDetails(
    BuildContext context,
    WidgetRef ref,
    ShopItem item,
    bool isOwned,
    bool selected,
  ) {
    showDialog<void>(
      context: context,
      builder: (_) => ShopItemDetailDialog(
        item: item,
        category: category,
        isOwned: isOwned,
        selected: selected,
        onUse: () => _applyItem(context, ref, item, isOwned),
      ),
    );
  }

  void _applyItem(BuildContext context, WidgetRef ref, ShopItem item, bool isOwned) {
    final notifier = ref.read(profileProvider.notifier);
    if (isOwned) {
      switch (category) {
        case 'skin':
          notifier.selectSkin(item.id);
        case 'effect':
          notifier.selectEffect(item.id);
        case 'ability':
          notifier.selectAbility(item.id);
        case 'companion':
          notifier.selectCompanion(item.id);
      }
      AudioService.instance.ui();
      return;
    }

    if (notifier.purchaseAndSelect(item.id, item.price, category)) {
      AudioService.instance.achievement();
      return;
    }

    final profile = ref.read(profileProvider);
    if (profile.coins < item.price) {
      showNoticeDialog(
        context,
        title: 'INSUFFICIENT COINS',
        message: 'You need ${item.price} coins for ${item.name}. '
            'Play a run to earn more.',
        tone: NoticeTone.error,
        icon: Icons.sentiment_dissatisfied,
        badgeIcon: Icons.monetization_on,
      );
    }
  }
}
