import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadowshift/core/constants.dart';
import 'package:shadowshift/core/utils.dart';
import 'package:shadowshift/domain/game/difficulty.dart';
import 'package:shadowshift/domain/game/engine.dart';
import 'package:shadowshift/domain/game/entities.dart';
import 'package:shadowshift/domain/game/enums.dart';
import 'package:shadowshift/domain/progression/catalog.dart';
import 'package:shadowshift/domain/services/audio_service.dart';
import 'package:shadowshift/domain/services/launch_service.dart';
import 'package:shadowshift/game/shadow_shift_game.dart';
import 'package:shadowshift/game/shadow_painter.dart';
import 'package:shadowshift/state/app_providers.dart';
import 'package:shadowshift/ui/navigation.dart';
import 'package:shadowshift/ui/screens/game_over_screen.dart';
import 'package:shadowshift/ui/screens/main_menu.dart';
import 'package:shadowshift/ui/widgets/design.dart';
import 'package:flame/game.dart';

class GameplayScreen extends ConsumerStatefulWidget {
  const GameplayScreen({super.key, required this.launch});

  final GameLaunch launch;

  @override
  ConsumerState<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends ConsumerState<GameplayScreen>
    with WidgetsBindingObserver {
  late GameEngine engine;
  late ShadowShiftGame game;
  late VisualOptions options;
  final ValueNotifier<int> _hudTick = ValueNotifier<int>(0);
  String _hudSignature = '';
  Timer? _countdownTimer;
  int _countdown = 3;
  bool _counting = true;
  bool _paused = false;
  bool _finished = false;
  bool _created = false;
  bool _backgroundSuspended = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_created) return;
    _created = true;
    final settings = ref.read(settingsProvider);
    final profile = ref.read(profileProvider);
    final size = MediaQuery.of(context).size;
    // A zero/invalid viewport must never poison the simulation with NaN.
    final width = size.width.isFinite && size.width > 0 ? size.width : 1.0;
    final height = size.height.isFinite && size.height > 0 ? size.height : 1.0;
    final worldHeight = clampDouble(1000 * (height / width), 700, 1600);
    // Only an unlocked runner may contribute perks or visuals to a run.
    final character = profile.unlockedCharacters.contains(profile.character)
        ? Catalog.find(Catalog.characters, profile.character)
        : Catalog.characters.first;
    // Normalise every cosmetic/core through the catalogue so a legacy or
    // corrupted save can never reach the engine with an unknown ID.
    final skinId = Catalog.find(Catalog.skins, profile.skin).id;
    final effectId = Catalog.find(Catalog.effects, profile.effect).id;
    final abilityId = Catalog.find(Catalog.abilities, profile.ability).id;
    final companionId = Catalog.find(Catalog.companions, profile.companion).id;
    options = VisualOptions(
      reducedMotion: settings.reducedMotion,
      screenShake: settings.screenShake,
      effectId: effectId,
      skinId: skinId,
      characterId: character.id,
      characterColor: character.color,
      companionId: companionId,
    );
    engine = GameEngine(
      mode: widget.launch.mode,
      seed: widget.launch.seed,
      worldHeight: worldHeight,
      objective: widget.launch.objective,
      loadout: Catalog.loadout(
        characterId: character.id,
        abilityId: abilityId,
        companionId: companionId,
      ),
    );
    engine.paused = true;
    game = ShadowShiftGame(
      engine: engine,
      options: options,
      challengeId: widget.launch.challengeId,
      onEvent: _onEvent,
      onFinish: _finishRun,
      onHudTick: _publishHud,
    );
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(milliseconds: 680), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _countdown--);
      if (_countdown < 0) {
        timer.cancel();
        // Do not resume while the app is backgrounded; the lifecycle handler
        // resumes the engine when the player returns.
        if (!_backgroundSuspended) engine.paused = false;
        setState(() => _counting = false);
      }
    });
  }

  void _onEvent(GameEvent event) {
    AudioService.instance.playEvent(event);
    final settings = ref.read(settingsProvider);
    if (!settings.haptics) return;
    if (event == GameEvent.switchDimension ||
        event == GameEvent.collectPowerUp ||
        event == GameEvent.shieldBreak ||
        event == GameEvent.gameOver) {
      haptic();
    }
  }

  /// The game ticks the HUD at 12.5Hz; only rebuild when something visible
  /// actually changed (score usually does, focus/effects often don't).
  void _publishHud() {
    final signature = _HudSignature.compute(engine, widget.launch);
    if (signature == _hudSignature) return;
    _hudSignature = signature;
    _hudTick.value++;
  }

  void _finishRun(RunResult runResult) {
    if (_finished || !mounted) return;
    _finished = true;
    final summary = ref.read(profileProvider.notifier).applyRun(runResult);
    if (summary.newAchievements.isNotEmpty || summary.challengeCompleted != null) {
      AudioService.instance.achievement();
    }
    resetAndPush(
      context,
      GameOverScreen(result: runResult, summary: summary, launch: widget.launch),
    );
  }

  void _togglePause({bool? force}) {
    if (_finished || _counting) return;
    final next = force ?? !_paused;
    if (next == _paused) return;
    setState(() => _paused = next);
    engine.paused = next;
    AudioService.instance.setMusicActive(!next);
    if (next) {
      game.pauseEngine();
    } else {
      game.resumeEngine();
    }
  }

  void _restart() {
    if (_finished) return;
    _finished = true;
    final launch = LaunchService.create(
      widget.launch.mode,
      challengeId: widget.launch.challengeId,
    );
    replaceScreen(context, GameplayScreen(launch: launch));
  }

  void _quit() {
    if (_finished) return;
    _finished = true;
    // Abandoned runs award nothing: quitting must never be a coin farm.
    AudioService.instance.setMusicActive(true);
    resetToScreen(context, const MainMenu());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      if (_finished) return;
      _backgroundSuspended = true;
      AudioService.instance.setMusicActive(false);
      if (!_counting && !_paused) _togglePause(force: true);
      return;
    }
    if (state != AppLifecycleState.resumed || _finished) return;
    _backgroundSuspended = false;
    AudioService.instance.setMusicActive(!_paused);
    // A countdown that expired in the background left the engine paused.
    if (!_counting && !_paused && engine.paused) {
      engine.paused = false;
      game.resumeEngine();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AudioService.instance.setMusicActive(true);
    _countdownTimer?.cancel();
    _hudTick.dispose();
    game.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showHints = ref.watch(settingsProvider.select((s) => s.showHints));
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          GameWidget(game: game),
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => engine.switchDimension(),
              onVerticalDragEnd: (_) => engine.switchDimension(),
              onLongPressStart: (_) => engine.setFocus(true),
              onLongPressEnd: (_) => engine.setFocus(false),
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: ValueListenableBuilder<int>(
                valueListenable: _hudTick,
                builder: (context, _, _) => _Hud(
                  engine: engine,
                  launch: widget.launch,
                  onPause: () => _togglePause(),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: IgnorePointer(
                child: ValueListenableBuilder<int>(
                  valueListenable: _hudTick,
                  builder: (context, _, _) =>
                      _BottomHud(engine: engine, showHint: showHints),
                ),
              ),
            ),
          ),
          if (_counting)
            _CountdownOverlay(count: _countdown, showHint: showHints),
          if (_paused && !_finished)
            _PauseOverlay(
              onResume: () => _togglePause(force: false),
              onRestart: _restart,
              onQuit: _quit,
            ),
        ],
      ),
    );
  }
}

