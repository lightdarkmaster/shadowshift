import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadowshift/core/theme.dart';
import 'package:shadowshift/data/repositories/storage_repository.dart';
import 'package:shadowshift/state/app_providers.dart';
import 'package:shadowshift/ui/screens/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Start independent platform work together instead of awaiting serially.
  final prefsFuture = SharedPreferences.getInstance();
  final orientationFuture = SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  final prefs = await prefsFuture;
  await orientationFuture;
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF05060F),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  final storage = StorageRepository(prefs);
  runApp(
    ProviderScope(
      overrides: [storageProvider.overrideWithValue(storage)],
      child: const ShadowShiftApp(),
    ),
  );
}

class ShadowShiftApp extends ConsumerStatefulWidget {
  const ShadowShiftApp({super.key});

  @override
  ConsumerState<ShadowShiftApp> createState() => _ShadowShiftAppState();
}

class _ShadowShiftAppState extends ConsumerState<ShadowShiftApp>
    with WidgetsBindingObserver {
  Timer? _rolloverTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkDay();
    _scheduleNextDayCheck();
  }

  void _checkDay() => ref.read(profileProvider.notifier).ensureToday();

  /// One timer per local midnight instead of waking every minute all day.
  void _scheduleNextDayCheck() {
    _rolloverTimer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1)
        .add(const Duration(milliseconds: 50));
    final delay = nextMidnight.difference(now);
    if (delay.isNegative) return;
    _rolloverTimer = Timer(delay, () {
      if (!mounted) return;
      _checkDay();
      _scheduleNextDayCheck();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Persist any debounced slider change before the OS may suspend the app.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      ref.read(settingsProvider.notifier).flush();
    }
    // Resuming also catches manual clock or time-zone changes.
    if (state == AppLifecycleState.resumed) {
      _checkDay();
      _scheduleNextDayCheck();
    }
  }

  @override
  void dispose() {
    _rolloverTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SHADOW SHIFT',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const SplashScreen(),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(textScaler: media.textScaler.clamp(maxScaleFactor: 1.3)),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
