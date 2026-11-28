import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadowshift/domain/progression/ranks.dart';

/// Queue of non-run promotions waiting for the global celebration overlay.
/// Run promotions are announced by GameOverScreen instead, so they appear on
/// the run report. Keeping this outside [PlayerProfile] means a promotion is
/// shown once, then discarded, while the permanent record stays in
/// `PlayerProfile.rankHistory`.
final pendingRankUpsProvider =
    NotifierProvider<PendingRankUps, List<RankPromotion>>(PendingRankUps.new);

class PendingRankUps extends Notifier<List<RankPromotion>> {
  @override
  List<RankPromotion> build() => const [];

  void enqueue(Iterable<RankPromotion> promotions) {
    final incoming = promotions.toList(growable: false);
    if (incoming.isEmpty) return;
    state = [...state, ...incoming];
  }

  RankPromotion? peek() => state.isEmpty ? null : state.first;

  void dismiss() {
    if (state.isEmpty) return;
    state = state.sublist(1);
  }

  void clear() {
    if (state.isEmpty) return;
    state = const [];
  }
}