/// Compact representation of everything the two HUD widgets display.
class _HudSignature {
  static String compute(GameEngine engine, GameLaunch launch) {
    final buffer = StringBuffer()
      ..write(formatScore(engine.score))
      ..write(':')
      ..write(engine.multiplier)
      ..write(':')
      ..write(engine.combo > 0)
      ..write(':')
      ..write(launch.mode == GameMode.timeAttack
          ? (60 - engine.elapsed).clamp(0, 60).toInt()
          : -1)
      ..write(':')
      ..write(launch.objective.kind == ObjectiveKind.none
          ? ''
          : launch.objective.progressText(
              engine.elapsed,
              engine.orbs,
              engine.combo,
              engine.score,
              engine.switches,
            ))
      ..write(':')
      ..write(engine.dimension.index)
      ..write(':')
      ..write(engine.loadout.focusAvailable)
      ..write(':')
      // Round to screen pixels-worth of progress: 2% steps preserve the bar's
      // visible motion without rebuilding on every sub-percent change.
      ..write((engine.focusEnergy * 50).round())
      ..write(':');
    for (final entry in engine.effects.entries) {
      buffer
        ..write(entry.key.index)
        ..write('=')
        ..write(entry.value.ceil())
        ..write(',');
    }
    return buffer.toString();
  }
}

