import 'package:shadowshift/core/constants.dart';
import 'package:shadowshift/core/utils.dart';
import 'package:shadowshift/domain/game/enums.dart';

/// Mutable snapshot reused by the engine every frame. Callers and tests should
/// treat its values as read-only; only [DifficultyController] writes to it.
class DifficultySnapshot {
  DifficultySnapshot({
    required this.progress,
    required this.speed,
    required this.spawnInterval,
    required this.complexity,
  });

  double progress;
  double speed;
  double spawnInterval;
  int complexity;
}

/// Central, tunable difficulty curve. Progress is capped so the game never
/// outruns human reaction time, and spawn intervals never fall below 0.8s.
abstract final class DifficultyController {
  static DifficultySnapshot at(double seconds, int score) {
    final snapshot = DifficultySnapshot(
      progress: 0,
      speed: 0,
      spawnInterval: 0,
      complexity: 1,
    );
    updateInto(snapshot, seconds, score);
    return snapshot;
  }

  /// Updates an existing snapshot in place so the 60fps loop allocates nothing.
  /// Uses exactly the same formula as [at].
  static void updateInto(DifficultySnapshot target, double seconds, int score) {
    final timePart = seconds / GameConfig.secondsToMaxDifficulty;
    final scorePart = score / 90000;
    final progress = clampDouble(timePart * 0.78 + scorePart * 0.22, 0, 1);
    // Ease-out curve: fast early ramp, gentle late-game increase.
    final eased = 1 - (1 - progress) * (1 - progress);
    target.progress = progress;
    target.speed =
        GameConfig.baseSpeed + (GameConfig.maxSpeed - GameConfig.baseSpeed) * eased;
    target.spawnInterval = GameConfig.baseSpawnInterval -
        (GameConfig.baseSpawnInterval - GameConfig.minSpawnInterval) * eased;
    target.complexity =
        progress < 0.18 ? 1 : progress < 0.45 ? 2 : progress < 0.75 ? 3 : 4;
  }
}

abstract final class ScoreCalculator {
  static int multiplierForCombo(int combo) => 1 + (combo ~/ 5).clamp(0, 7);

  static int orbPoints(int combo, {bool doubled = false}) =>
      50 * multiplierForCombo(combo) * (doubled ? 2 : 1);

  static int dodgePoints(int combo, {bool doubled = false}) =>
      25 * multiplierForCombo(combo) * (doubled ? 2 : 1);
}

abstract final class PowerUpCatalog {
  static String label(PowerUpKind kind) => switch (kind) {
        PowerUpKind.shield => 'PHASE SHIELD',
        PowerUpKind.magnet => 'ORB MAGNET',
        PowerUpKind.slow => 'TIME DILATION',
        PowerUpKind.double => 'DOUBLE SCORE',
      };

  /// Compact label for the gameplay HUD. Avoids splitting [label] every tick.
  static String shortLabel(PowerUpKind kind) => switch (kind) {
        PowerUpKind.shield => 'PHASE',
        PowerUpKind.magnet => 'ORB',
        PowerUpKind.slow => 'TIME',
        PowerUpKind.double => 'DOUBLE',
      };

  static String description(PowerUpKind kind) => switch (kind) {
        PowerUpKind.shield => 'Absorbs the next collision',
        PowerUpKind.magnet => 'Pulls in every nearby orb',
        PowerUpKind.slow => 'Slows incoming obstacles',
        PowerUpKind.double => 'Doubles all points earned',
      };

  static Duration duration(PowerUpKind kind) => switch (kind) {
        PowerUpKind.shield => const Duration(seconds: 14),
        PowerUpKind.magnet => const Duration(seconds: 9),
        PowerUpKind.slow => const Duration(seconds: 7),
        PowerUpKind.double => const Duration(seconds: 9),
      };
}
