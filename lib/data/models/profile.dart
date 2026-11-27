import 'package:shadowshift/core/utils.dart';
import 'package:shadowshift/domain/progression/catalog.dart';

class DailyState {
  DailyState({
    required this.date,
    Set<String>? claimedMissions,
    Map<String, int>? missionProgress,
    this.rewardClaimed = false,
    this.streak = 0,
    this.lastRewardDate = '',
  })  : claimedMissions = claimedMissions ?? <String>{},
        missionProgress = missionProgress ?? <String, int>{};

  String date;
  Set<String> claimedMissions;
  Map<String, int> missionProgress;
  bool rewardClaimed;
  int streak;
  String lastRewardDate;

  Map<String, dynamic> toJson() => {
        'date': date,
        'claimedMissions': claimedMissions.toList(),
        'missionProgress': missionProgress,
        'rewardClaimed': rewardClaimed,
        'streak': streak,
        'lastRewardDate': lastRewardDate,
      };

  factory DailyState.fromJson(Map<String, dynamic> json, String today) {
    final date = json['date'] is String ? json['date'] as String : today;
    final sameDay = date == today;
    return DailyState(
      date: today,
      claimedMissions: sameDay
          ? _stringSet(json['claimedMissions'])
          : <String>{},
      missionProgress: sameDay
          ? _intMap(json['missionProgress'])
          : <String, int>{},
      rewardClaimed: sameDay && json['rewardClaimed'] == true,
      streak: safeInt(json['streak'], 0, max: 3650),
      lastRewardDate: json['lastRewardDate'] is String ? json['lastRewardDate'] as String : '',
    );
  }

  static Set<String> _stringSet(Object? value) {
    if (value is! List) return <String>{};
    return value.whereType<String>().toSet();
  }

  static Map<String, int> _intMap(Object? value) {
    if (value is! Map) return <String, int>{};
    return value.map((key, value) => MapEntry(key.toString(), safeInt(value, 0)));
  }
}

class PlayerProfile {
  PlayerProfile({
    this.version = 1,
    this.coins = 0,
    this.xp = 0,
    this.totalRuns = 0,
    this.totalOrbs = 0,
    this.totalShifts = 0,
    this.totalSeconds = 0,
    this.bestCombo = 0,
    this.bestTimeAttackScore = 0,
    this.dailyBestScore = 0,
    Set<String>? unlockedCharacters,
    Set<String>? unlockedSkins,
    Set<String>? unlockedEffects,
    Set<String>? unlockedAbilities,
    Set<String>? achievements,
    Set<String>? completedChallenges,
    Map<String, int>? bestScores,
    String? character,
    String? skin,
    String? effect,
    String? ability,
    DailyState? daily,
  })  : unlockedCharacters = unlockedCharacters ?? {'nyx'},
        unlockedSkins = unlockedSkins ?? {'aurora'},
        unlockedEffects = unlockedEffects ?? {'classic'},
        unlockedAbilities = unlockedAbilities ?? {'none'},
        achievements = achievements ?? <String>{},
        completedChallenges = completedChallenges ?? <String>{},
        bestScores = bestScores ?? <String, int>{},
        character = character ?? 'nyx',
        skin = skin ?? 'aurora',
        effect = effect ?? 'classic',
        ability = ability ?? 'none',
        daily = daily ?? DailyState(date: '');

  int version;
  int coins;
  int xp;
  int totalRuns;
  int totalOrbs;
  int totalShifts;
  int totalSeconds;
  int bestCombo;
  int bestTimeAttackScore;
  int dailyBestScore;
  Set<String> unlockedCharacters;
  Set<String> unlockedSkins;
  Set<String> unlockedEffects;
  Set<String> unlockedAbilities;
  Set<String> achievements;
  Set<String> completedChallenges;
  Map<String, int> bestScores;
  String character;
  String skin;
  String effect;
  String ability;
  DailyState daily;

  int get level => levelForXp(xp);
  int get xpInLevel => xp - xpRequiredForLevel(level);
  int get xpForNextLevel => xpRequiredForLevel(level + 1) - xpRequiredForLevel(level);

  static const int maxLevel = 100;

  // Closed form of sum(80 + 40*l for l in 1..level-1), precomputed once.
  static final List<int> _levelThresholds = List<int>.generate(
    maxLevel + 2,
    (level) => 20 * level * level + 60 * level - 80,
  );

  static int xpRequiredForLevel(int level) {
    if (level <= 1) return 0;
    if (level >= _levelThresholds.length) return _levelThresholds.last;
    return _levelThresholds[level];
  }

  static int levelForXp(int points) {
    var low = 1;
    var high = maxLevel;
    while (low < high) {
      final mid = (low + high + 1) >> 1;
      if (points >= xpRequiredForLevel(mid)) {
        low = mid;
      } else {
        high = mid - 1;
      }
    }
    return low;
  }

