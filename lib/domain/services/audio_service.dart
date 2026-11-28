import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shadowshift/data/models/app_settings.dart';
import 'package:shadowshift/domain/game/enums.dart';

/// Generates all sound assets locally as tiny PCM WAV files on first launch.
/// No network, bundles or large assets are required.
abstract final class WavSynth {
  /// Exact byte length of a generated clip. Lets the cache validate a file
  /// without synthesizing its samples first.
  static int byteLength(double seconds, {int sampleRate = 22050}) =>
      44 + (seconds * sampleRate).round() * 2;

  static Uint8List build(double seconds, double Function(double t, int i) sample,
      {int sampleRate = 22050}) {
    final count = (seconds * sampleRate).round();
    // One allocation for the header and PCM data instead of two buffers plus a
    // spread copy. Music is ~353KB, so this removes several MB of churn.
    final bytes = Uint8List(44 + count * 2);
    final view = ByteData.sublistView(bytes);
    for (var i = 0; i < count; i++) {
      final value = sample(i / sampleRate, i).clamp(-1.0, 1.0);
      view.setInt16(44 + 2 * i, (value * 32767).round(), Endian.little);
    }
    void put(int offset, String text) {
      for (var i = 0; i < text.length; i++) {
        view.setUint8(offset + i, text.codeUnitAt(i));
      }
    }

    put(0, 'RIFF');
    view.setUint32(4, 36 + count * 2, Endian.little);
    put(8, 'WAVE');
    put(12, 'fmt ');
    view.setUint32(16, 16, Endian.little);
    view.setUint16(20, 1, Endian.little);
    view.setUint16(22, 1, Endian.little);
    view.setUint32(24, sampleRate, Endian.little);
    view.setUint32(28, sampleRate * 2, Endian.little);
    view.setUint16(32, 2, Endian.little);
    view.setUint16(34, 16, Endian.little);
    put(36, 'data');
    view.setUint32(40, count * 2, Endian.little);
    return bytes;
  }

  static double Function(double t, int i) music() {
    const notes = [110.0, 164.81, 220.0, 246.94, 164.81, 220.0, 329.63, 246.94];
    final random = math.Random(1337);
    return (t, i) {
      final step = (t * 4).floor() % notes.length;
      final local = (t * 4) % 1;
      final freq = notes[step];
      final env = math.exp(-local * 2.6);
      final pad = math.sin(2 * math.pi * 55 * t) * 0.09;
      final lead = math.sin(2 * math.pi * freq * t) * 0.19 * env;
      final shimmer = math.sin(2 * math.pi * freq * 2 * t) * 0.05 * env;
      final kick = math.sin(2 * math.pi * 52 * (t % 0.5)) * math.exp(-(t % 0.5) * 18) * 0.24;
      final hat = (random.nextDouble() - 0.5) * math.exp(-((t * 8) % 1) * 30) * 0.05;
      return pad + lead + shimmer + kick + hat;
    };
  }

  static double tone(double t, double freq, double decay) =>
      math.sin(2 * math.pi * freq * t) * math.exp(-t * decay);

  /// Duration used for both synthesis and cache validation.
  static double sfxSeconds(String name) => switch (name) {
        'switch' => 0.2,
        'collect' => 0.14,
        'power' => 0.4,
        'crash' => 0.48,
        'shield' => 0.3,
        'ui' => 0.07,
        'achievement' => 0.7,
        'rank_up' => 1.15,
        _ => 0.05,
      };

  static Uint8List sfx(String name) {
    final random = math.Random(name.hashCode);
    return switch (name) {
      'switch' => build(sfxSeconds(name), (t, i) {
          final freq = 340 + 900 * (t / 0.2);
          return math.sin(2 * math.pi * freq * t) * math.exp(-t * 13) * 0.5;
        }),
      'collect' => build(sfxSeconds(name), (t, i) {
          return (tone(t, 880, 22) + tone(t, 1320, 18) * 0.5) * 0.34;
        }),
      'power' => build(sfxSeconds(name), (t, i) {
          return (tone(t, 440, 7) + tone(t, 660, 7) + tone(t, 880, 7)) * 0.19;
        }),
      'crash' => build(sfxSeconds(name), (t, i) {
          final noise = random.nextDouble() * 2 - 1;
          return (noise * math.exp(-t * 8) * 0.4 + tone(t, 90, 6) * 0.4);
        }),
      'shield' => build(sfxSeconds(name), (t, i) {
          return tone(t, 210 - 90 * (t / 0.3), 9) * 0.45 + tone(t, 620, 20) * 0.15;
        }),
      'ui' => build(sfxSeconds(name), (t, i) => tone(t, 720, 45) * 0.22),
      'achievement' => build(sfxSeconds(name), (t, i) {
          final notes = [523.25, 659.25, 783.99, 1046.5];
          final step = (t / 0.175).floor().clamp(0, 3);
          return tone(t - step * 0.175, notes[step], 7) * 0.24;
        }),
      'rank_up' => build(sfxSeconds(name), (t, i) {
          final notes = [392.0, 523.25, 659.25, 783.99, 1046.5];
          final step = (t / 0.19).floor().clamp(0, 4);
          final local = t - step * 0.19;
          return tone(local, notes[step], 8) * 0.26 +
              tone(local, notes[step] * 2, 14) * 0.08;
        }),
      _ => build(sfxSeconds(name), (t, i) => 0.0),
    };
  }
}

/// Offline audio manager. All players are created lazily and dispose cleanly.
class AudioService {
  AudioService._();

  static final AudioService instance = AudioService._();

