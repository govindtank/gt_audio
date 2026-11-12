import 'package:flutter_test/flutter_test.dart';
import 'package:gt_audio/gt_audio.dart';

void main() {
  group('GtTrack Tests', () {
    test('instantiates with proper default values', () {
      final track = GtTrack(
        id: 'track-1',
        title: 'Neon Nights',
        audioUri: Uri.parse('https://example.com/audio.mp3'),
      );

      expect(track.id, 'track-1');
      expect(track.title, 'Neon Nights');
      expect(track.artist, 'Unknown Artist');
      expect(track.album, 'Unknown Album');
      expect(track.isDownloaded, false);
      expect(track.effectiveUri, Uri.parse('https://example.com/audio.mp3'));
    });

    test('serializes to and from JSON accurately', () {
      final track = GtTrack(
        id: 't-2',
        title: 'Synthwave Odyssey',
        artist: 'Govind',
        album: 'Cyber Dreams',
        duration: const Duration(minutes: 3, seconds: 45),
        audioUri: Uri.parse('https://example.com/track2.mp3'),
        artUri: Uri.parse('https://example.com/art2.jpg'),
        localPath: '/tmp/track2.mp3',
        extras: {'genre': 'Electronic'},
      );

      final json = track.toJson();
      final revived = GtTrack.fromJson(json);

      expect(revived.id, track.id);
      expect(revived.title, track.title);
      expect(revived.artist, track.artist);
      expect(revived.album, track.album);
      expect(revived.duration, track.duration);
      expect(revived.audioUri, track.audioUri);
      expect(revived.artUri, track.artUri);
      expect(revived.localPath, track.localPath);
      expect(revived.extras?['genre'], 'Electronic');
    });

    test('converts to MediaItem for AudioService', () {
      final track = GtTrack(
        id: 't-3',
        title: 'Electric Horizon',
        artist: 'Govind',
        audioUri: Uri.parse('https://example.com/track3.mp3'),
        duration: const Duration(seconds: 120),
      );

      final mediaItem = track.toMediaItem();
      expect(mediaItem.id, 't-3');
      expect(mediaItem.title, 'Electric Horizon');
      expect(mediaItem.artist, 'Govind');
      expect(mediaItem.duration?.inSeconds, 120);
      expect(mediaItem.extras?['audioUri'], 'https://example.com/track3.mp3');

      final reconstructed = GtTrack.fromMediaItem(mediaItem);
      expect(reconstructed.id, track.id);
      expect(reconstructed.title, track.title);
      expect(reconstructed.artist, track.artist);
    });

    test('equality and hashCode work as expected', () {
      final t1 = GtTrack(
        id: 'same-id',
        title: 'Title A',
        audioUri: Uri.parse('https://a.com'),
      );
      final t2 = GtTrack(
        id: 'same-id',
        title: 'Title B',
        audioUri: Uri.parse('https://b.com'),
      );

      expect(t1, equals(t2));
      expect(t1.hashCode, equals(t2.hashCode));
    });
  });
}
