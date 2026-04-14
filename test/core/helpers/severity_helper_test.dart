// ABOUTME: Tests for SeverityHelper mapping concentration values and allergenicity indices.
// ABOUTME: Covers label ranges, base colors, concentration-adjusted colors, and allergenicity labels.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udahni/core/helpers/severity_helper.dart';
import 'package:udahni/core/theme/app_theme.dart';

void main() {
  group('SeverityHelper.concentrationLabel', () {
    test('returns Nema for value 0', () {
      expect(SeverityHelper.concentrationLabel(0), 'Nema');
    });

    test('returns Niska for values in low range (1-10)', () {
      expect(SeverityHelper.concentrationLabel(1), 'Niska');
      expect(SeverityHelper.concentrationLabel(10), 'Niska');
    });

    test('returns Srednja for values in medium range (11-50)', () {
      expect(SeverityHelper.concentrationLabel(11), 'Srednja');
      expect(SeverityHelper.concentrationLabel(50), 'Srednja');
    });

    test('returns Visoka for values in high range (51+)', () {
      expect(SeverityHelper.concentrationLabel(51), 'Visoka');
      expect(SeverityHelper.concentrationLabel(1000), 'Visoka');
    });
  });

  group('SeverityHelper.allergenicityBaseColor', () {
    test('returns severityLow for index 1', () {
      expect(SeverityHelper.allergenicityBaseColor(1), AppTheme.severityLow);
    });

    test('returns severityMedium for index 2', () {
      expect(SeverityHelper.allergenicityBaseColor(2), AppTheme.severityMedium);
    });

    test('returns severityHigh for index 3', () {
      expect(SeverityHelper.allergenicityBaseColor(3), AppTheme.severityHigh);
    });

    test('returns grey for unknown index', () {
      expect(SeverityHelper.allergenicityBaseColor(0), Colors.grey);
      expect(SeverityHelper.allergenicityBaseColor(99), Colors.grey);
    });
  });

  group('SeverityHelper.allergenicityColorForConcentration', () {
    test('returns full base color for high concentration (51+)', () {
      final full = SeverityHelper.allergenicityBaseColor(2);
      final result = SeverityHelper.allergenicityColorForConcentration(
        allergenicityIndex: 2,
        concentration: 51,
      );
      expect(result, full);
    });

    test('returns lightened color for medium concentration (11-50)', () {
      final full = SeverityHelper.allergenicityBaseColor(2);
      final result = SeverityHelper.allergenicityColorForConcentration(
        allergenicityIndex: 2,
        concentration: 25,
      );
      // Should be lighter than the base color
      final fullHsl = HSLColor.fromColor(full);
      final resultHsl = HSLColor.fromColor(result);
      expect(resultHsl.lightness, greaterThan(fullHsl.lightness));
    });

    test('returns most lightened color for low concentration (1-10)', () {
      final mediumResult = SeverityHelper.allergenicityColorForConcentration(
        allergenicityIndex: 2,
        concentration: 25,
      );
      final lowResult = SeverityHelper.allergenicityColorForConcentration(
        allergenicityIndex: 2,
        concentration: 5,
      );
      final mediumHsl = HSLColor.fromColor(mediumResult);
      final lowHsl = HSLColor.fromColor(lowResult);
      expect(lowHsl.lightness, greaterThan(mediumHsl.lightness));
    });

    test('works for all allergenicity indices', () {
      for (final index in [1, 2, 3]) {
        final result = SeverityHelper.allergenicityColorForConcentration(
          allergenicityIndex: index,
          concentration: 100,
        );
        expect(result, isA<Color>());
      }
    });
  });

  group('SeverityHelper.allergenicityLabel', () {
    test('returns Slab for index 1', () {
      expect(SeverityHelper.allergenicityLabel(1), 'Slab');
    });

    test('returns Srednji for index 2', () {
      expect(SeverityHelper.allergenicityLabel(2), 'Srednji');
    });

    test('returns Jak for index 3', () {
      expect(SeverityHelper.allergenicityLabel(3), 'Jak');
    });

    test('returns Nepoznato for unknown index', () {
      expect(SeverityHelper.allergenicityLabel(0), 'Nepoznato');
      expect(SeverityHelper.allergenicityLabel(99), 'Nepoznato');
    });
  });
}
