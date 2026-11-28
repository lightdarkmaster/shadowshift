import 'package:material_ui/material_ui.dart';

import 'package:shadowshift/core/utils.dart';

/// One immutable rank definition. UI never hard-codes thresholds or colours;
/// it reads everything from [RankConfig] so configuration stays centralized.
class RankTier {
  const RankTier({
    required this.id,
    required this.name,
    required this.description,
    required this.minXp,
    required this.maxXp,
    required this.color,
    required this.accentColor,
    required this.icon,
    required this.titleId,
    required this.titleName,
    required this.rewardId,
    required this.rewardName,
    required this.rewardDescription,
    this.rewardSkinId = '',
    this.rewardEffectId = '',
  });

  final String id;
  final String name;
  final String description;
  final int minXp;
  /// Inclusive upper bound. `-1` means unlimited.
  final int maxXp;
  final Color color;
  final Color accentColor;
  final IconData icon;
  final String titleId;
  final String titleName;
  final String rewardId;
  final String rewardName;
  final String rewardDescription;

  /// Cosmetic-only catalog IDs granted with this rank. Characters are never
  /// granted here because they carry gameplay perks.
  final String rewardSkinId;
  final String rewardEffectId;

  bool get isMax => maxXp < 0;

  /// Reaper and above get the subtle animated emblem treatment.
  bool get hasSpecialEffect => RankConfig.all.indexOf(this) >= 4;

  String get xpRange => isMax
      ? '${RankConfig.xpLabel(minXp)}+ XP'
      : '${RankConfig.xpLabel(minXp)} - ${RankConfig.xpLabel(maxXp)} XP';
}

/// Centralized rank configuration, XP curve and rank-safe parsing helpers.
abstract final class RankConfig {
  static const all = <RankTier>[
    RankTier(
      id: 'rookie',
      name: 'ROOKIE',
      description: 'Every legend starts somewhere!',
      minXp: 0,
      maxXp: 999,
      color: Color(0xFF9AA6B2),
      accentColor: Color(0xFFD6DEE8),
      icon: Icons.shield_outlined,
      titleId: 'fresh_meat',
      titleName: 'Fresh Meat',
      rewardId: 'default_badge',
      rewardName: 'Default player badge',
      rewardDescription: 'The standard Shadow Shift Neon badge.',
    ),
    RankTier(
      id: 'scout',
      name: 'SCOUT',
      description: 'Explore, learn, and discover the shadows.',
      minXp: 1000,
      maxXp: 2999,
      color: Color(0xFFCD7F32),
      accentColor: Color(0xFFFFD9A0),
      icon: Icons.explore_outlined,
      titleId: 'night_explorer',
      titleName: 'Night Explorer',
      rewardId: 'explorer_title',
      rewardName: 'Inferno skin + Explorer title',
      rewardDescription: 'Unlock the Inferno skin and Night Explorer title.',
      rewardSkinId: 'inferno',
    ),
    RankTier(
      id: 'phantom',
      name: 'PHANTOM',
      description: 'Silent, smart, and getting stronger.',
      minXp: 3000,
      maxXp: 8999,
      color: Color(0xFFB8D8FF),
      accentColor: Color(0xFF7FC8FF),
      icon: Icons.psychology_outlined,
      titleId: 'ghost_walker',
      titleName: 'Ghost Walker',
      rewardId: 'ghost_walker_title',
      rewardName: 'Comet effect + Ghost Walker title',
      rewardDescription: 'Unlock the Comet effect and Ghost Walker title.',
      rewardEffectId: 'comet',
    ),
    RankTier(
      id: 'shadow_hunter',
      name: 'SHADOW HUNTER',
      description: 'The shadows are your playground.',
      minXp: 9000,
      maxXp: 26999,
      color: Color(0xFFA46BFF),
      accentColor: Color(0xFFD3B6FF),
      icon: Icons.track_changes,
      titleId: 'darkness_chaser',
      titleName: 'Darkness Chaser',
      rewardId: 'hunter_border',
      rewardName: 'Pulse effect + Hunter border',
      rewardDescription: 'A violet profile border and the Pulse trail effect.',
      rewardEffectId: 'pulse',
    ),
    RankTier(
      id: 'reaper',
      name: 'REAPER',
      description: 'A deadly player among the best.',
      minXp: 27000,
      maxXp: 80999,
      color: Color(0xFFFF3B5C),
      accentColor: Color(0xFFFFA0B0),
      icon: Icons.sports_martial_arts,
      titleId: 'soul_collector',
      titleName: 'Soul Collector',
      rewardId: 'reaper_emblem',
      rewardName: 'Neon skin + Reaper emblem',
      rewardDescription: 'A crimson emblem and the Neon skin.',
      rewardSkinId: 'neon',
    ),
    RankTier(
      id: 'night_legend',
      name: 'NIGHT LEGEND',
      description: 'A rare player with legendary skills.',
      minXp: 81000,
      maxXp: 242999,
      color: Color(0xFFFFD166),
      accentColor: Color(0xFFFFF0B8),
      icon: Icons.workspace_premium,
      titleId: 'fearless_one',
      titleName: 'Fearless One',
      rewardId: 'golden_effect',
      rewardName: 'Solar skin + Nova effect',
      rewardDescription: 'A golden animated glow, Solar skin and Nova effect.',
      rewardSkinId: 'solar',
      rewardEffectId: 'nova',
    ),
    RankTier(
      id: 'shadow_master',
      name: 'SHADOW MASTER',
      description: 'The ultimate champion of the shadows.',
      minXp: 243000,
      maxXp: -1,
      color: Color(0xFFD08CFF),
      accentColor: Color(0xFF35F5F1),
      icon: Icons.emoji_events,
      titleId: 'lord_of_the_night',
      titleName: 'Lord of the Night',
      rewardId: 'legendary_avatar',
      rewardName: 'Spectrum skin + Prism effect + Legendary badge',
      rewardDescription: 'The exclusive Shadow Master cosmetics.',
      rewardSkinId: 'spectrum',
      rewardEffectId: 'prism',
    ),
  ];

