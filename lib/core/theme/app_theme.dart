import 'package:flutter/material.dart';

/// MasterOfCoin app theme - inspired by modern finance apps.
/// Light: Clean, green accent on white. Dark: Teal/green with gold accents.
class AppTheme {
  AppTheme._();

  // Shared accent colors
  static const Color _accentGreen = Color(0xFF4CAF50);
  static const Color _accentGold = Color(0xFFFFB74D);
  static const Color _positiveGreen = Color(0xFF2E7D32);
  static const Color _negativeRed = Color(0xFFC62828);

  // Light theme colors (reference: Robert Fox dashboard)
  static const Color _lightBg = Color(0xFFF7F7F7);
  static const Color _lightCard = Color(0xFFFFFFFF);
  static const Color _lightTextPrimary = Color(0xFF333333);
  static const Color _lightTextSecondary = Color(0xFF888888);

  // Dark theme colors (reference: Sophie dark teal finance app)
  static const Color _darkBg = Color(0xFF0F1F20);
  static const Color _darkCard = Color(0xFF1E4A4C);
  static const Color _darkCardElevated = Color(0xFF2D6F73);
  static const Color _darkTextPrimary = Color(0xFFFFFFFF);
  static const Color _darkTextSecondary = Color(0xFFB0BEC5);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: _lightBg,
      colorScheme: ColorScheme.light(
        primary: _accentGreen,
        secondary: _accentGreen.withOpacity(0.8),
        surface: _lightCard,
        error: _negativeRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: _lightTextPrimary,
        onSurfaceVariant: _lightTextSecondary,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: _lightBg,
        foregroundColor: _lightTextPrimary,
        titleTextStyle: TextStyle(
          color: _lightTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: _lightCard,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _accentGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _accentGreen,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: _lightCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontWeight: FontWeight.bold,
          color: _lightTextPrimary,
          fontSize: 28,
        ),
        titleLarge: TextStyle(
          fontWeight: FontWeight.w600,
          color: _lightTextPrimary,
          fontSize: 18,
        ),
        bodyMedium: TextStyle(
          color: _lightTextPrimary,
          fontSize: 14,
        ),
        bodySmall: TextStyle(
          color: _lightTextSecondary,
          fontSize: 12,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _darkBg,
      colorScheme: ColorScheme.dark(
        primary: _accentGold,
        secondary: _accentGold.withOpacity(0.8),
        surface: _darkCard,
        error: _negativeRed,
        onPrimary: _darkTextPrimary,
        onSecondary: _darkTextPrimary,
        onSurface: _darkTextPrimary,
        onSurfaceVariant: _darkTextSecondary,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: _darkBg,
        foregroundColor: _darkTextPrimary,
        titleTextStyle: TextStyle(
          color: _darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: _darkCard,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _darkCardElevated,
          foregroundColor: _darkTextPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _accentGold,
        foregroundColor: _darkTextPrimary,
        elevation: 4,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: _darkCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontWeight: FontWeight.bold,
          color: _darkTextPrimary,
          fontSize: 28,
        ),
        titleLarge: TextStyle(
          fontWeight: FontWeight.w600,
          color: _darkTextPrimary,
          fontSize: 18,
        ),
        bodyMedium: TextStyle(
          color: _darkTextPrimary,
          fontSize: 14,
        ),
        bodySmall: TextStyle(
          color: _darkTextSecondary,
          fontSize: 12,
        ),
      ),
    );
  }

  /// Semantic colors (theme-aware)
  static Color positiveColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF81C784)
          : _positiveGreen;

  static Color negativeColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFFE57373)
          : _negativeRed;
}
