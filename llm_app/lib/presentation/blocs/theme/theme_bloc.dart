import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:llm_app/core/theme/app_theme.dart';
import 'package:llm_app/presentation/blocs/theme/theme_event.dart';
import 'package:llm_app/presentation/blocs/theme/theme_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  static const String isDarkModeKey = 'is_dark_mode';
  static const String themeTypeKey = 'theme_type';

  ThemeBloc() : super(ThemeState.initial()) {
    on<InitTheme>(_onInitTheme);
    on<ThemeChanged>(_onThemeChanged);
    on<ToggleThemeMode>(_onToggleThemeMode);
    on<ChangeThemeType>(_onChangeThemeType);
  }

  Future<void> _onInitTheme(InitTheme event, Emitter<ThemeState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool(isDarkModeKey) ?? false;
    final themeType = prefs.getInt(themeTypeKey) ?? AppTheme.blueTheme;

    emit(ThemeState(
      themeData: isDarkMode
          ? AppTheme.getDarkTheme(themeType)
          : AppTheme.getLightTheme(themeType),
      isDarkMode: isDarkMode,
      themeType: themeType,
    ));
  }

  Future<void> _onThemeChanged(
      ThemeChanged event, Emitter<ThemeState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(isDarkModeKey, event.isDarkMode);
    await prefs.setInt(themeTypeKey, event.themeType);

    emit(ThemeState(
      themeData: event.isDarkMode
          ? AppTheme.getDarkTheme(event.themeType)
          : AppTheme.getLightTheme(event.themeType),
      isDarkMode: event.isDarkMode,
      themeType: event.themeType,
    ));
  }

  Future<void> _onToggleThemeMode(
      ToggleThemeMode event, Emitter<ThemeState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(isDarkModeKey, event.isDarkMode);

    emit(ThemeState(
      themeData: event.isDarkMode
          ? AppTheme.getDarkTheme(state.themeType)
          : AppTheme.getLightTheme(state.themeType),
      isDarkMode: event.isDarkMode,
      themeType: state.themeType,
    ));
  }

  Future<void> _onChangeThemeType(
      ChangeThemeType event, Emitter<ThemeState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(themeTypeKey, event.themeType);

    emit(ThemeState(
      themeData: state.isDarkMode
          ? AppTheme.getDarkTheme(event.themeType)
          : AppTheme.getLightTheme(event.themeType),
      isDarkMode: state.isDarkMode,
      themeType: event.themeType,
    ));
  }
}
