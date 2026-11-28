import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shadowshift/core/constants.dart';
import 'package:shadowshift/data/models/profile.dart';
import 'package:shadowshift/data/repositories/storage_repository.dart';
import 'package:shadowshift/domain/multiplayer/multiplayer_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

MultiplayerMatchRecord filledMatch() {
  var record = MultiplayerMatchRecord.start(
    id: 'mp-test-1',
    playedAt: DateTime(2026, 11, 28, 12),
    players: const ['Player 1', 'Player 2', 'Player 3'],
    rounds: 2,
  );
  // Turn order: R1 P1, P2, P3 then R2 P1, P2, P3.
  for (final score in [120, 180, 100, 150, 90, 140]) {
    record = MultiplayerSession.fromRecord(record).recordScore(score).record;
  }
  return record;
}

void main() {
  group('turn order', () {
    test('players alternate turns across rounds with fresh state', () {
      var session = MultiplayerSession.fromRecord(
        MultiplayerMatchRecord.start(
          id: 'mp-order',
          playedAt: DateTime(2026),
          players: const ['A', 'B', 'C'],
          rounds: 2,
        ),
      );

      expect(session.currentRound, 1);
      expect(session.currentPlayer, 'A');
      expect(session.completedPlayers, isEmpty);
      expect(session.remainingPlayers, ['A', 'B', 'C']);

      session = session.recordScore(10);
      expect(session.currentPlayer, 'B');
      expect(session.completedPlayers, ['A']);
      expect(session.remainingPlayers, ['B', 'C']);

      session = session.recordScore(20).recordScore(30);
      expect(session.currentRound, 2);
      expect(session.currentPlayer, 'A');

      session = session.recordScore(40).recordScore(50).recordScore(60);
      expect(session.isComplete, isTrue);
      expect(session.record.allTurnsRecorded, isTrue);
    });
  });

  group('scoring and rewards', () {
    test('totals, tie winners and standings are computed per player', () {
      final record = filledMatch();
      expect(record.totalFor(0), 270);
      expect(record.totalFor(1), 270);
      expect(record.totalFor(2), 240);
      expect(record.winningScore, 270);
      expect(record.winnerNames, ['Player 1', 'Player 2']);
      expect(record.standings.map((entry) => entry.rank), [1, 1, 3]);
    });

    test('an interrupted match is never completed or awarded', () {
      final profile = MultiplayerProfile();
      var record = MultiplayerMatchRecord.start(
        id: 'mp-incomplete',
        playedAt: DateTime(2026),
        players: const ['A', 'B'],
        rounds: 2,
      );
      record = MultiplayerSession.fromRecord(record).recordScore(100).record;
      expect(MultiplayerService.rewardsFor(record), (gold: 0, xp: 0));
      final next = MultiplayerService.completeMatch(profile, record);
      expect(next.history, isEmpty);
      expect(next.gold, 0);
      expect(next.xp, 0);
      expect(next.gamesPlayed, 0);
      expect(next.activeMatch, isNull);
    });

    test('completion pays once and only to the multiplayer wallet', () {
      const start = MultiplayerProfile();
      final record = filledMatch();
      final complete = MultiplayerService.completeMatch(start, record);
      expect(complete.gold, greaterThan(0));
      expect(complete.xp, greaterThan(0));
      expect(complete.history.length, 1);
      expect(complete.gamesPlayed, 1);
      expect(complete.wins, 2); // tied winners both count as wins.
      expect(complete.losses, 1);
      expect(complete.playerStats['Player 1']!.totalPoints, 270);
      expect(complete.playerStats['Player 3']!.losses, 1);
      expect(complete.highestScore, 180);

      // A duplicate finish cannot pay again or duplicate history.
      final again = MultiplayerService.completeMatch(complete, record);
      expect(again.gold, complete.gold);
      expect(again.xp, complete.xp);
      expect(again.history.length, 1);
    });

    test('stale completed active records are dropped on load', () {
      final stale = filledMatch().completedWith(gold: 10, xp: 20);
      final decoded = MultiplayerProfile.fromJson({
        'activeMatch': stale.toJson(),
      });
      expect(decoded.activeMatch, isNull);
      expect(decoded.history, isEmpty);
    });
  });

  group('persistence separation', () {
    test('multiplayer save round-trips without touching the solo profile',
        () async {
      final soloJson = PlayerProfile(coins: 999, xp: 888).toJson();
      SharedPreferences.setMockInitialValues({
        StorageKeys.profile: jsonEncode(soloJson),
      });
      final prefs = await SharedPreferences.getInstance();
      final repository = StorageRepository(prefs);

      expect(repository.loadProfile().coins, 999);
      expect(repository.loadProfile().xp, 888);
      expect(repository.loadMultiplayerProfile().gold, 0);

      final record = filledMatch();
      final multiplayer = MultiplayerService.completeMatch(
        const MultiplayerProfile(),
        record,
      );
      await repository.saveMultiplayerProfile(multiplayer);

      expect(repository.loadMultiplayerProfile().gold, multiplayer.gold);
      expect(repository.loadMultiplayerProfile().history.length, 1);
      expect(repository.loadMultiplayerProfile().activeMatch, isNull);
      // The single-player blob is byte-for-byte untouched.
      expect(repository.loadProfile().coins, 999);
      expect(repository.loadProfile().xp, 888);
      expect(prefs.getString(StorageKeys.profile), jsonEncode(soloJson));
    });
  });
}