  static const defaultTitleId = 'fresh_meat';
  /// Rookie starts at 0, Scout at 1,000, then every threshold triples.
  static const maxRankXp = 243000;
  static const defaultPlayerName = 'SHADOW';

  /// Exact XP numbers with thousands separators so large thresholds stay
  /// readable instead of being abbreviated as 243.0K.
  static String xpLabel(int value) => value.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (match) => ',',
      );

  static RankTier forXp(int xp) {
    for (var i = all.length - 1; i >= 0; i--) {
      if (xp >= all[i].minXp) return all[i];
    }
    return all.first;
  }

  static RankTier byId(String id) {
    for (final tier in all) {
      if (tier.id == id) return tier;
    }
    return all.first;
  }

  static RankTier? next(RankTier tier) {
    final index = all.indexOf(tier);
    if (index < 0 || index + 1 >= all.length) return null;
    return all[index + 1];
  }

  static Set<String> unlockedRewardIdsForXp(int xp) =>
      all.where((tier) => xp >= tier.minXp).map((tier) => tier.rewardId).toSet();

  static Set<String> unlockedTitleIdsForXp(int xp) =>
      all.where((tier) => xp >= tier.minXp).map((tier) => tier.titleId).toSet();

  static Set<String> unlockedSkinIdsForXp(int xp) => all
      .where((tier) => xp >= tier.minXp && tier.rewardSkinId.isNotEmpty)
      .map((tier) => tier.rewardSkinId)
      .toSet();

  static Set<String> unlockedEffectIdsForXp(int xp) => all
      .where((tier) => xp >= tier.minXp && tier.rewardEffectId.isNotEmpty)
      .map((tier) => tier.rewardEffectId)
      .toSet();

  static String titleName(String titleId) {
    for (final tier in all) {
      if (tier.titleId == titleId) return tier.titleName;
    }
    return all.first.titleName;
  }

  static String rewardName(String rewardId) {
    for (final tier in all) {
      if (tier.rewardId == rewardId) return tier.rewardName;
    }
    return all.first.rewardName;
  }

  static ({RankTier current, RankTier? next, int requiredXp, int remainingXp, double progress, bool isMax}) progressForXp(int xp) {
    final current = forXp(xp);
    final nextTier = next(current);
    if (nextTier == null) {
      return (
        current: current,
        next: null,
        requiredXp: current.minXp,
        remainingXp: 0,
        progress: 1,
        isMax: true,
      );
    }
    final span = nextTier.minXp - current.minXp;
    final earned = xp - current.minXp;
    final fraction = span <= 0 ? 0.0 : (earned / span).clamp(0.0, 1.0);
    return (
      current: current,
      next: nextTier,
      requiredXp: nextTier.minXp,
      remainingXp: (nextTier.minXp - xp).clamp(0, nextTier.minXp),
      progress: fraction,
      isMax: false,
    );
  }

  /// Returns one entry per crossed threshold so multi-rank jumps are recorded
  /// correctly instead of skipping intermediate promotions.
  static List<RankPromotion> promotionsBetween(
    int beforeXp,
    int afterXp,
    DateTime now, {
    int earnedXp = 0,
    List<String> achievementIds = const [],
  }) {
    if (afterXp <= beforeXp) return const [];
    var cursor = forXp(beforeXp);
    final promotions = <RankPromotion>[];
    while (true) {
      final target = next(cursor);
      if (target == null || afterXp < target.minXp) break;
      promotions.add(RankPromotion(
        fromRankId: cursor.id,
        toRankId: target.id,
        xpThreshold: target.minXp,
        earnedXp: earnedXp,
        achievedAt: now.toIso8601String(),
        achievementIds: List<String>.from(achievementIds),
        rewardId: target.rewardId,
      ));
      cursor = target;
    }
    return promotions;
  }

  static String sanitizePlayerName(String raw) {
    final cleaned = raw
        .trim()
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9 _-]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned.length < 3) return defaultPlayerName;
    return cleaned.length > 14 ? cleaned.substring(0, 14) : cleaned;
  }
}

