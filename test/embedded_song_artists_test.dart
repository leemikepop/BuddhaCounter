import 'package:buddha_counter/core/constants/chant_songs.dart';
import 'package:buddha_counter/core/content/embedded_song_artists.dart';
import 'package:buddha_counter/core/utils/audio_metadata_reader.dart';
import 'package:flutter_test/flutter_test.dart';

/// Web 版不讀音檔，改用 kEmbeddedSongArtists；這裡確保那份清單和音檔標籤一致
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('kEmbeddedSongArtists matches the artist tag inside every audio file',
      () async {
    final fromFiles = <int, String>{};
    for (final song in ChantConstants.defaultSongs) {
      final artist =
          (await AudioMetadataReader.readFromAsset(song.assetPath))?.artist;
      if (artist != null && artist.trim().isNotEmpty) {
        fromFiles[song.id] = artist.trim();
      }
    }
    expect(kEmbeddedSongArtists, fromFiles,
        reason: 'update lib/core/content/embedded_song_artists.dart');
  });

  test('the web metadata path yields the same song list as reading the files',
      () async {
    await ChantConstants.loadMetadataFromAssets();
    final fromFiles = [
      for (final s in ChantConstants.allSongs) (s.title, s.artist, s.album)
    ];

    ChantConstants.applyEmbeddedMetadata();
    final fromList = [
      for (final s in ChantConstants.allSongs) (s.title, s.artist, s.album)
    ];

    expect(fromList, fromFiles);
  });
}
