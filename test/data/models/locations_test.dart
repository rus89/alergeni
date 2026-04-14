// ABOUTME: Tests for the Locations model's JSON serialization and equality.
// ABOUTME: Covers fromJson (including lat/lng string parsing), toJson, and == operator.

import 'package:flutter_test/flutter_test.dart';
import 'package:udahni/data/models/locations.dart';

void main() {
  final testJson = {
    'id': 1,
    'name': 'Beograd',
    'latitude': '44.8125',
    'longitude': '20.4612',
    'description': 'Beograd monitoring station',
  };

  group('Locations.fromJson', () {
    test('parses all fields correctly', () {
      final loc = Locations.fromJson(testJson);
      expect(loc.id, 1);
      expect(loc.name, 'Beograd');
      expect(loc.latitude, 44.8125);
      expect(loc.longitude, 20.4612);
      expect(loc.description, 'Beograd monitoring station');
    });

    test('parses lat/lng as strings via double.tryParse', () {
      final loc = Locations.fromJson({...testJson, 'latitude': '44.5', 'longitude': '20.1'});
      expect(loc.latitude, 44.5);
      expect(loc.longitude, 20.1);
    });

    test('falls back to 0.0 for unparseable lat/lng', () {
      final loc = Locations.fromJson({...testJson, 'latitude': 'invalid', 'longitude': null});
      expect(loc.latitude, 0.0);
      expect(loc.longitude, 0.0);
    });
  });

  group('Locations.toJson', () {
    test('serializes lat/lng as strings', () {
      final loc = Locations.fromJson(testJson);
      final json = loc.toJson();
      expect(json['latitude'], isA<String>());
      expect(json['longitude'], isA<String>());
    });

    test('round-trips through fromJson', () {
      final original = Locations.fromJson(testJson);
      final restored = Locations.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.latitude, original.latitude);
      expect(restored.longitude, original.longitude);
    });
  });

  group('Locations equality', () {
    test('two locations with same id are equal', () {
      final a = Locations.fromJson(testJson);
      final b = Locations.fromJson({...testJson, 'name': 'Different Name'});
      expect(a, equals(b));
    });

    test('two locations with different ids are not equal', () {
      final a = Locations.fromJson(testJson);
      final b = Locations.fromJson({...testJson, 'id': 2});
      expect(a, isNot(equals(b)));
    });

    test('hashCode matches for equal locations', () {
      final a = Locations.fromJson(testJson);
      final b = Locations.fromJson({...testJson, 'name': 'Different'});
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