/// A single XP source shown in the run report. Keeping these itemized makes
/// awards transparent and prevents the UI from guessing where XP came from.
class RankXpAward {
  const RankXpAward({required this.label, required this.amount});

  final String label;
  final int amount;

  Map<String, dynamic> toJson() => {'label': label, 'amount': amount};

  factory RankXpAward.fromJson(Object? raw) {
    if (raw is! Map) return const RankXpAward(label: 'XP', amount: 0);
    final json = Map<String, dynamic>.from(raw);
    return RankXpAward(
      label: json['label'] is String ? json['label'] as String : 'XP',
      amount: safeInt(json['amount'], 0, max: 100000000),
    );
  }
}

/// Persisted promotion history entry. Rewards and achievements unlocked at the
/// moment of promotion are stored so history stays accurate after later runs.
class RankPromotion {
  const RankPromotion({
    required this.fromRankId,
    required this.toRankId,
    required this.xpThreshold,
    required this.earnedXp,
    required this.achievedAt,
    this.achievementIds = const [],
    this.rewardId = '',
  });

  final String fromRankId;
  final String toRankId;
  final int xpThreshold;
  final int earnedXp;
  final String achievedAt;
  final List<String> achievementIds;
  final String rewardId;

  RankTier get fromTier => RankConfig.byId(fromRankId);
  RankTier get toTier => RankConfig.byId(toRankId);

  Map<String, dynamic> toJson() => {
        'fromRankId': fromRankId,
        'toRankId': toRankId,
        'xpThreshold': xpThreshold,
        'earnedXp': earnedXp,
        'achievedAt': achievedAt,
        'achievementIds': achievementIds,
        'rewardId': rewardId,
      };

  static List<RankPromotion> fromList(Iterable<RankPromotion> entries) =>
      entries.map((entry) => RankPromotion(
            fromRankId: entry.fromRankId,
            toRankId: entry.toRankId,
            xpThreshold: entry.xpThreshold,
            earnedXp: entry.earnedXp,
            achievedAt: entry.achievedAt,
            achievementIds: List<String>.from(entry.achievementIds),
            rewardId: entry.rewardId,
          )).toList(growable: true);

  factory RankPromotion.fromJson(Object? raw) {
    if (raw is! Map) {
      return const RankPromotion(
        fromRankId: 'rookie',
        toRankId: 'rookie',
        xpThreshold: 0,
        earnedXp: 0,
        achievedAt: '',
      );
    }
    final json = Map<String, dynamic>.from(raw);
    return RankPromotion(
      fromRankId: json['fromRankId'] is String ? json['fromRankId'] as String : 'rookie',
      toRankId: json['toRankId'] is String ? json['toRankId'] as String : 'rookie',
      xpThreshold: safeInt(json['xpThreshold'], 0, max: 100000000),
      earnedXp: safeInt(json['earnedXp'], 0, max: 100000000),
      achievedAt: json['achievedAt'] is String ? json['achievedAt'] as String : '',
      achievementIds: json['achievementIds'] is List
          ? (json['achievementIds'] as List).whereType<String>().toList()
          : const [],
      rewardId: json['rewardId'] is String ? json['rewardId'] as String : '',
    );
  }
}
