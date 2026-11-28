import 'dart:math' as math;
import 'dart:ui' show Color;

import 'package:shadowshift/core/constants.dart';
import 'package:shadowshift/core/utils.dart';
import 'package:shadowshift/domain/game/difficulty.dart';
import 'package:shadowshift/domain/game/entities.dart';
import 'package:shadowshift/domain/game/enums.dart';
import 'package:shadowshift/domain/game/rng.dart';

/// Per-run modifiers granted by unlocked characters and permanent abilities.
class RunLoadout {
  const RunLoadout({
    this.shieldStart = false,
    this.orbBonus = 1.0,
    this.speedReduction = 1.0,
    this.focusAvailable = false,
    this.magnetStart = false,
    this.slowStart = false,
    this.doubleStart = false,
    this.shieldDurationBonus = 1.0,
    this.dodgeBonus = 1.0,
    this.scoreBonus = 1.0,
  });

  final bool shieldStart;
  final double orbBonus;
  final double speedReduction;
  final bool focusAvailable;
  final bool magnetStart;
  final bool slowStart;
  final bool doubleStart;
  final double shieldDurationBonus;
  final double dodgeBonus;
  final double scoreBonus;
}

/// Pure gameplay simulation. Contains no Flutter widgets and no rendering,
/// which makes every rule unit-testable and keeps the render loop lightweight.
class GameEngine {
  GameEngine({
    required this.mode,
    required this.seed,
    required this.worldHeight,
    required this.objective,
    this.loadout = const RunLoadout(),
  }) : rng = SeededRandom(seed) {
    playerY = worldHeight * 0.52;
    if (loadout.shieldStart) {
      effects[PowerUpKind.shield] =
          GameConfig.shieldDuration * loadout.shieldDurationBonus;
    }
    if (loadout.magnetStart) effects[PowerUpKind.magnet] = GameConfig.magnetDuration;
    if (loadout.slowStart) effects[PowerUpKind.slow] = GameConfig.slowDuration;
    if (loadout.doubleStart) effects[PowerUpKind.double] = GameConfig.doubleDuration;
  }

  final GameMode mode;
  final int seed;
  final double worldHeight;
  final RunObjective objective;
  final RunLoadout loadout;
  final SeededRandom rng;

  late final double playerY;
  Dimension dimension = Dimension.light;
  double elapsed = 0;
  int score = 0;
  int orbs = 0;
  int combo = 0;
  int maxCombo = 0;
  int switches = 0;
  int dodges = 0;
  bool isOver = false;
  bool paused = false;
  RunEndReason? endReason;
  double focusEnergy = GameConfig.maxFocusEnergy;
  bool focusing = false;

  final List<Obstacle> obstacles = <Obstacle>[];
  final List<Orb> orbEntities = <Orb>[];
  final List<PowerUpEntity> powerUps = <PowerUpEntity>[];
  final List<Particle> particles = <Particle>[];
  final Map<PowerUpKind, double> effects = <PowerUpKind, double>{};
  List<GameEvent> _events = <GameEvent>[];
  List<GameEvent> _eventScratch = <GameEvent>[];
  final List<PowerUpKind> _expiredEffects = <PowerUpKind>[];
  final DifficultySnapshot _difficulty = DifficultyController.at(0, 0);

  // Give the player a moment to read the lane after the countdown finishes.
  double _spawnTimer = 1.6;
  double _orbTimer = 0.35;
  double _powerTimer = 14;
  double _invulnerability = 1;
  double _switchGrace = 0;
  int _id = 0;
  Dimension? _lastDimension;

  DifficultySnapshot get difficulty => _difficulty;
  int get multiplier => ScoreCalculator.multiplierForCombo(combo);
  bool get hasShield => (effects[PowerUpKind.shield] ?? 0) > 0;

