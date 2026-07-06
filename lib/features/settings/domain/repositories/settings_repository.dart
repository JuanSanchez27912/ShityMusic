import '../entities/app_settings.dart';

abstract class SettingsRepository {
  Future<AppSettings> load();
  Future<AppSettings> saveThemePreference(AppThemePreference preference);
  Future<AppSettings> saveExcludedFolders(List<String> folders);
}
