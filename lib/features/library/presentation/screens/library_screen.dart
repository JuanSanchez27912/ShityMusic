import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/widgets/track_artwork.dart';
import '../../../../core/extensions/duration_x.dart';
import '../../domain/entities/track.dart';
import '../controllers/library_controller.dart';
import '../../../player/presentation/controllers/player_controller.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key, required this.onOpenPlayer});

  final VoidCallback onOpenPlayer;

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final libraryAsync = ref.watch(libraryControllerProvider);
    final theme = Theme.of(context);

    return libraryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) {
        return Center(
          child: FilledButton.icon(
            onPressed: () => ref.invalidate(libraryControllerProvider),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Recargar'),
          ),
        );
      },
      data: (libraryState) {
        final tracks = libraryState.tracks
            .where((track) => _matchesQuery(track, _query))
            .toList(growable: false);

        return RefreshIndicator(
          onRefresh: () =>
              ref.read(libraryControllerProvider.notifier).refresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 140),
            children: [
              _LibraryHeroCard(state: libraryState),
              const SizedBox(height: 18),
              TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'Buscar por título, artista o álbum',
                ),
                onChanged: (value) {
                  setState(() {
                    _query = value.trim().toLowerCase();
                  });
                },
              ),
              const SizedBox(height: 18),
              if (!libraryState.permissionGranted)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Permiso pendiente',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Para listar canciones del teléfono necesito acceso a la biblioteca multimedia.',
                          style: theme.textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () => ref
                              .read(libraryControllerProvider.notifier)
                              .requestPermissionAndReload(),
                          icon: const Icon(Icons.library_music_rounded),
                          label: const Text('Conceder acceso'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (tracks.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          libraryState.totalTracks == 0
                              ? 'No encontré canciones en el dispositivo.'
                              : 'No hay resultados para la búsqueda actual.',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          libraryState.totalTracks == 0
                              ? 'Agrega música local o vuelve a escanear la biblioteca desde ajustes.'
                              : 'Prueba con otro nombre o revisa la lista negra de carpetas.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...tracks.indexed.map((entry) {
                  final index = entry.$1;
                  final track = entry.$2;
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == tracks.length - 1 ? 0 : 12,
                    ),
                    child: _TrackTile(
                      track: track,
                      onTap: () => _playTrack(tracks, index),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  bool _matchesQuery(Track track, String query) {
    if (query.isEmpty) {
      return true;
    }

    final searchable = '${track.title} ${track.artist} ${track.album}'
        .toLowerCase();
    return searchable.contains(query);
  }

  Future<void> _playTrack(List<Track> queue, int index) async {
    try {
      await ref
          .read(playerControllerProvider.notifier)
          .playTrackList(queue, initialIndex: index);

      if (!mounted) {
        return;
      }

      widget.onOpenPlayer();
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo iniciar la reproducción de este archivo.'),
        ),
      );
    }
  }
}

class _LibraryHeroCard extends StatelessWidget {
  const _LibraryHeroCard({required this.state});

  final MusicLibraryState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.secondary.withValues(alpha: 0.9),
            theme.colorScheme.primary.withValues(alpha: 0.72),
          ],
        ),
        borderRadius: BorderRadius.circular(34),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Shity Music',
              style: theme.textTheme.headlineLarge?.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Reproductor local con letras adjuntas, sincronización visual y reglas de exclusión por carpeta.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _StatPill(
                  label: 'Disponibles',
                  value: '${state.tracks.length}',
                ),
                _StatPill(label: 'Detectadas', value: '${state.totalTracks}'),
                _StatPill(label: 'Ocultas', value: '${state.hiddenTracks}'),
                _StatPill(
                  label: 'Rutas bloqueadas',
                  value: '${state.excludedFolders.length}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackTile extends StatelessWidget {
  const _TrackTile({required this.track, required this.onTap});

  final Track track;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface.withValues(alpha: 0.86),
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              TrackArtwork(track: track, size: 64, radius: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      track.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${track.album} • ${track.duration.formatClock()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.play_circle_fill_rounded,
                size: 34,
                color: theme.colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
