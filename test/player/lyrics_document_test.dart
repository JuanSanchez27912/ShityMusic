import 'package:flutter_test/flutter_test.dart';
import 'package:shity_music/features/player/domain/entities/lyrics_document.dart';

void main() {
  group('LyricsDocument', () {
    test('parses synced lrc lines', () {
      final document = LyricsDocument.fromRaw(
        raw: '''
[00:05.00]Linea uno
[00:12.34]Linea dos
''',
        source: 'manual',
      );

      expect(document.isSynced, isTrue);
      expect(document.lines.length, 2);
      expect(document.lines.first.text, 'Linea uno');
      expect(document.lines.last.timestamp.inMilliseconds, 12340);
    });

    test('falls back to plain text when timestamps are missing', () {
      final document = LyricsDocument.fromRaw(
        raw: '''
Primera linea
Segunda linea
''',
        source: 'manual',
      );

      expect(document.isSynced, isFalse);
      expect(document.lines.length, 2);
      expect(document.plainText, 'Primera linea\nSegunda linea');
    });
  });
}
