import 'package:shadowshift/core/utils.dart';
import 'package:shadowshift/data/models/profile.dart';
import 'package:shadowshift/domain/game/entities.dart';
import 'package:shadowshift/domain/game/enums.dart';
import 'package:shadowshift/domain/progression/catalog.dart';
import 'package:shadowshift/domain/progression/ranks.dart';
import 'package:shadowshift/domain/services/daily_service.dart';
import 'package:shadowshift/domain/services/rank_service.dart';

class RewardSummary {
  RewardSummary({
    required this.profile,
    required this.coins,
    required this.xp,
    required this.levelBefore,
    required this.levelAfter,
    required this.newAchievements,
    required this.challengeCompleted,
    required this.completedMissionIds,
    required this.isNewBest,
    this.rankBefore,
    this.rankAfter,
    this.xpAwards = const [],
    this.rankPromotions = const [],
    this.win = false,
    this.winStreak = 0,
    this.duplicate = false,
    this.invalid = false,
  });

  final PlayerProfile profile;
  final int coins;
  final int xp;
  final int levelBefore;
  final int levelAfter;
  final List<String> newAchievements;
  final ChallengeDef? challengeCompleted;
  final List<String> completedMissionIds;
  final bool isNewBest;
  final RankTier? rankBefore;
  final RankTier? rankAfter;
  final List<RankXpAward> xpAwards;
  final List<RankPromotion> rankPromotions;
  final bool win;
  final int winStreak;
  final bool duplicate;
  final bool invalid;

  bool get promoted => rankPromotions.isNotEmpty;
}

