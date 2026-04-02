// ABOUTME: Manages the user's personal allergen selections with local persistence.
// ABOUTME: Provides toggle, query, and load/save via SharedPreferences.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PersonalAllergenViewModel extends ChangeNotifier {
  static const String _storageKey = 'personal_allergen_ids';

  Set<int> _selectedIds = {};

  Set<int> get selectedAllergenIds => Set.unmodifiable(_selectedIds);

  bool isSelected(int allergenId) => _selectedIds.contains(allergenId);

  Future<void> loadSelections() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_storageKey);
    if (stored != null) {
      final List<dynamic> decoded = jsonDecode(stored);
      _selectedIds = decoded.cast<int>().toSet();
    }
    notifyListeners();
  }

  Future<void> toggleAllergen(int allergenId) async {
    if (_selectedIds.contains(allergenId)) {
      _selectedIds.remove(allergenId);
    } else {
      _selectedIds.add(allergenId);
    }
    notifyListeners();
    await _saveSelections();
  }

  Future<void> _saveSelections() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_selectedIds.toList()));
  }
}
