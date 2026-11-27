import 'package:flutter_test/flutter_test.dart';
import 'package:shadowshift/data/models/app_settings.dart';
import 'package:shadowshift/data/models/profile.dart';
import 'package:shadowshift/data/repositories/storage_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('profile and settings persist through the repository', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = await StorageRepository.create();
    final profile = PlayerProfile(
      coins: 321,
      unlockedCharacters: {'nyx', 'echo'},
      bestScores: {'classic': 8888},
    );
    await repository.saveProfile(profile);
    await repository.saveSettings(const AppSettings(musicVolume: 0.2, haptics: false));

    expect(repository.loadProfile().coins, 321);
    expect(repository.loadProfile().unlockedCharacters, {'nyx', 'echo'});
    expect(repository.loadProfile().bestScores['classic'], 8888);
    expect(repository.loadSettings().musicVolume, 0.2);
    expect(repository.loadSettings().haptics, isFalse);
  });

  test('corrupt save data falls back to a valid profile', () async {
    SharedPreferences.setMockInitialValues({
      'shadowshift.profile.v1': '{broken json',
      'shadowshift.settings.v1': '[]',
    });
    final repository = await StorageRepository.create();
    expect(repository.loadProfile().coins, 0);
    expect(repository.loadSettings().musicVolume, 0.5);
  });

  test('daily state resets when the stored date is stale', () async {
    SharedPreferences.setMockInitialValues({
      'shadowshift.profile.v1':
          '{"coins":10,"daily":{"date":"2020-01-01","missionProgress":{"a":5},"claimedMissions":["a"],"rewardClaimed":true}}',
    });
    final repository = await StorageRepository.create();
    final profile = repository.loadProfile(now: DateTime(2026, 11, 27));
    expect(profile.daily.date, '2026-11-27');
    expect(profile.daily.missionProgress, isEmpty);
    expect(profile.daily.claimedMissions, isEmpty);
    expect(profile.daily.rewardClaimed, isFalse);
    expect(profile.coins, 10);
  });
}