  /// Returns the frame's events without copying. Buffers are swapped so events
  /// added while handling the callback land in the next frame's buffer.
  List<GameEvent> drainEvents() {
    if (_events.isEmpty) return const <GameEvent>[];
    final drained = _events;
    // Clear the incoming scratch buffer before it becomes the next frame's
    // event list; [drained] must stay intact for the caller.
    _events = _eventScratch..clear();
    _eventScratch = drained;
    return drained;
  }

  void switchDimension() {
    if (paused || isOver) return;
    dimension = dimension.other;
    switches++;
    // Brief phase grace makes fast consecutive taps feel responsive instead
    // of punishing a switch made a fraction of a second too early.
    _switchGrace = 0.09;
    _burst(GameConfig.playerX, playerY + GameConfig.playerRadius, 12,
        dimension.isLight ? const Color(0xFF35F5F1) : const Color(0xFFA46BFF), 150);
    _events.add(GameEvent.switchDimension);
  }

  void setFocus(bool active) {
    focusing = active && loadout.focusAvailable && focusEnergy > 0 && !paused && !isOver;
  }

  void update(double dt) {
    if (paused || isOver) return;
    if (!dt.isFinite) return;
    dt = clampDouble(dt, 0, GameConfig.maxDeltaTime);
    if (dt <= 0) return;
    elapsed += dt;
    if (mode == GameMode.timeAttack && elapsed >= 60) {
      elapsed = 60;
      _finish(RunEndReason.timeUp);
      return;
    }

    _updateEffects(dt);
    DifficultyController.updateInto(_difficulty, elapsed, score);
    final diff = _difficulty;
    // Effect state is stable for the rest of this frame; resolve it once.
    final slowActive = hasEffect(PowerUpKind.slow);
    final magnetActive = hasEffect(PowerUpKind.magnet);
    final doubleActive = hasEffect(PowerUpKind.double);
    final speed = diff.speed *
        (slowActive ? 0.64 : 1) *
        (focusing ? 0.55 : 1) *
        loadout.speedReduction;
    score += (speed * dt * 0.035 * (doubleActive ? 2 : 1) * loadout.scoreBonus)
        .round();

    _spawnTimer -= dt;
    if (_spawnTimer <= 0) {
      _spawnWave(diff);
      _spawnTimer = diff.spawnInterval * rng.range(0.94, 1.08);
    }
    _orbTimer -= dt;
    if (_orbTimer <= 0) {
      _spawnOrb();
      _orbTimer = rng.range(0.52, 0.92);
    }
    _powerTimer -= dt;
    if (_powerTimer <= 0) {
      _spawnPowerUp();
      _powerTimer = rng.range(17, 26);
    }

    for (final obstacle in obstacles) {
      obstacle.x -= speed * dt;
      if (obstacle.countsForCombo &&
          !obstacle.counted &&
          obstacle.right < GameConfig.playerX - 18) {
        obstacle.counted = true;
        dodges++;
        combo++;
        maxCombo = math.max(maxCombo, combo);
        score += (ScoreCalculator.dodgePoints(combo, doubled: doubleActive) *
                loadout.dodgeBonus *
                loadout.scoreBonus)
            .round();
        _events.add(GameEvent.dodge);
      }
    }
    for (final orb in orbEntities) {
      orb.x -= speed * dt;
      if (magnetActive && !orb.collected) {
        final dx = GameConfig.playerX - orb.x;
        final dy = playerY - orb.y;
        final distance = math.sqrt(dx * dx + dy * dy);
        if (distance < 260 && distance > 0) {
          orb.x += dx / distance * 620 * dt;
          // Orb.y is final so magnetised orbs snap to the player's lane.
        }
      }
    }
    for (final powerUp in powerUps) {
      powerUp.x -= speed * dt;
    }
    for (final particle in particles) {
      particle.update(dt);
    }
    particles.removeWhere((p) => p.isDead);

    _checkCollisions(magnetActive: magnetActive, doubleActive: doubleActive);

    obstacles.removeWhere((o) => o.right < -100);
    orbEntities.removeWhere((o) => o.x < -60 || o.collected);
    powerUps.removeWhere((p) => p.x < -60 || p.collected);

    if (!isOver && objective.isMet(elapsed, orbs, combo, score, switches)) {
      _finish(RunEndReason.objectiveComplete);
    }
  }

