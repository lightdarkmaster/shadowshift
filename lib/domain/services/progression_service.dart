import 'package:shadowshift/core/utils.dart';
import 'package:shadowshift/data/models/profile.dart';
import 'package:shadowshift/domain/game/entities.dart';
import 'package:shadowshift/domain/game/enums.dart';
import 'package:shadowshift/domain/progression/catalog.dart';
import 'package:shadowshift/domain/services/daily_service.dart';

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
}

/// Pure reward/economy rules. Mutates a copy of the profile so callers always
/// commit one atomic update.
class ProgressionService {
  static RewardSummary applyRun(
    PlayerProfile source,
    RunResult result, {
    DateTime? now,
  }) {
    final profile = source.copy();
    final currentTime = now ?? DateTime.now();
    final today = dateKey(currentTime);
    if (profile.daily.date != today) {
      // Carry streak/last claim date forward so a run after midnight does not
      // break a streak that was still valid when the day changed.
      profile.daily = DailyState(
        date: today,
        streak: profile.daily.streak,
        lastRewardDate: profile.daily.lastRewardDate,
      );
    }
    final levelBefore = profile.level;
    final isNewBest = result.score > (profile.bestScores[result.mode.name] ?? 0);

    final baseCoins = (result.score ~/ 28) + result.orbs * 2 + (result.objectiveMet ? 100 : 0);
    final coins = baseCoins.clamp(5, 2000);
    final xp = (result.score ~/ 16) + result.orbs * 3 + result.seconds ~/ 2;
    profile.coins += coins;
    profile.xp += xp;
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
    if (result.objectiveMet && result.challengeId != null) {
      final challenge = Challenges.byId(result.challengeId!);
      if (challenge != null && !profile.completedChallenges.contains(challenge.id)) {
        profile.completedChallenges.add(challenge.id);
        profile.coins += challenge.rewardCoins;
        profile.xp += challenge.rewardXp;
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
    for (final definition in Achievements.all) {
      if (profile.achievements.contains(definition.id)) continue;
      if (_isUnlocked(definition.id, profile, result)) {
        profile.achievements.add(definition.id);
        profile.coins += definition.rewardCoins;
        newAchievements.add(definition.id);
      }
    }

    return RewardSummary(
      profile: profile,
      coins: coins,
      xp: xp,
      levelBefore: levelBefore,
      levelAfter: profile.level,
      newAchievements: newAchievements,
      challengeCompleted: completedChallenge,
      completedMissionIds: completedMissions,
      isNewBest: isNewBest,
    );
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
    next.xp += rewardXp;
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
