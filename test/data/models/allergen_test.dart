// ABOUTME: Tests for the Allergen model's JSON serialization and localization logic.
// ABOUTME: Covers fromJson, toJson round-trips, and all allergenicityDisplayLocalized variants.

import 'package:flutter_test/flutter_test.dart';
import 'package:udahni/data/models/allergen.dart';

void main() {
  final testJson = {
    'id': 1,
    'name': 'Betula',
    'localized_name': 'Breza',
    'margine_top': 3,
    'margine_bottom': 9,
    'type': 1,
    'allergenicity': 2,
    'allergenicity_display': 'moderate',
  };

  group('Allergen.fromJson', () {
    test('parses all fields correctly', () {
      final allergen = Allergen.fromJson(testJson);
      expect(allergen.id, 1);
      expect(allergen.name, 'Betula');
      expect(allergen.localizedName, 'Breza');
      expect(allergen.marginTop, 3);
      expect(allergen.marginBottom, 9);
      expect(allergen.type, 1);
      expect(allergen.allergenicityIndex, 2);
      expect(allergen.allergenicityDisplay, 'moderate');
    });
  });

  group('Allergen.toJson', () {
    test('serializes all fields correctly', () {
      final allergen = Allergen.fromJson(testJson);
      final json = allergen.toJson();
      expect(json['id'], 1);
      expect(json['name'], 'Betula');
      expect(json['localized_name'], 'Breza');
      expect(json['margine_top'], 3);
      expect(json['margine_bottom'], 9);
      expect(json['type'], 1);
      expect(json['allergenicity'], 2);
      expect(json['allergenicity_display'], 'moderate');
    });

    test('round-trips through fromJson', () {
      final original = Allergen.fromJson(testJson);
      final restored = Allergen.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.allergenicityIndex, original.allergenicityIndex);
    });
  });

  group('Allergen.allergenicityDisplayLocalized', () {
    Allergen withDisplay(String display) =>
        Allergen.fromJson({...testJson, 'allergenicity_display': display});

    test('maps mild to Nizak', () {
      expect(withDisplay('mild').allergenicityDisplayLocalized, 'Nizak');
    });

    test('maps low to Nizak', () {
      expect(withDisplay('low').allergenicityDisplayLocalized, 'Nizak');
    });

    test('maps slab to Nizak', () {
      expect(withDisplay('slab').allergenicityDisplayLocalized, 'Nizak');
    });

    test('maps nizak to Nizak', () {
      expect(withDisplay('nizak').allergenicityDisplayLocalized, 'Nizak');
    });

    test('maps moderate to Srednji', () {
      expect(withDisplay('moderate').allergenicityDisplayLocalized, 'Srednji');
    });

    test('maps medium to Srednji', () {
      expect(withDisplay('medium').allergenicityDisplayLocalized, 'Srednji');
    });

    test('maps srednji to Srednji', () {
      expect(withDisplay('srednji').allergenicityDisplayLocalized, 'Srednji');
    });

    test('maps severe to Visok', () {
      expect(withDisplay('severe').allergenicityDisplayLocalized, 'Visok');
    });

    test('maps high to Visok', () {
      expect(withDisplay('high').allergenicityDisplayLocalized, 'Visok');
    });

    test('maps jak to Visok', () {
      expect(withDisplay('jak').allergenicityDisplayLocalized, 'Visok');
    });

    test('returns original value for unknown display string', () {
      expect(withDisplay('unknown_value').allergenicityDisplayLocalized, 'unknown_value');
    });

    test('is case-insensitive (trims and lowercases input)', () {
      expect(withDisplay('  MILD  ').allergenicityDisplayLocalized, 'Nizak');
      expect(withDisplay('Moderate').allergenicityDisplayLocalized, 'Srednji');
    });
  });
}
