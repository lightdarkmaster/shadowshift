import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadowshift/data/repositories/storage_repository.dart';
import 'package:shadowshift/main.dart';
import 'package:shadowshift/state/app_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpApp(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
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
