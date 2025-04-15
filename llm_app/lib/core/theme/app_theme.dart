import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const _primaryBlue = Color(0xFF2196F3);
  static const _primaryGreen = Color(0xFF4CAF50);
  static const _primaryPurple = Color(0xFF673AB7);

  // Light Theme Colors
  static const _lightPrimaryContainer = Color(0xFFE3F2FD);
  static const _lightBackground = Color(0xFFF5F5F5);
  static const _lightSurface = Color(0xFFFFFFFF);
  static const _lightError = Color(0xFFB00020);
  static const _lightOnPrimary = Color(0xFFFFFFFF);
  static const _lightOnBackground = Color(0xFF121212);
  static const _lightOnSurface = Color(0xFF121212);
  static const _lightOnError = Color(0xFFFFFFFF);

  // Dark Theme Colors
  static const _darkPrimaryContainer = Color(0xFF0D47A1);
  static const _darkBackground = Color(0xFF121212);
  static const _darkSurface = Color(0xFF1E1E1E);
  static const _darkError = Color(0xFFCF6679);
  static const _darkOnPrimary = Color(0xFF000000);
  static const _darkOnBackground = Color(0xFFFFFFFF);
  static const _darkOnSurface = Color(0xFFFFFFFF);
  static const _darkOnError = Color(0xFF000000);

  // Theme Types
  static const int blueTheme = 0;
  static const int greenTheme = 1;
  static const int purpleTheme = 2;

  // Get primary color based on theme type
  static Color getPrimaryColor(int themeType) {
    switch (themeType) {
      case greenTheme:
        return _primaryGreen;
      case purpleTheme:
        return _primaryPurple;
      case blueTheme:
      default:
        return _primaryBlue;
    }
  }

  // Light Theme
  static ThemeData getLightTheme(int themeType) {
    final primaryColor = getPrimaryColor(themeType);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: primaryColor,
        onPrimary: _lightOnPrimary,
        primaryContainer: _lightPrimaryContainer,
        onPrimaryContainer: primaryColor.withOpacity(0.8),
        secondary: primaryColor.withOpacity(0.7),
        onSecondary: _lightOnPrimary,
        secondaryContainer: _lightPrimaryContainer.withOpacity(0.8),
        onSecondaryContainer: primaryColor.withOpacity(0.8),
        tertiary: primaryColor.withOpacity(0.5),
        onTertiary: _lightOnPrimary,
        tertiaryContainer: _lightPrimaryContainer.withOpacity(0.6),
        onTertiaryContainer: primaryColor.withOpacity(0.7),
        error: _lightError,
        onError: _lightOnError,
        errorContainer: _lightError.withOpacity(0.1),
        onErrorContainer: _lightError,
        surface: _lightSurface,
        onSurface: _lightOnSurface,
        surfaceContainerHighest: _lightBackground.withOpacity(0.9),
        onSurfaceVariant: _lightOnSurface.withOpacity(0.8),
        outline: _lightOnSurface.withOpacity(0.2),
        outlineVariant: _lightOnSurface.withOpacity(0.1),
        shadow: _lightOnSurface.withOpacity(0.2),
        scrim: _lightOnSurface.withOpacity(0.1),
        inverseSurface: _darkSurface,
        onInverseSurface: _darkOnSurface,
        inversePrimary: primaryColor.withOpacity(0.8),
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _lightSurface,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _lightError),
        ),
      ),
    );
  }

  // Dark Theme
  static ThemeData getDarkTheme(int themeType) {
    final primaryColor = getPrimaryColor(themeType);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: primaryColor,
        onPrimary: _darkOnPrimary,
        primaryContainer: _darkPrimaryContainer,
        onPrimaryContainer: primaryColor.withOpacity(0.8),
        secondary: primaryColor.withOpacity(0.7),
        onSecondary: _darkOnPrimary,
        secondaryContainer: _darkPrimaryContainer.withOpacity(0.8),
        onSecondaryContainer: primaryColor.withOpacity(0.8),
        tertiary: primaryColor.withOpacity(0.5),
        onTertiary: _darkOnPrimary,
        tertiaryContainer: _darkPrimaryContainer.withOpacity(0.6),
        onTertiaryContainer: primaryColor.withOpacity(0.7),
        error: _darkError,
        onError: _darkOnError,
        errorContainer: _darkError.withOpacity(0.1),
        onErrorContainer: _darkError,
        surface: _darkSurface,
        onSurface: _darkOnSurface,
        surfaceContainerHighest: _darkBackground.withOpacity(0.9),
        onSurfaceVariant: _darkOnSurface.withOpacity(0.8),
        outline: _darkOnSurface.withOpacity(0.2),
        outlineVariant: _darkOnSurface.withOpacity(0.1),
        shadow: Colors.black.withOpacity(0.3),
        scrim: Colors.black.withOpacity(0.2),
        inverseSurface: _lightSurface,
        onInverseSurface: _lightOnSurface,
        inversePrimary: primaryColor.withOpacity(0.8),
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkSurface.withOpacity(0.7),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _darkError),
        ),
      ),
    );
  }
}