  bool hasEffect(PowerUpKind kind) => (effects[kind] ?? 0) > 0;

  /// Ends the run explicitly (for example when the player quits from pause).
  void finishRun(RunEndReason reason) => _finish(reason);

  void _updateEffects(double dt) {
    if (_invulnerability > 0) _invulnerability -= dt;
    if (_switchGrace > 0) _switchGrace -= dt;
    _expiredEffects.clear();
    for (final entry in effects.entries) {
      final remaining = entry.value - dt;
      if (remaining <= 0) {
        _expiredEffects.add(entry.key);
      } else {
        effects[entry.key] = remaining;
      }
    }
    for (final kind in _expiredEffects) {
      effects.remove(kind);
    }
    if (focusing) {
      focusEnergy = math.max(0, focusEnergy - 34 * dt);
      if (focusEnergy <= 0) focusing = false;
    } else {
      focusEnergy = math.min(GameConfig.maxFocusEnergy, focusEnergy + 13 * dt);
    }
  }

  void _spawnWave(DifficultySnapshot diff) {
    final dimension = _lastDimension != null && rng.nextDouble() > 0.72
        ? _lastDimension!
        : (rng.nextBool() ? Dimension.light : Dimension.shadow);
    _lastDimension = dimension;
    final kind = switch (diff.complexity) {
      1 => ObstacleKind.standard,
      2 => rng.nextBool() ? ObstacleKind.standard : ObstacleKind.wide,
      3 => rng.nextBool() ? ObstacleKind.wide : ObstacleKind.doubleStack,
      _ => switch (rng.nextInt(3)) {
          0 => ObstacleKind.standard,
          1 => ObstacleKind.wide,
          _ => ObstacleKind.doubleStack,
        },
    };
    final width = kind == ObstacleKind.wide
        ? GameConfig.obstacleWidth * 1.75
        : GameConfig.obstacleWidth;
    final jitter = rng.range(-38, 38);
    final height = GameConfig.obstacleHeight;
    final x = GameConfig.worldWidth + 55;
    obstacles.add(Obstacle(
      id: ++_id,
      x: x,
      y: playerY - height / 2 + jitter,
      dimension: dimension,
      kind: kind,
      width: width,
      height: height,
    ));
    if (kind == ObstacleKind.doubleStack) {
      obstacles.add(Obstacle(
        id: ++_id,
        x: x + rng.range(-30, 30),
        y: playerY + height * 0.55,
        dimension: dimension,
        kind: ObstacleKind.standard,
        width: GameConfig.obstacleWidth * 0.8,
        height: height * 0.7,
        countsForCombo: false,
      ));
    }
  }

  void _spawnOrb() {
    orbEntities.add(Orb(
      id: ++_id,
      x: GameConfig.worldWidth + 20,
      y: clampDouble(playerY + rng.range(-78, 78), 70, worldHeight - 70),
      dimension: rng.nextBool() ? Dimension.light : Dimension.shadow,
    ));
  }

  void _spawnPowerUp() {
    final kinds = PowerUpKind.values;
    powerUps.add(PowerUpEntity(
      id: ++_id,
      x: GameConfig.worldWidth + 60,
      y: clampDouble(playerY + rng.range(-50, 50), 80, worldHeight - 80),
      kind: kinds[rng.nextInt(kinds.length)],
    ));
  }

