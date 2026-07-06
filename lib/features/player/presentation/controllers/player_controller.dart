import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';

import '../../../../core/providers/shared_preferences_provider.dart';
import '../../../library/domain/entities/track.dart';
import '../../data/lrclib_lyrics_repository.dart';
import '../../domain/entities/lyrics_document.dart';
import '../../domain/repositories/lyrics_repository.dart';

final audioPlayerProvider = Provider<AudioPlayer>((ref) {
  final player = AudioPlayer();
  ref.onDispose(player.dispose);
  return player;
});

final lyricsRepositoryProvider = Provider<LyricsRepository>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);

  return LrcLibLyricsRepository(
    client: client,
    preferences: ref.watch(sharedPreferencesProvider),
  );
});

final playerControllerProvider =
    NotifierProvider<PlayerController, PlayerControllerState>(
      PlayerController.new,
    );

class PlayerControllerState {
  const PlayerControllerState({
    this.queue = const [],
    this.currentIndex,
    this.isPlaying = false,
    this.isShuffleEnabled = false,
    this.loopMode = LoopMode.off,
    this.position = Duration.zero,
    this.bufferedPosition = Duration.zero,
    this.duration = Duration.zero,
    this.processingState = ProcessingState.idle,
    this.lyrics,
    this.lyricsLoading = false,
    this.lyricsError,
  });

  static const Object _sentinel = Object();

  final List<Track> queue;
  final int? currentIndex;
  final bool isPlaying;
  final bool isShuffleEnabled;
  final LoopMode loopMode;
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;
  final ProcessingState processingState;
  final LyricsDocument? lyrics;
  final bool lyricsLoading;
  final String? lyricsError;

  Track? get currentTrack {
    final index = currentIndex;
    if (index == null || index < 0 || index >= queue.length) {
      return null;
    }

    return queue[index];
  }

  PlayerControllerState copyWith({
    List<Track>? queue,
    Object? currentIndex = _sentinel,
    bool? isPlaying,
    bool? isShuffleEnabled,
    LoopMode? loopMode,
    Duration? position,
    Duration? bufferedPosition,
    Duration? duration,
    ProcessingState? processingState,
    Object? lyrics = _sentinel,
    bool? lyricsLoading,
    Object? lyricsError = _sentinel,
  }) {
    return PlayerControllerState(
      queue: queue ?? this.queue,
      currentIndex: identical(currentIndex, _sentinel)
          ? this.currentIndex
          : currentIndex as int?,
      isPlaying: isPlaying ?? this.isPlaying,
      isShuffleEnabled: isShuffleEnabled ?? this.isShuffleEnabled,
      loopMode: loopMode ?? this.loopMode,
      position: position ?? this.position,
      bufferedPosition: bufferedPosition ?? this.bufferedPosition,
      duration: duration ?? this.duration,
      processingState: processingState ?? this.processingState,
      lyrics: identical(lyrics, _sentinel)
          ? this.lyrics
          : lyrics as LyricsDocument?,
      lyricsLoading: lyricsLoading ?? this.lyricsLoading,
      lyricsError: identical(lyricsError, _sentinel)
          ? this.lyricsError
          : lyricsError as String?,
    );
  }
}

class PlayerController extends Notifier<PlayerControllerState> {
  bool _listenersAttached = false;

  AudioPlayer get _player => ref.read(audioPlayerProvider);
  LyricsRepository get _lyricsRepository => ref.read(lyricsRepositoryProvider);

  @override
  PlayerControllerState build() {
    if (!_listenersAttached) {
      _attachListeners();
      _listenersAttached = true;
    }

    return PlayerControllerState(
      currentIndex: _player.currentIndex,
      isPlaying: _player.playing,
      isShuffleEnabled: _player.shuffleModeEnabled,
      loopMode: _player.loopMode,
      position: _player.position,
      bufferedPosition: _player.bufferedPosition,
      duration: _player.duration ?? Duration.zero,
      processingState: _player.processingState,
    );
  }

  Future<void> clearLyricsForCurrentTrack() async {
    final track = state.currentTrack;
    if (track == null) {
      return;
    }

    await _lyricsRepository.clearLyrics(track);
    state = state.copyWith(lyrics: null, lyricsError: null);
  }

  Future<bool> downloadLyricsForCurrentTrack() async {
    final track = state.currentTrack;
    if (track == null) {
      return false;
    }

    state = state.copyWith(lyricsLoading: true, lyricsError: null);

    try {
      final requestedKey = track.lyricsCacheKey;
      final lyrics = await _lyricsRepository.fetchLyrics(track);
      if (!ref.mounted || state.currentTrack?.lyricsCacheKey != requestedKey) {
        return false;
      }

      if (lyrics == null) {
        state = state.copyWith(
          lyricsLoading: false,
          lyricsError:
              'No encontré una letra para esta canción. Puedes adjuntar un LRC manualmente.',
        );
        return false;
      }

      state = state.copyWith(
        lyrics: lyrics,
        lyricsLoading: false,
        lyricsError: null,
      );
      return true;
    } catch (_) {
      if (!ref.mounted) {
        return false;
      }

      state = state.copyWith(
        lyricsLoading: false,
        lyricsError:
            'No se pudo descargar la letra. Revisa la conexión e inténtalo de nuevo.',
      );
      return false;
    }
  }

