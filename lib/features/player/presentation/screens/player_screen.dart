import 'dart:math' as math;

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../app/widgets/track_artwork.dart';
import '../../domain/entities/lyrics_document.dart';
import '../controllers/player_controller.dart';
import '../widgets/lyrics_viewer.dart';

class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerControllerProvider);
    final controller = ref.read(playerControllerProvider.notifier);
    final track = playerState.currentTrack;
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppTheme.backdropGradient(theme.brightness),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: track == null
              ? Center(
                  child: Text(
                    'No hay ninguna canción en reproducción.',
                    style: theme.textTheme.titleLarge,
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final artworkSize = math
                        .min(
                          constraints.maxWidth * 0.72,
                          constraints.maxHeight < 760 ? 240 : 320,
                        )
                        .toDouble();

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              IconButton.filledTonal(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.arrow_back_rounded),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Reproduciendo ahora',
                                      style: theme.textTheme.titleLarge,
                                    ),
                                    Text(
                                      track.album,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Hero(
                            tag: 'player-art-${track.id}',
                            child: TrackArtwork(
                              track: track,
                              size: artworkSize,
                              radius: 34,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            track.title,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            track.artist,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              FilterChip(
                                selected: playerState.isShuffleEnabled,
                                label: const Text('Aleatorio'),
                                avatar: Icon(
                                  Icons.shuffle_rounded,
                                  color: playerState.isShuffleEnabled
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                                onSelected: (_) => controller.toggleShuffle(),
                              ),
                              const SizedBox(width: 10),
                              FilterChip(
                                selected: playerState.loopMode != LoopMode.off,
                                label: Text(
                                  _loopModeLabel(playerState.loopMode),
                                ),
                                avatar: Icon(
                                  playerState.loopMode == LoopMode.one
                                      ? Icons.repeat_one_rounded
                                      : Icons.repeat_rounded,
                                  color: playerState.loopMode != LoopMode.off
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                                onSelected: (_) => controller.cycleLoopMode(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ProgressBar(
                            progress: playerState.position,
                            buffered: playerState.bufferedPosition,
                            total: playerState.duration > Duration.zero
                                ? playerState.duration
                                : const Duration(milliseconds: 1),
                            onSeek: controller.seek,
                            barHeight: 6,
                            thumbRadius: 8,
                            baseBarColor: theme.colorScheme.onSurface
                                .withValues(alpha: 0.12),
                            bufferedBarColor: theme.colorScheme.primary
                                .withValues(alpha: 0.22),
                            progressBarColor: theme.colorScheme.primary,
                            thumbColor: theme.colorScheme.primary,
                            timeLabelTextStyle: theme.textTheme.labelLarge,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                onPressed: controller.skipPrevious,
                                iconSize: 34,
                                icon: const Icon(Icons.skip_previous_rounded),
                              ),
                              IconButton(
                                onPressed: () => controller.seekBy(
                                  const Duration(seconds: -10),
                                ),
                                iconSize: 28,
                                icon: const Icon(Icons.replay_10_rounded),
                              ),
                              IconButton.filled(
                                onPressed: controller.togglePlayback,
                                iconSize: 38,
                                icon: Icon(
                                  playerState.isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                ),
                              ),
                              IconButton(
                                onPressed: () => controller.seekBy(
                                  const Duration(seconds: 10),
                                ),
                                iconSize: 28,
                                icon: const Icon(Icons.forward_10_rounded),
                              ),
                              IconButton(
                                onPressed: controller.skipNext,
                                iconSize: 34,
                                icon: const Icon(Icons.skip_next_rounded),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Expanded(
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  18,
                                  18,
                                  18,
                                  12,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Visor de letras',
                                                style:
                                                    theme.textTheme.titleLarge,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                playerState.lyrics?.source ??
                                                    'Sin letra adjunta',
                                                style: theme
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.copyWith(
                                                      color: theme
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: 'Descargar letra',
                                          onPressed: () async {
                                            final success = await controller
                                                .downloadLyricsForCurrentTrack();
                                            if (!context.mounted) {
                                              return;
                                            }

                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  success
                                                      ? 'Letra actualizada.'
                                                      : 'No se pudo obtener una letra automática.',
                                                ),
                                              ),
                                            );
                                          },
                                          icon: const Icon(
                                            Icons.download_rounded,
                                          ),
                                        ),
                                        IconButton(
                                          tooltip: 'Adjuntar o editar letra',
                                          onPressed: () async {
                                            await _showLyricsEditor(
                                              context,
                                              controller,
                                              playerState.lyrics,
                                            );
                                          },
                                          icon: const Icon(
                                            Icons.edit_note_rounded,
                                          ),
                                        ),
                                        if (playerState.lyrics != null)
                                          IconButton(
                                            tooltip: 'Quitar letra adjunta',
                                            onPressed: controller
                                                .clearLyricsForCurrentTrack,
                                            icon: const Icon(
                                              Icons.delete_outline_rounded,
                                            ),
                                          ),
                                      ],
                                    ),
                                    if (playerState.lyricsLoading) ...[
                                      const SizedBox(height: 12),
                                      const LinearProgressIndicator(),
                                    ],
                                    if (playerState.lyricsError != null) ...[
                                      const SizedBox(height: 12),
                                      Text(
                                        playerState.lyricsError!,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: theme.colorScheme.error,
                                            ),
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                    Expanded(
                                      child: LyricsViewer(
                                        lyrics: playerState.lyrics,
                                        position: playerState.position,
                                        onSeekToLine: controller.seek,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  static String _loopModeLabel(LoopMode loopMode) {
    return switch (loopMode) {
      LoopMode.off => 'Bucle: no',
      LoopMode.all => 'Bucle: lista',
      LoopMode.one => 'Bucle: una',
    };
  }

  static Future<void> _showLyricsEditor(
    BuildContext context,
    PlayerController controller,
    LyricsDocument? existingLyrics,
  ) async {
    final editorController = TextEditingController(
      text: existingLyrics?.raw ?? '',
    );

    final rawLyrics = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Adjuntar letra'),
          content: TextField(
            controller: editorController,
            autofocus: true,
            maxLines: 14,
            minLines: 10,
            decoration: const InputDecoration(
              hintText: '[00:12.00] Primera linea\n[00:18.40] Segunda linea',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(editorController.text.trim()),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (rawLyrics == null || rawLyrics.isEmpty) {
      editorController.dispose();
      return;
    }

    await controller.saveManualLyrics(rawLyrics);
    editorController.dispose();
  }
}
