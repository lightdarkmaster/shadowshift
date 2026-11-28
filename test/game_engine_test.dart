import 'package:flutter_test/flutter_test.dart';
import 'package:shadowshift/core/constants.dart';
import 'package:shadowshift/domain/game/difficulty.dart';
import 'package:shadowshift/domain/game/engine.dart';
import 'package:shadowshift/domain/game/entities.dart';
import 'package:shadowshift/domain/game/enums.dart';

GameEngine makeEngine({
  int seed = 42,
  GameMode mode = GameMode.classic,
  RunObjective? objective,
  RunLoadout loadout = const RunLoadout(),
}) {
  return GameEngine(
    mode: mode,
    seed: seed,
    worldHeight: 1200,
    objective: objective ??
        const RunObjective(kind: ObjectiveKind.none, target: 0),
    loadout: loadout,
  );
}

void main() {
  group('dimension switching', () {
    test('tap toggles dimension and records the switch', () {
      final engine = makeEngine();
      expect(engine.dimension, Dimension.light);
      engine.switchDimension();
      expect(engine.dimension, Dimension.shadow);
      expect(engine.switches, 1);
      engine.switchDimension();
      expect(engine.dimension, Dimension.light);
      expect(engine.switches, 2);
    });

    test('switching is ignored while paused or after game over', () {
      final engine = makeEngine();
      engine.paused = true;
      engine.switchDimension();
      expect(engine.switches, 0);
      engine.paused = false;
      engine.finishRun(RunEndReason.quit);
      engine.switchDimension();
      expect(engine.switches, 0);
    });
  });

  group('event delivery', () {
    test('drainEvents returns events once and keeps them intact for the caller', () {
      final engine = makeEngine();
      engine.switchDimension();
      final first = engine.drainEvents();
      expect(first, contains(GameEvent.switchDimension));
      expect(engine.drainEvents(), isEmpty);

      engine.switchDimension();
      final second = engine.drainEvents();
      expect(second, contains(GameEvent.switchDimension));
      expect(engine.drainEvents(), isEmpty);
    });
  });

  group('difficulty and scoring', () {
    test('difficulty increases but stays within fair bounds', () {
      final early = DifficultyController.at(0, 0);
      final late = DifficultyController.at(300, 500000);
      expect(late.progress, lessThanOrEqualTo(1.0));
      expect(late.speed, greaterThan(early.speed));
      expect(late.speed, lessThanOrEqualTo(GameConfig.maxSpeed + 0.001));
      expect(late.spawnInterval, greaterThanOrEqualTo(GameConfig.minSpawnInterval - 0.001));
      expect(late.spawnInterval, lessThan(early.spawnInterval));
      expect(late.complexity, 4);
    });

    test('combo multiplier grows in tiers and caps at x8', () {
      expect(ScoreCalculator.multiplierForCombo(0), 1);
      expect(ScoreCalculator.multiplierForCombo(4), 1);
      expect(ScoreCalculator.multiplierForCombo(5), 2);
      expect(ScoreCalculator.multiplierForCombo(25), 6);
      expect(ScoreCalculator.multiplierForCombo(1000), 8);
      expect(ScoreCalculator.orbPoints(5, doubled: true), 200);
    });
  });

  group('collision and rewards', () {
    test('matching-dimension obstacle ends the run', () {
      final engine = makeEngine();
      // The runner starts with one second of spawn protection, so place the
      // obstacle far enough right that it arrives after that grace expires.
      engine.obstacles.add(Obstacle(
        id: 1,
        x: GameConfig.playerX + 360,
        y: engine.playerY - 100,
        dimension: engine.dimension,
        kind: ObstacleKind.standard,
        height: 200,
      ));
      for (var frame = 0; frame < 120 && !engine.isOver; frame++) {
        engine.update(1 / 60);
      }
      expect(engine.isOver, isTrue);
      expect(engine.endReason, RunEndReason.collision);
    });

    test('opposite-dimension obstacle is harmless', () {
      final engine = makeEngine();
      engine.obstacles.add(Obstacle(
        id: 1,
        x: GameConfig.playerX,
        y: engine.playerY - 100,
        dimension: Dimension.shadow,
        kind: ObstacleKind.standard,
        height: 200,
      ));
      engine.update(1 / 60);
      expect(engine.isOver, isFalse);
    });

    test('starting shield absorbs the first hit and resets combo', () {
      final engine = makeEngine(
        loadout: const RunLoadout(shieldStart: true),
      );
      engine.combo = 12;
      engine.obstacles.add(Obstacle(
        id: 1,
        x: GameConfig.playerX,
        y: engine.playerY - 100,
        dimension: engine.dimension,
        kind: ObstacleKind.standard,
        height: 200,
      ));
      engine.update(1 / 60);
      expect(engine.isOver, isFalse);
      expect(engine.hasShield, isFalse);
      expect(engine.combo, 0);
      expect(engine.obstacles.first.destroyed, isTrue);
    });

    test('orbs only collect in the matching dimension unless magnet is active', () {
      final engine = makeEngine();
      engine.orbEntities.add(Orb(
        id: 1,
        x: GameConfig.playerX,
        y: engine.playerY,
        dimension: Dimension.shadow,
      ));
      engine.update(1 / 60);
      expect(engine.orbs, 0);
      engine.effects[PowerUpKind.magnet] = 5;
      engine.update(1 / 60);
      expect(engine.orbs, 1);
      expect(engine.score, greaterThan(0));
    });

    test('power-ups activate and expire on time', () {
      final engine = makeEngine();
      engine.effects[PowerUpKind.slow] = 0.02;
      engine.update(0.03);
      expect(engine.hasEffect(PowerUpKind.slow), isFalse);
      engine.powerUps.add(PowerUpEntity(
        id: 9,
        x: GameConfig.playerX,
        y: engine.playerY,
        kind: PowerUpKind.double,
      ));
      engine.update(1 / 60);
      expect(engine.hasEffect(PowerUpKind.double), isTrue);
    });

    test('successful dodges raise combo and score', () {
      final engine = makeEngine();
      engine.obstacles.add(Obstacle(
        id: 2,
        x: GameConfig.playerX - 100,
        y: engine.playerY - 100,
        dimension: Dimension.shadow,
        kind: ObstacleKind.standard,
        height: 200,
      ));
      engine.update(1 / 60);
      expect(engine.dodges, 1);
      expect(engine.combo, 1);
      expect(engine.score, greaterThanOrEqualTo(25));
    });
  });

  group('modes and objectives', () {
    test('time attack ends exactly at 60 seconds', () {
      final engine = makeEngine(mode: GameMode.timeAttack);
      for (var i = 0; i < 1300 && !engine.isOver; i++) {
        engine.obstacles.clear();
        engine.update(0.05);
      }
      expect(engine.isOver, isTrue);
      expect(engine.endReason, RunEndReason.timeUp);
      expect(engine.elapsed, 60);
    });

    test('challenge objective completes when target is met', () {
      final engine = makeEngine(
        mode: GameMode.challenge,
        objective: const RunObjective(kind: ObjectiveKind.survive, target: 1),
      );
      for (var i = 0; i < 30 && !engine.isOver; i++) {
        engine.update(0.05);
      }
      expect(engine.endReason, RunEndReason.objectiveComplete);
      expect(engine.result(challengeId: 'first_light').objectiveMet, isTrue);
    });

    test('survive-and-orbs objective requires both conditions', () {
      final objective = RunObjective(
        kind: ObjectiveKind.surviveAndOrbs,
        target: 2,
        secondaryTarget: 3,
      );
      expect(objective.isMet(3, 0, 0, 0, 0), isFalse);
      expect(objective.isMet(1, 5, 0, 0, 0), isFalse);
      expect(objective.isMet(3, 3, 0, 0, 0), isTrue);
    });
  });

  group('determinism and fairness', () {
    test('same seed produces identical obstacle streams', () {
      final a = makeEngine(seed: 123456);
      final b = makeEngine(seed: 123456);
      for (var i = 0; i < 400; i++) {
        a.update(1 / 60);
        b.update(1 / 60);
      }
      expect(a.obstacles.length, b.obstacles.length);
      for (var i = 0; i < a.obstacles.length; i++) {
        expect(a.obstacles[i].dimension, b.obstacles[i].dimension);
        expect(a.obstacles[i].x, closeTo(b.obstacles[i].x, 0.0001));
        expect(a.obstacles[i].kind, b.obstacles[i].kind);
      }
    });

    test('a reactive player can survive 90 seconds at max difficulty', () {
      final engine = makeEngine(seed: 777);
      for (var frame = 0; frame < 90 * 60 && !engine.isOver; frame++) {
        // Bot: shift away when a same-dimension obstacle is within reacting range.
        final threat = engine.obstacles.any(
          (o) =>
              o.dimension == engine.dimension &&
              o.right > GameConfig.playerX - GameConfig.playerRadius &&
              o.left < GameConfig.playerX + 230 &&
              o.y < engine.playerY + GameConfig.playerRadius &&
              o.y + o.height > engine.playerY - GameConfig.playerRadius,
        );
        if (threat) engine.switchDimension();
        engine.update(1 / 60);
      }
      expect(engine.elapsed, greaterThan(89));
      expect(engine.isOver, isFalse, reason: 'fair-play bot should survive');
      expect(engine.difficulty.progress, greaterThan(0.3));
    });
  });
}
