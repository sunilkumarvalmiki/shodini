import 'package:equatable/equatable.dart';

abstract class ThemeEvent extends Equatable {
  const ThemeEvent();

  @override
  List<Object> get props => [];
}

class ThemeChanged extends ThemeEvent {
  final bool isDarkMode;
  final int themeType;

  const ThemeChanged({required this.isDarkMode, required this.themeType});

  @override
  List<Object> get props => [isDarkMode, themeType];
}

class ToggleThemeMode extends ThemeEvent {
  final bool isDarkMode;

  const ToggleThemeMode({required this.isDarkMode});

  @override
  List<Object> get props => [isDarkMode];
}

class ChangeThemeType extends ThemeEvent {
  final int themeType;

  const ChangeThemeType({required this.themeType});

  @override
  List<Object> get props => [themeType];
}

class InitTheme extends ThemeEvent {}
 