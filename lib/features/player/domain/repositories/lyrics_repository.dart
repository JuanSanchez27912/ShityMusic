import '../../../library/domain/entities/track.dart';
import '../entities/lyrics_document.dart';

abstract class LyricsRepository {
  Future<LyricsDocument?> loadCachedLyrics(Track track);
  Future<LyricsDocument?> fetchLyrics(Track track);
  Future<LyricsDocument> saveManualLyrics(Track track, String rawLyrics);
  Future<void> clearLyrics(Track track);
}
