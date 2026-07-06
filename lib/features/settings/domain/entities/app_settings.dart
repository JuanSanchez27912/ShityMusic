import 'package:flutter/material.dart';

enum AppThemePreference {
  system,
  light,
  dark;

  ThemeMode toThemeMode() {
    return switch (this) {
      AppThemePreference.system => ThemeMode.system,
      AppThemePreference.light => ThemeMode.light,
      AppThemePreference.dark => ThemeMode.dark,
    };
  }

  String get label {
    return switch (this) {
      AppThemePreference.system => 'Sistema',
      AppThemePreference.light => 'Claro',
      AppThemePreference.dark => 'Oscuro',
    };
  }

  static AppThemePreference fromStorage(String? value) {
    return AppThemePreference.values.firstWhere(
      (preference) => preference.name == value,
      orElse: () => AppThemePreference.system,
    );
  }
}

class AppSettings {
  const AppSettings({
    required this.themePreference,
    required this.excludedFolders,
  });

  const AppSettings.defaults()
    : themePreference = AppThemePreference.system,
      excludedFolders = const [];

  final AppThemePreference themePreference;
  final List<String> excludedFolders;

  AppSettings copyWith({
    AppThemePreference? themePreference,
    List<String>? excludedFolders,
  }) {
    return AppSettings(
      themePreference: themePreference ?? this.themePreference,
      excludedFolders: excludedFolders ?? this.excludedFolders,
    );
  }
}
