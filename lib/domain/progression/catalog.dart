import 'package:flutter/material.dart';
import 'package:shadowshift/domain/game/engine.dart';
import 'package:shadowshift/domain/game/entities.dart';
import 'package:shadowshift/domain/game/enums.dart';

class ShopItem {
  const ShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.color,
    this.icon = Icons.bolt,
  });

  final String id;
  final String name;
  final String description;
  final int price;
  final Color color;
  final IconData icon;
}

abstract final class Catalog {
  static const characters = <ShopItem>[
    ShopItem(
      id: 'nyx',
      name: 'NYX',
      description: 'Balanced phase runner. Standard reacting systems.',
      price: 0,
      color: Color(0xFF35F5F1),
      icon: Icons.person,
    ),
    ShopItem(
      id: 'flux',
      name: 'FLUX',
      description: '+15% points from every energy orb.',
      price: 550,
      color: Color(0xFF3A7BFF),
      icon: Icons.auto_awesome,
    ),
    ShopItem(
      id: 'echo',
      name: 'ECHO',
      description: 'Obstacles move 6% slower. Easier reaction windows.',
      price: 850,
      color: Color(0xFFA46BFF),
      icon: Icons.blur_on,
    ),
    ShopItem(
      id: 'spectre',
      name: 'SPECTRE',
      description: 'Hold the screen to slow time (Chrono Focus).',
      price: 1300,
      color: Color(0xFFFF5BA7),
      icon: Icons.slow_motion_video,
    ),
    ShopItem(
      id: 'zenith',
      name: 'ZENITH',
      description: 'Begin every run with a Phase Shield.',
      price: 1900,
      color: Color(0xFFFFD166),
      icon: Icons.shield,
    ),
  ];

  static const skins = <ShopItem>[
    ShopItem(
      id: 'aurora',
      name: 'AURORA',
      description: 'Cyan-violet signature glow.',
      price: 0,
      color: Color(0xFF35F5F1),
      icon: Icons.palette,
    ),
    ShopItem(
      id: 'inferno',
      name: 'INFERNO',
      description: 'Hot magenta and amber highlights.',
      price: 400,
      color: Color(0xFFFF8A4C),
      icon: Icons.local_fire_department,
    ),
    ShopItem(
      id: 'toxic',
      name: 'TOXIC',
      description: 'Acid green spectral trail.',
      price: 700,
      color: Color(0xFF9DFF5B),
      icon: Icons.science,
    ),
    ShopItem(
      id: 'frost',
      name: 'FROST',
      description: 'Icy blue crystalline plating.',
      price: 1100,
      color: Color(0xFF9DEBFF),
      icon: Icons.ac_unit,
    ),
  ];

  static const effects = <ShopItem>[
    ShopItem(
      id: 'classic',
      name: 'CLASSIC',
      description: 'Clean phase ripples.',
      price: 0,
      color: Color(0xFF35F5F1),
      icon: Icons.blur_circular,
    ),
    ShopItem(
      id: 'comet',
      name: 'COMET',
      description: 'Long, bright particle streaks.',
      price: 500,
      color: Color(0xFF3A7BFF),
      icon: Icons.travel_explore,
    ),
    ShopItem(
      id: 'pulse',
      name: 'PULSE',
      description: 'Expanding concentric shockwaves.',
      price: 900,
      color: Color(0xFFA46BFF),
      icon: Icons.radio_button_checked,
    ),
    ShopItem(
      id: 'void',
      name: 'VOID',
      description: 'Dark violet with ember sparks.',
      price: 1500,
      color: Color(0xFFFF5BA7),
      icon: Icons.dark_mode,
    ),
  ];

