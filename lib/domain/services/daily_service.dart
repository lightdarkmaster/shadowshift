import 'package:shadowshift/core/utils.dart';
import 'package:shadowshift/domain/game/entities.dart';
import 'package:shadowshift/domain/game/enums.dart';
import 'package:shadowshift/domain/progression/catalog.dart';

class _DailyContent {
  _DailyContent._(this.key, this.seed, this.challenge, this.missions);

  factory _DailyContent(String key) {
    final seed = hashString('SHADOW-SHIFT-$key');
    return _DailyContent._(
      key,
      seed,
      DailyService._buildChallenge(seed),
      List.unmodifiable(DailyService._buildMissions(key, seed)),
    );
  }

  final String key;
  final int seed;
  final RunObjective challenge;
  final List<MissionDef> missions;
}

/// Entirely local, deterministic daily content. The same calendar date always
/// produces the same seed, objective and missions on every device.
abstract final class DailyService {
  // A single date's content is reused across all screens and run settlement.
  static _DailyContent? _cachedContent;

  static _DailyContent _content(DateTime date) {
    final key = dateKey(date);
    final cached = _cachedContent;
    if (cached != null && cached.key == key) return cached;
    final content = _DailyContent(key);
    _cachedContent = content;
    return content;
  }

  static int seedFor(DateTime date) => _content(date).seed;

  static RunObjective challengeFor(DateTime date) => _content(date).challenge;

  static List<MissionDef> missionsFor(DateTime date) => _content(date).missions;

  static RunObjective _buildChallenge(int seed) {
    final surviveTarget = 45 + (seed % 31); // 45-75s
    final orbTarget = 12 + ((seed >> 5) % 14); // 12-25 orbs
    return RunObjective(
      kind: ObjectiveKind.surviveAndOrbs,
      target: surviveTarget,
      secondaryTarget: orbTarget,
      title: 'Survive ${surviveTarget}s · $orbTarget orbs',
    );
  }

  static List<MissionDef> _buildMissions(String key, int seed) {
    // Stepping by a number coprime with 5 guarantees three distinct kinds.
    final base = seed % 5;
    final step = 1 + ((seed >> 7) % 4);
    final kinds = <ObjectiveKind>[
      for (var i = 0; i < 3; i++) ObjectiveKind.values[1 + ((base + i * step) % 5)],
    ];
    return List.generate(3, (index) {
      final kind = kinds[index];
      final variant = (seed >> (11 + index * 6)) & 0xFF;
      final target = _target(kind, variant);
      return MissionDef(
        id: '$key-m$index',
        kind: kind,
        title: _title(kind, target),
        target: target,
        rewardCoins: 60 + variant % 60,
        rewardXp: 30 + variant % 35,
      );
    });
  }

  static int _target(ObjectiveKind kind, int variant) => switch (kind) {
        ObjectiveKind.survive => 30 + variant % 45,
        ObjectiveKind.orbs => 10 + variant % 18,
        ObjectiveKind.combo => 8 + variant % 16,
        ObjectiveKind.score => 1500 + (variant % 12) * 500,
        ObjectiveKind.switches => 15 + variant % 30,
        _ => 20,
      };

  static String _title(ObjectiveKind kind, int target) => switch (kind) {
        ObjectiveKind.survive => 'Survive ${target}s today',
        ObjectiveKind.orbs => 'Collect $target orbs today',
        ObjectiveKind.combo => 'Reach $target combo today',
        ObjectiveKind.score => 'Score $target points today',
        ObjectiveKind.switches => 'Shift dimensions $target times today',
        _ => 'Complete today\'s objective',
      };

  static int missionProgress(MissionDef mission, RunResult result) => switch (mission.kind) {
        ObjectiveKind.survive => result.seconds.floor(),
        ObjectiveKind.orbs => result.orbs,
        ObjectiveKind.combo => result.maxCombo,
        ObjectiveKind.score => result.score,
        ObjectiveKind.switches => result.switches,
        _ => 0,
      };

  static bool accumulates(ObjectiveKind kind) =>
      kind == ObjectiveKind.orbs || kind == ObjectiveKind.switches;
}