  Future<void> cycleLoopMode() async {
    final nextMode = switch (state.loopMode) {
      LoopMode.off => LoopMode.all,
      LoopMode.all => LoopMode.one,
      LoopMode.one => LoopMode.off,
    };

    await _player.setLoopMode(nextMode);
    state = state.copyWith(loopMode: nextMode);
  }

  Future<void> playTrackList(
    List<Track> queue, {
    required int initialIndex,
  }) async {
    if (queue.isEmpty) {
      return;
    }

    var safeIndex = initialIndex;
    if (safeIndex < 0) {
      safeIndex = 0;
    }
    if (safeIndex >= queue.length) {
      safeIndex = queue.length - 1;
    }

    state = state.copyWith(
      queue: queue,
      currentIndex: safeIndex,
      position: Duration.zero,
      bufferedPosition: Duration.zero,
      lyrics: null,
      lyricsLoading: true,
      lyricsError: null,
    );

    final sources = queue
        .map((track) => AudioSource.file(track.filePath, tag: track))
        .toList(growable: false);

    await _player.setAudioSources(
      sources,
      initialIndex: safeIndex,
      initialPosition: Duration.zero,
    );
    await _player.play();
    await _restoreLyricsForCurrentTrack();
  }

  Future<void> saveManualLyrics(String rawLyrics) async {
    final track = state.currentTrack;
    if (track == null) {
      return;
    }

    final requestedKey = track.lyricsCacheKey;
    state = state.copyWith(lyricsLoading: true, lyricsError: null);

    final lyrics = await _lyricsRepository.saveManualLyrics(track, rawLyrics);
    if (!ref.mounted || state.currentTrack?.lyricsCacheKey != requestedKey) {
      return;
    }

    state = state.copyWith(
      lyrics: lyrics,
      lyricsLoading: false,
      lyricsError: null,
    );
  }

  Future<void> seek(Duration position) {
    return _player.seek(position);
  }

  Future<void> seekBy(Duration offset) {
    var target = state.position + offset;
    if (target < Duration.zero) {
      target = Duration.zero;
    }
    if (state.duration > Duration.zero && target > state.duration) {
      target = state.duration;
    }
    return _player.seek(target);
  }

  Future<void> skipNext() async {
    if (_player.hasNext) {
      await _player.seekToNext();
    }
  }

  Future<void> skipPrevious() async {
    if (state.position > const Duration(seconds: 3)) {
      await _player.seek(Duration.zero);
      return;
    }

    if (_player.hasPrevious) {
      await _player.seekToPrevious();
      return;
    }

    await _player.seek(Duration.zero);
  }

  Future<void> togglePlayback() async {
    if (_player.playing) {
      await _player.pause();
      return;
    }

    await _player.play();
  }

  Future<void> toggleShuffle() async {
    final enabled = !state.isShuffleEnabled;
    if (enabled) {
      await _player.shuffle();
    }

    await _player.setShuffleModeEnabled(enabled);
    state = state.copyWith(isShuffleEnabled: enabled);
  }

  void _attachListeners() {
    final subscriptions = <StreamSubscription<dynamic>>[
      _player.playerStateStream.listen((playerState) {
        if (!ref.mounted) {
          return;
        }

        state = state.copyWith(
          isPlaying: playerState.playing,
          processingState: playerState.processingState,
        );
      }),
      _player.positionStream.listen((position) {
        if (!ref.mounted) {
          return;
        }

        state = state.copyWith(position: position);
      }),
      _player.bufferedPositionStream.listen((bufferedPosition) {
        if (!ref.mounted) {
          return;
        }

        state = state.copyWith(bufferedPosition: bufferedPosition);
      }),
      _player.durationStream.listen((duration) {
        if (!ref.mounted) {
          return;
        }

        state = state.copyWith(duration: duration ?? Duration.zero);
      }),
      _player.currentIndexStream.listen((index) {
        if (!ref.mounted) {
          return;
        }

        state = state.copyWith(currentIndex: index);
        unawaited(_restoreLyricsForCurrentTrack());
      }),
      _player.shuffleModeEnabledStream.listen((enabled) {
        if (!ref.mounted) {
          return;
        }

        state = state.copyWith(isShuffleEnabled: enabled);
      }),
      _player.loopModeStream.listen((mode) {
        if (!ref.mounted) {
          return;
        }

        state = state.copyWith(loopMode: mode);
      }),
    ];

    ref.onDispose(() {
      for (final subscription in subscriptions) {
        subscription.cancel();
      }
    });
  }

  Future<void> _restoreLyricsForCurrentTrack() async {
    final track = state.currentTrack;
    if (track == null) {
      state = state.copyWith(
        lyrics: null,
        lyricsLoading: false,
        lyricsError: null,
      );
      return;
    }

    final requestedKey = track.lyricsCacheKey;
    state = state.copyWith(
      lyrics: null,
      lyricsLoading: true,
      lyricsError: null,
    );

    final lyrics = await _lyricsRepository.loadCachedLyrics(track);
    if (!ref.mounted || state.currentTrack?.lyricsCacheKey != requestedKey) {
      return;
    }

    state = state.copyWith(
      lyrics: lyrics,
      lyricsLoading: false,
      lyricsError: null,
    );
  }
}
