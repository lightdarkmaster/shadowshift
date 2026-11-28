import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadowshift/core/utils.dart';
import 'package:shadowshift/data/models/app_settings.dart';
import 'package:shadowshift/data/models/profile.dart';
import 'package:shadowshift/data/repositories/storage_repository.dart';
import 'package:shadowshift/domain/game/entities.dart';
import 'package:shadowshift/domain/multiplayer/multiplayer_models.dart';
import 'package:shadowshift/domain/progression/ranks.dart';
import 'package:shadowshift/domain/services/audio_service.dart';
import 'package:shadowshift/domain/services/progression_service.dart';
import 'package:shadowshift/state/rank_providers.dart';

final storageProvider = Provider<StorageRepository>((ref) {
  throw UnimplementedError('StorageRepository must be overridden at startup.');
});

final profileProvider = NotifierProvider<ProfileNotifier, PlayerProfile>(
  ProfileNotifier.new,
);

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

/// Deliberately separate from [profileProvider]. It loads from a different
/// storage key and never reads, writes, or rewards the single-player profile.
final multiplayerProfileProvider =
    NotifierProvider<MultiplayerProfileNotifier, MultiplayerProfile>(
  MultiplayerProfileNotifier.new,
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

  void _commit(PlayerProfile profile, {bool announceRankUps = true}) {
    final previousXp = state.xp;
    state = profile;
    if (announceRankUps && profile.xp > previousXp) {
      final promotions = RankConfig.promotionsBetween(
        previousXp,
        profile.xp,
        DateTime.now(),
        earnedXp: profile.xp - previousXp,
      );
      ref.read(pendingRankUpsProvider.notifier).enqueue(promotions);
    }
    // All related records live in this one JSON blob, so one write is the
    // transaction boundary for XP, rank, history and rewards.
    ref.read(storageProvider).saveProfile(profile);
  }

  RewardSummary applyRun(RunResult result) {
    final summary = ProgressionService.applyRun(state, result);
    // Run promotions are announced by GameOverScreen from the summary, so the
    // dialog appears on the run report instead of over live gameplay.
    _commit(summary.profile, announceRankUps: false);
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

  bool equipTitle(String titleId) {
    if (!state.unlockedTitles.contains(titleId)) return false;
    if (state.equippedTitle == titleId) return true;
    _commit(state.copy()..equippedTitle = titleId);
    return true;
  }

  void setPlayerName(String raw) {
    final name = RankConfig.sanitizePlayerName(raw);
    if (name == state.playerName) return;
    _commit(state.copy()..playerName = name);
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

  void resetProgress() {
    ref.read(pendingRankUpsProvider.notifier).clear();
    _commit(PlayerProfile());
  }
}

/// Owns the entire offline multiplayer save. No method here touches XP, gold,
/// achievements, missions, ranks, or any other single-player state.
class MultiplayerProfileNotifier extends Notifier<MultiplayerProfile> {
  @override
  MultiplayerProfile build() => ref.read(storageProvider).loadMultiplayerProfile();

  void _commit(MultiplayerProfile profile) {
    state = profile;
    ref.read(storageProvider).saveMultiplayerProfile(profile);
  }

  MultiplayerMatchRecord startMatch(List<String> players, int rounds) {
    final names = players
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toList();
    if (names.length < 2 || rounds < 1 || rounds > 20) {
      throw ArgumentError('A multiplayer match needs 2-6 players and 1-20 rounds.');
    }
    final now = DateTime.now();
    final record = MultiplayerMatchRecord.start(
      id: MultiplayerService.newMatchId(now),
      playedAt: now,
      players: names,
      rounds: rounds.clamp(1, 20),
    );
    _commit(MultiplayerService.saveActiveMatch(state, record));
    return record;
  }

  /// Persists one completed turn immediately so an interrupted match can be
  /// resumed without replaying or double-awarding earlier turns.
  void recordTurn(MultiplayerMatchRecord record, int score) {
    final updated = MultiplayerSession.fromRecord(record).recordScore(score).record;
    _commit(MultiplayerService.saveActiveMatch(state, updated));
  }

  MultiplayerProfile completeMatch(MultiplayerMatchRecord record) {
    // A record that somehow reaches this path with gaps stays in progress.
    if (!record.allTurnsRecorded) return state;
    final next = MultiplayerService.completeMatch(state, record);
    if (next.history.length == state.history.length) return state;
    _commit(next);
    return next;
  }

  void clearActiveMatch() => _commit(state.copyWith(clearActiveMatch: true));
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
