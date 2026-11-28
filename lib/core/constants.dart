import 'package:material_ui/material_ui.dart';

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
  static const appName = 'SHADOW SHIFT NEON';
  static const tagline = 'PHASE. DODGE. SURVIVE.';
  static const version = '1.0.0';
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

/// Calm left-green / right-purple backdrop shared by every screen.
/// Colours are deep and low-saturation so UI text stays readable and long
/// play sessions do not get hit with harsh neon contrast.
abstract final class AppGradients {
  static const leftDeep = Color(0xFF0C3A34);
  static const leftMid = Color(0xFF0A2626);
  static const rightDeep = Color(0xFF2B1B4F);
  static const rightMid = Color(0xFF16102F);
  static const centerFade = Color(0x000A0F1E);

  static const leftWash = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.center,
    colors: [leftDeep, leftMid, centerFade],
    stops: [0, 0.55, 1],
  );

  static const rightWash = LinearGradient(
    begin: Alignment.center,
    end: Alignment.centerRight,
    colors: [centerFade, rightMid, rightDeep],
    stops: [0, 0.45, 1],
  );

  /// Darkens only the outer edges, keeping the centre calm behind cards.
  static const vignette = RadialGradient(
    center: Alignment.center,
    radius: 0.95,
    colors: [Color(0x00050A14), Color(0x80050912)],
    stops: [0.35, 1],
  );
}

abstract final class StorageKeys {
  static const profile = 'shadowshift.profile.v1';
  static const settings = 'shadowshift.settings.v1';

  /// Kept under a distinct key so multiplayer data can never be decoded into
  /// the single-player profile (or vice versa).
  static const multiplayer = 'shadowshift.multiplayer.v1';
}
