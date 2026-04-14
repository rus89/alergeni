// ABOUTME: Tests for LevelHelper mapping numeric level/trend codes to display values.
// ABOUTME: Covers labels, colors, icons, and pin colors for all valid and unknown inputs.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udahni/core/helpers/level_helper.dart';

void main() {
  group('LevelHelper.levelToLabel', () {
    test('returns Vrlo niska for level 1', () {
      expect(LevelHelper.levelToLabel(1), 'Vrlo niska');
    });

    test('returns Niska for level 2', () {
      expect(LevelHelper.levelToLabel(2), 'Niska');
    });

    test('returns Srednja for level 3', () {
      expect(LevelHelper.levelToLabel(3), 'Srednja');
    });

    test('returns Visoka for level 4', () {
      expect(LevelHelper.levelToLabel(4), 'Visoka');
    });

    test('returns Vrlo visoka for level 5', () {
      expect(LevelHelper.levelToLabel(5), 'Vrlo visoka');
    });

    test('returns Nepoznato for unknown level', () {
      expect(LevelHelper.levelToLabel(0), 'Nepoznato');
      expect(LevelHelper.levelToLabel(6), 'Nepoznato');
      expect(LevelHelper.levelToLabel(-1), 'Nepoznato');
    });
  });

  group('LevelHelper.levelToColor', () {
    test('returns lightGreen for level 1', () {
      expect(LevelHelper.levelToColor(1), Colors.lightGreen);
    });

    test('returns green for level 2', () {
      expect(LevelHelper.levelToColor(2), Colors.green);
    });

    test('returns orange for level 3', () {
      expect(LevelHelper.levelToColor(3), Colors.orange);
    });

    test('returns redAccent for level 4', () {
      expect(LevelHelper.levelToColor(4), Colors.redAccent);
    });

    test('returns red for level 5', () {
      expect(LevelHelper.levelToColor(5), Colors.red);
    });

    test('returns grey for unknown level', () {
      expect(LevelHelper.levelToColor(0), Colors.grey);
      expect(LevelHelper.levelToColor(99), Colors.grey);
    });
  });

  group('LevelHelper.trendToLabel', () {
    test('returns opadajuci for trend 1', () {
      expect(LevelHelper.trendToLabel(1), 'Opadajući trend');
    });

    test('returns stabilan for trend 2', () {
      expect(LevelHelper.trendToLabel(2), 'Stabilan trend');
    });

    test('returns rastuci for trend 3', () {
      expect(LevelHelper.trendToLabel(3), 'Rastući trend');
    });

    test('returns unavailable for null', () {
      expect(LevelHelper.trendToLabel(null), 'Trend nije dostupan');
    });

    test('returns unavailable for unknown trend', () {
      expect(LevelHelper.trendToLabel(0), 'Trend nije dostupan');
      expect(LevelHelper.trendToLabel(99), 'Trend nije dostupan');
    });
  });

  group('LevelHelper.trendToIcon', () {
    test('returns trending_down for trend 1', () {
      expect(LevelHelper.trendToIcon(1), Icons.trending_down);
    });

    test('returns trending_flat for trend 2', () {
      expect(LevelHelper.trendToIcon(2), Icons.trending_flat);
    });

    test('returns trending_up for trend 3', () {
      expect(LevelHelper.trendToIcon(3), Icons.trending_up);
    });

    test('returns help_outline for null or unknown', () {
      expect(LevelHelper.trendToIcon(null), Icons.help_outline);
      expect(LevelHelper.trendToIcon(0), Icons.help_outline);
    });
  });

  group('LevelHelper.trendToPinColor', () {
    test('returns green for trend 1 (declining)', () {
      expect(LevelHelper.trendToPinColor(1), Colors.green);
    });

    test('returns orange for trend 2 (stable)', () {
      expect(LevelHelper.trendToPinColor(2), Colors.orange);
    });

    test('returns red for trend 3 (rising)', () {
      expect(LevelHelper.trendToPinColor(3), Colors.red);
    });

    test('returns grey for null or unknown', () {
      expect(LevelHelper.trendToPinColor(null), Colors.grey.shade600);
      expect(LevelHelper.trendToPinColor(0), Colors.grey.shade600);
    });
  });
}
