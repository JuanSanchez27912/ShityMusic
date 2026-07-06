import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/entities/lyrics_document.dart';

class LyricsViewer extends StatefulWidget {
  const LyricsViewer({
    super.key,
    required this.lyrics,
    required this.position,
    required this.onSeekToLine,
  });

  final LyricsDocument? lyrics;
  final Duration position;
  final ValueChanged<Duration> onSeekToLine;

  @override
  State<LyricsViewer> createState() => _LyricsViewerState();
}

class _LyricsViewerState extends State<LyricsViewer> {
  static const double _lineExtent = 58;

  final ScrollController _scrollController = ScrollController();
  int _lastAnimatedIndex = -1;

  @override
  void didUpdateWidget(covariant LyricsViewer oldWidget) {
    super.didUpdateWidget(oldWidget);

    final lyrics = widget.lyrics;
    if (lyrics == null || !lyrics.isSynced) {
      return;
    }

    final activeIndex = _activeIndexForPosition(lyrics, widget.position);
    if (activeIndex == _lastAnimatedIndex || activeIndex < 0) {
      return;
    }

    _lastAnimatedIndex = activeIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      final targetOffset = math
          .max(0, (activeIndex * _lineExtent) - 120)
          .toDouble();

      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lyrics = widget.lyrics;
    final theme = Theme.of(context);

    if (lyrics == null || lyrics.lines.isEmpty) {
      return Center(
        child: Text(
          'Todavía no hay una letra adjunta para esta canción.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    if (!lyrics.isSynced) {
      return ListView.separated(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemBuilder: (context, index) {
          final line = lyrics.lines[index];
          return Text(line.text, style: theme.textTheme.bodyLarge);
        },
        separatorBuilder: (context, index) => const SizedBox(height: 14),
        itemCount: lyrics.lines.length,
      );
    }

    final activeIndex = _activeIndexForPosition(lyrics, widget.position);

    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 20),
      itemCount: lyrics.lines.length,
      itemBuilder: (context, index) {
        final line = lyrics.lines[index];
        final isActive = index == activeIndex;
        final isPast = index < activeIndex;

        return SizedBox(
          height: _lineExtent,
          child: GestureDetector(
            onTap: () => widget.onSeekToLine(line.timestamp),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: isActive
                  ? 1
                  : isPast
                  ? 0.58
                  : 0.72,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                alignment: Alignment.centerLeft,
                transform: Matrix4.translationValues(
                  isActive ? 8.0 : 0.0,
                  0,
                  0,
                ),
                child: Text(
                  line.text,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: isActive
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                    fontSize: isActive ? 22 : 18,
                    fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  int _activeIndexForPosition(LyricsDocument lyrics, Duration position) {
    for (var index = lyrics.lines.length - 1; index >= 0; index--) {
      if (position >= lyrics.lines[index].timestamp) {
        return index;
      }
    }

    return 0;
  }
}
