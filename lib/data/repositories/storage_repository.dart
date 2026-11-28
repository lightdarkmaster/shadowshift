import 'dart:convert';

import 'package:shadowshift/core/constants.dart';
import 'package:shadowshift/core/utils.dart';
import 'package:shadowshift/data/models/app_settings.dart';
import 'package:shadowshift/data/models/profile.dart';
import 'package:shadowshift/domain/multiplayer/multiplayer_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local-only persistence. All loaded data passes through validating parsers
/// so corrupted or legacy saves degrade gracefully to safe defaults.
class StorageRepository {
  StorageRepository(this._prefs);

  final SharedPreferences _prefs;

  String? _cachedProfileRaw;
  Object? _cachedProfileJson;
  String? _cachedSettingsRaw;
  Object? _cachedSettingsJson;
  String? _cachedMultiplayerRaw;
  Object? _cachedMultiplayerJson;

  static Future<StorageRepository> create() async =>
      StorageRepository(await SharedPreferences.getInstance());

  /// Parses a stored JSON string at most once while its raw value is unchanged.
  /// Models copy the decoded map, so the cached value is never mutated.
  Object? _decode(String key, String raw) {
    if (key == 'profile') {
      if (raw == _cachedProfileRaw) return _cachedProfileJson;
    } else if (key == 'settings') {
      if (raw == _cachedSettingsRaw) return _cachedSettingsJson;
    } else if (raw == _cachedMultiplayerRaw) {
      return _cachedMultiplayerJson;
    }
    final decoded = jsonDecode(raw);
    if (key == 'profile') {
      _cachedProfileRaw = raw;
      _cachedProfileJson = decoded;
    } else if (key == 'settings') {
      _cachedSettingsRaw = raw;
      _cachedSettingsJson = decoded;
    } else {
      _cachedMultiplayerRaw = raw;
      _cachedMultiplayerJson = decoded;
    }
    return decoded;
  }

  PlayerProfile loadProfile({DateTime? now}) {
    final raw = _prefs.getString(StorageKeys.profile);
    if (raw == null) return PlayerProfile();
    try {
      return PlayerProfile.fromJson(_decode('profile', raw), dateKey(now ?? DateTime.now()));
    } catch (_) {
      return PlayerProfile();
    }
  }

  Future<void> saveProfile(PlayerProfile profile) =>
      _prefs.setString(StorageKeys.profile, jsonEncode(profile.toJson()));

  AppSettings loadSettings() {
    final raw = _prefs.getString(StorageKeys.settings);
    if (raw == null) return const AppSettings();
    try {
      return AppSettings.fromJson(_decode('settings', raw));
    } catch (_) {
      return const AppSettings();
    }
  }

  Future<void> saveSettings(AppSettings settings) =>
      _prefs.setString(StorageKeys.settings, jsonEncode(settings.toJson()));

  MultiplayerProfile loadMultiplayerProfile() {
    final raw = _prefs.getString(StorageKeys.multiplayer);
    if (raw == null) return const MultiplayerProfile();
    try {
      return MultiplayerProfile.fromJson(
        _decode('multiplayer', raw) as Map<String, Object?>,
      );
    } catch (_) {
      return const MultiplayerProfile();
    }
  }

  Future<void> saveMultiplayerProfile(MultiplayerProfile profile) =>
      _prefs.setString(StorageKeys.multiplayer, jsonEncode(profile.toJson()));
}
