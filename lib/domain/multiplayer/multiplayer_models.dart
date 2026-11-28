import 'dart:math' as math;

/// Local-only multiplayer data. None of these types reference PlayerProfile or
/// single-player services, which keeps rewards and stats structurally isolated.
enum MultiplayerMatchStatus { inProgress, completed }

MultiplayerMatchStatus _statusFrom(Object? value) => switch (value) {
      'completed' => MultiplayerMatchStatus.completed,
      _ => MultiplayerMatchStatus.inProgress,
    };

String _statusTo(MultiplayerMatchStatus status) => switch (status) {
      MultiplayerMatchStatus.inProgress => 'inProgress',
      MultiplayerMatchStatus.completed => 'completed',
    };

Map<String, Object?> _objectMap(Object? value) {
  if (value is! Map) return const <String, Object?>{};
  return value.map(
    (key, dynamic value) => MapEntry<String, Object?>(key.toString(), value),
  );
}

int _int(Object? value, [int fallback = 0]) => switch (value) {
      final int v => v,
      final num v => v.round(),
      final String v => int.tryParse(v) ?? fallback,
      _ => fallback,
    };

String _string(Object? value, [String fallback = '']) =>
    value is String ? value : fallback;

List<String> _stringList(Object? value) => value is List
    ? value.map((entry) => _string(entry)).where((name) => name.isNotEmpty).toList()
    : <String>[];

int? _score(Object? value) {
  if (value == null) return null;
  final parsed = _int(value, -1);
  return parsed < 0 ? null : parsed;
}

List<List<int?>> _scoreMatrix(Object? value, int players, int rounds) {
  final source = value is List ? value : const <Object?>[];
  return List.generate(rounds, (round) {
    final row = round < source.length && source[round] is List
        ? source[round] as List
        : const <Object?>[];
    return List.generate(players, (player) {
      return player < row.length ? _score(row[player]) : null;
    });
  });
}

class MultiplayerStanding {
  const MultiplayerStanding({
    required this.playerIndex,
    required this.name,
    required this.total,
    required this.rank,
    required this.isWinner,
  });

  final int playerIndex;
  final String name;
  final int total;
  final int rank;
  final bool isWinner;
}

class MultiplayerMatchRecord {
  MultiplayerMatchRecord({
    required this.id,
    required this.playedAt,
    required List<String> players,
    required this.rounds,
    required List<List<int?>> scores,
    this.status = MultiplayerMatchStatus.inProgress,
    this.goldAwarded = 0,
    this.xpAwarded = 0,
  })  : players = List<String>.unmodifiable(players),
        scores = List<List<int?>>.unmodifiable(
          scores.map((row) => List<int?>.unmodifiable(row)).toList(),
        );

  factory MultiplayerMatchRecord.start({
    required String id,
    required DateTime playedAt,
    required List<String> players,
    required int rounds,
  }) {
    return MultiplayerMatchRecord(
      id: id,
      playedAt: playedAt,
      players: players,
      rounds: rounds,
      scores: List.generate(rounds, (_) => List<int?>.filled(players.length, null)),
    );
  }

  factory MultiplayerMatchRecord.fromJson(Map<String, Object?> json) {
    final players = _stringList(json['players']);
    final rounds = _int(json['rounds'], 1).clamp(1, 20);
    return MultiplayerMatchRecord(
      id: _string(json['id'], 'unknown-match'),
      playedAt: DateTime.tryParse(_string(json['playedAt'])) ?? DateTime.fromMillisecondsSinceEpoch(0),
      players: players.isEmpty ? const ['Player 1', 'Player 2'] : players,
      rounds: rounds,
      scores: _scoreMatrix(json['scores'], players.isEmpty ? 2 : players.length, rounds),
      status: _statusFrom(json['status']),
      goldAwarded: _int(json['goldAwarded']),
      xpAwarded: _int(json['xpAwarded']),
    );
  }

  final String id;
  final DateTime playedAt;
  final List<String> players;
  final int rounds;
  final List<List<int?>> scores;
  final MultiplayerMatchStatus status;
  final int goldAwarded;
  final int xpAwarded;

  bool get isCompleted => status == MultiplayerMatchStatus.completed;

  bool get allTurnsRecorded {
    for (final row in scores) {
      for (final score in row) {
        if (score == null) return false;
      }
    }
    return true;
  }

