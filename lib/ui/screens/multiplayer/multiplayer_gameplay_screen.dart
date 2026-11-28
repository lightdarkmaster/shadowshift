import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadowshift/core/constants.dart';
import 'package:shadowshift/core/utils.dart';
import 'package:shadowshift/domain/game/engine.dart';
import 'package:shadowshift/domain/game/entities.dart';
import 'package:shadowshift/domain/game/enums.dart';
import 'package:shadowshift/domain/multiplayer/multiplayer_models.dart';
import 'package:shadowshift/domain/services/audio_service.dart';
import 'package:shadowshift/game/shadow_painter.dart';
import 'package:shadowshift/game/shadow_shift_game.dart';
import 'package:shadowshift/state/app_providers.dart';
import 'package:shadowshift/ui/navigation.dart';
import 'package:shadowshift/ui/screens/multiplayer/multiplayer_home_screen.dart';
import 'package:shadowshift/ui/screens/multiplayer/multiplayer_results_screen.dart';
import 'package:shadowshift/ui/screens/multiplayer/multiplayer_transition_screen.dart';
import 'package:shadowshift/ui/widgets/design.dart';
import 'package:flame/game.dart';

enum _TurnPhase { transition, playing, turnResult }

/// Runs one offline hot-seat match. It constructs a brand-new [GameEngine]
/// for every turn, so no player can inherit another player's obstacles, timer,
/// effects or score. It deliberately never calls the single-player settlement.
class MultiplayerGameplayScreen extends ConsumerStatefulWidget {
  const MultiplayerGameplayScreen({super.key, required this.match});

  final MultiplayerMatchRecord match;

  @override
  ConsumerState<MultiplayerGameplayScreen> createState() =>
      _MultiplayerGameplayScreenState();
}

