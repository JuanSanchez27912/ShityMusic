import 'dart:convert';

import 'lyric_line.dart';

class LyricsDocument {
  const LyricsDocument({
    required this.raw,
    required this.lines,
    required this.isSynced,
    required this.source,
    required this.updatedAt,
  });

  factory LyricsDocument.fromRaw({
    required String raw,
    required String source,
    DateTime? updatedAt,
  }) {
    final normalizedRaw = raw.trim();
    final syncedLines = _parseSyncedLines(normalizedRaw);

    return LyricsDocument(
      raw: normalizedRaw,
      lines: syncedLines.isNotEmpty
          ? syncedLines
          : _parsePlainLines(normalizedRaw),
      isSynced: syncedLines.isNotEmpty,
      source: source,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  factory LyricsDocument.fromJson(Map<String, dynamic> json) {
    return LyricsDocument.fromRaw(
      raw: (json['raw'] ?? '').toString(),
      source: (json['source'] ?? 'Local').toString(),
      updatedAt: DateTime.tryParse((json['updatedAt'] ?? '').toString()),
    );
  }

  static final RegExp _timestampPattern = RegExp(
    r'\[(\d{1,2}):(\d{2})(?:[.:](\d{1,3}))?\]',
  );

  final String raw;
  final List<LyricLine> lines;
  final bool isSynced;
  final String source;
  final DateTime updatedAt;

  String get plainText => lines.map((line) => line.text).join('\n');

  Map<String, dynamic> toJson() {
    return {
      'raw': raw,
      'source': source,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static List<LyricLine> _parsePlainLines(String raw) {
    return LineSplitter.split(raw)
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .map((line) => LyricLine(timestamp: Duration.zero, text: line))
        .toList(growable: false);
  }

  static List<LyricLine> _parseSyncedLines(String raw) {
    final lines = <LyricLine>[];

    for (final line in LineSplitter.split(raw)) {
      final matches = _timestampPattern
          .allMatches(line)
          .toList(growable: false);
      if (matches.isEmpty) {
        continue;
      }

      final content = line.replaceAll(_timestampPattern, '').trim();
      final lyricText = content.isEmpty ? '...' : content;

      for (final match in matches) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final fraction = match.group(3);

        lines.add(
          LyricLine(
            timestamp: Duration(
              minutes: minutes,
              seconds: seconds,
              milliseconds: _fractionToMilliseconds(fraction),
            ),
            text: lyricText,
          ),
        );
      }
    }

    lines.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return lines;
  }

  static int _fractionToMilliseconds(String? fraction) {
    if (fraction == null || fraction.isEmpty) {
      return 0;
    }

    if (fraction.length == 1) {
      return int.parse(fraction) * 100;
    }
    if (fraction.length == 2) {
      return int.parse(fraction) * 10;
    }

    return int.parse(fraction.substring(0, 3));
  }
}
