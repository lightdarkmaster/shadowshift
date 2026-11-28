/// Concrete, easy-to-read examples shown when a shop item is tapped.
///
/// The copy here is intentionally separate from [ShopItem.description] so the
/// list can stay short while the detail dialog explains exactly what changes
/// during a run.
class ShopExample {
  const ShopExample({
    required this.title,
    required this.detail,
    required this.before,
    required this.after,
  });

  final String title;
  final String detail;
  final String before;
  final String after;
}

abstract final class ShopExamples {
  static const Map<String, ShopExample> _items = {
    // Skins ---------------------------------------------------------------
    'skin:aurora': ShopExample(
      title: 'Cyan arrival, violet fade',
      detail:
          'A clean dodge flashes cyan, then settles into a violet trail. This is visual only: score and timing stay exactly the same.',
      before: 'BASE GLOW',
      after: 'CYAN -> VIOLET',
    ),
    'skin:inferno': ShopExample(
      title: 'Hot core, magenta wake',
      detail:
          'The runner burns amber at the centre and leaves a hot magenta wake behind every phase shift.',
      before: 'BASE GLOW',
      after: 'AMBER -> MAGENTA',
    ),
    'skin:toxic': ShopExample(
      title: 'Acid ghost trail',
      detail:
          'Each shift leaves a lime afterimage that fades back into the lane before the next obstacle.',
      before: 'BASE GLOW',
      after: 'ACID GREEN',
    ),
    'skin:frost': ShopExample(
      title: 'Frosted plating',
      detail:
          'The runner reads like pale ice and the trail breaks into small crystal-blue shards.',
      before: 'BASE GLOW',
      after: 'ICE BLUE',
    ),
    'skin:solar': ShopExample(
      title: 'Supernova aura',
      detail:
          'Dodges pop with a gold flare, like a tiny sun going off at the runner position.',
      before: 'BASE GLOW',
      after: 'GOLD FLARE',
    ),
    'skin:neon': ShopExample(
      title: 'Circuit signature',
      detail:
          'The trail looks like a glowing magenta circuit running down the lane behind you.',
      before: 'BASE GLOW',
      after: 'MAGENTA CIRCUIT',
    ),
    'skin:phantom': ShopExample(
      title: 'Ghost afterimage',
      detail:
          'The runner dims to ghost white and leaves a soft pale double for a moment after a shift.',
      before: 'BASE GLOW',
      after: 'GHOST WHITE',
    ),
    'skin:spectrum': ShopExample(
      title: 'Cycling prism',
      detail:
          'Unlike AURORA, the hue keeps rotating: one shift glows cyan, the next magenta, then gold.',
      before: 'BASE GLOW',
      after: 'ALL HUES',
    ),

    // Effects -------------------------------------------------------------
    'effect:classic': ShopExample(
      title: 'One clean ripple',
      detail:
          'Every phase shift sends out a single cyan ring. Easy to read, with no extra clutter in the lane.',
      before: 'BASIC RIPPLE',
      after: 'CYAN RING',
    ),
    'effect:comet': ShopExample(
      title: 'Particle streaks',
      detail:
          'Dodges throw long blue streaks down the lane instead of round rings.',
      before: 'BASIC RIPPLE',
      after: 'BLUE STREAKS',
    ),
    'effect:pulse': ShopExample(
      title: 'Layered shockwaves',
      detail:
          'A shift releases two or three violet rings that expand one after another.',
      before: 'BASIC RIPPLE',
      after: '2-3 RINGS',
    ),
    'effect:void': ShopExample(
      title: 'Dark ripples, pink embers',
      detail:
          'The ripples stay dim and violet while small pink embers rise from the impact point.',
      before: 'BASIC RIPPLE',
      after: 'DARK + EMBERS',
    ),
    'effect:nova': ShopExample(
      title: 'Starburst on every shift',
      detail:
          'Each phase throws gold rays outward, like a mini supernova at the runner.',
      before: 'BASIC RIPPLE',
      after: 'GOLD RAYS',
    ),
    'effect:glitch': ShopExample(
      title: 'Signal split',
      detail:
          'The runner briefly separates into colour-shifted copies with thin scanning lines across the lane.',
      before: 'BASIC RIPPLE',
      after: 'RGB SPLIT',
    ),
    'effect:blizzard': ShopExample(
      title: 'Drifting crystals',
      detail:
          'Pale blue ice flakes drift across the lane after each phase instead of a plain ring.',
      before: 'BASIC RIPPLE',
      after: 'ICE CRYSTALS',
    ),
    'effect:prism': ShopExample(
      title: 'Multi-hue waves',
      detail:
          'The wake changes colour and every shockwave carries several hues at once.',
      before: 'BASIC RIPPLE',
      after: 'RAINBOW WAVES',
    ),

    // Cores ---------------------------------------------------------------
    'ability:none': ShopExample(
      title: 'No passive ability',
      detail:
          'Nothing changes at the start of a run. A 100-point orb is still worth 100 points.',
      before: '100 PTS',
      after: '100 PTS',
    ),
    'ability:overclock': ShopExample(
      title: 'Orb points +8%',
      detail:
          'Every energy orb is scored 8% higher for the whole run. Dodge points are unchanged.',
      before: '100 PTS',
      after: '108 PTS',
    ),
    'ability:magnet_core': ShopExample(
      title: 'Orb Magnet at start',
      detail:
          'From the first second, nearby orbs curve toward you for 9 seconds. The magnet still expires normally.',
      before: 'COLLECT MANUALLY',
      after: 'AUTO-PULL 9S',
    ),
    'ability:phase_core': ShopExample(
      title: 'Phase Shield at start',
      detail:
          'The first obstacle contact is absorbed instead of ending the run. The shield icon shows it is active.',
      before: '1 HIT = RUN OVER',
      after: '1 HIT BLOCKED',
    ),
    'ability:chrono_core': ShopExample(
      title: 'Time Slow at start',
      detail:
          'Obstacles move at 64% speed for the first 7 seconds, giving you a longer reaction window.',
      before: '100% SPEED',
      after: '64% FOR 7S',
    ),
    'ability:double_core': ShopExample(
      title: 'Double Score at start',
      detail:
          'All points count double for 9 seconds, including distance, orbs, and clean dodges.',
      before: '100 PTS',
      after: '200 PTS',
    ),
    'ability:aegis_core': ShopExample(
      title: 'Shields last 50% longer',
      detail:
          'Both the start shield and shield pickups stay active for half again as long.',
      before: '14S SHIELD',
      after: '21S SHIELD',
    ),
    'ability:momentum_core': ShopExample(
      title: 'Dodge points +20%',
      detail:
          'Clean dodges are worth 20% more for the whole run. Orb points are unchanged.',
      before: '100 PTS',
      after: '120 PTS',
    ),

    // Companions ----------------------------------------------------------
    'companion:none': ShopExample(
      title: 'Solo run',
      detail:
          'No ally appears beside the runner and no bonus is added to your score.',
      before: 'NO ALLY',
      after: 'NO BONUS',
    ),
    'companion:wisp': ShopExample(
      title: 'Orb points +5%',
      detail:
          'A tiny cyan wisp floats beside the runner and adds 5% to every energy orb collected.',
      before: '100 PTS',
      after: '105 PTS',
    ),
    'companion:sentinel': ShopExample(
      title: 'Shield uptime +25%',
      detail:
          'The violet sentinel extends every shield you start with or pick up during the run.',
      before: '14S SHIELD',
      after: '17.5S SHIELD',
    ),
    'companion:spark': ShopExample(
      title: 'Dodge points +10%',
      detail:
          'The gold spark grants 10% more points for clean dodges. Orb points are unchanged.',
      before: '100 PTS',
      after: '110 PTS',
    ),
    'companion:beacon': ShopExample(
      title: 'Orb Magnet at start',
      detail:
          'The beacon trails the runner and pulls nearby orbs in for the first 9 seconds.',
      before: 'COLLECT MANUALLY',
      after: 'AUTO-PULL 9S',
    ),
  };

  static ShopExample forItem(String category, String id) =>
      _items['$category:$id'] ??
      const ShopExample(
        title: 'Preview unavailable',
        detail: 'This item has no extra example yet.',
        before: 'CURRENT',
        after: 'UPGRADED',
      );
}
