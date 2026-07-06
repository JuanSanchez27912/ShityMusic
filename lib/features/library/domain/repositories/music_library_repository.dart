import '../entities/track.dart';

class MusicLibrarySnapshot {
  const MusicLibrarySnapshot({
    required this.permissionGranted,
    required this.tracks,
  });

  final bool permissionGranted;
  final List<Track> tracks;
}

abstract class MusicLibraryRepository {
  Future<MusicLibrarySnapshot> loadTracks({bool requestPermission = true});
  Future<bool> requestPermission({bool retryRequest = true});
}
