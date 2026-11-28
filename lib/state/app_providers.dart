import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadowshift/core/utils.dart';
import 'package:shadowshift/data/models/app_settings.dart';
import 'package:shadowshift/data/models/profile.dart';
import 'package:shadowshift/data/repositories/storage_repository.dart';
import 'package:shadowshift/domain/game/entities.dart';
import 'package:shadowshift/domain/services/audio_service.dart';
import 'package:shadowshift/domain/services/progression_service.dart';

final storageProvider = Provider<StorageRepository>((ref) {
  throw UnimplementedError('StorageRepository must be overridden at startup.');
});

final profileProvider = NotifierProvider<ProfileNotifier, PlayerProfile>(
  ProfileNotifier.new,
);

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

class ProfileNotifier extends Notifier<PlayerProfile> {
  @override
  PlayerProfile build() {
    final profile = ref.read(storageProvider).loadProfile();
    final today = DateTime.now();
    final key = dateKey(today);
    if (profile.daily.date == key) return profile;
    return profile.copy()..daily = profile.daily.copyWithDate(key);
  }

  void _commit(PlayerProfile profile) {
    state = profile;
    ref.read(storageProvider).saveProfile(profile);
  }

  RewardSummary applyRun(RunResult result) {
    final summary = ProgressionService.applyRun(state, result);
    _commit(summary.profile);
    return summary;
  }

  bool purchase(String itemId, int price, String category) {
    final next = ProgressionService.purchase(state, itemId, price, category);
    if (next == null) return false;
    _commit(next);
    return true;
  }

  /// Buys and equips in one commit, avoiding a second copy/JSON write.
  bool purchaseAndSelect(String itemId, int price, String category) {
    final next = ProgressionService.purchase(state, itemId, price, category);
    if (next == null) return false;
    switch (category) {
      case 'character':
        next.character = itemId;
      case 'skin':
        next.skin = itemId;
      case 'effect':
        next.effect = itemId;
      case 'ability':
        next.ability = itemId;
      case 'companion':
        next.companion = itemId;
    }
    _commit(next);
    return true;
  }

  void selectCharacter(String id) {
    if (!state.unlockedCharacters.contains(id)) return;
    _commit(state.copy()..character = id);
  }

  void selectSkin(String id) {
    if (!state.unlockedSkins.contains(id)) return;
    _commit(state.copy()..skin = id);
  }

  void selectEffect(String id) {
    if (!state.unlockedEffects.contains(id)) return;
    _commit(state.copy()..effect = id);
  }

  void selectAbility(String id) {
    if (!state.unlockedAbilities.contains(id)) return;
    _commit(state.copy()..ability = id);
  }

  void selectCompanion(String id) {
    if (!state.unlockedCompanions.contains(id)) return;
    _commit(state.copy()..companion = id);
  }

  int claimMission(String id, int coins, int xp) {
    final next = ProgressionService.claimMission(state, id, coins, xp, DateTime.now());
    if (next == null) return 0;
    _commit(next);
    return coins;
  }

  int claimDailyReward() {
    final result = ProgressionService.claimDailyReward(state, DateTime.now());
    if (result.coins <= 0) return 0;
    _commit(result.profile);
    return result.coins;
  }

  void ensureToday() {
    final now = DateTime.now();
    final key = dateKey(now);
    if (state.daily.date != key) {
      _commit(state.copy()..daily = state.daily.copyWithDate(key));
    }
  }

  void resetProgress() => _commit(PlayerProfile());
}

extension DailyStateX on DailyState {
  /// Starts a fresh day while carrying the streak forward. Missions and the
  /// daily reward must never leak into the next day.
  DailyState copyWithDate(String date) => DailyState(
        date: date,
        streak: streak,
        lastRewardDate: lastRewardDate,
      );
}

class SettingsNotifier extends Notifier<AppSettings> {
  Timer? _persistTimer;
  AppSettings? _pending;

  @override
  AppSettings build() {
    final storage = ref.read(storageProvider);
    ref.onDispose(() {
      _persistTimer?.cancel();
      final pending = _pending;
      if (pending != null) storage.saveSettings(pending);
    });
    return storage.loadSettings();
  }

  void _commit(AppSettings settings) {
    state = settings;
    // Slider drags can fire dozens of times per second. Keep the UI instant,
    // batch the disk write, and flush on lifecycle pause/dispose.
    _pending = settings;
    AudioService.instance.updateSettings(settings);
    _persistTimer?.cancel();
    _persistTimer = Timer(const Duration(milliseconds: 250), flush);
  }

  void flush() {
    _persistTimer?.cancel();
    final pending = _pending;
    if (pending == null) return;
    _pending = null;
    ref.read(storageProvider).saveSettings(pending);
  }

  void setMusicVolume(double value) => _commit(state.copyWith(musicVolume: value));
  void setSfxVolume(double value) => _commit(state.copyWith(sfxVolume: value));
  void setHaptics(bool value) => _commit(state.copyWith(haptics: value));
  void setReducedMotion(bool value) => _commit(state.copyWith(reducedMotion: value));
  void setScreenShake(bool value) => _commit(state.copyWith(screenShake: value));
  void setShowHints(bool value) => _commit(state.copyWith(showHints: value));
}
