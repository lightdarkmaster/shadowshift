import 'package:flutter_test/flutter_test.dart';
import 'package:shadowshift/domain/progression/catalog.dart';

void main() {
  group('Catalog.loadout', () {
    test('the default runner grants no bonus', () {
      final loadout = Catalog.loadout(characterId: 'nyx', abilityId: 'none');
      expect(loadout.shieldStart, isFalse);
      expect(loadout.orbBonus, 1.0);
      expect(loadout.speedReduction, 1.0);
      expect(loadout.focusAvailable, isFalse);
      expect(loadout.magnetStart, isFalse);
      expect(loadout.scoreBonus, 1.0);
    });

    test('each unlocked runner applies its advertised perk', () {
      expect(
        Catalog.loadout(characterId: 'flux', abilityId: 'none').orbBonus,
        closeTo(1.15, 0.0001),
      );
      expect(
        Catalog.loadout(characterId: 'echo', abilityId: 'none').speedReduction,
        closeTo(0.94, 0.0001),
      );
      expect(
        Catalog.loadout(characterId: 'spectre', abilityId: 'none').focusAvailable,
        isTrue,
      );
      expect(
        Catalog.loadout(characterId: 'zenith', abilityId: 'none').shieldStart,
        isTrue,
      );
    });

    test('the new runners apply their advertised perks', () {
      expect(
        Catalog.loadout(characterId: 'viper', abilityId: 'none').dodgeBonus,
        closeTo(1.2, 0.0001),
      );
      expect(
        Catalog.loadout(characterId: 'onyx', abilityId: 'none').magnetStart,
        isTrue,
      );
      expect(
        Catalog.loadout(characterId: 'lumen', abilityId: 'none').scoreBonus,
        closeTo(1.1, 0.0001),
      );
    });

    test('companions stack with runners and cores', () {
      final wisp = Catalog.loadout(
        characterId: 'flux',
        abilityId: 'none',
        companionId: 'wisp',
      );
      expect(wisp.orbBonus, closeTo(1.15 * 1.05, 0.0001));

      final sentinel = Catalog.loadout(
        characterId: 'nyx',
        abilityId: 'aegis_core',
        companionId: 'sentinel',
      );
      expect(sentinel.shieldDurationBonus, closeTo(1.5 * 1.25, 0.0001));

      final spark = Catalog.loadout(
        characterId: 'viper',
        abilityId: 'none',
        companionId: 'spark',
      );
      expect(spark.dodgeBonus, closeTo(1.2 * 1.1, 0.0001));

      final beacon = Catalog.loadout(
        characterId: 'nyx',
        abilityId: 'none',
        companionId: 'beacon',
      );
      expect(beacon.magnetStart, isTrue);
    });

    test('cores stack with character perks', () {
      final loadout = Catalog.loadout(
        characterId: 'flux',
        abilityId: 'overclock',
      );
      expect(loadout.orbBonus, closeTo(1.15 * 1.08, 0.0001));

      final shielded = Catalog.loadout(
        characterId: 'nyx',
        abilityId: 'phase_core',
      );
      expect(shielded.shieldStart, isTrue);
    });

    test('each new core applies its advertised perk', () {
      final chrono = Catalog.loadout(
        characterId: 'nyx',
        abilityId: 'chrono_core',
      );
      expect(chrono.slowStart, isTrue);
      expect(chrono.doubleStart, isFalse);

      final doubleCore = Catalog.loadout(
        characterId: 'nyx',
        abilityId: 'double_core',
      );
      expect(doubleCore.doubleStart, isTrue);

      final aegis = Catalog.loadout(
        characterId: 'nyx',
        abilityId: 'aegis_core',
      );
      expect(aegis.shieldDurationBonus, closeTo(1.5, 0.0001));

      final momentum = Catalog.loadout(
        characterId: 'nyx',
        abilityId: 'momentum_core',
      );
      expect(momentum.dodgeBonus, closeTo(1.2, 0.0001));
    });

    test('unknown ids fall back to the default loadout', () {
      final loadout = Catalog.loadout(
        characterId: 'missing',
        abilityId: 'missing',
      );
      expect(loadout.orbBonus, 1.0);
      expect(loadout.shieldStart, isFalse);
      expect(loadout.slowStart, isFalse);
      expect(loadout.doubleStart, isFalse);
      expect(loadout.shieldDurationBonus, 1.0);
      expect(loadout.dodgeBonus, 1.0);
      expect(loadout.scoreBonus, 1.0);
    });

    test('an unknown companion is a no-op', () {
      final loadout = Catalog.loadout(
        characterId: 'nyx',
        abilityId: 'none',
        companionId: 'missing',
      );
      expect(loadout.scoreBonus, 1.0);
      expect(loadout.orbBonus, 1.0);
      expect(loadout.magnetStart, isFalse);
    });
  });

  group('Shop catalog', () {
    test('every category has unique ids and a free starter', () {
      for (final items in [
        Catalog.characters,
        Catalog.skins,
        Catalog.effects,
        Catalog.abilities,
        Catalog.companions,
      ]) {
        expect(items.map((e) => e.id).toSet().length, items.length);
        expect(items.any((e) => e.price == 0), isTrue);
        for (final item in items) {
          expect(item.name, isNotEmpty);
          expect(item.description, isNotEmpty);
          expect(item.price, greaterThanOrEqualTo(0));
        }
      }
    });

    test('icons are unique across every selectable category', () {
      final items = [
        ...Catalog.characters,
        ...Catalog.skins,
        ...Catalog.effects,
        ...Catalog.abilities,
        ...Catalog.companions,
      ];
      expect(items.map((e) => e.icon).toSet().length, items.length);
    });

    test('the expanded cosmetic and core ranges are available', () {
      expect(
        Catalog.skins.map((e) => e.id),
        containsAll(['solar', 'neon', 'phantom', 'spectrum']),
      );
      expect(
        Catalog.effects.map((e) => e.id),
        containsAll(['nova', 'glitch', 'blizzard', 'prism']),
      );
      expect(
        Catalog.abilities.map((e) => e.id),
        containsAll([
          'chrono_core',
          'double_core',
          'aegis_core',
          'momentum_core',
        ]),
      );
      expect(
        Catalog.characters.map((e) => e.id),
        containsAll(['viper', 'onyx', 'lumen']),
      );
      expect(
        Catalog.companions.map((e) => e.id),
        containsAll(['wisp', 'sentinel', 'spark', 'beacon']),
      );
    });
  });
}
