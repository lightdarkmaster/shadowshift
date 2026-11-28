import 'dart:convert';
import 'dart:ui' show Size;

import 'package:material_ui/material_ui.dart' show Icons;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadowshift/core/constants.dart';
import 'package:shadowshift/data/models/profile.dart';
import 'package:shadowshift/data/repositories/storage_repository.dart';
import 'package:shadowshift/main.dart';
import 'package:shadowshift/state/app_providers.dart';
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
    expect(find.text('SHADOW SHIFT'), findsOneWidget);
    await advance(tester, const Duration(seconds: 3));
    await advance(tester, const Duration(milliseconds: 600));
    expect(find.text('ENTER THE SHIFT'), findsOneWidget);
    expect(find.text('COMMAND DECK'), findsOneWidget);
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
}
