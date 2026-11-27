import 'package:shadowshift/core/utils.dart';

class AppSettings {
  const AppSettings({
    this.musicVolume = 0.5,
    this.sfxVolume = 0.7,
    this.haptics = true,
    this.reducedMotion = false,
    this.screenShake = true,
    this.showHints = true,
  });

  final double musicVolume;
  final double sfxVolume;
  final bool haptics;
  final bool reducedMotion;
  final bool screenShake;
  final bool showHints;

  AppSettings copyWith({
    double? musicVolume,
    double? sfxVolume,
    bool? haptics,
    bool? reducedMotion,
    bool? screenShake,
    bool? showHints,
  }) {
    return AppSettings(
      musicVolume: musicVolume ?? this.musicVolume,
      sfxVolume: sfxVolume ?? this.sfxVolume,
      haptics: haptics ?? this.haptics,
      reducedMotion: reducedMotion ?? this.reducedMotion,
      screenShake: screenShake ?? this.screenShake,
      showHints: showHints ?? this.showHints,
    );
  }

  Map<String, dynamic> toJson() => {
        'musicVolume': musicVolume,
        'sfxVolume': sfxVolume,
        'haptics': haptics,
        'reducedMotion': reducedMotion,
        'screenShake': screenShake,
        'showHints': showHints,
      };

  factory AppSettings.fromJson(Object? raw) {
    if (raw is! Map) return const AppSettings();
    return AppSettings(
      musicVolume: safeDouble(raw['musicVolume'], 0.5),
      sfxVolume: safeDouble(raw['sfxVolume'], 0.7),
      haptics: raw['haptics'] != false,
      reducedMotion: raw['reducedMotion'] == true,
      screenShake: raw['screenShake'] != false,
      showHints: raw['showHints'] != false,
    );
  }
}
