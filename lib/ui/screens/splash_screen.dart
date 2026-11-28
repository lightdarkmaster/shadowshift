import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadowshift/core/constants.dart';
import 'package:shadowshift/domain/services/audio_service.dart';
import 'package:shadowshift/state/app_providers.dart';
import 'package:shadowshift/ui/screens/main_menu.dart';
import 'package:shadowshift/ui/widgets/design.dart';
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
    final skinId = ref.watch(profileProvider.select((p) => p.skin));
    final effectId = ref.watch(profileProvider.select((p) => p.effect));
    final scale = Tween<double>(begin: 0.7, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    final fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 1, curve: Curves.easeOut)),
    );
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: SpaceBackground(
              reducedMotion: reducedMotion,
              skinId: skinId,
              effectId: effectId,
            ),
          ),
          SafeArea(
            child: Center(
              child: FadeTransition(
                opacity: fade,
                child: ScaleTransition(
                  scale: scale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/shadowshift_logo.png',
                        width: 136,
                        height: 136,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: AppLayout.xl + AppLayout.md),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: GradientLabel(
                          AppStrings.appName,
                          fontSize: 31,
                          letterSpacing: 5,
                        ),
                      ),
                      const SizedBox(height: AppLayout.md),
                      const Text(
                        AppStrings.tagline,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 3,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: AppLayout.xxl + AppLayout.lg),
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
          ),
        ],
      ),
    );
  }
}
