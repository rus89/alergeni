// ABOUTME: Tests for the Pollens model's JSON serialization and date handling.
// ABOUTME: Covers fromJson, toJson, and ISO date output format.

import 'package:flutter_test/flutter_test.dart';
import 'package:udahni/data/models/pollens.dart';

void main() {
  final testJson = {
    'id': 7,
    'location': 2,
    'date': '2026-04-01',
    'concentrations': [10, 20, 30],
  };

  group('Pollens.fromJson', () {
    test('parses all fields correctly', () {
      final p = Pollens.fromJson(testJson);
      expect(p.id, 7);
      expect(p.locationId, 2);
      expect(p.date, DateTime(2026, 4, 1));
      expect(p.concentrationIds, [10, 20, 30]);
    });

    test('parses date as DateTime', () {
      final p = Pollens.fromJson(testJson);
      expect(p.date.year, 2026);
      expect(p.date.month, 4);
      expect(p.date.day, 1);
    });
  });

  group('Pollens.toJson', () {
    test('serializes date as YYYY-MM-DD string', () {
      final p = Pollens.fromJson(testJson);
      final json = p.toJson();
      expect(json['date'], '2026-04-01');
    });

    test('serializes concentrations as list', () {
      final p = Pollens.fromJson(testJson);
      final json = p.toJson();
      expect(json['concentrations'], [10, 20, 30]);
    });

    test('round-trips through fromJson', () {
      final original = Pollens.fromJson(testJson);
      final restored = Pollens.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.locationId, original.locationId);
      expect(restored.date, original.date);
      expect(restored.concentrationIds, original.concentrationIds);
    });
  });
}
