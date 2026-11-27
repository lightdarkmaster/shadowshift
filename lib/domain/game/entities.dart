import 'dart:ui' show Color;

import 'package:shadowshift/core/constants.dart';
import 'package:shadowshift/domain/game/enums.dart';

class Obstacle {
  Obstacle({
    required this.id,
    required this.x,
    required this.y,
    required this.dimension,
    required this.kind,
    this.width = GameConfig.obstacleWidth,
    this.height = GameConfig.obstacleHeight,
    this.countsForCombo = true,
  });

  final int id;
  double x;
  final double y;
  final Dimension dimension;
  final ObstacleKind kind;
  final double width;
  final double height;
  final bool countsForCombo;
  bool counted = false;
  bool destroyed = false;

  double get right => x + width / 2;
  double get left => x - width / 2;

  bool overlaps(double px, double py, double radius) =>
      px + radius > left && px - radius < right && py + radius > y && py - radius < y + height;
}

class Orb {
  Orb({required this.id, required this.x, required this.y, required this.dimension});

  final int id;
  double x;
  final double y;
  final Dimension dimension;
  bool collected = false;
}

class PowerUpEntity {
  PowerUpEntity({required this.id, required this.x, required this.y, required this.kind});

  final int id;
  double x;
  final double y;
  final PowerUpKind kind;
  bool collected = false;
}

class Particle {
  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    required this.size,
    required this.color,
  });

  double x;
  double y;
  final double vx;
  final double vy;
  double life;
  final double size;
  final Color color;

  bool get isDead => life <= 0;

  void update(double dt) {
    x += vx * dt;
    y += vy * dt;
    life -= dt;
  }
}

class RunObjective {
  const RunObjective({
    required this.kind,
    required this.target,
    this.secondaryTarget,
    this.title = '',
  });

  final ObjectiveKind kind;
  final int target;
  final int? secondaryTarget;
  final String title;

  bool isMet(double seconds, int orbs, int combo, int score, int switches) {
    switch (kind) {
      case ObjectiveKind.none:
        return false;
      case ObjectiveKind.survive:
        return seconds >= target;
      case ObjectiveKind.orbs:
        return orbs >= target;
      case ObjectiveKind.combo:
        return combo >= target;
      case ObjectiveKind.score:
        return score >= target;
      case ObjectiveKind.switches:
        return switches >= target;
      case ObjectiveKind.surviveAndOrbs:
        return seconds >= target && orbs >= (secondaryTarget ?? 0);
    }
  }

  String progressText(double seconds, int orbs, int combo, int score, int switches) {
    switch (kind) {
      case ObjectiveKind.none:
        return '';
      case ObjectiveKind.survive:
        return '${seconds.floor()}/${target}s';
      case ObjectiveKind.orbs:
        return '$orbs/$target orbs';
      case ObjectiveKind.combo:
        return '$combo/$target combo';
      case ObjectiveKind.score:
        return '$score/$target pts';
      case ObjectiveKind.switches:
        return '$switches/$target shifts';
      case ObjectiveKind.surviveAndOrbs:
        return '${seconds.floor()}/${target}s · $orbs/${secondaryTarget ?? 0} orbs';
    }
  }
}

class RunResult {
  RunResult({
    required this.mode,
    required this.score,
    required this.seconds,
    required this.orbs,
    required this.maxCombo,
    required this.switches,
    required this.dodges,
    required this.reason,
    required this.objective,
    required this.seed,
    this.challengeId,
  });

  final GameMode mode;
  final int score;
  final double seconds;
  final int orbs;
  final int maxCombo;
  final int switches;
  final int dodges;
  final RunEndReason reason;
  final RunObjective objective;
  final int seed;
  final String? challengeId;

  bool get objectiveMet => reason == RunEndReason.objectiveComplete;
}
