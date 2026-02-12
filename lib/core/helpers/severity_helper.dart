import 'package:alergeni/core/constants/severity_thresholds.dart';
import 'package:alergeni/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class SeverityHelper {
  SeverityHelper._();

  static String concentrationLabel(int value) {
    if (value >= SeverityThresholds.highMin) return 'Visoka';
    if (value >= SeverityThresholds.mediumMin) return 'Srednja';
    if (value >= SeverityThresholds.lowMin) return 'Niska';
    return 'Nema';
  }

  static Color allergenicityBaseColor(int allergenicityIndex) {
    return switch (allergenicityIndex) {
      1 => AppTheme.severityLow,
      2 => AppTheme.severityMedium,
      3 => AppTheme.severityHigh,
      _ => Colors.grey,
    };
  }

  static Color allergenicityColorForConcentration({
    required int allergenicityIndex,
    required int concentration,
  }) {
    final baseColor = allergenicityBaseColor(allergenicityIndex);

    if (concentration >= SeverityThresholds.highMin) return baseColor;
    if (concentration >= SeverityThresholds.mediumMin) {
      return _lighten(baseColor, 0.1);
    }
    return _lighten(baseColor, 0.3);
  }

  static String allergenicityLabel(int allergenicityIndex) {
    return switch (allergenicityIndex) {
      1 => 'Slab',
      2 => 'Srednji',
      3 => 'Jak',
      _ => 'Nepoznato',
    };
  }

  static Color _lighten(Color color, double factor) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness + factor).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
}
