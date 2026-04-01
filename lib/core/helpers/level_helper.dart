// ABOUTME: Shared helper for converting pollen severity levels and trends to display values.
// ABOUTME: Maps numeric level/trend codes to localized labels, colors, and icons.
import 'package:flutter/material.dart';

class LevelHelper {
  LevelHelper._();

  static String levelToLabel(int level) {
    return switch (level) {
      1 => 'Vrlo niska',
      2 => 'Niska',
      3 => 'Srednja',
      4 => 'Visoka',
      5 => 'Vrlo visoka',
      _ => 'Nepoznato',
    };
  }

  static Color levelToColor(int level) {
    return switch (level) {
      1 => Colors.lightGreen,
      2 => Colors.green,
      3 => Colors.orange,
      4 => Colors.redAccent,
      5 => Colors.red,
      _ => Colors.grey,
    };
  }

  static String trendToLabel(int? trend) {
    return switch (trend) {
      1 => 'Opadajući trend',
      2 => 'Stabilan trend',
      3 => 'Rastući trend',
      _ => 'Trend nije dostupan',
    };
  }

  static IconData trendToIcon(int? trend) {
    return switch (trend) {
      1 => Icons.trending_down,
      2 => Icons.trending_flat,
      3 => Icons.trending_up,
      _ => Icons.help_outline,
    };
  }

  static Color trendToPinColor(int? trend) {
    return switch (trend) {
      1 => Colors.green,
      2 => Colors.orange,
      3 => Colors.red,
      _ => Colors.grey.shade600,
    };
  }
}
