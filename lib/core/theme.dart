import 'package:flutter/material.dart';
import 'package:shadowshift/core/constants.dart';

abstract final class AppTheme {
  static ThemeData get dark {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.cyan,
        brightness: Brightness.dark,
        primary: AppColors.cyan,
        secondary: AppColors.violet,
        surface: AppColors.surface,
        error: AppColors.danger,
      ),
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Segoe UI',
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(bodyColor: AppColors.text, displayColor: AppColors.text),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1.4),
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.text),
      dividerColor: AppColors.surfaceLight,
    );
  }
}

/// Reusable neon gradient used for primary actions and progress bars.
const LinearGradient neonGradient = LinearGradient(
  colors: [AppColors.cyan, AppColors.blue, AppColors.violet],
  stops: [0, 0.5, 1],
);