class _MultiplayerGameplayScreenState extends ConsumerState<MultiplayerGameplayScreen>
    with WidgetsBindingObserver {
  late MultiplayerMatchRecord _record;
  _TurnPhase _phase = _TurnPhase.transition;
  GameEngine? _engine;
  ShadowShiftGame? _game;
  final ValueNotifier<int> _hudTick = ValueNotifier<int>(0);
  Timer? _countdownTimer;
  int _countdown = 3;
  bool _counting = false;
  bool _paused = false;
  bool _finished = false;
  bool _backgroundSuspended = false;
  int? _lastTurnScore;

  MultiplayerSession get _session => MultiplayerSession.fromRecord(_record);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // If a match was interrupted, continue from the last persisted turn.
    final active = ref.read(multiplayerProfileProvider).activeMatch;
    _record = active != null && active.id == widget.match.id ? active : widget.match;
  }

  void _startTurn() {
    if (_finished || _session.isComplete) return;
    _disposeGame();
    final settings = ref.read(settingsProvider);
    final size = MediaQuery.of(context).size;
    final width = size.width.isFinite && size.width > 0 ? size.width : 1.0;
    final height = size.height.isFinite && size.height > 0 ? size.height : 1.0;
    final worldHeight = clampDouble(1000 * (height / width), 700, 1600);
    final round = _session.currentRound;
    final playerIndex = _session.currentPlayerIndex;

    final engine = GameEngine(
      mode: GameMode.classic,
      seed: hashString('${_record.id}-$round-$playerIndex'),
      worldHeight: worldHeight,
      objective: const RunObjective(kind: ObjectiveKind.none, target: 0),
      // Multiplayer is a level playing field: no single-player unlock perks.
      loadout: const RunLoadout(),
    );
    engine.paused = true;
    final game = ShadowShiftGame(
      engine: engine,
      options: VisualOptions(
        reducedMotion: settings.reducedMotion,
        screenShake: settings.screenShake,
      ),
      onEvent: _onEvent,
      onFinish: _finishTurn,
      onHudTick: _publishHud,
      challengeId: null,
      // Empty runId keeps this result out of single-player reward dedupe.
      runId: '',
    );

    setState(() {
      _engine = engine;
      _game = game;
      _phase = _TurnPhase.playing;
      _paused = false;
      _lastTurnScore = null;
    });
    _startCountdown();
  }

  void _startCountdown({bool fromPause = false}) {
    _countdownTimer?.cancel();
    _countdown = 3;
    _counting = true;
    _paused = false;
    _engine?.paused = true;
    if (fromPause && !_backgroundSuspended) {
      AudioService.instance.setMusicActive(true);
    }
    if (mounted) setState(() {});
    _countdownTimer = Timer.periodic(const Duration(milliseconds: 680), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _countdown--);
      if (_countdown >= 0) return;
      timer.cancel();
      _counting = false;
      if (!_backgroundSuspended) {
        _engine?.paused = false;
        _game?.resumeEngine();
      }
      setState(() {});
    });
  }

  void _onEvent(GameEvent event) {
    AudioService.instance.playEvent(event);
    final settings = ref.read(settingsProvider);
    if (settings.haptics &&
        (event == GameEvent.switchDimension ||
            event == GameEvent.shieldBreak ||
            event == GameEvent.gameOver)) {
      haptic();
    }
  }

  void _publishHud() {
    if (mounted && !_counting) _hudTick.value++;
  }

  void _finishTurn(RunResult result) {
    if (_finished || _phase != _TurnPhase.playing || !mounted) return;
    _countdownTimer?.cancel();
    _counting = false;
    _engine?.paused = true;
    _game?.pauseEngine();

    final session = MultiplayerSession.fromRecord(_record);
    final scored = session.recordScore(result.score);
    // Persist immediately: an app kill after this point cannot lose the turn
    // or replay it twice when the player returns.
    ref.read(multiplayerProfileProvider.notifier).recordTurn(_record, result.score);
    setState(() {
      _record = scored.record;
      _lastTurnScore = result.score;
      _phase = _TurnPhase.turnResult;
    });
  }

  void _continueAfterTurn() {
    if (_finished) return;
    if (_session.isComplete) {
      _finishMatch();
      return;
    }
    _disposeGame();
    setState(() => _phase = _TurnPhase.transition);
  }

  void _finishMatch() {
    if (_finished) return;
    _finished = true;
    _countdownTimer?.cancel();
    _disposeGame();
    // This is the ONLY reward path for multiplayer, and it writes solely to
    // the independent multiplayer profile/history.
    final updated = ref.read(multiplayerProfileProvider.notifier).completeMatch(_record);
    // Show the committed record so reward totals and completed status match
    // what was actually persisted in history.
    MultiplayerMatchRecord completed = _record;
    for (final match in updated.history) {
      if (match.id == _record.id) {
        completed = match;
        break;
      }
    }
    if (!mounted) return;
    AudioService.instance.achievement();
    pushScreen(context, MultiplayerResultsScreen(match: completed));
  }

  void _togglePause({bool? force}) {
    if (_finished || _phase != _TurnPhase.playing || _counting) return;
    final next = force ?? !_paused;
    if (next == _paused) return;
    if (next) {
      setState(() => _paused = true);
      _engine?.paused = true;
      AudioService.instance.setMusicActive(false);
      _game?.pauseEngine();
      return;
    }
    _startCountdown(fromPause: true);
  }

  void _quit() {
    if (_finished) return;
    _finished = true;
    _countdownTimer?.cancel();
    _disposeGame();
    AudioService.instance.setMusicActive(true);
    resetToScreen(context, const MultiplayerHomeScreen());
  }

  void _disposeGame() {
    _countdownTimer?.cancel();
    _game?.dispose();
    _game = null;
    _engine = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      if (_finished || _phase != _TurnPhase.playing) return;
      _backgroundSuspended = true;
      AudioService.instance.setMusicActive(false);
      if (!_counting && !_paused) _togglePause(force: true);
      return;
    }
    if (state != AppLifecycleState.resumed || _finished) return;
    _backgroundSuspended = false;
    AudioService.instance.setMusicActive(!_paused);
    if (_phase != _TurnPhase.playing) return;
    // A countdown that expired while away starts again so every player sees
    // the full 3-2-1-GO before danger resumes.
    if (_counting || _paused) {
      _startCountdown(fromPause: true);
      return;
    }
    if (_engine?.paused ?? false) {
      _engine?.paused = false;
      _game?.resumeEngine();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeGame();
    AudioService.instance.setMusicActive(true);
    _hudTick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    if (_phase == _TurnPhase.transition) {
      return MultiplayerTransitionScreen(
        playerName: session.currentPlayer,
        round: session.currentRound,
        totalRounds: _record.rounds,
        onStart: _startTurn,
      );
    }
    if (_phase == _TurnPhase.turnResult) {
      return _TurnResultScreen(
        playerName: _record.players[
            (session.currentPlayerIndex - 1).clamp(0, _record.players.length - 1)],
        score: _lastTurnScore ?? 0,
        round: (session.currentRound - 1).clamp(1, _record.rounds),
        totalRounds: _record.rounds,
        isMatchComplete: session.isComplete,
        onContinue: _continueAfterTurn,
      );
    }

    final reducedMotion = ref.watch(settingsProvider.select((s) => s.reducedMotion));
    final showHints = ref.watch(settingsProvider.select((s) => s.showHints));
    final game = _game;
    if (game == null) {
      return const Scaffold(body: SizedBox.shrink());
    }
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          GameWidget(game: game),
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _engine?.switchDimension(),
              onVerticalDragEnd: (_) => _engine?.switchDimension(),
              onLongPressStart: (_) => _engine?.setFocus(true),
              onLongPressEnd: (_) => _engine?.setFocus(false),
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
                builder: (context, _, _) => _MultiplayerHud(
                  playerName: session.currentPlayer,
                  round: session.currentRound,
                  totalRounds: _record.rounds,
                  score: _engine?.score ?? 0,
                  completed: session.completedPlayers,
                  remaining: session.remainingPlayers,
                  onPause: () => _togglePause(),
                ),
              ),
            ),
          ),
          if (_counting)
            _CountdownOverlay(count: _countdown, showHint: showHints),
          if (_paused && !_finished)
            _PauseOverlay(
              onResume: () => _togglePause(force: false),
              onQuit: _quit,
            ),
          if (reducedMotion) const SizedBox.shrink(),
        ],
      ),
    );
  }
}

