import 'package:flutter/material.dart';

class AllergenTypeHelper {
  AllergenTypeHelper._();

  static const int treeTypeId = 1;
  static const int grassTypeId = 2;
  static const int weedTypeId = 3;

  //--------------------------------------------------------------------------
  static Icon getIconForType(int typeId) {
    return switch (typeId) {
      treeTypeId => const Icon(Icons.nature, color: Colors.green),
      grassTypeId => const Icon(Icons.grass, color: Colors.lightGreen),
      weedTypeId => const Icon(Icons.local_florist, color: Colors.orange),
      _ => const Icon(Icons.all_inclusive, color: Colors.grey),
    };
  }

  //--------------------------------------------------------------------------
  static String getLocalizedNameForType(int typeId) {
    return switch (typeId) {
      treeTypeId => 'Drveće',
      grassTypeId => 'Trave',
      weedTypeId => 'Korov',
      _ => 'Nepoznato',
    };
  }
}