  PlayerProfile copy() => PlayerProfile(
        version: version,
        coins: coins,
        xp: xp,
        totalRuns: totalRuns,
        totalOrbs: totalOrbs,
        totalShifts: totalShifts,
        totalSeconds: totalSeconds,
        bestCombo: bestCombo,
        bestTimeAttackScore: bestTimeAttackScore,
        dailyBestScore: dailyBestScore,
        unlockedCharacters: Set<String>.from(unlockedCharacters),
        unlockedSkins: Set<String>.from(unlockedSkins),
        unlockedEffects: Set<String>.from(unlockedEffects),
        unlockedAbilities: Set<String>.from(unlockedAbilities),
        achievements: Set<String>.from(achievements),
        completedChallenges: Set<String>.from(completedChallenges),
        bestScores: Map<String, int>.from(bestScores),
        character: character,
        skin: skin,
        effect: effect,
        ability: ability,
        daily: DailyState(
          date: daily.date,
          claimedMissions: Set<String>.from(daily.claimedMissions),
          missionProgress: Map<String, int>.from(daily.missionProgress),
          rewardClaimed: daily.rewardClaimed,
          streak: daily.streak,
          lastRewardDate: daily.lastRewardDate,
        ),
      );

  Map<String, dynamic> toJson() => {
        'version': version,
        'coins': coins,
        'xp': xp,
        'totalRuns': totalRuns,
        'totalOrbs': totalOrbs,
        'totalShifts': totalShifts,
        'totalSeconds': totalSeconds,
        'bestCombo': bestCombo,
        'bestTimeAttackScore': bestTimeAttackScore,
        'dailyBestScore': dailyBestScore,
        'unlockedCharacters': unlockedCharacters.toList(),
        'unlockedSkins': unlockedSkins.toList(),
        'unlockedEffects': unlockedEffects.toList(),
        'unlockedAbilities': unlockedAbilities.toList(),
        'achievements': achievements.toList(),
        'completedChallenges': completedChallenges.toList(),
        'bestScores': bestScores,
        'character': character,
        'skin': skin,
        'effect': effect,
        'ability': ability,
        'daily': daily.toJson(),
      };

  factory PlayerProfile.fromJson(Object? raw, String today) {
    if (raw is! Map) return PlayerProfile();
    final json = Map<String, dynamic>.from(raw);
    final profile = PlayerProfile(
      version: safeInt(json['version'], 1, min: 1, max: 1000),
      coins: safeInt(json['coins'], 0, max: 100000000),
      xp: safeInt(json['xp'], 0, max: 100000000),
      totalRuns: safeInt(json['totalRuns'], 0, max: 100000000),
      totalOrbs: safeInt(json['totalOrbs'], 0, max: 100000000),
      totalShifts: safeInt(json['totalShifts'], 0, max: 100000000),
      totalSeconds: safeInt(json['totalSeconds'], 0, max: 100000000),
      bestCombo: safeInt(json['bestCombo'], 0, max: 100000000),
      bestTimeAttackScore: safeInt(json['bestTimeAttackScore'], 0, max: 100000000),
      dailyBestScore: safeInt(json['dailyBestScore'], 0, max: 100000000),
      unlockedCharacters: _knownSet(json['unlockedCharacters'], Catalog.characters.map((e) => e.id), {'nyx'}),
      unlockedSkins: _knownSet(json['unlockedSkins'], Catalog.skins.map((e) => e.id), {'aurora'}),
      unlockedEffects: _knownSet(json['unlockedEffects'], Catalog.effects.map((e) => e.id), {'classic'}),
      unlockedAbilities: _knownSet(json['unlockedAbilities'], Catalog.abilities.map((e) => e.id), {'none'}),
      achievements: _knownSet(json['achievements'], Achievements.all.map((e) => e.id), {}),
      completedChallenges: _knownSet(json['completedChallenges'], Challenges.all.map((e) => e.id), {}),
      bestScores: _intMap(json['bestScores']),
      character: json['character'] is String ? json['character'] as String : 'nyx',
      skin: json['skin'] is String ? json['skin'] as String : 'aurora',
      effect: json['effect'] is String ? json['effect'] as String : 'classic',
      ability: json['ability'] is String ? json['ability'] as String : 'none',
      daily: json['daily'] is Map
          ? DailyState.fromJson(Map<String, dynamic>.from(json['daily'] as Map), today)
          : DailyState(date: today),
    );
    // Guard against corrupted selection values.
    profile.unlockedCharacters.add('nyx');
    if (!profile.unlockedCharacters.contains(profile.character)) profile.character = 'nyx';
    if (!profile.unlockedSkins.contains(profile.skin)) profile.skin = 'aurora';
    if (!profile.unlockedEffects.contains(profile.effect)) profile.effect = 'classic';
    if (!profile.unlockedAbilities.contains(profile.ability)) profile.ability = 'none';
    return profile;
  }

  static Set<String> _knownSet(Object? value, Iterable<String> valid, Set<String> fallback) {
    if (value is! List) return fallback;
    final allowed = valid.toSet();
    final result = value.whereType<String>().where(allowed.contains).toSet();
    return result.isEmpty ? fallback : result;
  }

  static Map<String, int> _intMap(Object? value) {
    if (value is! Map) return <String, int>{};
    return value.map((key, entry) => MapEntry(key.toString(), safeInt(entry, 0)));
  }
}