class _MultiplayerHud extends StatelessWidget {
  const _MultiplayerHud({
    required this.playerName,
    required this.round,
    required this.totalRounds,
    required this.score,
    required this.completed,
    required this.remaining,
    required this.onPause,
  });

  final String playerName;
  final int round;
  final int totalRounds;
  final int score;
  final List<String> completed;
  final List<String> remaining;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: GlassCard(
        padding: const EdgeInsets.all(AppLayout.sm + 2),
        borderColor: AppColors.violet.withValues(alpha: 0.42),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.groups, size: 16, color: AppColors.violet),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    playerName.toUpperCase(),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                      color: AppColors.text,
                    ),
                  ),
                ),
                Text(
                  'R$round/$totalRounds',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.cyan,
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: onPause,
                  icon: const Icon(Icons.pause_rounded, size: 18),
                  constraints: const BoxConstraints.tightFor(width: 28, height: 28),
                  padding: EdgeInsets.zero,
                  color: AppColors.muted,
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    formatScore(score),
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                      shadows: [Shadow(color: AppColors.cyan, blurRadius: 14)],
                    ),
                  ),
                ),
                Text(
                  'LOCAL MATCH',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: AppColors.muted.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: [
                for (final name in completed)
                  _PlayerChip(name: name, done: true),
                for (final name in remaining)
                  _PlayerChip(name: name, done: false),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerChip extends StatelessWidget {
  const _PlayerChip({required this.name, required this.done});

  final String name;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: (done ? AppColors.cyan : AppColors.violet).withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            done ? Icons.check_circle : Icons.schedule,
            size: 10,
            color: done ? AppColors.cyan : AppColors.violet,
          ),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 90),
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: done ? AppColors.cyan : AppColors.muted,
              ),
            ),
          ),
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
                fontSize: 88,
                fontWeight: FontWeight.w900,
                color: AppColors.cyan,
                shadows: [Shadow(color: AppColors.violet, blurRadius: 30)],
              ),
            ),
            if (showHint)
              const Text(
                'TAP OR SWIPE TO PHASE',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 2,
                  color: AppColors.text,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PauseOverlay extends StatelessWidget {
  const _PauseOverlay({required this.onResume, required this.onQuit});

  final VoidCallback onResume;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background.withValues(alpha: 0.9),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: GlassCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'TURN PAUSED',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'The match stays exactly where you left it.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                  const SizedBox(height: 22),
                  NeonButton(label: 'RESUME TURN', icon: Icons.play_arrow, onPressed: onResume),
                  const SizedBox(height: 10),
                  NeonButton(
                    label: 'END MATCH',
                    icon: Icons.exit_to_app,
                    secondary: true,
                    color: AppColors.danger,
                    onPressed: onQuit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TurnResultScreen extends StatelessWidget {
  const _TurnResultScreen({
    required this.playerName,
    required this.score,
    required this.round,
    required this.totalRounds,
    required this.isMatchComplete,
    required this.onContinue,
  });

  final String playerName;
  final int score;
  final int round;
  final int totalRounds;
  final bool isMatchComplete;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppLayout.pagePadding,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppLayout.maxContentWidth),
              child: GlassCard(
                borderColor: AppColors.cyan.withValues(alpha: 0.42),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt, size: 46, color: AppColors.cyan),
                    const SizedBox(height: 10),
                    const Text(
                      'SIGNAL LOST',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                        color: AppColors.pink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$playerName · Round $round of $totalRounds',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      formatScore(score),
                      style: const TextStyle(
                        fontSize: 54,
                        fontWeight: FontWeight.w900,
                        color: AppColors.text,
                        shadows: [Shadow(color: AppColors.violet, blurRadius: 24)],
                      ),
                    ),
                    const Text(
                      'POINTS THIS TURN',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.8,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 24),
                    NeonButton(
                      label: isMatchComplete ? 'SEE RESULTS' : 'NEXT PLAYER',
                      icon: isMatchComplete ? Icons.emoji_events : Icons.arrow_forward,
                      onPressed: onContinue,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
