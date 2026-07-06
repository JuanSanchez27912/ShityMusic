import 'package:on_audio_query/on_audio_query.dart';

import '../domain/entities/track.dart';
import '../domain/repositories/music_library_repository.dart';

class DeviceMusicLibraryRepository implements MusicLibraryRepository {
  DeviceMusicLibraryRepository(this._audioQuery);

  final OnAudioQuery _audioQuery;

  @override
  Future<MusicLibrarySnapshot> loadTracks({
    bool requestPermission = true,
  }) async {
    final hasPermission = requestPermission
        ? await _audioQuery.checkAndRequest(retryRequest: true)
        : await _audioQuery.permissionsStatus();

    if (!hasPermission) {
      return const MusicLibrarySnapshot(permissionGranted: false, tracks: []);
    }

    final songs = await _audioQuery.querySongs(
      sortType: SongSortType.TITLE,
      orderType: OrderType.ASC_OR_SMALLER,
      ignoreCase: true,
    );

    final tracks = songs
        .where((song) => song.data.trim().isNotEmpty)
        .where((song) => song.isMusic ?? true)
        .map(Track.fromSongModel)
        .toList(growable: false);

    return MusicLibrarySnapshot(permissionGranted: true, tracks: tracks);
  }

  @override
  Future<bool> requestPermission({bool retryRequest = true}) {
    return _audioQuery.checkAndRequest(retryRequest: retryRequest);
  }
}