  int scoreFor({required int roundIndex, required int playerIndex}) {
    if (roundIndex < 0 || roundIndex >= rounds) return 0;
    if (playerIndex < 0 || playerIndex >= players.length) return 0;
    return scores[roundIndex][playerIndex] ?? 0;
  }

  int totalFor(int playerIndex) {
    if (playerIndex < 0 || playerIndex >= players.length) return 0;
    var total = 0;
    for (final row in scores) {
      total += row[playerIndex] ?? 0;
    }
    return total;
  }

  int get totalPoints => List.generate(players.length, totalFor).fold<int>(0, (a, b) => a + b);

  int get winningScore {
    var best = 0;
    for (var i = 0; i < players.length; i++) {
      best = math.max(best, totalFor(i));
    }
    return best;
  }

  int get highestTurnScore {
    var best = 0;
    for (final row in scores) {
      for (final score in row) {
        if (score != null) best = math.max(best, score);
      }
    }
    return best;
  }

  List<MultiplayerStanding> get standings {
    final order = List<int>.generate(players.length, (index) => index)
      ..sort((a, b) => totalFor(b).compareTo(totalFor(a)));
    final winners = winningScore;
    var lastTotal = -1;
    var lastRank = 0;
    final result = <MultiplayerStanding>[];
    // Competition-style ranks: tied players share a place, and the next
    // distinct score keeps its position (1, 1, 3).
    for (var position = 0; position < order.length; position++) {
      final index = order[position];
      final total = totalFor(index);
      if (total != lastTotal) {
        lastTotal = total;
        lastRank = position + 1;
      }
      result.add(
        MultiplayerStanding(
          playerIndex: index,
          name: players[index],
          total: total,
          rank: lastRank,
          isWinner: total == winners,
        ),
      );
    }
    return result;
  }

  List<MultiplayerStanding> get winners => standings.where((entry) => entry.isWinner).toList();

  List<String> get winnerNames => winners.map((entry) => entry.name).toList();

  MultiplayerMatchRecord withScore({
    required int roundIndex,
    required int playerIndex,
    required int score,
  }) {
    if (roundIndex < 0 ||
        roundIndex >= rounds ||
        playerIndex < 0 ||
        playerIndex >= players.length) {
      return this;
    }
    final next = scores.map((row) => List<int?>.from(row)).toList();
    next[roundIndex][playerIndex] = score.clamp(0, 10000000);
    return MultiplayerMatchRecord(
      id: id,
      playedAt: playedAt,
      players: players,
      rounds: rounds,
      scores: next,
      status: status,
      goldAwarded: goldAwarded,
      xpAwarded: xpAwarded,
    );
  }

  MultiplayerMatchRecord completedWith({required int gold, required int xp}) {
    return MultiplayerMatchRecord(
      id: id,
      playedAt: playedAt,
      players: players,
      rounds: rounds,
      scores: scores,
      status: MultiplayerMatchStatus.completed,
      goldAwarded: gold,
      xpAwarded: xp,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'playedAt': playedAt.toIso8601String(),
        'players': players,
        'rounds': rounds,
        'scores': scores,
        'status': _statusTo(status),
        'goldAwarded': goldAwarded,
        'xpAwarded': xpAwarded,
      };
}

/// Per-player career record inside Multiplayer Mode only.
class MultiplayerPlayerStats {
  const MultiplayerPlayerStats({
    required this.name,
    this.games = 0,
    this.wins = 0,
    this.losses = 0,
    this.totalPoints = 0,
    this.bestScore = 0,
  });

  factory MultiplayerPlayerStats.fromJson(Map<String, Object?> json) {
    return MultiplayerPlayerStats(
      name: _string(json['name'], 'Player'),
      games: _int(json['games']),
      wins: _int(json['wins']),
      losses: _int(json['losses']),
      totalPoints: _int(json['totalPoints']),
      bestScore: _int(json['bestScore']),
    );
  }

  final String name;
  final int games;
  final int wins;
  final int losses;
  final int totalPoints;
  final int bestScore;

