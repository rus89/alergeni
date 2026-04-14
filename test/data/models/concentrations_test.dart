// ABOUTME: Tests for the Concentrations model's JSON serialization.
// ABOUTME: Covers fromJson and toJson round-trips.

import 'package:flutter_test/flutter_test.dart';
import 'package:udahni/data/models/concentrations.dart';

void main() {
  final testJson = {'id': 5, 'allergen': 3, 'value': 42, 'pollen': 10};

  group('Concentrations.fromJson', () {
    test('parses all fields correctly', () {
      final c = Concentrations.fromJson(testJson);
      expect(c.id, 5);
      expect(c.allergenId, 3);
      expect(c.value, 42);
      expect(c.pollenId, 10);
    });
  });

  group('Concentrations.toJson', () {
    test('serializes using API field names', () {
      final c = Concentrations.fromJson(testJson);
      final json = c.toJson();
      expect(json['id'], 5);
      expect(json['allergen'], 3);
      expect(json['value'], 42);
      expect(json['pollen'], 10);
    });

    test('round-trips through fromJson', () {
      final original = Concentrations.fromJson(testJson);
      final restored = Concentrations.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.allergenId, original.allergenId);
      expect(restored.value, original.value);
      expect(restored.pollenId, original.pollenId);
    });
  });
}
