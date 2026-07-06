import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../library/domain/entities/track.dart';
import '../domain/entities/lyrics_document.dart';
import '../domain/repositories/lyrics_repository.dart';

class LrcLibLyricsRepository implements LyricsRepository {
  LrcLibLyricsRepository({
    required http.Client client,
    required SharedPreferences preferences,
  }) : _client = client,
       _preferences = preferences;

  static const String _cacheKey = 'lyrics_cache_v1';

  final http.Client _client;
  final SharedPreferences _preferences;

  @override
  Future<void> clearLyrics(Track track) async {
    final cache = _readCache()..remove(track.lyricsCacheKey);
    await _writeCache(cache);
  }

  @override
  Future<LyricsDocument?> fetchLyrics(Track track) async {
    final directMatch = await _requestExactMatch(track);
    if (directMatch != null) {
      return _persist(track, directMatch);
    }

    final searchResult = await _search(track);
    if (searchResult != null) {
      return _persist(track, searchResult);
    }

    return null;
  }

  @override
  Future<LyricsDocument?> loadCachedLyrics(Track track) async {
    final cache = _readCache();
    final payload = cache[track.lyricsCacheKey];

    if (payload is Map<String, dynamic>) {
      return LyricsDocument.fromJson(payload);
    }
    if (payload is Map) {
      return LyricsDocument.fromJson(payload.cast<String, dynamic>());
    }

    return null;
  }

  @override
  Future<LyricsDocument> saveManualLyrics(Track track, String rawLyrics) async {
    final document = LyricsDocument.fromRaw(
      raw: rawLyrics,
      source: 'Adjunta manualmente',
    );
    return _persist(track, document);
  }

  Future<LyricsDocument?> _requestExactMatch(Track track) async {
    final response = await _client.get(
      Uri.https('lrclib.net', '/api/get', {
        'track_name': track.title,
        'artist_name': track.artist,
        if (track.album.isNotEmpty) 'album_name': track.album,
      }),
      headers: const {'Accept': 'application/json'},
    );

    if (response.statusCode == 404) {
      return null;
    }
    if (response.statusCode != 200) {
      throw Exception('LRCLIB returned ${response.statusCode}.');
    }

    final payload = jsonDecode(response.body);
    if (payload is! Map) {
      return null;
    }

    return _documentFromApi(payload.cast<String, dynamic>());
  }

  Future<LyricsDocument?> _search(Track track) async {
    final response = await _client.get(
      Uri.https('lrclib.net', '/api/search', {
        'track_name': track.title,
        'artist_name': track.artist,
      }),
      headers: const {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      return null;
    }

    final payload = jsonDecode(response.body);
    if (payload is! List) {
      return null;
    }

    Map<String, dynamic>? fallback;
    for (final item in payload) {
      if (item is! Map) {
        continue;
      }

      final candidate = item.cast<String, dynamic>();
      fallback ??= candidate;

      final syncedLyrics = (candidate['syncedLyrics'] ?? '').toString().trim();
      if (syncedLyrics.isNotEmpty) {
        return _documentFromApi(candidate);
      }
    }

    if (fallback == null) {
      return null;
    }

    return _documentFromApi(fallback);
  }

  LyricsDocument? _documentFromApi(Map<String, dynamic> payload) {
    final syncedLyrics = (payload['syncedLyrics'] ?? '').toString().trim();
    final plainLyrics = (payload['plainLyrics'] ?? '').toString().trim();
    final raw = syncedLyrics.isNotEmpty ? syncedLyrics : plainLyrics;

    if (raw.isEmpty) {
      return null;
    }

    return LyricsDocument.fromRaw(
      raw: raw,
      source: syncedLyrics.isNotEmpty ? 'LRCLIB sincronizada' : 'LRCLIB texto',
    );
  }

  Future<LyricsDocument> _persist(Track track, LyricsDocument document) async {
    final cache = _readCache()..[track.lyricsCacheKey] = document.toJson();
    await _writeCache(cache);
    return document;
  }

  Map<String, dynamic> _readCache() {
    final rawCache = _preferences.getString(_cacheKey);
    if (rawCache == null || rawCache.isEmpty) {
      return <String, dynamic>{};
    }

    final decoded = jsonDecode(rawCache);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return decoded.cast<String, dynamic>();
    }

    return <String, dynamic>{};
  }

  Future<void> _writeCache(Map<String, dynamic> cache) {
    return _preferences.setString(_cacheKey, jsonEncode(cache));
  }
}
