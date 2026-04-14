// ABOUTME: Tests for the AllergenTypes model's JSON serialization.
// ABOUTME: Covers fromJson and toJson round-trips.

import 'package:flutter_test/flutter_test.dart';
import 'package:udahni/data/models/allergen_types.dart';

void main() {
  group('AllergenTypes.fromJson', () {
    test('parses id and name correctly', () {
      final type = AllergenTypes.fromJson({'id': 2, 'name': 'Trave'});
      expect(type.id, 2);
      expect(type.name, 'Trave');
    });
  });

  group('AllergenTypes.toJson', () {
    test('serializes id and name correctly', () {
      final type = AllergenTypes(id: 2, name: 'Trave');
      final json = type.toJson();
      expect(json['id'], 2);
      expect(json['name'], 'Trave');
    });

    test('round-trips through fromJson', () {
      final original = AllergenTypes(id: 3, name: 'Korov');
      final restored = AllergenTypes.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.name, original.name);
    });
  });
}