  static const abilities = <ShopItem>[
    ShopItem(
      id: 'none',
      name: 'NO CORE',
      description: 'No passive ability equipped.',
      price: 0,
      color: Color(0xFF8E9AC0),
      icon: Icons.block,
    ),
    ShopItem(
      id: 'overclock',
      name: 'OVERCLOCK',
      description: '+8% score from all sources.',
      price: 600,
      color: Color(0xFF35F5F1),
      icon: Icons.trending_up,
    ),
    ShopItem(
      id: 'magnet_core',
      name: 'MAGNET CORE',
      description: 'Start each run with Orb Magnet active.',
      price: 1000,
      color: Color(0xFFFFD166),
      icon: Icons.settings_input_antenna,
    ),
    ShopItem(
      id: 'phase_core',
      name: 'PHASE CORE',
      description: 'Start each run with a Phase Shield.',
      price: 1400,
      color: Color(0xFFA46BFF),
      icon: Icons.shield,
    ),
  ];

  static ShopItem? character(String id) =>
      characters.where((item) => item.id == id).cast<ShopItem?>().firstWhere(
            (item) => item?.id == id,
            orElse: () => null,
          );

  static ShopItem find(List<ShopItem> items, String id) =>
      items.firstWhere((item) => item.id == id, orElse: () => items.first);

  static RunLoadout loadout({
    required String characterId,
    required String abilityId,
  }) {
    var shield = characterId == 'zenith' || abilityId == 'phase_core';
    var orbs = characterId == 'flux' ? 1.15 : 1.0;
    var speed = characterId == 'echo' ? 0.94 : 1.0;
    var focus = characterId == 'spectre';
    var magnet = abilityId == 'magnet_core';
    if (abilityId == 'overclock') orbs *= 1.08;
    return RunLoadout(
      shieldStart: shield,
      orbBonus: orbs,
      speedReduction: speed,
      focusAvailable: focus,
      magnetStart: magnet,
    );
  }
}

class ChallengeDef {
  const ChallengeDef({
    required this.id,
    required this.title,
    required this.description,
    required this.objective,
    required this.rewardCoins,
    required this.rewardXp,
  });

  final String id;
  final String title;
  final String description;
  final RunObjective objective;
  final int rewardCoins;
  final int rewardXp;
}

abstract final class Challenges {
  static const List<ChallengeDef> all = [
    ChallengeDef(
      id: 'first_light',
      title: 'FIRST LIGHT',
      description: 'Survive for 30 seconds.',
      objective: RunObjective(kind: ObjectiveKind.survive, target: 30, title: 'Survive 30s'),
      rewardCoins: 120,
      rewardXp: 60,
    ),
    ChallengeDef(
      id: 'collector',
      title: 'COLLECTOR',
      description: 'Collect 18 energy orbs in one run.',
      objective: RunObjective(kind: ObjectiveKind.orbs, target: 18, title: 'Collect 18 orbs'),
      rewardCoins: 180,
      rewardXp: 80,
    ),
    ChallengeDef(
      id: 'chain',
      title: 'CHAIN REACTION',
      description: 'Reach a x6 combo multiplier (25 chained dodges/orbs).',
      objective: RunObjective(kind: ObjectiveKind.combo, target: 25, title: 'Reach 25 combo'),
      rewardCoins: 240,
      rewardXp: 110,
    ),
    ChallengeDef(
      id: 'sprinter',
      title: 'SPRINTER',
      description: 'Score 6,000 points in a single run.',
      objective: RunObjective(kind: ObjectiveKind.score, target: 6000, title: 'Score 6,000'),
      rewardCoins: 320,
      rewardXp: 140,
    ),
    ChallengeDef(
      id: 'phase_master',
      title: 'PHASE MASTER',
      description: 'Switch dimensions 60 times in one run.',
      objective: RunObjective(kind: ObjectiveKind.switches, target: 60, title: 'Shift 60 times'),
      rewardCoins: 400,
      rewardXp: 180,
    ),
    ChallengeDef(
      id: 'endurance',
      title: 'ENDURANCE',
      description: 'Survive 75 seconds and collect 35 orbs.',
      objective: RunObjective(
        kind: ObjectiveKind.surviveAndOrbs,
        target: 75,
        secondaryTarget: 35,
        title: '75s + 35 orbs',
      ),
      rewardCoins: 650,
      rewardXp: 300,
    ),
  ];

