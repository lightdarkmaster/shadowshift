import 'package:flutter/material.dart';

/// Tuning values for the gameplay simulation. The engine works in virtual
/// world units so that behaviour is identical on every screen aspect ratio.
abstract final class GameConfig {
  static const double worldWidth = 1000;
  static const double playerX = 205;
  static const double playerRadius = 27;
  static const double baseSpeed = 305;
  static const double maxSpeed = 690;
  static const double baseSpawnInterval = 1.12;
  static const double minSpawnInterval = 0.80;
  static const double secondsToMaxDifficulty = 190;
  static const double obstacleWidth = 74;
  static const double obstacleHeight = 250;
  static const double orbRadius = 13;
  static const double maxDeltaTime = 0.05;
  static const double shieldDuration = 14;
  static const double magnetDuration = 9;
  static const double slowDuration = 7;
  static const double doubleDuration = 9;
  static const double maxFocusEnergy = 100;
}

abstract final class AppStrings {
  static const appName = 'SHADOW SHIFT';
  static const tagline = 'PHASE. DODGE. SURVIVE.';
}

abstract final class AppColors {
  static const background = Color(0xFF05060F);
  static const surface = Color(0xFF0D1020);
  static const surfaceLight = Color(0xFF161A31);
  static const cyan = Color(0xFF35F5F1);
  static const violet = Color(0xFFA46BFF);
  static const blue = Color(0xFF3A7BFF);
  static const pink = Color(0xFFFF5BA7);
  static const gold = Color(0xFFFFD166);
  static const text = Color(0xFFEEF3FF);
  static const muted = Color(0xFF8E9AC0);
  static const danger = Color(0xFFFF4D6D);
}

abstract final class StorageKeys {
  static const profile = 'shadowshift.profile.v1';
  static const settings = 'shadowshift.settings.v1';
}
