import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

import '../../features/library/domain/entities/track.dart';

class TrackArtwork extends StatelessWidget {
  const TrackArtwork({
    super.key,
    required this.track,
    required this.size,
    this.radius = 20,
  });

  final Track track;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);

    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        width: size,
        height: size,
        child: QueryArtworkWidget(
          id: track.artworkId,
          type: ArtworkType.AUDIO,
          keepOldArtwork: true,
          artworkFit: BoxFit.cover,
          nullArtworkWidget: _FallbackArtwork(size: size),
        ),
      ),
    );
  }
}

class _FallbackArtwork extends StatelessWidget {
  const _FallbackArtwork({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.secondary.withValues(alpha: 0.85),
            theme.colorScheme.primary.withValues(alpha: 0.75),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.graphic_eq_rounded,
          size: size * 0.38,
          color: Colors.white.withValues(alpha: 0.88),
        ),
      ),
    );
  }
}
