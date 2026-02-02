import 'package:flutter/material.dart';

//--------------------------------------------------------------------------
class AppTheme {
  // Private constructor - this class only has static members
  AppTheme._();

  // Brand colors
  static const Color primaryGreen = Color(0xFF4CAF50); // Main green
  static const Color primaryGreenDark = Color(0xFF388E3C); // Darker green
  static const Color primaryGreenLight = Color(
    0xFFC8E6C9,
  ); // Light green background

  // Severity colors (for allergen levels)
  static const Color severityLow = Color(0xFF4CAF50); // Green - mild
  static const Color severityMedium = Color(0xFFFF9800); // Orange - moderate
  static const Color severityHigh = Color(0xFFF44336); // Red - high

  // Neutral colors
  static const Color textPrimary = Color(0xFF212121); // Almost black
  static const Color textSecondary = Color(0xFF757575); // Gray
  static const Color background = Color(0xFFFAFAFA); // Off-white
  static const Color surface = Color(0xFFFFFFFF); // White

  //--------------------------------------------------------------------------
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: background,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
