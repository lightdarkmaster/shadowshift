import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:shadowshift/core/constants.dart';
import 'package:shadowshift/domain/game/engine.dart';
import 'package:shadowshift/domain/game/enums.dart';
import 'package:shadowshift/domain/progression/catalog.dart';

class VisualOptions {
  const VisualOptions({
    this.reducedMotion = false,
    this.screenShake = true,
    this.effectId = 'classic',
    this.skinId = 'aurora',
    this.characterId = 'nyx',
    this.characterColor = AppColors.cyan,
    this.companionId = 'none',
  });

  final bool reducedMotion;
  final bool screenShake;
  final String effectId;
  final String skinId;

  /// The unlocked runner used for this run. Its colour and emblem are drawn
  /// on the player so the selection screen and gameplay stay in sync.
  final String characterId;
  final Color characterColor;

  /// A floating ally selected in the shop's COMPANIONS tab.
  final String companionId;
}

List<Color> _fadeColors(Color base) =>
    List<Color>.generate(17, (i) => base.withValues(alpha: i / 16));

/// Hue cycle shared by the PRISM skin and effect so their colours stay in sync.
Color _rainbow(double phase) =>
    HSVColor.fromAHSV(1, (phase % 1) * 360, 0.82, 1).toColor();

/// Draws the whole world in one canvas pass. Keeping rendering in a single
/// painter avoids hundreds of Flame components and keeps 60fps easy to hold.
class ShadowPainter extends CustomPainter {
  ShadowPainter(this.engine, this.options) {
    _characterGlow = options.characterColor.withValues(alpha: 0.22);
    _characterAccent = options.characterColor.withValues(alpha: 0.9);
    _echoPaint.color = options.characterColor.withValues(alpha: 0.2);
    // Catalogue colours are the single source of truth, so new shop items
    // change the runner without needing another switch in the painter.
    _skinColor = Catalog.find(Catalog.skins, options.skinId).color;
    _effectColor = Catalog.find(Catalog.effects, options.effectId).color;
    _companionColor = Catalog.find(Catalog.companions, options.companionId).color;
  }

  final GameEngine engine;
  final VisualOptions options;
  late final Color _characterGlow;
  late final Color _characterAccent;
  late final Color _skinColor;
  late final Color _effectColor;
  late final Color _companionColor;
  int _lastSwitches = 0;
  double _switchPulse = 0;
  double _shake = 0;

  // Reusable paint objects and precomputed colours/shaders. Canvas painting is
  // synchronous, so mutating these between draw calls is safe and avoids
  // allocating Color/Paint/gradient objects 60 times a second.
  static const _blur18 = MaskFilter.blur(BlurStyle.normal, 18);
  static const _blur14 = MaskFilter.blur(BlurStyle.normal, 14);
  static const _blur10 = MaskFilter.blur(BlurStyle.normal, 10);

