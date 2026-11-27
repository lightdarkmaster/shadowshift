import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadowshift/core/constants.dart';
import 'package:shadowshift/domain/services/audio_service.dart';
import 'package:shadowshift/state/app_providers.dart';
import 'package:shadowshift/ui/screens/main_menu.dart';
import 'package:shadowshift/ui/widgets/space_background.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))
      ..forward();
    final settings = ref.read(settingsProvider);
    AudioService.instance.init(settings);
    _timer = Timer(const Duration(milliseconds: 2300), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, _, _) => const MainMenu(),
          transitionsBuilder: (_, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = ref.watch(settingsProvider.select((s) => s.reducedMotion));
    final scale = Tween<double>(begin: 0.7, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    final fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 1, curve: Curves.easeOut)),
    );
    return Scaffold(
      body: Stack(
        children: [
          SpaceBackground(reducedMotion: reducedMotion),
          Center(
            child: FadeTransition(
              opacity: fade,
              child: ScaleTransition(
                scale: scale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 122,
                      height: 122,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [AppColors.cyan, AppColors.violet],
                        ),
                        boxShadow: [
                          BoxShadow(color: AppColors.cyan.withValues(alpha: 0.5), blurRadius: 45),
                        ],
                      ),
                      child: const Icon(Icons.flash_on, size: 62, color: Colors.white),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      AppStrings.appName,
                      style: TextStyle(
                        fontSize: 31,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 7,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      AppStrings.tagline,
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 3.4,
                        color: AppColors.cyan,
                      ),
                    ),
                    const SizedBox(height: 44),
                    SizedBox(
                      width: 170,
                      child: LinearProgressIndicator(
                        color: AppColors.violet,
                        backgroundColor: AppColors.surfaceLight,
                        minHeight: 3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
