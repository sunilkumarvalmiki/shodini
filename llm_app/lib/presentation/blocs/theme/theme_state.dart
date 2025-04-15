import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:llm_app/core/theme/app_theme.dart';

class ThemeState extends Equatable {
  final ThemeData themeData;
  final bool isDarkMode;
  final int themeType;

  const ThemeState({
    required this.themeData,
    required this.isDarkMode,
    required this.themeType,
  });

  factory ThemeState.initial() {
    return ThemeState(
      themeData: AppTheme.getLightTheme(AppTheme.blueTheme),
      isDarkMode: false,
      themeType: AppTheme.blueTheme,
    );
  }

  ThemeState copyWith({
    ThemeData? themeData,
    bool? isDarkMode,
    int? themeType,
  }) {
    return ThemeState(
      themeData: themeData ?? this.themeData,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      themeType: themeType ?? this.themeType,
    );
  }

  @override
  List<Object> get props => [isDarkMode, themeType];
}
