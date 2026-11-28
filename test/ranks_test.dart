import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadowshift/core/utils.dart';
import 'package:shadowshift/data/models/profile.dart';
import 'package:shadowshift/data/repositories/storage_repository.dart';
import 'package:shadowshift/domain/game/entities.dart';
import 'package:shadowshift/domain/game/enums.dart';
import 'package:shadowshift/domain/progression/catalog.dart';
import 'package:shadowshift/domain/progression/ranks.dart';
import 'package:shadowshift/domain/services/daily_service.dart';
import 'package:shadowshift/domain/services/progression_service.dart';
import 'package:shadowshift/domain/services/rank_service.dart';
import 'package:shadowshift/state/app_providers.dart';
import 'package:shadowshift/state/rank_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

RunResult rankResult({
  int score = 1200,
  int orbs = 8,
  double seconds = 30,
  RunEndReason reason = RunEndReason.collision,
  String runId = '',
  String? challengeId,
}) {
  return RunResult(
    mode: GameMode.classic,
    score: score,
    seconds: seconds,
    orbs: orbs,
    maxCombo: 5,
    switches: 6,
    dodges: 2,
    reason: reason,
    objective: const RunObjective(kind: ObjectiveKind.none, target: 0),
    seed: 7,
    runId: runId,
    challengeId: challengeId,
  );
}

