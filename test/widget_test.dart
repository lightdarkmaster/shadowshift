import 'dart:convert';
import 'dart:ui' show Size;

import 'package:material_ui/material_ui.dart' show Icons, MaterialApp, TextField;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadowshift/core/constants.dart';
import 'package:shadowshift/data/models/profile.dart';
import 'package:shadowshift/data/repositories/storage_repository.dart';
import 'package:shadowshift/domain/multiplayer/multiplayer_models.dart';
import 'package:shadowshift/main.dart';
import 'package:shadowshift/state/app_providers.dart';
import 'package:shadowshift/ui/screens/multiplayer/multiplayer_results_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpApp(
    WidgetTester tester, {
    Map<String, Object> values = const {},
  }) async {
    SharedPreferences.setMockInitialValues(values);
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageProvider.overrideWithValue(StorageRepository(prefs))],
        child: const ShadowShiftApp(),
      ),
    );
  }

  // The ambient starfield intentionally animates forever, so pumpAndSettle
  // can never settle. Advance real time in bounded steps instead.
  Future<void> advance(WidgetTester tester, Duration duration) async {
    const step = Duration(milliseconds: 50);
    for (var elapsed = Duration.zero; elapsed < duration; elapsed += step) {
      await tester.pump(step);
    }
  }

  testWidgets('splash transitions into a working main menu', (tester) async {
    await pumpApp(tester);
    expect(find.text('SHADOW SHIFT NEON'), findsOneWidget);
    await advance(tester, const Duration(seconds: 3));
    await advance(tester, const Duration(milliseconds: 600));
    expect(find.text('ENTER THE SHIFT'), findsOneWidget);
    expect(find.text('COMMAND DECK'), findsOneWidget);
    expect(find.text('ROOKIE'), findsOneWidget);
  });

  testWidgets('main menu fits a narrow phone without overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpApp(tester);
    await advance(tester, const Duration(seconds: 4));
    expect(find.text('COMMAND DECK'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Every command-deck tile stays reachable via scrolling on short screens.
    await tester.scrollUntilVisible(find.text('SETTINGS'), 160);
    expect(find.text('SETTINGS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('command deck screens fit a narrow phone without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpApp(tester);
    await advance(tester, const Duration(seconds: 4));

    for (final label in [
      'CHARACTERS',
      'SHOP',
      'RANKS',
      'ACHIEVEMENTS',
      'MISSIONS',
      'STATS',
      'SETTINGS',
    ]) {
      await tester.scrollUntilVisible(find.text(label), 160);
      await tester.tap(find.text(label));
      await advance(tester, const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull, reason: '$label overflowed');
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await advance(tester, const Duration(milliseconds: 400));
    }
  });

  testWidgets('multiplayer home and setup stay isolated on a narrow phone',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpApp(tester);
    await advance(tester, const Duration(seconds: 4));
    await tester.scrollUntilVisible(find.text('MULTIPLAYER'), 160);
    final soloBefore = ProviderScope.containerOf(
      tester.element(find.byType(ShadowShiftApp)),
    ).read(profileProvider);

    await tester.tap(find.text('MULTIPLAYER').first);
    await advance(tester, const Duration(milliseconds: 500));
    expect(find.text('MULTIPLAYER'), findsWidgets);
    await tester.scrollUntilVisible(find.text('NEW MATCH').first, 160);
    await tester.tap(find.text('NEW MATCH').first);
    await advance(tester, const Duration(milliseconds: 500));
    expect(find.text('MATCH SUMMARY'), findsOneWidget);
    expect(find.text('START GAME'), findsOneWidget);

    // Starting a match must reach the hot-seat hand-off without an
    // inherited-widget error before initState completes.
    await tester.ensureVisible(find.text('START GAME').first);
    await tester.pump();
    await tester.tap(find.text('START GAME').first);
    await advance(tester, const Duration(milliseconds: 500));
    expect(find.text('START TURN'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Opening multiplayer must not mutate solo coins, XP or achievements.
    final soloAfter = ProviderScope.containerOf(
      tester.element(find.byType(ShadowShiftApp)),
    ).read(profileProvider);
    expect(soloAfter.coins, soloBefore.coins);
    expect(soloAfter.xp, soloBefore.xp);
    expect(soloAfter.achievements, soloBefore.achievements);
  });

  testWidgets('multiplayer results celebrate a completed match cleanly',
      (tester) async {
    var record = MultiplayerMatchRecord.start(
      id: 'mp-widget',
      playedAt: DateTime(2026),
      players: const ['Player 1', 'Player 2'],
      rounds: 1,
    );
    record = MultiplayerSession.fromRecord(record).recordScore(300).record;
    record = MultiplayerSession.fromRecord(record).recordScore(120).record;
    final completed = record.completedWith(gold: 100, xp: 150);

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageProvider.overrideWithValue(StorageRepository(prefs))],
        child: MaterialApp(home: MultiplayerResultsScreen(match: completed)),
      ),
    );
    await advance(tester, const Duration(milliseconds: 600));
    expect(find.text('MATCH RESULTS'), findsOneWidget);
    expect(find.text('PLAYER 1 WINS!'), findsOneWidget);
    // Confetti and the animated trophy must not produce negative margins.
    expect(tester.takeException(), isNull);
  });

  testWidgets('achievements screen fits a narrow phone without repeated cards',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpApp(tester);
    await advance(tester, const Duration(seconds: 4));
    await tester.scrollUntilVisible(find.text('ACHIEVEMENTS'), 160);
    await tester.tap(find.text('ACHIEVEMENTS'));
    await advance(tester, const Duration(milliseconds: 500));

    expect(find.text('TOTAL UNLOCKED'), findsOneWidget);
    expect(find.text('FIRST SHIFT'), findsOneWidget);
    expect(find.text('INFINITE CHAIN'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mode and challenge screens fit a narrow phone', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpApp(tester);
    await advance(tester, const Duration(seconds: 4));
    await tester.tap(find.text('ENTER THE SHIFT'));
    await advance(tester, const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull, reason: 'mode selection overflowed');

    await tester.tap(find.text('CHALLENGE'));
    await advance(tester, const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull, reason: 'challenges overflowed');
  });

  testWidgets('unlocking a runner equips it for the next run', (tester) async {
    await pumpApp(
      tester,
      values: {
        StorageKeys.profile: jsonEncode(
          PlayerProfile(coins: 1000).toJson(),
        ),
      },
    );
    await advance(tester, const Duration(seconds: 4));

    await tester.scrollUntilVisible(find.text('CHARACTERS'), 160);
    await tester.tap(find.text('CHARACTERS'));
    await advance(tester, const Duration(milliseconds: 500));

    await tester.scrollUntilVisible(find.text('550'), 160);
    await tester.tap(find.text('550'));
    await advance(tester, const Duration(milliseconds: 500));

    final profile = ProviderScope.containerOf(
      tester.element(find.byType(ShadowShiftApp)),
    ).read(profileProvider);
    expect(profile.unlockedCharacters, contains('flux'));
    expect(profile.character, 'flux');
    expect(find.text('ACTIVE'), findsOneWidget);
    expect(find.text('FLUX'), findsNWidgets(2));

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await advance(tester, const Duration(milliseconds: 400));
    await tester.tap(find.text('ENTER THE SHIFT'));
    await advance(tester, const Duration(milliseconds: 500));
    await tester.tap(find.text('CLASSIC'));
    await advance(tester, const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
  });

  testWidgets('insufficient coins opens a sad dialog instead of a snackbar',
      (tester) async {
    await pumpApp(
      tester,
      values: {
        StorageKeys.profile: jsonEncode(
          PlayerProfile(coins: 0).toJson(),
        ),
      },
    );
    await advance(tester, const Duration(seconds: 4));

    await tester.scrollUntilVisible(find.text('CHARACTERS'), 160);
    await tester.tap(find.text('CHARACTERS'));
    await advance(tester, const Duration(milliseconds: 500));
    await tester.scrollUntilVisible(find.text('550'), 160);
    await tester.tap(find.text('550'));
    await advance(tester, const Duration(milliseconds: 400));

    expect(find.text('INSUFFICIENT COINS'), findsOneWidget);
    expect(find.textContaining('550 energy coins for FLUX'), findsOneWidget);
    expect(find.byIcon(Icons.sentiment_dissatisfied), findsOneWidget);
    expect(find.byIcon(Icons.monetization_on), findsWidgets);

    await tester.tap(find.text('OK'));
    await advance(tester, const Duration(milliseconds: 300));
    expect(find.text('INSUFFICIENT COINS'), findsNothing);
  });

  testWidgets('main menu opens mode selection', (tester) async {
    await pumpApp(tester);
    await advance(tester, const Duration(seconds: 3));
    await advance(tester, const Duration(milliseconds: 600));
    await tester.tap(find.text('ENTER THE SHIFT'));
    await advance(tester, const Duration(milliseconds: 600));
    expect(find.text('SELECT MODE'), findsOneWidget);
    expect(find.text('CLASSIC'), findsOneWidget);
    expect(find.text('TIME ATTACK'), findsOneWidget);
  });

  testWidgets('mode selection opens a challenge picker', (tester) async {
    await pumpApp(tester);
    await advance(tester, const Duration(seconds: 3));
    await advance(tester, const Duration(milliseconds: 600));
    await tester.tap(find.text('ENTER THE SHIFT'));
    await advance(tester, const Duration(milliseconds: 600));
    await tester.tap(find.text('CHALLENGE'));
    await advance(tester, const Duration(milliseconds: 600));
    expect(find.text('CHALLENGES'), findsOneWidget);
    expect(find.text('FIRST LIGHT'), findsOneWidget);
  });

  testWidgets('progress reset requires the exact keyword', (tester) async {
    await pumpApp(
      tester,
      values: {
        StorageKeys.profile: jsonEncode(
          PlayerProfile(coins: 777).toJson(),
        ),
      },
    );
    await advance(tester, const Duration(seconds: 4));
    await tester.scrollUntilVisible(find.text('SETTINGS'), 160);
    await tester.tap(find.text('SETTINGS'));
    await advance(tester, const Duration(milliseconds: 500));
    await tester.scrollUntilVisible(find.text('RESET ALL PROGRESS'), 160);
    await tester.tap(find.text('RESET ALL PROGRESS'));
    await advance(tester, const Duration(milliseconds: 400));

    final container = ProviderScope.containerOf(
      tester.element(find.byType(ShadowShiftApp)),
    );

    await tester.enterText(find.byType(TextField), 'shadowshift');
    await tester.tap(find.text('DELETE PROGRESS'));
    await advance(tester, const Duration(milliseconds: 300));
    expect(container.read(profileProvider).coins, 777,
        reason: 'wrong casing must not erase progress');
    expect(find.text('RESET PROGRESS?'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Shadowshift');
    await tester.pump();
    await tester.tap(find.text('DELETE PROGRESS'));
    await advance(tester, const Duration(milliseconds: 400));
    expect(container.read(profileProvider).coins, 0);
    expect(find.text('RESET PROGRESS?'), findsNothing);
  });
}
