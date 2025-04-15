import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Enum representing the available theme modes
enum AppThemeMode {
  light,
  dark,
  system,
}

/// A service to manage application themes and persist theme preferences
class ThemeService extends ChangeNotifier {
  static const String _themePreferenceKey = 'app_theme_mode';

  // Singleton instance
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;

  ThemeService._internal();

  // Default to system theme
  AppThemeMode _currentThemeMode = AppThemeMode.system;

  /// Get the current theme mode
  AppThemeMode get themeMode => _currentThemeMode;

  /// Get the ThemeMode for Flutter's theme system
  ThemeMode get flutterThemeMode {
    switch (_currentThemeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
      default:
        return ThemeMode.system;
    }
  }

  /// Check if dark mode is active
  bool get isDarkMode {
    switch (_currentThemeMode) {
      case AppThemeMode.light:
        return false;
      case AppThemeMode.dark:
        return true;
      case AppThemeMode.system:
      default:
        // Check platform brightness
        final platformBrightness =
            WidgetsBinding.instance.platformDispatcher.platformBrightness;
        return platformBrightness == Brightness.dark;
    }
  }

  /// Initialize the theme service
  Future<void> init() async {
    await loadThemePreference();
  }

  /// Load saved theme preference
  Future<void> loadThemePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_themePreferenceKey);

      if (savedMode != null) {
        _currentThemeMode = AppThemeMode.values.firstWhere(
          (mode) => mode.toString() == savedMode,
          orElse: () => AppThemeMode.system,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading theme preference: $e');
      // Default to system theme if preference can't be loaded
      _currentThemeMode = AppThemeMode.system;
    }
  }

  /// Set the app theme mode and persist the setting
  Future<void> setThemeMode(AppThemeMode mode) async {
    if (_currentThemeMode == mode) return;

    _currentThemeMode = mode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themePreferenceKey, mode.toString());
    } catch (e) {
      debugPrint('Error saving theme preference: $e');
    }
  }

  /// Toggle between light and dark mode
  Future<void> toggleTheme() async {
    final newMode = isDarkMode ? AppThemeMode.light : AppThemeMode.dark;
    await setThemeMode(newMode);
  }

  /// Get the light theme data
  ThemeData getLightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      // Add more theme customizations here
    );
  }

  /// Get the dark theme data
  ThemeData getDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      ),
      // Add more theme customizations here
    );
  }
}
