enum Dimension { light, shadow }

enum GameMode { classic, timeAttack, challenge, daily }

enum ObstacleKind { standard, wide, doubleStack }

enum PowerUpKind { shield, magnet, slow, double }

enum ObjectiveKind { none, survive, orbs, combo, score, switches, surviveAndOrbs }

enum RunEndReason { collision, timeUp, objectiveComplete, quit }

enum GameEvent {
  switchDimension,
  collectOrb,
  collectPowerUp,
  shieldBreak,
  dodge,
  gameOver,
  objectiveComplete,
}

extension DimensionX on Dimension {
  Dimension get other => this == Dimension.light ? Dimension.shadow : Dimension.light;
  bool get isLight => this == Dimension.light;
  bool get isShadow => this == Dimension.shadow;
  String get label => isLight ? 'LIGHT' : 'SHADOW';
}

extension GameModeX on GameMode {
  String get label => switch (this) {
        GameMode.classic => 'CLASSIC',
        GameMode.timeAttack => 'TIME ATTACK',
        GameMode.challenge => 'CHALLENGE',
        GameMode.daily => 'DAILY',
      };
  String get description => switch (this) {
        GameMode.classic => 'Endless survival. How far can you phase?',
        GameMode.timeAttack => '60 seconds. Maximum score. No mercy.',
        GameMode.challenge => 'Handcrafted objectives, unlocked in sequence.',
        GameMode.daily => 'One deterministic run for everyone, every day.',
      };
}