  Map<String, Object?> toJson() => {
        'name': name,
        'games': games,
        'wins': wins,
        'losses': losses,
        'totalPoints': totalPoints,
        'bestScore': bestScore,
      };
}

/// Entirely separate save object. It never reads or writes PlayerProfile data.
class MultiplayerProfile {
  const MultiplayerProfile({
    this.gold = 0,
    this.xp = 0,
    this.totalPoints = 0,
    this.gamesPlayed = 0,
    this.wins = 0,
    this.losses = 0,
    this.highestScore = 0,
    Map<String, MultiplayerPlayerStats>? playerStats,
    List<MultiplayerMatchRecord>? history,
    this.activeMatch,
  })  : playerStats = playerStats ?? const <String, MultiplayerPlayerStats>{},
        history = history ?? const <MultiplayerMatchRecord>[];

  factory MultiplayerProfile.fromJson(Map<String, Object?> json) {
    final stats = <String, MultiplayerPlayerStats>{};
    for (final entry in _objectMap(json['playerStats']).entries) {
      stats[entry.key] = MultiplayerPlayerStats.fromJson(_objectMap(entry.value));
    }
    final history = <MultiplayerMatchRecord>[];
    final historyJson = json['history'];
    if (historyJson is List) {
      for (final entry in historyJson) {
        final map = _objectMap(entry);
        if (map.isEmpty) continue;
        final match = MultiplayerMatchRecord.fromJson(map);
        // Interrupted matches are never stored as history, even if a stale
        // or hand-edited save contains one.
        if (match.isCompleted) history.add(match);
      }
    }
    final active = _objectMap(json['activeMatch']);
    return MultiplayerProfile(
      gold: _int(json['gold']),
      xp: _int(json['xp']),
      totalPoints: _int(json['totalPoints']),
      gamesPlayed: _int(json['gamesPlayed']),
      wins: _int(json['wins']),
      losses: _int(json['losses']),
      highestScore: _int(json['highestScore']),
      playerStats: stats,
      history: history,
      activeMatch: active.isEmpty
          ? null
          : MultiplayerMatchRecord.fromJson(active).isCompleted
              ? null
              : MultiplayerMatchRecord.fromJson(active),
    );
  }

  final int gold;
  final int xp;
  final int totalPoints;
  final int gamesPlayed;
  final int wins;
  final int losses;
  final int highestScore;
  final Map<String, MultiplayerPlayerStats> playerStats;
  final List<MultiplayerMatchRecord> history;
  final MultiplayerMatchRecord? activeMatch;

  MultiplayerMatchRecord? get recentMatch => history.isEmpty ? null : history.first;

  MultiplayerProfile copyWith({
    int? gold,
    int? xp,
    int? totalPoints,
    int? gamesPlayed,
    int? wins,
    int? losses,
    int? highestScore,
    Map<String, MultiplayerPlayerStats>? playerStats,
    List<MultiplayerMatchRecord>? history,
    MultiplayerMatchRecord? activeMatch,
    bool clearActiveMatch = false,
  }) {
    return MultiplayerProfile(
      gold: gold ?? this.gold,
      xp: xp ?? this.xp,
      totalPoints: totalPoints ?? this.totalPoints,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      highestScore: highestScore ?? this.highestScore,
      playerStats: playerStats ?? this.playerStats,
      history: history ?? this.history,
      activeMatch: clearActiveMatch ? null : activeMatch ?? this.activeMatch,
    );
  }

  Map<String, Object?> toJson() => {
        'gold': gold,
        'xp': xp,
        'totalPoints': totalPoints,
        'gamesPlayed': gamesPlayed,
        'wins': wins,
        'losses': losses,
        'highestScore': highestScore,
        'playerStats': playerStats.map((key, value) => MapEntry(key, value.toJson())),
        'history': history.map((match) => match.toJson()).toList(),
        if (activeMatch != null) 'activeMatch': activeMatch!.toJson(),
      };
}

/// In-memory turn tracker. Every turn writes its score into a record that can
/// be persisted mid-match, but only [MultiplayerService.completeMatch] may
/// award rewards or add a match to history.
class MultiplayerSession {
  MultiplayerSession({
    required List<String> players,
    required int rounds,
    String? id,
    DateTime? startedAt,
  })  : assert(players.length >= 2, 'Multiplayer needs at least two players'),
        assert(rounds >= 1, 'A match needs at least one round'),
        record = MultiplayerMatchRecord.start(
          id: id ?? MultiplayerService.newMatchId(startedAt ?? DateTime.now()),
          playedAt: startedAt ?? DateTime.now(),
          players: players,
          rounds: rounds,
        );

