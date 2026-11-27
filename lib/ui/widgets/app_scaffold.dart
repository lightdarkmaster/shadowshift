import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadowshift/core/constants.dart';
import 'package:shadowshift/core/utils.dart';
import 'package:shadowshift/state/app_providers.dart';
import 'package:shadowshift/ui/widgets/space_background.dart';

class AppScaffold extends ConsumerWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.showBack = true,
    this.showCoins = true,
    this.actions,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final bool showBack;
  final bool showCoins;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coins = ref.watch(profileProvider.select((p) => p.coins));
    final reducedMotion = ref.watch(settingsProvider.select((s) => s.reducedMotion));
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: SpaceBackground(reducedMotion: reducedMotion)),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                  child: Row(
                    children: [
                      if (showBack)
                        IconButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.surfaceLight.withValues(alpha: 0.6),
                            side: BorderSide(color: AppColors.cyan.withValues(alpha: 0.18)),
                          ),
                        ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.8,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (subtitle != null)
                              Text(subtitle!,
                                  style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                          ],
                        ),
                      ),
                      ...?actions,
                      if (showCoins)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.bolt, size: 15, color: AppColors.gold),
                              const SizedBox(width: 5),
                              Text(formatScore(coins),
                                  style: const TextStyle(
                                      color: AppColors.gold,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(child: body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