class _Hud extends StatelessWidget {
  const _Hud({
    required this.engine,
    required this.launch,
    required this.onPause,
  });

  final GameEngine engine;
  final GameLaunch launch;
  final VoidCallback onPause;

  static const _scoreStyle = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w900,
    letterSpacing: 1,
    shadows: [Shadow(color: AppColors.cyan, blurRadius: 14)],
  );
  static const _comboActiveStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.2,
    color: AppColors.violet,
  );
  static const _comboIdleStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.2,
    color: AppColors.muted,
  );
  static const _timerStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w800,
    color: AppColors.pink,
  );
  static const _objectiveStyle = TextStyle(fontSize: 11, color: AppColors.cyan);
  static final ButtonStyle _pauseStyle = IconButton.styleFrom(
    backgroundColor: AppColors.surfaceLight.withValues(alpha: 0.75),
    side: BorderSide(color: AppColors.cyan.withValues(alpha: 0.25)),
  );

  @override
  Widget build(BuildContext context) {
    final timeLeft = launch.mode == GameMode.timeAttack
        ? (60 - engine.elapsed).clamp(0, 60).toInt()
        : null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(formatScore(engine.score), style: _scoreStyle),
                Row(
                  children: [
                    Text(
                      'x${engine.multiplier} COMBO',
                      style: engine.combo > 0 ? _comboActiveStyle : _comboIdleStyle,
                    ),
                    if (timeLeft != null) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.timer, size: 13, color: AppColors.pink),
                      const SizedBox(width: 4),
                      Text('${timeLeft}s', style: _timerStyle),
                    ],
                  ],
                ),
                if (launch.objective.kind != ObjectiveKind.none)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      launch.objective.progressText(
                        engine.elapsed,
                        engine.orbs,
                        engine.combo,
                        engine.score,
                        engine.switches,
                      ),
                      style: _objectiveStyle,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: onPause,
            icon: const Icon(Icons.pause_rounded),
            style: _pauseStyle,
          ),
        ],
      ),
    );
  }
}

class _BottomHud extends StatelessWidget {
  const _BottomHud({required this.engine, required this.showHint});

  final GameEngine engine;
  final bool showHint;