  MultiplayerSession.fromRecord(this.record) : assert(record.players.length >= 2);

  final MultiplayerMatchRecord record;

  int get currentRound {
    for (var round = 0; round < record.rounds; round++) {
      for (final score in record.scores[round]) {
        if (score == null) return round + 1;
      }
    }
    return record.rounds + 1;
  }

  int get currentPlayerIndex {
    final round = (currentRound - 1).clamp(0, record.rounds - 1);
    final row = record.scores[round];
    for (var i = 0; i < row.length; i++) {
      if (row[i] == null) return i;
    }
    return row.length;
  }

  bool get isComplete => currentRound > record.rounds;

  String get currentPlayer {
    final index = currentPlayerIndex.clamp(0, record.players.length - 1);
    return record.players[index];
  }

  List<String> get completedPlayers {
    final index = currentPlayerIndex.clamp(0, record.players.length);
    return record.players.take(index).toList();
  }

  List<String> get remainingPlayers {
    final index = currentPlayerIndex.clamp(0, record.players.length);
    return record.players.skip(index).toList();
  }

  MultiplayerSession recordScore(int score) {
    return MultiplayerSession.fromRecord(
      record.withScore(
        roundIndex: currentRound - 1,
        playerIndex: currentPlayerIndex,
        score: score,
      ),
    );
  }
}

/// Pure helpers for multiplayer rewards and save mutation.
abstract final class MultiplayerService {
  static String newMatchId(DateTime now) {
    final stamp = now.microsecondsSinceEpoch.toRadixString(36);
    final salt = math.Random().nextInt(1 << 30).toRadixString(36);
    return 'mp-$stamp-$salt';
  }

  static ({int gold, int xp}) rewardsFor(MultiplayerMatchRecord record) {
    if (!record.allTurnsRecorded) return (gold: 0, xp: 0);
    final total = record.totalPoints;
    final winnerBonus = record.winners.length == 1 ? 1 : 0;
    return (
      gold: total ~/ 20 + winnerBonus * 100,
      xp: total ~/ 10 + winnerBonus * 150,
    );
  }

  static MultiplayerProfile saveActiveMatch(
    MultiplayerProfile profile,
    MultiplayerMatchRecord record,
  ) {
    if (record.isCompleted) return profile;
    return profile.copyWith(activeMatch: record);
  }

  /// Only this path commits rewards, stats and history. A stale or interrupted
  /// record can never reach it without every turn being recorded first.
  static MultiplayerProfile completeMatch(
    MultiplayerProfile profile,
    MultiplayerMatchRecord record,
  ) {
    if (!record.allTurnsRecorded) return profile;
    // A duplicate completion (e.g. a retried button tap) must never pay twice.
    if (profile.history.any((match) => match.id == record.id)) return profile;
    final rewards = rewardsFor(record);
    final completed = record.completedWith(gold: rewards.gold, xp: rewards.xp);
    final winnerNames = completed.winnerNames.toSet();
    final stats = Map<String, MultiplayerPlayerStats>.from(profile.playerStats);

    for (var i = 0; i < completed.players.length; i++) {
      final name = completed.players[i];
      final previous = stats[name] ?? MultiplayerPlayerStats(name: name);
      var best = previous.bestScore;
      for (final row in completed.scores) {
        final score = row[i];
        if (score != null) best = math.max(best, score);
      }
      stats[name] = MultiplayerPlayerStats(
        name: name,
        games: previous.games + 1,
        wins: previous.wins + (winnerNames.contains(name) ? 1 : 0),
        losses: previous.losses + (winnerNames.contains(name) ? 0 : 1),
        totalPoints: previous.totalPoints + completed.totalFor(i),
        bestScore: best,
      );
    }

    return profile.copyWith(
      gold: profile.gold + rewards.gold,
      xp: profile.xp + rewards.xp,
      totalPoints: profile.totalPoints + completed.totalPoints,
      gamesPlayed: profile.gamesPlayed + 1,
      wins: profile.wins + winnerNames.length,
      losses: profile.losses + completed.players.length - winnerNames.length,
      highestScore: math.max(profile.highestScore, completed.highestTurnScore),
      playerStats: stats,
      history: [completed, ...profile.history],
      clearActiveMatch: true,
    );
  }
}
