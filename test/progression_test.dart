import 'package:flutter_test/flutter_test.dart';
import 'package:shadowshift/core/utils.dart';
import 'package:shadowshift/data/models/profile.dart';
import 'package:shadowshift/domain/game/entities.dart';
import 'package:shadowshift/domain/game/enums.dart';
import 'package:shadowshift/domain/progression/catalog.dart';
import 'package:shadowshift/domain/services/daily_service.dart';
import 'package:shadowshift/domain/services/launch_service.dart';
import 'package:shadowshift/domain/services/progression_service.dart';

RunResult result({
  GameMode mode = GameMode.classic,
  int score = 1000,
  int orbs = 10,
  int switches = 12,
  int maxCombo = 11,
  double seconds = 25,
  RunEndReason reason = RunEndReason.collision,
  String? challengeId,
}) {
  return RunResult(
    mode: mode,
    score: score,
    seconds: seconds,
    orbs: orbs,
    maxCombo: maxCombo,
    switches: switches,
    dodges: 8,
    reason: reason,
    objective: const RunObjective(kind: ObjectiveKind.none, target: 0),
    seed: 1,
    challengeId: challengeId,
  );
}

void main() {
  group('achievement catalog', () {
    test('achievement ids are unique and resolvable', () {
      final ids = Achievements.all.map((achievement) => achievement.id).toList();
      expect(ids.length, 26);
      expect(ids.toSet().length, ids.length);
      expect(Achievements.unique.length, ids.length);
      for (final achievement in Achievements.all) {
        expect(Achievements.byId(achievement.id), same(achievement));
      }
    });
  });

  group('daily generation', () {
    final date = DateTime(2026, 11, 27);

    test('daily seed, objective and missions are deterministic', () {
      final a = DailyService.challengeFor(date);
      final b = DailyService.challengeFor(DateTime(2026, 11, 27, 23, 59));
      expect(a.target, b.target);
      expect(a.secondaryTarget, b.secondaryTarget);
      expect(DailyService.seedFor(date), DailyService.seedFor(DateTime(2026, 11, 27, 1)));
      final missionsA = DailyService.missionsFor(date);
      final missionsB = DailyService.missionsFor(date);
      expect(missionsA.map((m) => m.id), missionsB.map((m) => m.id));
      expect(missionsA.map((m) => m.target), missionsB.map((m) => m.target));
    });

    test('missions have three distinct objectives', () {
      final missions = DailyService.missionsFor(date);
      expect(missions.length, 3);
      expect(missions.map((m) => m.kind).toSet().length, 3);
    });

    test('different dates usually produce different challenges', () {
      expect(
        DailyService.seedFor(date),
        isNot(DailyService.seedFor(date.add(const Duration(days: 1)))),
      );
    });
  });

  group('run rewards', () {
    final now = DateTime(2026, 11, 27, 12);

    test('run updates stats, best score and awards coins and XP', () {
      final summary = ProgressionService.applyRun(PlayerProfile(), result(), now: now);
      expect(summary.profile.totalRuns, 1);
      expect(summary.profile.totalOrbs, 10);
      expect(summary.profile.totalShifts, 12);
      expect(summary.profile.bestScores['classic'], 1000);
      expect(summary.coins, greaterThan(0));
      expect(summary.xp, greaterThan(0));
      expect(summary.newAchievements, contains('first_run'));
      expect(summary.isNewBest, isTrue);
    });

    test('new milestones unlock once and never repeat', () {
      final profile = PlayerProfile(
        xp: 30000,
        totalRuns: 9,
        totalOrbs: 999,
        totalShifts: 99,
        bestCombo: 35,
        bestWinStreak: 7,
        bestTimeAttackScore: 2000,
        dailyBestScore: 1500,
        completedChallenges: Challenges.all.map((c) => c.id).toSet(),
        unlockedCharacters: {'nyx', 'flux'},
        unlockedSkins: {'aurora', 'ember'},
        unlockedEffects: {'classic', 'pulse'},
        unlockedAbilities: {'none', 'overclock'},
        unlockedCompanions: {'none', 'wisp'},
      );

      final first = ProgressionService.applyRun(
        profile,
        result(seconds: 121),
        now: now,
      );
      expect(
        first.newAchievements,
        containsAll([
          'orbs_1000',
          'shifts_100',
          'survive_120',
          'combo_35',
          'runs_10',
          'streak_3',
          'streak_7',
          'time_attack_2k',
          'daily_1500',
          'level_20',
          'challenges_6',
          'rank_phantom',
          'full_kit',
        ]),
      );

      final second = ProgressionService.applyRun(
        first.profile,
        result(seconds: 121),
        now: now.add(const Duration(minutes: 1)),
      );
      expect(second.newAchievements, isEmpty);
    });

    test('best score is not overwritten by a worse run', () {
      final first = ProgressionService.applyRun(PlayerProfile(), result(score: 5000), now: now);
      final second = ProgressionService.applyRun(first.profile, result(score: 100), now: now);
      expect(second.profile.bestScores['classic'], 5000);
      expect(second.isNewBest, isFalse);
    });

    test('challenge rewards are granted only once', () {
      final challenge = Challenges.all.first;
      final run = result(
        mode: GameMode.challenge,
        score: 3000,
        seconds: 40,
        reason: RunEndReason.objectiveComplete,
        challengeId: challenge.id,
      );
      final first = ProgressionService.applyRun(PlayerProfile(), run, now: now);
      expect(first.challengeCompleted?.id, challenge.id);
      expect(first.profile.completedChallenges, contains(challenge.id));
      final second = ProgressionService.applyRun(first.profile, run, now: now);
      expect(second.challengeCompleted, isNull);
      expect(second.profile.coins, first.profile.coins + second.coins);
    });

    test('challenge unlocking is sequential', () {
      final profile = PlayerProfile();
      expect(
        LaunchService.isChallengeUnlocked(profile, Challenges.all.first),
        isTrue,
      );
      expect(
        LaunchService.isChallengeUnlocked(profile, Challenges.all[1]),
        isFalse,
      );
      final completed = PlayerProfile(
        completedChallenges: {Challenges.all.first.id},
      );
      expect(
        LaunchService.isChallengeUnlocked(completed, Challenges.all[1]),
        isTrue,
      );
    });
  });

  group('economy and persistence', () {
    test('purchase deducts coins and unlocks an item', () {
      final profile = PlayerProfile(coins: 1000);
      final next = ProgressionService.purchase(profile, 'flux', 550, 'character');
      expect(next, isNotNull);
      expect(next!.coins, 450);
      expect(next.unlockedCharacters, contains('flux'));
      expect(
        ProgressionService.purchase(next, 'spectre', 1300, 'character'),
        isNull,
      );
    });

    test('companions use the same purchase economy', () {
      final profile = PlayerProfile(coins: 700);
      final next = ProgressionService.purchase(
        profile,
        'wisp',
        600,
        'companion',
      );
      expect(next, isNotNull);
      expect(next!.coins, 100);
      expect(next.unlockedCompanions, contains('wisp'));
      expect(
        ProgressionService.purchase(next, 'beacon', 2400, 'companion'),
        isNull,
      );
    });

    test('daily reward cannot be claimed twice and tracks streaks', () {
      final first = ProgressionService.claimDailyReward(
        PlayerProfile(),
        DateTime(2026, 11, 27),
      );
      expect(first.coins, 50);
      expect(first.profile.daily.streak, 1);
      final second = ProgressionService.claimDailyReward(
        first.profile,
        DateTime(2026, 11, 27),
      );
      expect(second.coins, 0);
      final nextDay = ProgressionService.claimDailyReward(
        first.profile,
        DateTime(2026, 11, 28),
      );
      expect(nextDay.profile.daily.streak, 2);
      expect(nextDay.coins, 65);
    });

    test('daily reward preview matches the amount actually claimed', () {
      final now = DateTime(2026, 11, 27);
      final profile = PlayerProfile(
        daily: DailyState(
          date: '2026-11-26',
          streak: 4,
          lastRewardDate: '2026-11-26',
        ),
      );
      final preview = ProgressionService.dailyRewardAmount(profile, now);
      final claimed = ProgressionService.claimDailyReward(profile, now);
      expect(preview, claimed.coins);
      expect(claimed.streak, 5);

      final stale = PlayerProfile(
        daily: DailyState(
          date: '2026-11-25',
          streak: 9,
          lastRewardDate: '2026-11-25',
        ),
      );
      expect(ProgressionService.dailyRewardAmount(stale, now), 50);
      expect(ProgressionService.claimDailyReward(stale, now).streak, 1);
    });

    test('a run after midnight keeps the streak alive', () {
      final profile = PlayerProfile(
        daily: DailyState(
          date: '2026-11-26',
          streak: 4,
          lastRewardDate: '2026-11-26',
        ),
      );
      final applied = ProgressionService.applyRun(
        profile,
        result(),
        now: DateTime(2026, 11, 27),
      );
      expect(applied.profile.daily.streak, 4);
      expect(applied.profile.daily.lastRewardDate, '2026-11-26');
      expect(
        ProgressionService.claimDailyReward(
          applied.profile,
          DateTime(2026, 11, 27),
        ).streak,
        5,
      );
    });

    test('mission rewards require completion and reset next day', () {
      final now = DateTime(2026, 11, 27);
      final mission = DailyService.missionsFor(now).first;
      final profile = PlayerProfile(
        daily: DailyState(
          date: dateKey(now),
          missionProgress: {mission.id: mission.target},
        ),
      );
      final claimed = ProgressionService.claimMission(
        profile,
        mission.id,
        mission.rewardCoins,
        mission.rewardXp,
        now,
      );
      expect(claimed, isNotNull);
      expect(claimed!.coins, profile.coins + mission.rewardCoins);
      expect(
        ProgressionService.claimMission(
          claimed,
          mission.id,
          mission.rewardCoins,
          mission.rewardXp,
          now,
        ),
        isNull,
      );
    });

    test('profile JSON round-trips and rejects corrupted values', () {
      final original = PlayerProfile(
        coins: 500,
        xp: 250,
        character: 'nyx',
        unlockedCharacters: {'nyx', 'flux'},
        companion: 'wisp',
        unlockedCompanions: {'none', 'wisp'},
        bestScores: {'classic': 4200},
      );
      final decoded = PlayerProfile.fromJson(original.toJson(), '2026-11-27');
      expect(decoded.coins, 500);
      expect(decoded.unlockedCharacters, {'nyx', 'flux'});
      expect(decoded.companion, 'wisp');
      expect(decoded.unlockedCompanions, {'none', 'wisp'});
      expect(decoded.bestScores['classic'], 4200);

      final corrupted = PlayerProfile.fromJson(
        {
          'coins': -999,
          'xp': 'not a number',
          'character': 'unknown',
          'unlockedCharacters': ['unknown', 'flux'],
          'companion': 'unknown',
          'unlockedCompanions': ['unknown', 'wisp'],
          'bestScores': {'classic': -5},
        },
        '2026-11-27',
      );
      expect(corrupted.coins, 0);
      expect(corrupted.xp, 0);
      expect(corrupted.character, 'nyx');
      expect(corrupted.companion, 'none');
      expect(corrupted.unlockedCompanions, {'wisp'});
      expect(corrupted.bestScores['classic'], 0);
    });

    test('level curve increases monotonically', () {
      expect(PlayerProfile.levelForXp(0), 1);
      expect(PlayerProfile.levelForXp(120), 2);
      expect(PlayerProfile.levelForXp(100000), greaterThan(10));
      expect(
        PlayerProfile.xpRequiredForLevel(5),
        greaterThan(PlayerProfile.xpRequiredForLevel(4)),
      );
      for (var level = 1; level <= PlayerProfile.maxLevel + 1; level++) {
        var oldFormula = 0;
        for (var l = 1; l < level; l++) {
          oldFormula += 80 + 40 * l;
        }
        expect(PlayerProfile.xpRequiredForLevel(level), oldFormula);
      }
    });
  });
}