void main() {
  final now = DateTime(2026, 11, 28, 12);

  group('rank configuration', () {
    test('new player is Rookie at 0 XP', () {
      final profile = PlayerProfile();
      expect(profile.xp, 0);
      expect(profile.rankTier.id, 'rookie');
      expect(profile.rankProgress.requiredXp, 1000);
      expect(profile.rankProgress.progress, 0);
      expect(profile.equippedTitle, RankConfig.defaultTitleId);
      expect(profile.unlockedTitles, contains(RankConfig.defaultTitleId));
    });

    test('all seven tiers map to the exact XP ranges', () {
      expect(RankConfig.all.map((tier) => tier.id), [
        'rookie',
        'scout',
        'phantom',
        'shadow_hunter',
        'reaper',
        'night_legend',
        'shadow_master',
      ]);
      expect(RankConfig.forXp(0).id, 'rookie');
      expect(RankConfig.forXp(999).id, 'rookie');
      expect(RankConfig.forXp(1000).id, 'scout');
      expect(RankConfig.forXp(2999).id, 'scout');
      expect(RankConfig.forXp(3000).id, 'phantom');
      expect(RankConfig.forXp(8999).id, 'phantom');
      expect(RankConfig.forXp(9000).id, 'shadow_hunter');
      expect(RankConfig.forXp(26999).id, 'shadow_hunter');
      expect(RankConfig.forXp(27000).id, 'reaper');
      expect(RankConfig.forXp(80999).id, 'reaper');
      expect(RankConfig.forXp(81000).id, 'night_legend');
      expect(RankConfig.forXp(242999).id, 'night_legend');
      expect(RankConfig.forXp(243000).id, 'shadow_master');
      expect(RankConfig.forXp(1000000).id, 'shadow_master');
      expect(RankConfig.maxRankXp, 243000);

      final minimums = RankConfig.all.map((tier) => tier.minXp).toList();
      expect(minimums[0], 0);
      expect(minimums[1], 1000);
      for (var i = 2; i < minimums.length; i++) {
        expect(minimums[i], minimums[i - 1] * 3);
      }
    });

    test('Shadow Master is the terminal rank with no next target', () {
      final profile = PlayerProfile(xp: 243000);
      final progress = profile.rankProgress;
      expect(progress.isMax, isTrue);
      expect(progress.next, isNull);
      expect(progress.progress, 1);
      expect(progress.remainingXp, 0);
      expect(
        RankConfig.promotionsBetween(243000, 300000, now),
        isEmpty,
      );
    });

    test('each tier exposes a unique badge, colour and reward', () {
      final ids = RankConfig.all.map((tier) => tier.id).toSet();
      final rewardIds = RankConfig.all.map((tier) => tier.rewardId).toSet();
      final titles = RankConfig.all.map((tier) => tier.titleId).toSet();
      final colors = RankConfig.all.map((tier) => tier.color.toARGB32()).toSet();
      expect(ids.length, 7);
      expect(rewardIds.length, 7);
      expect(titles.length, 7);
      expect(colors.length, 7);
      expect(
        RankConfig.all.where((tier) => tier.hasSpecialEffect).length,
        3,
      );
    });
  });

  group('XP events', () {
    test('a valid match grants match, victory and accomplishment XP', () {
      final summary = ProgressionService.applyRun(
        PlayerProfile(),
        rankResult(),
        now: now,
      );
      expect(summary.xpAwards.map((award) => award.label), contains('MATCH COMPLETE'));
      expect(summary.xpAwards.map((award) => award.label), contains('VICTORY'));
      expect(summary.xp, greaterThanOrEqualTo(20 + 50 + 25));
      expect(summary.profile.xp, summary.xp);
      expect(summary.win, isTrue);
    });

    test('a short valid match still earns the 20 XP floor', () {
      final awards = RankService.runAwards(
        result: rankResult(score: 0, orbs: 0, seconds: 0),
        isNewBest: true,
        objectiveAlreadyRewarded: false,
        winStreak: 1,
        challengeRewardXp: 0,
        newAchievementIds: const [],
      );
      final match = awards.firstWhere((award) => award.label == 'MATCH COMPLETE');
      expect(match.amount, 20);
    });

    test('objective XP is paid once and challenge XP is itemized', () {
      final objective = rankResult(reason: RunEndReason.objectiveComplete);
      final awards = RankService.runAwards(
        result: objective,
        isNewBest: false,
        objectiveAlreadyRewarded: false,
        winStreak: 1,
        challengeRewardXp: 40,
        newAchievementIds: const ['first_run'],
      );
      expect(awards.where((award) => award.label == 'OBJECTIVE').length, 1);
      expect(awards.where((award) => award.label == 'CHALLENGE').single.amount, 40);

      final alreadyPaid = RankService.runAwards(
        result: objective,
        isNewBest: false,
        objectiveAlreadyRewarded: true,
        winStreak: 1,
        challengeRewardXp: 40,
        newAchievementIds: const [],
      );
      expect(alreadyPaid.where((award) => award.label == 'OBJECTIVE'), isEmpty);
    });

    test('a replayed challenge pays objective XP but not challenge XP again', () {
      final challenge = Challenges.all.first;
      final run = rankResult(
        score: 3000,
        reason: RunEndReason.objectiveComplete,
        challengeId: challenge.id,
      );
      final first = ProgressionService.applyRun(PlayerProfile(), run, now: now);
      expect(first.xpAwards.map((award) => award.label), isNot(contains('OBJECTIVE')));

      final replay = ProgressionService.applyRun(first.profile, run, now: now);
      expect(replay.xpAwards.map((award) => award.label), contains('OBJECTIVE'));
      expect(replay.xpAwards.map((award) => award.label), isNot(contains('CHALLENGE')));
    });

    test('win streaks add a bounded bonus only after the first win', () {
      expect(RankService.streakBonus(1), 0);
      expect(RankService.streakBonus(2), 10);
      expect(RankService.streakBonus(6), 50);
      expect(RankService.streakBonus(1000), 50);

      final first = ProgressionService.applyRun(
        PlayerProfile(),
        rankResult(score: 1000),
        now: now,
      );
      final second = ProgressionService.applyRun(
        first.profile,
        rankResult(score: 2000),
        now: now,
      );
      expect(second.winStreak, 2);
      expect(
        second.xpAwards.map((award) => award.label),
        contains('WIN STREAK x2'),
      );
    });

    test('abandoned and malformed runs grant nothing', () {
      final abandoned = ProgressionService.applyRun(
        PlayerProfile(),
        rankResult(reason: RunEndReason.quit),
        now: now,
      );
      expect(abandoned.invalid, isTrue);
      expect(abandoned.xp, 0);
      expect(abandoned.coins, 0);
      expect(abandoned.profile.xp, 0);
      expect(abandoned.profile.totalRuns, 0);

      final malformed = ProgressionService.applyRun(
        PlayerProfile(),
        rankResult(score: -5),
        now: now,
      );
      expect(malformed.invalid, isTrue);
      expect(malformed.profile.xp, 0);
    });

    test('a run id can only be rewarded once', () {
      final run = rankResult(runId: 'match-001');
      final first = ProgressionService.applyRun(PlayerProfile(), run, now: now);
      expect(first.xp, greaterThan(0));
      final second = ProgressionService.applyRun(first.profile, run, now: now);
      expect(second.duplicate, isTrue);
      expect(second.xp, 0);
      expect(second.coins, 0);
      expect(second.profile.xp, first.profile.xp);
      expect(second.profile.processedRunIds, contains('match-001'));
    });

    test('live preview matches the settled rewards and grows with the run', () {
      final run = rankResult(score: 5000, orbs: 20, seconds: 40);
      final preview = ProgressionService.previewRunRewards(
        run,
        isNewBest: false,
        winStreak: 0,
      );
      // Pre-unlock achievements and a higher best so settlement has no bonus
      // sources the live HUD cannot know about yet.
      final profile = PlayerProfile(
        achievements: Achievements.all.map((a) => a.id).toSet(),
        bestScores: {'classic': 999999},
      );
      final settled = ProgressionService.applyRun(profile, run, now: now);
      expect(settled.coins, preview.coins);
      expect(settled.xp, preview.xp);

      final early = ProgressionService.previewRunRewards(
        rankResult(score: 100, orbs: 2, seconds: 4),
        isNewBest: false,
        winStreak: 0,
      );
      expect(preview.coins, greaterThan(early.coins));
      expect(preview.xp, greaterThan(early.xp));
    });
  });

  group('promotions and rewards', () {
    test('a large XP jump records every crossed rank', () {
      final promotions = RankConfig.promotionsBetween(0, 30000, now);
      expect(promotions.map((entry) => entry.toRankId), [
        'scout',
        'phantom',
        'shadow_hunter',
        'reaper',
      ]);
      expect(promotions.map((entry) => entry.xpThreshold), [
        1000,
        3000,
        9000,
        27000,
      ]);
      expect(promotions.first.fromRankId, 'rookie');
      expect(promotions.last.toRankId, 'reaper');
    });

    test('granting XP unlocks rewards and appends history in one step', () {
      final profile = PlayerProfile();
      final promotions = RankService.grantXp(profile, 30000, now);
      expect(profile.xp, 30000);
      expect(promotions.length, 4);
      expect(profile.rankHistory.length, 4);
      expect(
        profile.unlockedRankRewards,
        containsAll(RankConfig.unlockedRewardIdsForXp(30000)),
      );
      expect(profile.rankTier.id, 'reaper');
    });

    test('rank rewards unlock cosmetics without granting gameplay perks', () {
      final profile = PlayerProfile();
      final charactersBefore = Set<String>.from(profile.unlockedCharacters);
      RankService.grantXp(profile, 243000, now);

      expect(profile.unlockedSkins, containsAll(['inferno', 'neon', 'solar', 'spectrum']));
      expect(profile.unlockedEffects, containsAll(['comet', 'pulse', 'nova', 'prism']));
      expect(profile.unlockedCharacters, charactersBefore,
          reason: 'rank rewards must never grant perk-bearing runners');
    });

    test('titles unlock at their rank and locked titles cannot be equipped',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(overrides: [
        storageProvider.overrideWithValue(StorageRepository(prefs)),
      ]);
      addTearDown(container.dispose);
      final notifier = container.read(profileProvider.notifier);

      expect(notifier.equipTitle('ghost_walker'), isFalse);
      notifier.applyRun(rankResult(score: 60000, orbs: 40, seconds: 90));
      expect(notifier.state.unlockedTitles, contains('ghost_walker'));
      expect(notifier.equipTitle('ghost_walker'), isTrue);
      expect(notifier.state.equippedTitle, 'ghost_walker');
      // A locked endgame title stays locked even after a strong run.
      expect(notifier.equipTitle('lord_of_the_night'), isFalse);
    });

    test('run promotions open on the report; other XP sources queue once',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(overrides: [
        storageProvider.overrideWithValue(StorageRepository(prefs)),
      ]);
      addTearDown(container.dispose);
      final notifier = container.read(profileProvider.notifier);
      final queue = container.read(pendingRankUpsProvider.notifier);

      expect(queue.peek(), isNull);
      // A high score guarantees crossing the Scout threshold on this run.
      final summary = notifier.applyRun(
        rankResult(score: 40000, orbs: 60, seconds: 120),
      );
      expect(summary.rankPromotions, isNotEmpty);
      expect(summary.rankPromotions.first.fromRankId, 'rookie');
      expect(queue.peek(), isNull,
          reason: 'run rank-ups are announced by GameOverScreen');

      final today = DateTime.now();
      final mission = DailyService.missionsFor(today).first;
      final prepared = PlayerProfile(xp: 999)
        ..daily.date = dateKey(today)
        ..daily.missionProgress[mission.id] = mission.target;
      notifier.state = prepared;
      final coins = notifier.claimMission(
        mission.id,
        mission.rewardCoins,
        mission.rewardXp,
      );
      expect(coins, mission.rewardCoins);
      final queued = queue.peek();
      expect(queued, isNotNull);
      expect(queued!.toRankId, 'scout');

      while (queue.peek() != null) {
        queue.dismiss();
      }
      expect(queue.peek(), isNull);
    });
  });

  group('persistence', () {
    test('rank fields survive a JSON round trip', () {
      final profile = PlayerProfile(
        xp: 3200,
        playerName: 'shadow hunter',
        winStreak: 3,
        bestWinStreak: 4,
        equippedTitle: 'ghost_walker',
        unlockedRankRewards: RankConfig.unlockedRewardIdsForXp(3200),
      );
      final restored = PlayerProfile.fromJson(profile.toJson(), dateKey(now));
      expect(restored.xp, 3200);
      expect(restored.playerName, 'SHADOW HUNTER');
      expect(restored.winStreak, 3);
      expect(restored.bestWinStreak, 4);
      expect(restored.equippedTitle, 'ghost_walker');
      expect(restored.rankTier.id, 'phantom');
      expect(
        restored.unlockedRankRewards,
        containsAll(profile.unlockedRankRewards),
      );
    });

    test('an old save with XP only derives its rank cosmetics', () {
      final restored = PlayerProfile.fromJson({'xp': 81000}, dateKey(now));
      expect(restored.rankTier.id, 'night_legend');
      expect(restored.equippedTitle, RankConfig.defaultTitleId);
      expect(
        restored.unlockedRankRewards,
        containsAll(RankConfig.unlockedRewardIdsForXp(81000)),
      );
      expect(restored.rankHistory, isEmpty);
    });

    test('processed run ids are capped so storage stays bounded', () {
      final profile = PlayerProfile();
      for (var i = 0; i < 300; i++) {
        profile.processedRunIds.add('run-$i');
      }
      final restored = PlayerProfile.fromJson(profile.toJson(), dateKey(now));
      expect(restored.processedRunIds.length, 256);
    });
  });
}
