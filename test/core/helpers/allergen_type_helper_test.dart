// ABOUTME: Tests for AllergenTypeHelper mapping type IDs to icons, labels, and colors.
// ABOUTME: Covers all three allergen type IDs plus unknown/invalid inputs.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:udahni/core/helpers/allergen_type_helper.dart';

void main() {
  group('AllergenTypeHelper constants', () {
    test('treeTypeId is 1', () {
      expect(AllergenTypeHelper.treeTypeId, 1);
    });

    test('grassTypeId is 2', () {
      expect(AllergenTypeHelper.grassTypeId, 2);
    });

    test('weedTypeId is 3', () {
      expect(AllergenTypeHelper.weedTypeId, 3);
    });
  });

  group('AllergenTypeHelper.getLocalizedNameForType', () {
    test('returns Drveće for tree type', () {
      expect(AllergenTypeHelper.getLocalizedNameForType(1), 'Drveće');
    });

    test('returns Trave for grass type', () {
      expect(AllergenTypeHelper.getLocalizedNameForType(2), 'Trave');
    });

    test('returns Korov for weed type', () {
      expect(AllergenTypeHelper.getLocalizedNameForType(3), 'Korov');
    });

    test('returns Nepoznato for unknown type', () {
      expect(AllergenTypeHelper.getLocalizedNameForType(0), 'Nepoznato');
      expect(AllergenTypeHelper.getLocalizedNameForType(99), 'Nepoznato');
    });
  });

  group('AllergenTypeHelper.getColorForType', () {
    test('returns green for tree type', () {
      expect(AllergenTypeHelper.getColorForType(1), Colors.green);
    });

    test('returns lightGreen for grass type', () {
      expect(AllergenTypeHelper.getColorForType(2), Colors.lightGreen);
    });

    test('returns orange for weed type', () {
      expect(AllergenTypeHelper.getColorForType(3), Colors.orange);
    });

    test('returns grey for unknown type', () {
      expect(AllergenTypeHelper.getColorForType(0), Colors.grey);
      expect(AllergenTypeHelper.getColorForType(99), Colors.grey);
    });
  });

  group('AllergenTypeHelper.getIconForType', () {
    testWidgets('returns nature icon for tree type', (tester) async {
      final icon = AllergenTypeHelper.getIconForType(1);
      expect(icon.icon, Icons.nature);
    });

    testWidgets('returns grass icon for grass type', (tester) async {
      final icon = AllergenTypeHelper.getIconForType(2);
      expect(icon.icon, Icons.grass);
    });

    testWidgets('returns local_florist icon for weed type', (tester) async {
      final icon = AllergenTypeHelper.getIconForType(3);
      expect(icon.icon, Icons.local_florist);
    });

    testWidgets('returns all_inclusive icon for unknown type', (tester) async {
      final icon = AllergenTypeHelper.getIconForType(0);
      expect(icon.icon, Icons.all_inclusive);
    });
  });
}
