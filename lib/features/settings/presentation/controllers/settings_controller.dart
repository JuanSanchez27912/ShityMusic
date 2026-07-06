import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/shared_preferences_provider.dart';
import '../../../../core/utils/path_utils.dart';
import '../../data/shared_preferences_settings_repository.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final preferences = ref.watch(sharedPreferencesProvider);
  return SharedPreferencesSettingsRepository(preferences);
});

final settingsControllerProvider =
    AsyncNotifierProvider<SettingsController, AppSettings>(
      SettingsController.new,
    );

class SettingsController extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    return ref.read(settingsRepositoryProvider).load();
  }

  Future<void> updateThemePreference(AppThemePreference preference) async {
    final updatedSettings = await ref
        .read(settingsRepositoryProvider)
        .saveThemePreference(preference);
    state = AsyncData(updatedSettings);
  }

  Future<void> addExcludedFolder(String folderPath) async {
    final currentSettings = await future;
    final normalizedFolder = normalizeFolderPath(folderPath);
    if (normalizedFolder.isEmpty) {
      return;
    }

    final updatedFolders = <String>{
      ...currentSettings.excludedFolders,
      normalizedFolder,
    }.toList()..sort();

    final updatedSettings = await ref
        .read(settingsRepositoryProvider)
        .saveExcludedFolders(updatedFolders);
    state = AsyncData(updatedSettings);
  }

  Future<void> removeExcludedFolder(String folderPath) async {
    final currentSettings = await future;
    final normalizedFolder = normalizeFolderPath(folderPath);
    final updatedFolders = currentSettings.excludedFolders
        .where((folder) => folder != normalizedFolder)
        .toList(growable: false);

    final updatedSettings = await ref
        .read(settingsRepositoryProvider)
        .saveExcludedFolders(updatedFolders);
    state = AsyncData(updatedSettings);
  }

  Future<void> clearExcludedFolders() async {
    final updatedSettings = await ref
        .read(settingsRepositoryProvider)
        .saveExcludedFolders(const []);
    state = AsyncData(updatedSettings);
  }
}
