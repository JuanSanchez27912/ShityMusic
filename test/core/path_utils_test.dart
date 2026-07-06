import 'package:flutter_test/flutter_test.dart';
import 'package:shity_music/core/utils/path_utils.dart';

void main() {
  group('path utils', () {
    test('normalizes and matches excluded folders', () {
      const songPath = r'/storage/emulated/0/Music/Rock/song.mp3';
      const excluded = [r'/storage/emulated/0/Music/Rock'];

      expect(pathMatchesExcludedFolder(songPath, excluded), isTrue);
    });

    test('extracts folder suggestions from file paths', () {
      final suggestions = collectFolderSuggestions(const [
        '/music/a/song-1.mp3',
        '/music/a/song-2.mp3',
        '/music/b/song-3.mp3',
      ]);

      expect(suggestions.first, '/music/a');
      expect(suggestions, contains('/music/b'));
    });
  });
}