  bool _initialized = false;
  bool _initializing = false;
  bool _musicActive = true;
  bool _musicPlaying = false;
  double _appliedMusicVolume = -1;
  double _appliedSfxVolume = -1;
  Directory? _directory;
  AudioPlayer? _musicPlayer;
  final List<AudioPlayer> _sfxPlayers = <AudioPlayer>[];
  final Map<String, Source> _sources = <String, Source>{};
  int _nextPlayer = 0;
  AppSettings _settings = const AppSettings();

  Future<void> init(AppSettings settings) async {
    _settings = settings;
    if (_initialized || _initializing) return;
    _initializing = true;
    try {
      final docs = await getApplicationDocumentsDirectory();
      _directory = Directory('${docs.path}/shadowshift_audio');
      await _directory!.create(recursive: true);
      // Generators stay lazy: valid cached files skip all WAV synthesis.
      await _write(
        'music.wav',
        WavSynth.byteLength(8),
        () => WavSynth.build(8, WavSynth.music()),
      );
      for (final name in [
        'switch',
        'collect',
        'power',
        'crash',
        'shield',
        'ui',
        'achievement',
        'rank_up',
      ]) {
        await _write(
          '$name.wav',
          WavSynth.byteLength(WavSynth.sfxSeconds(name)),
          () => WavSynth.sfx(name),
        );
      }
      _musicPlayer = AudioPlayer(playerId: 'shadowshift-music');
      await _musicPlayer!.setVolume(_settings.musicVolume);
      _appliedMusicVolume = _settings.musicVolume;
      await _musicPlayer!.setReleaseMode(ReleaseMode.loop);
      for (var i = 0; i < 4; i++) {
        final player = AudioPlayer(playerId: 'shadowshift-sfx-$i');
        await player.setVolume(_settings.sfxVolume);
        _sfxPlayers.add(player);
      }
      _appliedSfxVolume = _settings.sfxVolume;
      _initialized = true;
      await _applyMusicState();
    } catch (_) {
      // Audio is enhancement only: the game stays fully playable without it.
      _initialized = false;
      _musicPlaying = false;
    } finally {
      _initializing = false;
    }
  }

  Future<void> _write(
    String name,
    int expectedLength,
    Uint8List Function() generate,
  ) async {
    final file = File('${_directory!.path}/$name');
    try {
      if (await file.length() == expectedLength) return;
    } on FileSystemException {
      // Missing file: synthesize below.
    }
    await file.writeAsBytes(generate());
  }

  Future<Source> _source(String name) async {
    final cached = _sources[name];
    if (cached != null) return cached;
    final source = DeviceFileSource('${_directory!.path}/$name.wav');
    _sources[name] = source;
    return source;
  }

  Future<void> _applyMusicState() async {
    if (!_initialized) return;
    final player = _musicPlayer;
    if (player == null) return;
    if (!_musicActive || _settings.musicVolume <= 0) {
      await player.stop();
      _musicPlaying = false;
      return;
    }
    if (_musicPlaying) {
      await player.resume();
    } else {
      // Load the source on demand so raising volume from zero actually starts
      // music instead of resuming an uninitialised player.
      await player.play(await _source('music'));
      _musicPlaying = true;
    }
  }

  Future<void> updateSettings(AppSettings settings) async {
    final previousMusicVolume = _settings.musicVolume;
    _settings = settings;
    if (!_initialized) return;
    try {
      if (settings.musicVolume != _appliedMusicVolume) {
        await _musicPlayer?.setVolume(settings.musicVolume);
        _appliedMusicVolume = settings.musicVolume;
      }
      if (settings.sfxVolume != _appliedSfxVolume) {
        for (final player in _sfxPlayers) {
          await player.setVolume(settings.sfxVolume);
        }
        _appliedSfxVolume = settings.sfxVolume;
      }
      // Only playback state needs changing when music crosses silence.
      if ((previousMusicVolume <= 0) != (settings.musicVolume <= 0)) {
        await _applyMusicState();
      }
    } catch (_) {
      // Volume changes must never surface errors to the UI.
    }
  }

  Future<void> playSfx(String name) async {
    if (!_initialized || _settings.sfxVolume <= 0 || _sfxPlayers.isEmpty) return;
    final player = _sfxPlayers[_nextPlayer % _sfxPlayers.length];
    _nextPlayer++;
    try {
      await player.play(await _source(name));
    } catch (_) {
      // Ignore playback failures; never interrupt gameplay.
    }
  }

  Future<void> playEvent(GameEvent event) async {
    switch (event) {
      case GameEvent.switchDimension:
        return playSfx('switch');
      case GameEvent.collectOrb:
        return playSfx('collect');
      case GameEvent.collectPowerUp:
        return playSfx('power');
      case GameEvent.shieldBreak:
        return playSfx('shield');
      case GameEvent.gameOver:
        return playSfx('crash');
      case GameEvent.objectiveComplete:
        return playSfx('achievement');
      case GameEvent.dodge:
        return;
    }
  }

  Future<void> achievement() => playSfx('achievement');
  Future<void> rankUp() => playSfx('rank_up');
  Future<void> ui() => playSfx('ui');

  Future<void> setMusicActive(bool active) async {
    _musicActive = active;
    try {
      await _applyMusicState();
    } catch (_) {
      // Audio is optional; gameplay continues silently if playback fails.
    }
  }

  Future<void> dispose() async {
    await _musicPlayer?.dispose();
    for (final player in _sfxPlayers) {
      await player.dispose();
    }
    _sfxPlayers.clear();
    _musicPlayer = null;
    _initialized = false;
    _musicPlaying = false;
    _musicActive = true;
    _appliedMusicVolume = -1;
    _appliedSfxVolume = -1;
  }
}

Future<void> haptic() async {
  try {
    await HapticFeedback.vibrate();
  } catch (_) {
    // Unsupported devices simply skip feedback.
  }
}