  static final BoxDecoration _effectLightDecoration = BoxDecoration(
    color: AppColors.surfaceLight.withValues(alpha: 0.8),
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: AppColors.cyan.withValues(alpha: 0.35)),
  );
  static final BoxDecoration _effectShadowDecoration = BoxDecoration(
    color: AppColors.surfaceLight.withValues(alpha: 0.8),
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: AppColors.violet.withValues(alpha: 0.35)),
  );
  static const TextStyle _effectLightStyle = TextStyle(
    fontSize: 10,
    color: AppColors.cyan,
    fontWeight: FontWeight.w700,
  );
  static const TextStyle _effectShadowStyle = TextStyle(
    fontSize: 10,
    color: AppColors.violet,
    fontWeight: FontWeight.w700,
  );
  static final BoxDecoration _barLightDecoration = BoxDecoration(
    color: AppColors.surface.withValues(alpha: 0.72),
    borderRadius: BorderRadius.circular(30),
    border: Border.all(color: AppColors.cyan.withValues(alpha: 0.4)),
  );
  static final BoxDecoration _barShadowDecoration = BoxDecoration(
    color: AppColors.surface.withValues(alpha: 0.72),
    borderRadius: BorderRadius.circular(30),
    border: Border.all(color: AppColors.violet.withValues(alpha: 0.4)),
  );
  static const TextStyle _lightActiveStyle = TextStyle(
    fontSize: 12,
    letterSpacing: 1.4,
    fontWeight: FontWeight.w800,
    color: AppColors.cyan,
  );
  static const TextStyle _shadowActiveStyle = TextStyle(
    fontSize: 12,
    letterSpacing: 1.4,
    fontWeight: FontWeight.w800,
    color: AppColors.violet,
  );
  static const TextStyle _mutedStyle = TextStyle(
    fontSize: 12,
    letterSpacing: 1.4,
    fontWeight: FontWeight.w800,
    color: AppColors.muted,
  );

  @override
  Widget build(BuildContext context) {
    final isLight = engine.dimension.isLight;
    final activeColor = isLight ? AppColors.cyan : AppColors.violet;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: [
          if (engine.effects.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                children: engine.effects.entries
                    .map(
                      (entry) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: isLight
                            ? _effectLightDecoration
                            : _effectShadowDecoration,
                        child: Text(
                          '${PowerUpCatalog.shortLabel(entry.key)} ${entry.value.ceil()}s',
                          style: isLight ? _effectLightStyle : _effectShadowStyle,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
            decoration:
                isLight ? _barLightDecoration : _barShadowDecoration,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('LIGHT',
                    style: isLight ? _lightActiveStyle : _mutedStyle),
                const SizedBox(width: 10),
                Icon(Icons.swap_horiz, size: 17, color: activeColor),
                const SizedBox(width: 10),
                Text('SHADOW',
                    style: isLight ? _mutedStyle : _shadowActiveStyle),
              ],
            ),
          ),
          if (engine.loadout.focusAvailable) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: 150,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  value: engine.focusEnergy / GameConfig.maxFocusEnergy,
                  minHeight: 5,
                  backgroundColor: AppColors.surfaceLight,
                  valueColor: const AlwaysStoppedAnimation(AppColors.gold),
                ),
              ),
            ),
            if (showHint)
              const Text('HOLD TO FOCUS',
                  style: TextStyle(fontSize: 9, letterSpacing: 1.2, color: AppColors.muted)),
          ],
        ],
      ),
    );
  }
}

class _CountdownOverlay extends StatelessWidget {
  const _CountdownOverlay({required this.count, required this.showHint});

  final int count;
  final bool showHint;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background.withValues(alpha: 0.55),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              count < 0 ? 'GO!' : '$count',
              style: const TextStyle(
                fontSize: 96,
                fontWeight: FontWeight.w900,
                color: AppColors.cyan,
                shadows: [Shadow(color: AppColors.violet, blurRadius: 30)],
              ),
            ),
            if (showHint)
              const Text('TAP OR SWIPE TO PHASE',
                  style: TextStyle(
                      fontSize: 12, letterSpacing: 2.2, color: AppColors.text)),
          ],
        ),
      ),
    );
  }
}

class _PauseOverlay extends StatelessWidget {
  const _PauseOverlay({
    required this.onResume,
    required this.onRestart,
    required this.onQuit,
  });

  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background.withValues(alpha: 0.88),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: GlassCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('PAUSED',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4)),
                  const SizedBox(height: 6),
                  const Text('Take a breath. The void can wait.',
                      style: TextStyle(fontSize: 12, color: AppColors.muted)),
                  const SizedBox(height: 24),
                  NeonButton(label: 'RESUME', icon: Icons.play_arrow, onPressed: onResume),
                  const SizedBox(height: 10),
                  NeonButton(
                      label: 'RESTART RUN',
                      icon: Icons.restart_alt,
                      secondary: true,
                      onPressed: onRestart),
                  const SizedBox(height: 10),
                  NeonButton(
                      label: 'QUIT TO MENU',
                      icon: Icons.exit_to_app,
                      secondary: true,
                      color: AppColors.danger,
                      onPressed: onQuit),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
