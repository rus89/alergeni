// ABOUTME: Tests for the Site model's JSON serialization including nullable fields.
// ABOUTME: Covers fromJson, toJson, and null handling for date and allergenName.

import 'package:flutter_test/flutter_test.dart';
import 'package:udahni/data/models/site.dart';

void main() {
  final testJson = {
    'location': 1,
    'date': '2026-04-01',
    'allergen': 3,
    'allergen_name': 'Betula',
    'allergenicity': 2,
    'level': 4,
    'trend': 3,
    'week': 14,
  };

  group('Site.fromJson', () {
    test('parses all fields correctly', () {
      final site = Site.fromJson(testJson);
      expect(site.locationId, 1);
      expect(site.date, '2026-04-01');
      expect(site.allergenId, 3);
      expect(site.allergenName, 'Betula');
      expect(site.allergenicityIndex, 2);
      expect(site.level, 4);
      expect(site.trend, 3);
      expect(site.week, 14);
    });

    test('parses null date correctly', () {
      final site = Site.fromJson({...testJson, 'date': null});
      expect(site.date, isNull);
    });

    test('parses null allergenName correctly', () {
      final site = Site.fromJson({...testJson, 'allergen_name': null});
      expect(site.allergenName, isNull);
    });
  });

  group('Site.toJson', () {
    test('serializes all fields correctly', () {
      final site = Site.fromJson(testJson);
      final json = site.toJson();
      expect(json['location'], 1);
      expect(json['allergen'], 3);
      expect(json['allergenicity'], 2);
      expect(json['level'], 4);
      expect(json['trend'], 3);
      expect(json['week'], 14);
    });

    test('round-trips through fromJson', () {
      final original = Site.fromJson(testJson);
      final restored = Site.fromJson(original.toJson());
      expect(restored.locationId, original.locationId);
      expect(restored.allergenId, original.allergenId);
      expect(restored.level, original.level);
      expect(restored.trend, original.trend);
      expect(restored.week, original.week);
    });
  });
}
