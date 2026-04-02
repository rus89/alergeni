// ABOUTME: Tests for personal allergen selection and persistence logic.
// ABOUTME: Verifies toggle, load, and query behavior of PersonalAllergenViewModel.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:udahni/presentation/viewmodels/personal_allergen_view_model.dart';

void main() {
  group('PersonalAllergenViewModel', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('starts with empty selection', () async {
      final vm = PersonalAllergenViewModel();
      await vm.loadSelections();
      expect(vm.selectedAllergenIds, isEmpty);
    });

    test('toggling an ID adds it', () async {
      final vm = PersonalAllergenViewModel();
      await vm.loadSelections();
      await vm.toggleAllergen(5);
      expect(vm.selectedAllergenIds, contains(5));
    });

    test('toggling an ID twice removes it', () async {
      final vm = PersonalAllergenViewModel();
      await vm.loadSelections();
      await vm.toggleAllergen(5);
      await vm.toggleAllergen(5);
      expect(vm.selectedAllergenIds, isNot(contains(5)));
    });

    test('isSelected returns correct value', () async {
      final vm = PersonalAllergenViewModel();
      await vm.loadSelections();
      await vm.toggleAllergen(3);
      expect(vm.isSelected(3), isTrue);
      expect(vm.isSelected(7), isFalse);
    });

    test('persists selections across instances', () async {
      final vm1 = PersonalAllergenViewModel();
      await vm1.loadSelections();
      await vm1.toggleAllergen(2);
      await vm1.toggleAllergen(8);

      final vm2 = PersonalAllergenViewModel();
      await vm2.loadSelections();
      expect(vm2.selectedAllergenIds, containsAll([2, 8]));
    });

    test('notifies listeners on toggle', () async {
      final vm = PersonalAllergenViewModel();
      await vm.loadSelections();
      var notified = false;
      vm.addListener(() => notified = true);
      await vm.toggleAllergen(1);
      expect(notified, isTrue);
    });
  });
}