  static ChallengeDef? byId(String id) {
    for (final challenge in all) {
      if (challenge.id == id) return challenge;
    }
    return null;
  }

  static ChallengeDef? nextUncompleted(Set<String> completed) {
    for (final challenge in all) {
      if (!completed.contains(challenge.id)) return challenge;
    }
    return null;
  }
}

class AchievementDef {
  const AchievementDef({
    required this.id,
    required this.title,
    required this.description,
    required this.rewardCoins,
    required this.icon,
  });

  final String id;
  final String title;
  final String description;
  final int rewardCoins;
  final IconData icon;
}

abstract final class Achievements {
  static const List<AchievementDef> all = [
    AchievementDef(
      id: 'first_run',
      title: 'FIRST SHIFT',
      description: 'Complete your first run.',
      rewardCoins: 40,
      icon: Icons.play_arrow,
    ),
    AchievementDef(
      id: 'orbs_100',
      title: 'ENERGY HOARDER',
      description: 'Collect 100 energy orbs in total.',
      rewardCoins: 80,
      icon: Icons.bolt,
    ),
    AchievementDef(
      id: 'orbs_500',
      title: 'ENERGY TITAN',
      description: 'Collect 500 energy orbs in total.',
      rewardCoins: 200,
      icon: Icons.flash_on,
    ),
    AchievementDef(
      id: 'combo_10',
      title: 'UNBROKEN',
      description: 'Reach a x3 combo multiplier.',
      rewardCoins: 100,
      icon: Icons.link,
    ),
    AchievementDef(
      id: 'combo_25',
      title: 'CHAIN GOD',
      description: 'Reach a x6 combo multiplier.',
      rewardCoins: 250,
      icon: Icons.power,
    ),
    AchievementDef(
      id: 'score_5k',
      title: 'HIGH VOLTAGE',
      description: 'Score 5,000 points in one run.',
      rewardCoins: 120,
      icon: Icons.show_chart,
    ),
    AchievementDef(
      id: 'score_20k',
      title: 'LEGENDARY RUN',
      description: 'Score 20,000 points in one run.',
      rewardCoins: 400,
      icon: Icons.emoji_events,
    ),
    AchievementDef(
      id: 'survive_60',
      title: 'MARATHON',
      description: 'Survive 60 seconds in a single run.',
      rewardCoins: 150,
      icon: Icons.timer,
    ),
    AchievementDef(
      id: 'shifts_500',
      title: 'DIMENSION WALKER',
      description: 'Switch dimensions 500 times in total.',
      rewardCoins: 180,
      icon: Icons.swap_horiz,
    ),
    AchievementDef(
      id: 'runs_25',
      title: 'REGULAR',
      description: 'Complete 25 runs.',
      rewardCoins: 160,
      icon: Icons.repeat,
    ),
    AchievementDef(
      id: 'challenges_3',
      title: 'PROBLEM SOLVER',
      description: 'Complete 3 challenges.',
      rewardCoins: 220,
      icon: Icons.extension,
    ),
    AchievementDef(
      id: 'level_10',
      title: 'VETERAN',
      description: 'Reach player level 10.',
      rewardCoins: 300,
      icon: Icons.military_tech,
    ),
  ];

  static AchievementDef? byId(String id) {
    for (final achievement in all) {
      if (achievement.id == id) return achievement;
    }
    return null;
  }
}

class MissionDef {
  const MissionDef({
    required this.id,
    required this.title,
    required this.kind,
    required this.target,
    required this.rewardCoins,
    required this.rewardXp,
  });

  final String id;
  final ObjectiveKind kind;
  final String title;
  final int target;
  final int rewardCoins;
  final int rewardXp;
}
