import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/app_settings.dart';
import '../domain/repositories/settings_repository.dart';

class SharedPreferencesSettingsRepository implements SettingsRepository {
  SharedPreferencesSettingsRepository(this._preferences);

  static const String _themePreferenceKey = 'theme_preference';
  static const String _excludedFoldersKey = 'excluded_folders';

  final SharedPreferences _preferences;

  @override
  Future<AppSettings> load() async {
    return AppSettings(
      themePreference: AppThemePreference.fromStorage(
        _preferences.getString(_themePreferenceKey),
      ),
      excludedFolders: List<String>.unmodifiable(
        _preferences.getStringList(_excludedFoldersKey) ?? const <String>[],
      ),
    );
  }

  @override
  Future<AppSettings> saveExcludedFolders(List<String> folders) async {
    await _preferences.setStringList(_excludedFoldersKey, folders);
    return load();
  }

  @override
  Future<AppSettings> saveThemePreference(AppThemePreference preference) async {
    await _preferences.setString(_themePreferenceKey, preference.name);
    return load();
  }
}
