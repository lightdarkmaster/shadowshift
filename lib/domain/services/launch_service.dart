import 'package:shadowshift/core/utils.dart';
import 'package:shadowshift/data/models/profile.dart';
import 'package:shadowshift/domain/game/entities.dart';
import 'package:shadowshift/domain/game/enums.dart';
import 'package:shadowshift/domain/progression/catalog.dart';
import 'package:shadowshift/domain/services/daily_service.dart';

class GameLaunch {
  const GameLaunch({
    required this.mode,
    required this.objective,
    required this.seed,
    this.challengeId,
    this.title,
    this.runId = '',
  });

  final GameMode mode;
  final RunObjective objective;
  final int seed;
  final String? challengeId;
  final String? title;

  /// Stable id for one launched match. Rewards are recorded once per id.
  final String runId;
}

abstract final class LaunchService {
  static GameLaunch create(GameMode mode, {String? challengeId, DateTime? now}) {
    final time = now ?? DateTime.now();
    final runId = '${mode.name}-${time.microsecondsSinceEpoch.toRadixString(36)}';
    switch (mode) {
      case GameMode.classic:
        return GameLaunch(
          mode: mode,
          objective: const RunObjective(kind: ObjectiveKind.none, target: 0),
          seed: time.microsecondsSinceEpoch & 0xFFFFFFFF,
          runId: runId,
        );
      case GameMode.timeAttack:
        return GameLaunch(
          mode: mode,
          objective: const RunObjective(kind: ObjectiveKind.none, target: 0),
          seed: (time.millisecondsSinceEpoch ~/ 3) & 0xFFFFFFFF,
          runId: runId,
        );
      case GameMode.daily:
        return GameLaunch(
          mode: mode,
          objective: DailyService.challengeFor(time),
          seed: DailyService.seedFor(time),
          title: 'DAILY ${dateKey(time)}',
          runId: runId,
        );
      case GameMode.challenge:
        final challenge = Challenges.byId(challengeId ?? Challenges.all.first.id) ??
            Challenges.all.first;
        return GameLaunch(
          mode: mode,
          objective: challenge.objective,
          seed: hashString('challenge-${challenge.id}'),
          challengeId: challenge.id,
          title: challenge.title,
          runId: '$runId-${challenge.id}',
        );
    }
  }

  static bool isChallengeUnlocked(PlayerProfile profile, ChallengeDef challenge) {
    final index = Challenges.all.indexWhere((item) => item.id == challenge.id);
    if (index <= 0) return true;
    return Challenges.all
        .take(index)
        .every((item) => profile.completedChallenges.contains(item.id));
  }
}