/// Pure reward/economy rules. Mutates a copy of the profile so callers always
/// commit one atomic update.
class ProgressionService {
  static RewardSummary applyRun(
    PlayerProfile source,
    RunResult result, {
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();
    final today = dateKey(currentTime);
    final rankBefore = source.rankTier;
    final levelBefore = source.level;
    final isNewBest = result.score > (source.bestScores[result.mode.name] ?? 0);

    // Quitting never reaches this method in normal play, but a malformed or
    // replayed result must also stay worthless at the domain boundary.
    final valid = result.reason != RunEndReason.quit &&
        result.score >= 0 &&
        result.seconds.isFinite &&
        result.seconds >= 0 &&
        result.orbs >= 0 &&
        result.switches >= 0 &&
        result.maxCombo >= 0 &&
        result.dodges >= 0;
    final duplicate = result.runId.isNotEmpty &&
        source.processedRunIds.contains(result.runId);
    if (!valid || duplicate) {
      return RewardSummary(
        profile: source.copy(),
        coins: 0,
        xp: 0,
        levelBefore: levelBefore,
        levelAfter: levelBefore,
        newAchievements: const [],
        challengeCompleted: null,
        completedMissionIds: const [],
        isNewBest: false,
        rankBefore: rankBefore,
        rankAfter: rankBefore,
        duplicate: duplicate,
        invalid: !valid,
      );
    }

    final profile = source.copy();
    if (profile.daily.date != today) {
      // Carry streak/last claim date forward so a run after midnight does not
      // break a streak that was still valid when the day changed.
      profile.daily = DailyState(
        date: today,
        streak: profile.daily.streak,
        lastRewardDate: profile.daily.lastRewardDate,
      );
    }
    if (result.runId.isNotEmpty) {
      profile.processedRunIds.add(result.runId);
      if (profile.processedRunIds.length > 256) {
        profile.processedRunIds =
            profile.processedRunIds.skip(profile.processedRunIds.length - 256).toSet();
      }
    }

    profile.totalRuns++;
    profile.totalOrbs += result.orbs;
    profile.totalShifts += result.switches;
    profile.totalSeconds += result.seconds.round();
    profile.bestCombo = profile.bestCombo > result.maxCombo ? profile.bestCombo : result.maxCombo;
    final modeKey = result.mode.name;
    if (result.score > (profile.bestScores[modeKey] ?? 0)) {
      profile.bestScores[modeKey] = result.score;
    }
    if (result.mode == GameMode.timeAttack &&
        result.score > profile.bestTimeAttackScore) {
      profile.bestTimeAttackScore = result.score;
    }
    if (result.mode == GameMode.daily && result.score > profile.dailyBestScore) {
      profile.dailyBestScore = result.score;
    }

    ChallengeDef? completedChallenge;
    var challengeCoins = 0;
    var challengeXp = 0;
    if (result.objectiveMet && result.challengeId != null) {
      final challenge = Challenges.byId(result.challengeId!);
      if (challenge != null && !profile.completedChallenges.contains(challenge.id)) {
        profile.completedChallenges.add(challenge.id);
        challengeCoins = challenge.rewardCoins;
        challengeXp = challenge.rewardXp;
        completedChallenge = challenge;
      }
    }

    final completedMissions = <String>[];
    for (final mission in DailyService.missionsFor(currentTime)) {
      if (profile.daily.claimedMissions.contains(mission.id)) continue;
      final value = DailyService.missionProgress(mission, result);
      final previous = profile.daily.missionProgress[mission.id] ?? 0;
      final next = DailyService.accumulates(mission.kind)
          ? previous + value
          : (previous > value ? previous : value);
      profile.daily.missionProgress[mission.id] = next;
      if (next >= mission.target) completedMissions.add(mission.id);
    }

    final newAchievements = <String>[];
    var achievementCoins = 0;
    for (final definition in Achievements.unique) {
      if (profile.achievements.contains(definition.id)) continue;
      if (_isUnlocked(definition.id, profile, result)) {
        profile.achievements.add(definition.id);
        achievementCoins += definition.rewardCoins;
        newAchievements.add(definition.id);
      }
    }
    final win = RankService.isWin(result, isNewBest);
    if (win) {
      profile.winStreak++;
      if (profile.winStreak > profile.bestWinStreak) {
        profile.bestWinStreak = profile.winStreak;
      }
    } else {
      profile.winStreak = 0;
    }

    // One reward calculation feeds both the stored profile and the live HUD
    // preview, so tweaking an award can never make them disagree.
    final preview = previewRunRewards(
      result,
      isNewBest: isNewBest,
      winStreak: profile.winStreak,
      // Only suppress objective XP when the challenge actually paid this run;
      // replaying a finished challenge still earns the objective award.
      objectiveAlreadyRewarded: challengeXp > 0,
      challengeRewardCoins: challengeCoins,
      challengeRewardXp: challengeXp,
      achievementRewardCoins: achievementCoins,
      newAchievementIds: newAchievements,
    );
    final awards = preview.awards;
    profile.coins += preview.coins;
    final promotions = RankService.grantXp(
      profile,
      preview.xp,
      currentTime,
      achievementIds: newAchievements,
    );

    return RewardSummary(
      profile: profile,
      coins: preview.coins,
      xp: preview.xp,
      levelBefore: levelBefore,
      levelAfter: profile.level,
      newAchievements: newAchievements,
      challengeCompleted: completedChallenge,
      completedMissionIds: completedMissions,
      isNewBest: isNewBest,
      rankBefore: rankBefore,
      rankAfter: profile.rankTier,
      xpAwards: awards,
      rankPromotions: promotions,
      win: win,
      winStreak: profile.winStreak,
    );
  }

  /// Preview of the rewards a run has earned so far. Shares the economy rules
  /// with [applyRun] so an in-game HUD can never show a gain settlement won't
  /// actually pay. Callers that don't yet know an achievement/mission outcome
  /// simply leave those bonuses at zero.
  static ({
    int coins,
    int xp,
    List<RankXpAward> awards,
  }) previewRunRewards(
    RunResult result, {
    required bool isNewBest,
    required int winStreak,
    bool objectiveAlreadyRewarded = false,
    int challengeRewardCoins = 0,
    int challengeRewardXp = 0,
    int achievementRewardCoins = 0,
    List<String> newAchievementIds = const [],
  }) {
    final baseCoins = (result.score ~/ 28) +
        result.orbs * 2 +
        (result.objectiveMet ? 100 : 0);
    final coins = baseCoins.clamp(5, 2000) +
        challengeRewardCoins +
        achievementRewardCoins;
    final awards = RankService.runAwards(
      result: result,
      isNewBest: isNewBest,
      objectiveAlreadyRewarded: objectiveAlreadyRewarded,
      winStreak: winStreak,
      challengeRewardXp: challengeRewardXp,
      newAchievementIds: newAchievementIds,
    );
    final xp = awards.fold<int>(0, (sum, award) => sum + award.amount);
    return (coins: coins, xp: xp, awards: awards);
  }

  static bool _isUnlocked(String id, PlayerProfile p, RunResult r) => switch (id) {
        'first_run' => p.totalRuns >= 1,
        'orbs_100' => p.totalOrbs >= 100,
        'orbs_500' => p.totalOrbs >= 500,
        'combo_10' => p.bestCombo >= 10,
        'combo_25' => p.bestCombo >= 25,
        'score_5k' => r.score >= 5000 || p.bestScores.values.any((v) => v >= 5000),
        'score_20k' => r.score >= 20000 || p.bestScores.values.any((v) => v >= 20000),
        'survive_60' => r.seconds >= 60,
        'shifts_500' => p.totalShifts >= 500,
        'runs_25' => p.totalRuns >= 25,
        'challenges_3' => p.completedChallenges.length >= 3,
        'level_10' => p.level >= 10,
        'orbs_1000' => p.totalOrbs >= 1000,
        'shifts_100' => p.totalShifts >= 100,
        'survive_120' => r.seconds >= 120,
        'combo_35' => p.bestCombo >= 35,
        'runs_10' => p.totalRuns >= 10,
        'runs_50' => p.totalRuns >= 50,
        'streak_3' => p.bestWinStreak >= 3,
        'streak_7' => p.bestWinStreak >= 7,
        'time_attack_2k' => p.bestTimeAttackScore >= 2000 ||
            (r.mode == GameMode.timeAttack && r.score >= 2000),
        'daily_1500' => p.dailyBestScore >= 1500 ||
            (r.mode == GameMode.daily && r.score >= 1500),
        'level_20' => p.level >= 20,
        'challenges_6' => p.completedChallenges.length >= Challenges.all.length,
        'rank_phantom' => RankConfig.forXp(p.xp).minXp >= 3000,
        'full_kit' => p.unlockedCharacters.length >= 2 &&
            p.unlockedSkins.length >= 2 &&
            p.unlockedEffects.length >= 2 &&
            p.unlockedAbilities.length >= 2 &&
            p.unlockedCompanions.length >= 2,
        _ => false,
      };

  /// Purchases an item and returns the updated profile, or null if the player
  /// cannot afford it or already owns it.
  static PlayerProfile? purchase(PlayerProfile source, String itemId, int price, String category) {
    var owned = switch (category) {
      'character' => source.unlockedCharacters,
      'skin' => source.unlockedSkins,
      'effect' => source.unlockedEffects,
      'ability' => source.unlockedAbilities,
      'companion' => source.unlockedCompanions,
      _ => <String>{},
    };
    if (owned.contains(itemId) || source.coins < price) return null;
    final next = source.copy();
    next.coins -= price;
    owned = switch (category) {
      'character' => next.unlockedCharacters,
      'skin' => next.unlockedSkins,
      'effect' => next.unlockedEffects,
      'ability' => next.unlockedAbilities,
      'companion' => next.unlockedCompanions,
      _ => next.unlockedCharacters,
    };
    owned.add(itemId);
    return next;
  }

  /// Claim a daily mission reward. Returns null when not claimable.
  static PlayerProfile? claimMission(
    PlayerProfile source,
    String missionId,
    int rewardCoins,
    int rewardXp,
    DateTime now,
  ) {
    final today = dateKey(now);
    if (source.daily.date != today || source.daily.claimedMissions.contains(missionId)) {
      return null;
    }
    final missions = DailyService.missionsFor(now);
    final mission = missions.where((m) => m.id == missionId).firstOrNull;
    if (mission == null || (source.daily.missionProgress[missionId] ?? 0) < mission.target) {
      return null;
    }
    final next = source.copy();
    next.daily.claimedMissions.add(missionId);
    next.coins += rewardCoins;
    RankService.grantXp(next, rewardXp, now);
    return next;
  }

  /// Preview of the next daily claim. Kept next to the claim logic so the UI
  /// can never advertise a different amount than the one actually awarded.
  static int dailyRewardAmount(PlayerProfile source, DateTime now) {
    final yesterday = dateKey(now.subtract(const Duration(days: 1)));
    final streak = source.daily.lastRewardDate == yesterday
        ? source.daily.streak + 1
        : 1;
    return (50 + (streak - 1) * 15).clamp(50, 250);
  }

  static ({PlayerProfile profile, int coins, int streak}) claimDailyReward(
    PlayerProfile source,
    DateTime now,
  ) {
    final today = dateKey(now);
    final profile = source.copy();
    if (profile.daily.date != today) {
      profile.daily.date = today;
      profile.daily.rewardClaimed = false;
      profile.daily.claimedMissions = <String>{};
      profile.daily.missionProgress = <String, int>{};
    }
    if (profile.daily.rewardClaimed) {
      return (profile: profile, coins: 0, streak: profile.daily.streak);
    }
    final yesterday = dateKey(now.subtract(const Duration(days: 1)));
    final streak = profile.daily.lastRewardDate == yesterday
        ? profile.daily.streak + 1
        : 1;
    final coins = (50 + (streak - 1) * 15).clamp(50, 250);
    profile.daily.rewardClaimed = true;
    profile.daily.streak = streak;
    profile.daily.lastRewardDate = today;
    profile.coins += coins;
    return (profile: profile, coins: coins, streak: streak);
  }
}
