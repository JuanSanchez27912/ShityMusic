import 'package:on_audio_query/on_audio_query.dart';

class Track {
  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    required this.filePath,
  });

  factory Track.fromSongModel(SongModel song) {
    String sanitize(String? value, String fallback) {
      final normalized = value?.trim() ?? '';
      if (normalized.isEmpty || normalized == '<unknown>') {
        return fallback;
      }
      return normalized;
    }

    return Track(
      id: song.id,
      title: sanitize(song.title, song.displayNameWOExt),
      artist: sanitize(song.artist, 'Artista desconocido'),
      album: sanitize(song.album, 'Sin álbum'),
      duration: Duration(milliseconds: song.duration ?? 0),
      filePath: song.data,
    );
  }

  final int id;
  final String title;
  final String artist;
  final String album;
  final Duration duration;
  final String filePath;

  int get artworkId => id;

  String get lyricsCacheKey {
    final normalizedPath = filePath.trim().toLowerCase();
    if (normalizedPath.isNotEmpty) {
      return normalizedPath;
    }

    return '${artist.toLowerCase()}|${album.toLowerCase()}|${title.toLowerCase()}|$id';
  }
}
