import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:shadowshift/core/constants.dart';
import 'package:shadowshift/domain/game/engine.dart';
import 'package:shadowshift/domain/game/entities.dart';
import 'package:shadowshift/domain/game/enums.dart';
import 'package:shadowshift/game/shadow_painter.dart';

/// Flame owns the frame loop and lifecycle; all simulation lives in the pure
/// [GameEngine] and all drawing in [ShadowPainter].
class ShadowShiftGame extends FlameGame {
  ShadowShiftGame({
    required this.engine,
    required this.options,
    required this.onEvent,
    required this.onFinish,
    required this.challengeId,
    this.onHudTick,
  });

  final GameEngine engine;
  final VisualOptions options;
  final void Function(GameEvent event) onEvent;
  final void Function(RunResult result) onFinish;
  final String? challengeId;
  final VoidCallback? onHudTick;

  CustomPainterComponent? _painter;
  double _hudTimer = 0;
  bool _finished = false;

  @override
  Color backgroundColor() => AppColors.background;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _painter = CustomPainterComponent(
      painter: ShadowPainter(engine, options),
      size: size,
    );
    await add(_painter!);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _painter?.size = size;
  }

  @override
  void update(double dt) {
    engine.update(dt);
    final painter = _painter?.painter;
    for (final event in engine.drainEvents()) {
      if (event == GameEvent.shieldBreak || event == GameEvent.gameOver) {
        if (painter is ShadowPainter) painter.triggerShake();
      }
      onEvent(event);
    }
    if (painter is ShadowPainter) painter.tick(dt);
    if (engine.isOver && !_finished) {
      _finished = true;
      onFinish(engine.result(challengeId: challengeId));
    }
    _hudTimer += dt;
    if (_hudTimer >= 0.08) {
      _hudTimer = 0;
      onHudTick?.call();
    }
    super.update(dt);
  }
}
