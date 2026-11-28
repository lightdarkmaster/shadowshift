import 'package:shadowshift/data/models/profile.dart';
import 'package:shadowshift/domain/game/entities.dart';
import 'package:shadowshift/domain/progression/ranks.dart';

/// Dedicated XP rules. All XP writes go through [grantXp] so thresholds,
/// rewards and history can never drift between different reward sources.
abstract final class RankService {
  /// The existing performance curve is the "complete a match" award. Its floor
  /// guarantees the suggested +20 XP even for a very short valid run.
  static const int completeMatchFloorXp = 20;
  static const int winXp = 50;
  static const int objectiveXp = 15;
  static const int accomplishmentXp = 25;
  static const int maxStreakBonusXp = 50;
  static const int maxXpPerAward = 20000;
  /// A single grant can exceed one award (match + victory + bonuses), and the
  /// ladder now reaches six figures, so cap the total well above both.
  static const int maxXpPerGrant = 1000000;

  static int cleanAmount(Object? value, {int max = maxXpPerAward}) {
    if (value is! num || !value.isFinite) return 0;
    return value.round().clamp(0, max);
  }

  /// Classic and time-attack runs have no opponent, so a "win" is completing
  /// the objective or beating the best score for that mode.
  static bool isWin(RunResult result, bool isNewBest) =>
      result.objectiveMet || isNewBest;

  static int streakBonus(int streak) {
    if (streak <= 1) return 0;
    return ((streak - 1) * 10).clamp(0, maxStreakBonusXp);
  }

  static int matchXp(RunResult result) {
    final raw = (result.score ~/ 16) + result.orbs * 3 + result.seconds ~/ 2;
    return raw.clamp(completeMatchFloorXp, maxXpPerAward);
  }

  /// Builds the itemized XP granted by one valid run. The caller decides when
  /// a challenge/achievement has already been paid, so the same event is never
  /// rewarded twice.
  static List<RankXpAward> runAwards({
    required RunResult result,
    required bool isNewBest,
    required bool objectiveAlreadyRewarded,
    required int winStreak,
    required int challengeRewardXp,
    required List<String> newAchievementIds,
  }) {
    final awards = <RankXpAward>[
      RankXpAward(label: 'MATCH COMPLETE', amount: matchXp(result)),
    ];

    if (result.objectiveMet && !objectiveAlreadyRewarded) {
      awards.add(const RankXpAward(label: 'OBJECTIVE', amount: objectiveXp));
    }
    if (challengeRewardXp > 0) {
      awards.add(RankXpAward(label: 'CHALLENGE', amount: challengeRewardXp));
    }
    if (isWin(result, isNewBest)) {
      awards.add(const RankXpAward(label: 'VICTORY', amount: winXp));
      final bonus = streakBonus(winStreak);
      if (bonus > 0) {
        awards.add(RankXpAward(label: 'WIN STREAK x$winStreak', amount: bonus));
      }
    }
    if (newAchievementIds.isNotEmpty) {
      awards.add(RankXpAward(
        label: '${newAchievementIds.length} ACCOMPLISHMENT${newAchievementIds.length == 1 ? '' : 'S'}',
        amount: accomplishmentXp * newAchievementIds.length,
      ));
    }
    return awards;
  }

  /// Single XP write point. Returns one entry per crossed rank threshold.
  static List<RankPromotion> grantXp(
    PlayerProfile profile,
    int amount,
    DateTime now, {
    List<String> achievementIds = const [],
  }) {
    final granted = cleanAmount(amount, max: maxXpPerGrant);
    if (granted <= 0) return const [];
    final before = profile.xp;
    final after = (before + granted).clamp(0, 100000000);
    profile.xp = after;
    profile.unlockedRankRewards.addAll(RankConfig.unlockedRewardIdsForXp(after));
    // Cosmetic unlocks are automatic and never touch gameplay stats or perks.
    profile.unlockedSkins.addAll(RankConfig.unlockedSkinIdsForXp(after));
    profile.unlockedEffects.addAll(RankConfig.unlockedEffectIdsForXp(after));

    final promotions = RankConfig.promotionsBetween(
      before,
      after,
      now,
      earnedXp: granted,
      achievementIds: achievementIds,
    );
    profile.rankHistory.addAll(promotions);
    if (profile.rankHistory.length > 60) {
      profile.rankHistory = profile.rankHistory.sublist(profile.rankHistory.length - 60);
    }
    return promotions;
  }
}
