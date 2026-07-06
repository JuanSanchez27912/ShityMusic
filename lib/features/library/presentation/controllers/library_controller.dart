import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../../../../core/utils/path_utils.dart';
import '../../../settings/domain/entities/app_settings.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../data/device_music_library_repository.dart';
import '../../domain/entities/track.dart';
import '../../domain/repositories/music_library_repository.dart';

final musicLibraryRepositoryProvider = Provider<MusicLibraryRepository>((ref) {
  return DeviceMusicLibraryRepository(OnAudioQuery());
});

final libraryControllerProvider =
    AsyncNotifierProvider<LibraryController, MusicLibraryState>(
      LibraryController.new,
    );

class MusicLibraryState {
  const MusicLibraryState({
    required this.permissionGranted,
    required this.tracks,
    required this.excludedFolders,
    required this.totalTracks,
    required this.hiddenTracks,
    required this.suggestedFolders,
  });

  final bool permissionGranted;
  final List<Track> tracks;
  final List<String> excludedFolders;
  final int totalTracks;
  final int hiddenTracks;
  final List<String> suggestedFolders;
}

class LibraryController extends AsyncNotifier<MusicLibraryState> {
  @override
  Future<MusicLibraryState> build() async {
    final settings = await ref.watch(settingsControllerProvider.future);
    return _load(settings: settings, requestPermission: true);
  }

  Future<void> refresh({bool requestPermission = false}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final settings = await ref.read(settingsControllerProvider.future);
      return _load(settings: settings, requestPermission: requestPermission);
    });
  }

  Future<void> requestPermissionAndReload() {
    return refresh(requestPermission: true);
  }

  Future<MusicLibraryState> _load({
    required AppSettings settings,
    required bool requestPermission,
  }) async {
    final snapshot = await ref
        .read(musicLibraryRepositoryProvider)
        .loadTracks(requestPermission: requestPermission);

    final visibleTracks = snapshot.tracks
        .where(
          (track) => !pathMatchesExcludedFolder(
            track.filePath,
            settings.excludedFolders,
          ),
        )
        .toList(growable: false);

    return MusicLibraryState(
      permissionGranted: snapshot.permissionGranted,
      tracks: visibleTracks,
      excludedFolders: settings.excludedFolders,
      totalTracks: snapshot.tracks.length,
      hiddenTracks: snapshot.tracks.length - visibleTracks.length,
      suggestedFolders: collectFolderSuggestions(
        snapshot.tracks.map((track) => track.filePath),
      ),
    );
  }
}
