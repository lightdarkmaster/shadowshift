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

    test('unknown ids fall back to the default loadout', () {
      final loadout = Catalog.loadout(
        characterId: 'missing',
        abilityId: 'missing',
      );
      expect(loadout.orbBonus, 1.0);
      expect(loadout.shieldStart, isFalse);
    });
  });
}