  void _checkCollisions({
    required bool magnetActive,
    required bool doubleActive,
  }) {
    final hitRadius = GameConfig.playerRadius * 0.78;
    final collisionGrace = _switchGrace > 0;
    var shieldActive = hasShield;
    for (final obstacle in obstacles) {
      if (obstacle.destroyed || obstacle.dimension != dimension) continue;
      if (collisionGrace) continue;
      if (!obstacle.overlaps(GameConfig.playerX, playerY, hitRadius)) continue;
      if (shieldActive) {
        effects.remove(PowerUpKind.shield);
        shieldActive = false;
        obstacle.destroyed = true;
        obstacle.counted = true;
        _invulnerability = 0.55;
        combo = 0;
        _burst(GameConfig.playerX, playerY, 26, AppPalette.danger, 260);
        _events.add(GameEvent.shieldBreak);
      } else if (_invulnerability <= 0) {
        _burst(GameConfig.playerX, playerY, 32, AppPalette.danger, 300);
        _finish(RunEndReason.collision);
        return;
      }
    }
    final collectRadius = GameConfig.playerRadius + GameConfig.orbRadius;
    for (final orb in orbEntities) {
      if (orb.collected) continue;
      if (!magnetActive && orb.dimension != dimension) continue;
      if ((orb.x - GameConfig.playerX).abs() > collectRadius ||
          (orb.y - playerY).abs() > collectRadius) {
        continue;
      }
      orb.collected = true;
      orbs++;
      combo++;
      maxCombo = math.max(maxCombo, combo);
      score += (ScoreCalculator.orbPoints(combo, doubled: doubleActive) *
              loadout.orbBonus *
              loadout.scoreBonus)
          .round();
      _burst(orb.x, orb.y, 8, AppPalette.gold, 135);
      _events.add(GameEvent.collectOrb);
    }
    for (final powerUp in powerUps) {
      if (powerUp.collected) continue;
      if ((powerUp.x - GameConfig.playerX).abs() > GameConfig.playerRadius + 19 ||
          (powerUp.y - playerY).abs() > GameConfig.playerRadius + 19) {
        continue;
      }
      powerUp.collected = true;
      final duration = switch (powerUp.kind) {
        PowerUpKind.shield => GameConfig.shieldDuration * loadout.shieldDurationBonus,
        PowerUpKind.magnet => GameConfig.magnetDuration,
        PowerUpKind.slow => GameConfig.slowDuration,
        PowerUpKind.double => GameConfig.doubleDuration,
      };
      effects[powerUp.kind] = math.max(effects[powerUp.kind] ?? 0, duration);
      _burst(powerUp.x, powerUp.y, 18, AppPalette.violet, 210);
      _events.add(GameEvent.collectPowerUp);
    }
  }

  void _burst(double x, double y, int count, Color color, double speed) {
    if (particles.length > 140) return;
    for (var i = 0; i < count; i++) {
      final angle = rng.nextDouble() * math.pi * 2;
      final velocity = speed * rng.range(0.35, 1);
      particles.add(Particle(
        x: x,
        y: y,
        vx: math.cos(angle) * velocity,
        vy: math.sin(angle) * velocity,
        life: rng.range(0.25, 0.62),
        size: rng.range(2, 5.5),
        color: color,
      ));
    }
  }

  void _finish(RunEndReason reason) {
    if (isOver) return;
    isOver = true;
    endReason = reason;
    focusing = false;
    _events.add(reason == RunEndReason.objectiveComplete
        ? GameEvent.objectiveComplete
        : GameEvent.gameOver);
  }

  RunResult result({String? challengeId, String runId = ''}) => RunResult(
        mode: mode,
        score: score,
        seconds: elapsed,
        orbs: orbs,
        maxCombo: maxCombo,
        switches: switches,
        dodges: dodges,
        reason: endReason ?? RunEndReason.quit,
        objective: objective,
        seed: seed,
        challengeId: challengeId,
        runId: runId,
      );
}

/// Palette kept in the pure logic layer so particles can be spawned without
/// importing Flutter widgets.
abstract final class AppPalette {
  static const danger = Color(0xFFFF4D6D);
  static const gold = Color(0xFFFFD166);
  static const violet = Color(0xFFA46BFF);
}