  static final Map<Dimension, Color> _gridColors = {
    Dimension.light: AppColors.cyan.withValues(alpha: 0.075),
    Dimension.shadow: AppColors.violet.withValues(alpha: 0.075),
  };
  static final Map<Dimension, Color> _laneColors = {
    Dimension.light: AppColors.cyan.withValues(alpha: 0.1),
    Dimension.shadow: AppColors.violet.withValues(alpha: 0.1),
  };
  static final LinearGradient _lightBackgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: const [Color(0xFF070B1A), Color(0xFF0B1428), Color(0xFF080A17)],
  );
  static final LinearGradient _shadowBackgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: const [Color(0xFF0B071A), Color(0xFF150C2B), Color(0xFF080715)],
  );
  static final LinearGradient _lightLaneGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Colors.transparent,
      _laneColors[Dimension.light]!,
      Colors.transparent,
    ],
  );
  static final LinearGradient _shadowLaneGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Colors.transparent,
      _laneColors[Dimension.shadow]!,
      Colors.transparent,
    ],
  );

  /// Same calm green/purple split as the UI screens, kept translucent so the
  /// dimension colours and obstacles still read clearly during a run.
  static final LinearGradient _leftSplitWash = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.center,
    colors: [
      AppGradients.leftDeep.withValues(alpha: 0.3),
      AppGradients.leftMid.withValues(alpha: 0.18),
      Colors.transparent,
    ],
    stops: const [0, 0.55, 1],
  );
  static final LinearGradient _rightSplitWash = LinearGradient(
    begin: Alignment.center,
    end: Alignment.centerRight,
    colors: [
      Colors.transparent,
      AppGradients.rightMid.withValues(alpha: 0.18),
      AppGradients.rightDeep.withValues(alpha: 0.3),
    ],
    stops: const [0, 0.45, 1],
  );

  static final Map<Dimension, Color> _obstacleGlowColors = {
    Dimension.light: AppColors.cyan.withValues(alpha: 0.16),
    Dimension.shadow: AppColors.violet.withValues(alpha: 0.16),
  };
  static final Map<Dimension, List<Color>> _obstacleFillColors = {
    Dimension.light: [
      AppColors.cyan.withValues(alpha: 0.36),
      AppColors.cyan.withValues(alpha: 0.09),
      AppColors.cyan.withValues(alpha: 0.24),
    ],
    Dimension.shadow: [
      AppColors.violet.withValues(alpha: 0.36),
      AppColors.violet.withValues(alpha: 0.09),
      AppColors.violet.withValues(alpha: 0.24),
    ],
  };
  static final LinearGradient _lightObstacleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: _obstacleFillColors[Dimension.light]!,
  );
  static final LinearGradient _shadowObstacleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: _obstacleFillColors[Dimension.shadow]!,
  );
  static final Map<Dimension, Color> _obstacleStrokeColors = {
    Dimension.light: AppColors.cyan.withValues(alpha: 0.9),
    Dimension.shadow: AppColors.violet.withValues(alpha: 0.9),
  };
  static final Map<Dimension, Color> _obstacleLineColors = {
    Dimension.light: AppColors.cyan.withValues(alpha: 0.42),
    Dimension.shadow: AppColors.violet.withValues(alpha: 0.42),
  };

  static final Map<Dimension, Color> _orbGlowActive = {
    Dimension.light: AppColors.gold.withValues(alpha: 0.16),
    Dimension.shadow: AppColors.pink.withValues(alpha: 0.16),
  };
  static final Map<Dimension, Color> _orbGlowDim = {
    Dimension.light: AppColors.gold.withValues(alpha: 0.16 * 0.32),
    Dimension.shadow: AppColors.pink.withValues(alpha: 0.16 * 0.32),
  };
  static final Map<Dimension, Color> _orbCoreActive = {
    Dimension.light: AppColors.gold,
    Dimension.shadow: AppColors.pink,
  };
  static final Map<Dimension, Color> _orbCoreDim = {
    Dimension.light: AppColors.gold.withValues(alpha: 0.32),
    Dimension.shadow: AppColors.pink.withValues(alpha: 0.32),
  };
  static final Color _orbSpark = Colors.white.withValues(alpha: 0.9);
  static final Color _orbSparkDim = Colors.white.withValues(alpha: 0.9 * 0.32);

  static final Map<PowerUpKind, Color> _powerCoreColors = {
    PowerUpKind.shield: AppColors.cyan,
    PowerUpKind.magnet: AppColors.gold,
    PowerUpKind.slow: AppColors.blue,
    PowerUpKind.double: AppColors.pink,
  };
  static final Map<PowerUpKind, Color> _powerGlowColors = {
    for (final entry in _powerCoreColors.entries)
      entry.key: entry.value.withValues(alpha: 0.25),
  };
  static final Map<PowerUpKind, Color> _powerFillColors = {
    for (final entry in _powerCoreColors.entries)
      entry.key: entry.value.withValues(alpha: 0.28),
  };

  static final Map<Dimension, Color> _playerBodyColors = {
    Dimension.light: AppColors.cyan.withValues(alpha: 0.92),
    Dimension.shadow: AppColors.violet.withValues(alpha: 0.92),
  };
  static final Map<Dimension, List<Color>> _playerTrailColors = {
    Dimension.light: [
      for (var i = 1; i <= 3; i++) AppColors.cyan.withValues(alpha: 0.25 / i),
    ],
    Dimension.shadow: [
      for (var i = 1; i <= 3; i++) AppColors.violet.withValues(alpha: 0.25 / i),
    ],
  };
  static final Color _playerStrokeColor = Colors.white.withValues(alpha: 0.85);
  static final Color _shieldColor = AppColors.cyan.withValues(alpha: 0.85);
  static final Color _focusColor = AppColors.gold.withValues(alpha: 0.7);

  static final List<Color> _dangerFade = _fadeColors(AppPalette.danger);
  static final List<Color> _goldFade = _fadeColors(AppPalette.gold);
  static final List<Color> _violetFade = _fadeColors(AppPalette.violet);

  static final Path _powerDiamond = Path()
    ..moveTo(0, -21)
    ..lineTo(21, 0)
    ..lineTo(0, 21)
    ..lineTo(-21, 0)
    ..close();
  static final Path _playerBody = Path()
    ..moveTo(GameConfig.playerRadius * 1.35, 0)
    ..lineTo(-GameConfig.playerRadius * 0.85, -GameConfig.playerRadius * 1.15)
    ..lineTo(-GameConfig.playerRadius * 0.45, 0)
    ..lineTo(-GameConfig.playerRadius * 0.85, GameConfig.playerRadius * 1.15)
    ..close();

  final Paint _backgroundPaint = Paint();
  final Paint _splitPaint = Paint();
  Shader? _leftSplitShader;
  Shader? _rightSplitShader;
  double? _splitShaderHeight;
  final Paint _gridPaint = Paint()..strokeWidth = 1.2;
  final Paint _lanePaint = Paint();
  final Paint _skylinePaint = Paint()
    ..color = const Color(0xFF11152D).withValues(alpha: 0.55);
  Shader? _backgroundShader;
  Dimension? _backgroundShaderDimension;
  double? _backgroundShaderHeight;
  Shader? _laneShader;
  Dimension? _laneShaderDimension;
  double? _laneShaderHorizon;

  final Paint _obstacleGlowPaint = Paint()..maskFilter = _blur18;
  final Paint _obstacleFillPaint = Paint();
  final Paint _obstacleStrokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;
  final Paint _obstacleLinePaint = Paint()..strokeWidth = 1.5;
  final Paint _obstacleDotPaint = Paint();

  final Paint _orbGlowPaint = Paint()..maskFilter = _blur10;
  final Paint _orbCorePaint = Paint();
  final Paint _orbSparkPaint = Paint();

  final Paint _powerGlowPaint = Paint()..maskFilter = _blur14;
  final Paint _powerFillPaint = Paint();
  final Paint _powerStrokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5;
  final Map<String, TextPainter> _powerLabels = <String, TextPainter>{};

  final Paint _playerGlowPaint = Paint()..maskFilter = _blur18;
  final Paint _playerTrailPaint = Paint();
  final Paint _playerBodyPaint = Paint();
  final Paint _playerStrokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  final Paint _skinPaint = Paint();
  final Paint _characterPaint = Paint()..style = PaintingStyle.stroke;
  final Paint _echoPaint = Paint();
  final Paint _shieldPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5;
  final Paint _focusPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  final Paint _particlePaint = Paint();
  final Paint _pulsePaint = Paint()..style = PaintingStyle.stroke;
  final Paint _skinRingPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.6;
  final Paint _effectRingPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.2;
  final Paint _overlayPaint = Paint();
  final Paint _companionGlowPaint = Paint()..maskFilter = _blur14;
  final Paint _companionRingPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  final Paint _companionCorePaint = Paint();

  static Color get _cyan => AppColors.cyan;
  static Color get _violet => AppColors.violet;

  Color dimensionColor(Dimension dimension) =>
      dimension.isLight ? _cyan : _violet;

  void triggerShake() => _shake = 1;

  /// Advances visual timers by real elapsed time so effects last the same
  /// wall-clock duration on 60Hz and 120Hz displays.
  void tick(double dt) {
    if (engine.switches != _lastSwitches) {
      _lastSwitches = engine.switches;
      _switchPulse = 1;
    }
    if (_shake > 0) _shake = math.max(0, _shake - dt * 2.7);
    if (_switchPulse > 0) _switchPulse = math.max(0, _switchPulse - dt * 2.1);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / GameConfig.worldWidth;
    final scaleY = size.height / engine.worldHeight;
    canvas.save();
    canvas.scale(scaleX, scaleY);

    if (_shake > 0 && options.screenShake && !options.reducedMotion) {
      final amount = _shake * 12;
      canvas.translate(
        math.sin(engine.elapsed * 91) * amount,
        math.cos(engine.elapsed * 77) * amount,
      );
    }

    _drawBackground(canvas);
    _drawOrbs(canvas);
    _drawPowerUps(canvas);
    _drawObstacles(canvas);
    _drawParticles(canvas);
    _drawPlayer(canvas);
    _drawCompanion(canvas);
    _drawSwitchPulse(canvas);
    canvas.restore();
  }

  void _drawBackground(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, GameConfig.worldWidth, engine.worldHeight);
    if (_backgroundShader == null ||
        _backgroundShaderDimension != engine.dimension ||
        _backgroundShaderHeight != engine.worldHeight) {
      final gradient = engine.dimension.isLight
          ? _lightBackgroundGradient
          : _shadowBackgroundGradient;
      _backgroundShader = gradient.createShader(rect);
      _backgroundShaderDimension = engine.dimension;
      _backgroundShaderHeight = engine.worldHeight;
    }
    _backgroundPaint.shader = _backgroundShader;
    canvas.drawRect(rect, _backgroundPaint);
    _drawSplitWash(canvas, rect);

    // VOID darkens only the backdrop; the shader cache stays dimension-keyed.
    if (options.effectId == 'void') {
      _overlayPaint.color = const Color(0xFF0A0316).withValues(alpha: 0.62);
      canvas.drawRect(rect, _overlayPaint);
    }

    final horizon = engine.playerY;
    _gridPaint.color = _gridColors[engine.dimension]!;
    final scroll = engine.elapsed * 110;
    for (var i = 0; i < 16; i++) {
      final x = ((i * 92 - scroll) % 1472) - 120;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x - 70, engine.worldHeight),
        _gridPaint,
      );
    }
    for (var i = 0; i < 12; i++) {
      final y = ((i * 118 + scroll * 0.16) % (engine.worldHeight + 200)) - 100;
      canvas.drawLine(
        Offset(0, y),
        Offset(GameConfig.worldWidth, y),
        _gridPaint,
      );
    }
    // Central lane highlight. The horizon is fixed for a run, so cache it.
    final laneRect = Rect.fromLTWH(
      0,
      horizon - 130,
      GameConfig.worldWidth,
      260,
    );
    if (_laneShader == null ||
        _laneShaderDimension != engine.dimension ||
        _laneShaderHorizon != horizon) {
      final gradient = engine.dimension.isLight
          ? _lightLaneGradient
          : _shadowLaneGradient;
      _laneShader = gradient.createShader(laneRect);
      _laneShaderDimension = engine.dimension;
      _laneShaderHorizon = horizon;
    }
    _lanePaint.shader = _laneShader;
    canvas.drawRect(laneRect, _lanePaint);

    // Distant skyline silhouettes for depth.
    for (var i = 0; i < 13; i++) {
      final height = 60.0 + ((i * 37) % 130);
      canvas.drawRect(
        Rect.fromLTWH(
          i * 84.0 - (scroll * 0.22 % 84),
          horizon - height - 55,
          62,
          height,
        ),
        _skylinePaint,
      );
    }
    _drawAmbientEffect(canvas);
  }

  /// Adds the same soft left-green / right-purple wash used by the UI screens.
  /// Both halves fade to transparent at the centre, so there is no hard seam.
  void _drawSplitWash(Canvas canvas, Rect rect) {
    final half = rect.width / 2;
    final left = Rect.fromLTWH(rect.left, rect.top, half, rect.height);
    final right = Rect.fromLTWH(rect.left + half, rect.top, half, rect.height);
    if (_splitShaderHeight != rect.height) {
      _leftSplitShader = _leftSplitWash.createShader(left);
      _rightSplitShader = _rightSplitWash.createShader(right);
      _splitShaderHeight = rect.height;
    }
    _splitPaint.shader = _leftSplitShader;
    canvas.drawRect(left, _splitPaint);
    _splitPaint.shader = _rightSplitShader;
    canvas.drawRect(right, _splitPaint);
    _splitPaint.shader = null;
  }

  /// Ambient details for effects that change the whole scene rather than the
  /// runner itself. The core scene stays untouched for CLASSIC.
  void _drawAmbientEffect(Canvas canvas) {
    final effect = options.effectId;
    if (effect == 'blizzard' && !options.reducedMotion) {
      for (var i = 0; i < 30; i++) {
        final drift = 42 + (i % 5) * 16;
        final x = ((i * 137.5 + engine.elapsed * drift) %
                (GameConfig.worldWidth + 80)) -
            40;
        final y = (i * 83.3 + engine.elapsed * (58 + (i % 4) * 14)) %
            engine.worldHeight;
        _particlePaint.color =
            Colors.white.withValues(alpha: 0.16 + (i % 3) * 0.08);
        canvas.drawCircle(Offset(x, y), 1.2 + (i % 3) * 0.7, _particlePaint);
      }
    }
    if (effect == 'glitch' && !options.reducedMotion) {
      _overlayPaint.color = AppColors.pink.withValues(alpha: 0.07);
      final offset = (engine.elapsed * 110) % 26;
      for (var y = offset; y < engine.worldHeight; y += 26) {
        canvas.drawRect(
          Rect.fromLTWH(0, y, GameConfig.worldWidth, 2),
          _overlayPaint,
        );
      }
    }
  }

  void _drawObstacles(Canvas canvas) {
    for (final obstacle in engine.obstacles) {
      if (obstacle.destroyed) continue;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          obstacle.left,
          obstacle.y,
          obstacle.width,
          obstacle.height,
        ),
        const Radius.circular(13),
      );
      _obstacleGlowPaint.color = _obstacleGlowColors[obstacle.dimension]!;
      canvas.drawRRect(rect.inflate(7), _obstacleGlowPaint);
      final gradient = obstacle.dimension.isLight
          ? _lightObstacleGradient
          : _shadowObstacleGradient;
      _obstacleFillPaint.shader = gradient.createShader(rect.outerRect);
      canvas.drawRRect(rect, _obstacleFillPaint);
      _obstacleStrokePaint.color = _obstacleStrokeColors[obstacle.dimension]!;
      canvas.drawRRect(rect, _obstacleStrokePaint);
      _obstacleLinePaint.color = _obstacleLineColors[obstacle.dimension]!;
      for (
        var y = obstacle.y + 18;
        y < obstacle.y + obstacle.height - 8;
        y += 26
      ) {
        canvas.drawLine(
          Offset(obstacle.left + 9, y),
          Offset(obstacle.right - 9, y),
          _obstacleLinePaint,
        );
      }
      _obstacleDotPaint.color = dimensionColor(obstacle.dimension);
      canvas.drawCircle(
        Offset(obstacle.x, obstacle.y + obstacle.height / 2),
        6,
        _obstacleDotPaint,
      );
    }
  }

  void _drawOrbs(Canvas canvas) {
    final magnetActive = engine.hasEffect(PowerUpKind.magnet);
    for (final orb in engine.orbEntities) {
      final dimension = orb.dimension;
      final active = dimension == engine.dimension || magnetActive;
      final center = Offset(orb.x, orb.y);
      _orbGlowPaint.color = (active ? _orbGlowActive : _orbGlowDim)[dimension]!;
      canvas.drawCircle(
        center,
        GameConfig.orbRadius * (active ? 2.1 : 1.5),
        _orbGlowPaint,
      );
      _orbCorePaint.color = (active ? _orbCoreActive : _orbCoreDim)[dimension]!;
      canvas.drawCircle(center, GameConfig.orbRadius, _orbCorePaint);
      _orbSparkPaint.color = active ? _orbSpark : _orbSparkDim;
      canvas.drawCircle(center, GameConfig.orbRadius * 0.45, _orbSparkPaint);
    }
  }

  void _drawPowerUps(Canvas canvas) {
    for (final powerUp in engine.powerUps) {
      final kind = powerUp.kind;
      final center = Offset(powerUp.x, powerUp.y);
      _powerGlowPaint.color = _powerGlowColors[kind]!;
      _powerFillPaint.color = _powerFillColors[kind]!;
      _powerStrokePaint.color = _powerCoreColors[kind]!;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.drawPath(_powerDiamond, _powerGlowPaint);
      canvas.drawPath(_powerDiamond, _powerFillPaint);
      canvas.drawPath(_powerDiamond, _powerStrokePaint);
      canvas.restore();

      final label = switch (kind) {
        PowerUpKind.shield => 'S',
        PowerUpKind.magnet => 'M',
        PowerUpKind.slow => 'T',
        PowerUpKind.double => '2',
      };
      final painter = _powerLabels.putIfAbsent(
        label,
        () => TextPainter(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        )..layout(),
      );
      painter.paint(
        canvas,
        center - Offset(painter.width / 2, painter.height / 2),
      );
    }
  }

  void _drawPlayer(Canvas canvas) {
    final dimension = engine.dimension;
    final x = GameConfig.playerX;
    final y = engine.playerY;
    final radius = GameConfig.playerRadius;
    // The runner's own colour gives each unlocked character a distinct glow,
    // while the body colour still communicates the active dimension.
    _playerGlowPaint.color = _characterGlow;
    canvas.drawCircle(Offset(x, y), radius * 2.2, _playerGlowPaint);

    // The equipped skin gets its own aura ring, making the choice readable at
    // a glance while the body colour keeps communicating the active dimension.
    _skinRingPaint.color = options.skinId == 'spectrum' && !options.reducedMotion
        ? _rainbow(engine.elapsed * 0.4).withValues(alpha: 0.6)
        : _skinColor.withValues(alpha: 0.45);
    canvas.drawCircle(Offset(x, y), radius * 1.5, _skinRingPaint);

    final effect = options.effectId;
    final trail = effect == 'comet' ? 4 : effect == 'nova' ? 2 : 1;
    final trailColors = _playerTrailColors[dimension]!;
    for (var i = 1; i <= trail; i++) {
      final alpha = 0.25 / i;
      _playerTrailPaint.color = switch (effect) {
        'prism' => _rainbow(engine.elapsed * 0.35 + i * 0.11).withValues(alpha: alpha),
        'void' => _effectColor.withValues(alpha: alpha * 1.2),
        'blizzard' => const Color(0xFF9DEBFF).withValues(alpha: alpha),
        _ => trailColors[math.min(i - 1, trailColors.length - 1)],
      };
      canvas.drawCircle(
        Offset(x - i * 26, y),
        radius * (0.55 - i * 0.08),
        _playerTrailPaint,
      );
    }
    // ECHO leaves faint after-images of its actual body shape behind.
    if (options.characterId == 'echo' && !options.reducedMotion) {
      for (var i = 1; i <= 2; i++) {
        canvas.save();
        canvas.translate(x - i * 22, y + (i.isOdd ? -8 : 8));
        canvas.drawPath(_playerBody, _echoPaint);
        canvas.restore();
      }
    }

    _playerBodyPaint.color = _playerBodyColors[dimension]!;
    _playerStrokePaint.color = _playerStrokeColor;
    canvas.save();
    canvas.translate(x, y);
    canvas.drawPath(_playerBody, _playerBodyPaint);
    canvas.drawPath(_playerBody, _playerStrokePaint);
    canvas.restore();
    _skinPaint.color = options.skinId == 'spectrum' && !options.reducedMotion
        ? _rainbow(engine.elapsed * 0.4)
        : _skinColor;
    canvas.drawCircle(Offset(x + 2, y), radius * 0.26, _skinPaint);

    if (effect == 'pulse' && !options.reducedMotion) {
      for (var ring = 0; ring < 3; ring++) {
        final phase = (engine.elapsed * 0.85 + ring / 3) % 1;
        _effectRingPaint.color =
            _effectColor.withValues(alpha: (1 - phase) * 0.45);
        canvas.drawCircle(
          Offset(x, y),
          radius * (1.3 + phase * 2.4),
          _effectRingPaint,
        );
      }
    }
    if (effect == 'glitch' && !options.reducedMotion) {
      _effectRingPaint.color = AppColors.cyan.withValues(alpha: 0.4);
      canvas.save();
      canvas.translate(x - 4, y);
      canvas.drawPath(_playerBody, _effectRingPaint);
      canvas.restore();
      _effectRingPaint.color = AppColors.pink.withValues(alpha: 0.4);
      canvas.save();
      canvas.translate(x + 4, y);
      canvas.drawPath(_playerBody, _effectRingPaint);
      canvas.restore();
    }

    _characterPaint.color = _characterAccent;
    _characterPaint.strokeWidth = 2;
    switch (options.characterId) {
      case 'flux':
        canvas.drawCircle(
          Offset(x + 2, y - radius * 0.34),
          radius * 0.13,
          _characterPaint,
        );
        canvas.drawCircle(
          Offset(x + 2, y + radius * 0.34),
          radius * 0.13,
          _characterPaint,
        );
        break;
      case 'echo':
        canvas.drawCircle(Offset(x + 2, y), radius * 0.42, _characterPaint);
        break;
      case 'spectre':
        canvas.drawCircle(Offset(x, y), radius * 1.32, _characterPaint);
        break;
      case 'zenith':
        canvas.drawLine(
          Offset(x + radius * 0.35, y - radius * 0.35),
          Offset(x + radius * 0.9, y),
          _characterPaint,
        );
        canvas.drawLine(
          Offset(x + radius * 0.35, y + radius * 0.35),
          Offset(x + radius * 0.9, y),
          _characterPaint,
        );
        break;
      case 'viper':
        canvas.drawLine(
          Offset(x - 8, y - radius * 0.4),
          Offset(x + 6, y),
          _characterPaint,
        );
        canvas.drawLine(
          Offset(x + 6, y),
          Offset(x - 8, y + radius * 0.4),
          _characterPaint,
        );
        break;
      case 'onyx':
        canvas.drawCircle(Offset(x + 2, y), radius * 0.3, _characterPaint);
        canvas.drawCircle(Offset(x + 2, y), radius * 0.55, _characterPaint);
        break;
      case 'lumen':
        for (var i = 0; i < 4; i++) {
          final angle = i * math.pi / 2 + engine.elapsed * 0.6;
          canvas.drawLine(
            Offset(
              x + 2 + math.cos(angle) * radius * 0.5,
              y + math.sin(angle) * radius * 0.5,
            ),
            Offset(
              x + 2 + math.cos(angle) * radius * 0.85,
              y + math.sin(angle) * radius * 0.85,
            ),
            _characterPaint,
          );
        }
        break;
    }
    if (engine.hasShield) {
      _shieldPaint.color = _shieldColor;
      canvas.drawCircle(Offset(x, y), radius * 1.7, _shieldPaint);
    }
    if (engine.focusing) {
      _focusPaint.color = _focusColor;
      canvas.drawCircle(Offset(x, y), radius * 2.1, _focusPaint);
    }
  }

  /// Small ally that bobs beside the runner. Its colour comes from the
  /// companion catalogue, so every unlocked ally looks distinct.
  void _drawCompanion(Canvas canvas) {
    if (options.companionId == 'none') return;
    final t = options.reducedMotion ? 0.0 : engine.elapsed;
    final x = GameConfig.playerX - 58 + math.sin(t * 2.3) * 6;
    final y = engine.playerY - 44 + math.cos(t * 1.7) * 9;
    _companionGlowPaint.color = _companionColor.withValues(alpha: 0.3);
    canvas.drawCircle(Offset(x, y), 18, _companionGlowPaint);
    _companionRingPaint.color = _companionColor.withValues(alpha: 0.7);
    canvas.drawCircle(Offset(x, y), 11, _companionRingPaint);
    _companionCorePaint.color = _companionColor;
    canvas.drawCircle(Offset(x, y), 5, _companionCorePaint);
  }

  void _drawParticles(Canvas canvas) {
    for (final particle in engine.particles) {
      final fade = options.effectId == 'void'
          ? _goldFade
          : particle.color == AppPalette.danger
          ? _dangerFade
          : particle.color == AppPalette.gold
          ? _goldFade
          : _violetFade;
      final alpha = (particle.life * 1.6).clamp(0.0, 1.0);
      final bucket = (alpha * 16).round().clamp(0, 16);
      _particlePaint.color = fade[bucket];
      canvas.drawCircle(
        Offset(particle.x, particle.y),
        particle.size,
        _particlePaint,
      );
    }
  }

  void _drawSwitchPulse(Canvas canvas) {
    if (_switchPulse <= 0 || options.reducedMotion) return;
    final progress = 1 - _switchPulse;
    _pulsePaint.color = dimensionColor(
      engine.dimension,
    ).withValues(alpha: _switchPulse * 0.55);
    _pulsePaint.strokeWidth = 3 * _switchPulse;
    final center = Offset(GameConfig.playerX, engine.playerY);
    final radius = 30 + progress * 220;
    canvas.drawCircle(center, radius, _pulsePaint);

    if (options.effectId == 'nova') {
      _effectRingPaint.color = _effectColor.withValues(alpha: _switchPulse * 0.8);
      for (var i = 0; i < 10; i++) {
        final angle = i * math.pi / 5 + engine.elapsed * 0.7;
        final inner = radius * 0.55;
        final outer = radius * 1.15;
        canvas.drawLine(
          center + Offset(math.cos(angle) * inner, math.sin(angle) * inner),
          center + Offset(math.cos(angle) * outer, math.sin(angle) * outer),
          _effectRingPaint,
        );
      }
    }
    if (options.effectId == 'prism') {
      for (var ring = 0; ring < 3; ring++) {
        _effectRingPaint.color = _rainbow(
          engine.elapsed * 0.5 + ring / 3,
        ).withValues(alpha: _switchPulse * 0.7);
        canvas.drawCircle(center, radius * (0.6 + ring * 0.28), _effectRingPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant ShadowPainter oldDelegate) => true;
}
