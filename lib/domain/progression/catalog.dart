import 'package:material_ui/material_ui.dart';
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
    ShopItem(
      id: 'viper',
      name: 'VIPER',
      description: '+20% points from every clean dodge.',
      price: 2400,
      color: Color(0xFF9DFF5B),
      icon: Icons.rocket_launch,
    ),
    ShopItem(
      id: 'onyx',
      name: 'ONYX',
      description: 'Start each run with Orb Magnet active.',
      price: 3000,
      color: Color(0xFF7A8CB8),
      icon: Icons.nightlight,
    ),
    ShopItem(
      id: 'lumen',
      name: 'LUMEN',
      description: '+10% points from every source.',
      price: 3800,
      color: Color(0xFFFFE9A8),
      icon: Icons.brightness_2,
    ),
  ];

  static const skins = <ShopItem>[
    ShopItem(
      id: 'aurora',
      name: 'AURORA',
      description: 'Cyan-violet signature glow.',
      price: 0,
      color: Color(0xFF35F5F1),
      icon: Icons.wb_twilight,
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
    ShopItem(
      id: 'solar',
      name: 'SOLAR',
      description: 'Radiant gold supernova core and aura.',
      price: 1600,
      color: Color(0xFFFFD166),
      icon: Icons.wb_sunny,
    ),
    ShopItem(
      id: 'neon',
      name: 'NEON',
      description: 'Electric magenta circuit signature.',
      price: 2200,
      color: Color(0xFFFF5BA7),
      icon: Icons.flash_on,
    ),
    ShopItem(
      id: 'phantom',
      name: 'PHANTOM',
      description: 'Ghost-white phase plating and trail.',
      price: 3000,
      color: Color(0xFFE6F4FF),
      icon: Icons.visibility_off,
    ),
    ShopItem(
      id: 'spectrum',
      name: 'SPECTRUM',
      description: 'Prismatic core that cycles through every hue.',
      price: 3800,
      color: Color(0xFFA46BFF),
      icon: Icons.color_lens,
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
    ShopItem(
      id: 'nova',
      name: 'NOVA',
      description: 'Radiating starbursts on every phase shift.',
      price: 2000,
      color: Color(0xFFFFD166),
      icon: Icons.brightness_5,
    ),
    ShopItem(
      id: 'glitch',
      name: 'GLITCH',
      description: 'Chromatic split and scanning signal lines.',
      price: 2600,
      color: Color(0xFFFF5BA7),
      icon: Icons.graphic_eq,
    ),
    ShopItem(
      id: 'blizzard',
      name: 'BLIZZARD',
      description: 'Drifting ice crystals across the lane.',
      price: 3300,
      color: Color(0xFF9DEBFF),
      icon: Icons.cloudy_snowing,
    ),
    ShopItem(
      id: 'prism',
      name: 'PRISM',
      description: 'Rainbow trail and multi-hue shockwaves.',
      price: 4000,
      color: Color(0xFFA46BFF),
      icon: Icons.filter_vintage,
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
      description: '+8% points from every energy orb.',
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
      icon: Icons.security,
    ),
    ShopItem(
      id: 'chrono_core',
      name: 'CHRONO CORE',
      description: 'Start each run with 7s of Time Slow.',
      price: 1800,
      color: Color(0xFF3A7BFF),
      icon: Icons.hourglass_top,
    ),
    ShopItem(
      id: 'double_core',
      name: 'DOUBLE CORE',
      description: 'Start each run with Double Score active.',
      price: 2400,
      color: Color(0xFFFF5BA7),
      icon: Icons.filter_2,
    ),
    ShopItem(
      id: 'aegis_core',
      name: 'AEGIS CORE',
      description: 'Shield pickups and starts last 50% longer.',
      price: 3000,
      color: Color(0xFF35F5F1),
      icon: Icons.health_and_safety,
    ),
    ShopItem(
      id: 'momentum_core',
      name: 'MOMENTUM CORE',
      description: '+20% points from every clean dodge.',
      price: 3600,
      color: Color(0xFFFFD166),
      icon: Icons.bolt,
    ),
  ];

  /// A small floating ally that follows the runner and grants a light perk.
  /// `none` is the free starter so existing saves keep working unchanged.
  static const companions = <ShopItem>[
    ShopItem(
      id: 'none',
      name: 'NO COMPANION',
      description: 'Run solo. No ally and no bonus.',
      price: 0,
      color: Color(0xFF8E9AC0),
      icon: Icons.do_not_disturb_alt,
    ),
    ShopItem(
      id: 'wisp',
      name: 'WISP',
      description: '+5% points from every energy orb.',
      price: 600,
      color: Color(0xFF35F5F1),
      icon: Icons.lens,
    ),
    ShopItem(
      id: 'sentinel',
      name: 'SENTINEL',
      description: 'Shield effects last 25% longer.',
      price: 1200,
      color: Color(0xFFA46BFF),
      icon: Icons.stars,
    ),
    ShopItem(
      id: 'spark',
      name: 'SPARK',
      description: '+10% points from clean dodges.',
      price: 1800,
      color: Color(0xFFFFD166),
      icon: Icons.filter_hdr,
    ),
    ShopItem(
      id: 'beacon',
      name: 'BEACON',
      description: 'Start each run with Orb Magnet active.',
      price: 2400,
      color: Color(0xFF3A7BFF),
      icon: Icons.gps_fixed,
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
    String companionId = 'none',
  }) {
    var shield = characterId == 'zenith' || abilityId == 'phase_core';
    var orbs = characterId == 'flux' ? 1.15 : 1.0;
    var speed = characterId == 'echo' ? 0.94 : 1.0;
    var focus = characterId == 'spectre';
    var magnet = abilityId == 'magnet_core';
    var dodge = abilityId == 'momentum_core' ? 1.2 : 1.0;
    var shieldDuration = abilityId == 'aegis_core' ? 1.5 : 1.0;
    var score = 1.0;
    if (abilityId == 'overclock') orbs *= 1.08;

    // Runner perks.
    if (characterId == 'viper') dodge *= 1.2;
    if (characterId == 'onyx') magnet = true;
    if (characterId == 'lumen') score *= 1.1;

    // Companion perks stack with the runner and core instead of replacing them.
    switch (companionId) {
      case 'wisp':
        orbs *= 1.05;
      case 'sentinel':
        shieldDuration *= 1.25;
      case 'spark':
        dodge *= 1.1;
      case 'beacon':
        magnet = true;
    }

    return RunLoadout(
      shieldStart: shield,
      orbBonus: orbs,
      speedReduction: speed,
      focusAvailable: focus,
      magnetStart: magnet,
      slowStart: abilityId == 'chrono_core',
      doubleStart: abilityId == 'double_core',
      shieldDurationBonus: shieldDuration,
      dodgeBonus: dodge,
      scoreBonus: score,
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
    AchievementDef(
      id: 'orbs_1000',
      title: 'ORB SINGULARITY',
      description: 'Collect 1,000 energy orbs in total.',
      rewardCoins: 350,
      icon: Icons.auto_awesome,
    ),
    AchievementDef(
      id: 'shifts_100',
      title: 'PHASE APPRENTICE',
      description: 'Switch dimensions 100 times in total.',
      rewardCoins: 90,
      icon: Icons.compare_arrows,
    ),
    AchievementDef(
      id: 'survive_120',
      title: 'ENDURANCE RUN',
      description: 'Survive 120 seconds in a single run.',
      rewardCoins: 300,
      icon: Icons.schedule,
    ),
    AchievementDef(
      id: 'combo_35',
      title: 'INFINITE CHAIN',
      description: 'Reach a x8 combo multiplier.',
      rewardCoins: 500,
      icon: Icons.all_inclusive,
    ),
    AchievementDef(
      id: 'runs_10',
      title: 'WARM UP',
      description: 'Complete 10 runs.',
      rewardCoins: 100,
      icon: Icons.directions_run,
    ),
    AchievementDef(
      id: 'runs_50',
      title: 'IRON WILL',
      description: 'Complete 50 runs.',
      rewardCoins: 350,
      icon: Icons.local_fire_department,
    ),
    AchievementDef(
      id: 'streak_3',
      title: 'ON A ROLL',
      description: 'Win 3 runs in a row.',
      rewardCoins: 180,
      icon: Icons.trending_up,
    ),
    AchievementDef(
      id: 'streak_7',
      title: 'UNSTOPPABLE',
      description: 'Win 7 runs in a row.',
      rewardCoins: 450,
      icon: Icons.whatshot,
    ),
    AchievementDef(
      id: 'time_attack_2k',
      title: 'SPRINT MASTER',
      description: 'Score 2,000 points in Time Attack.',
      rewardCoins: 220,
      icon: Icons.speed,
    ),
    AchievementDef(
      id: 'daily_1500',
      title: 'DAILY DOMINATOR',
      description: 'Score 1,500 points in a Daily Challenge.',
      rewardCoins: 260,
      icon: Icons.event_available,
    ),
    AchievementDef(
      id: 'level_20',
      title: 'ELITE OPERATIVE',
      description: 'Reach player level 20.',
      rewardCoins: 600,
      icon: Icons.workspace_premium,
    ),
    AchievementDef(
      id: 'challenges_6',
      title: 'ALL CLEAR',
      description: 'Complete all six challenges.',
      rewardCoins: 600,
      icon: Icons.task_alt,
    ),
    AchievementDef(
      id: 'rank_phantom',
      title: 'PHANTOM RISEN',
      description: 'Reach the Phantom rank.',
      rewardCoins: 400,
      icon: Icons.visibility_off,
    ),
    AchievementDef(
      id: 'full_kit',
      title: 'FULL KIT',
      description: 'Own an upgrade in every shop category.',
      rewardCoins: 500,
      icon: Icons.checklist,
    ),
  ];

  /// Defensive view for UI and reward settlement: unknown or duplicated IDs
  /// can never produce repeated cards or repeated coin grants.
  static final List<AchievementDef> unique = () {
    final seen = <String>{};
    return all.where((achievement) => seen.add(achievement.id)).toList(growable: false);
  }();

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
