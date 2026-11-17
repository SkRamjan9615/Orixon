import 'package:orixon/features/live_tv/data/models/m3u_channel.dart';
import 'package:orixon/features/live_tv/domain/services/playlist_channel_matcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const matcher = PlaylistChannelMatcher();

  M3uChannel incoming(String name, String url, {String tvgId = ''}) {
    return M3uChannel(name: name, streamUrl: url, tvgId: tvgId);
  }

  ExistingPlaylistChannel existing(int id, String url, {String tvgId = ''}) {
    return ExistingPlaylistChannel(id: id, streamUrl: url, tvgId: tvgId);
  }

  group('PlaylistChannelMatcher', () {
    test('matches unique tvg-id', () {
      final result = matcher.match(
        incoming: [
          incoming('New name', 'https://new.example/live', tvgId: 'star1'),
        ],
        existing: [existing(10, 'https://old.example/live', tvgId: 'star1')],
      );

      expect(result, {0: 10});
    });

    test('falls back to exact URL when incoming tvg-id is duplicated', () {
      final result = matcher.match(
        incoming: [
          incoming('Channel A', 'https://a.example/live', tvgId: 'duplicate'),
          incoming('Channel B', 'https://b.example/live', tvgId: 'duplicate'),
        ],
        existing: [
          existing(10, 'https://a.example/live', tvgId: 'duplicate'),
          existing(20, 'https://b.example/live', tvgId: 'duplicate'),
        ],
      );

      expect(result, {0: 10, 1: 20});
    });

    test('falls back to exact URL when existing tvg-id is duplicated', () {
      final result = matcher.match(
        incoming: [
          incoming('Channel A', 'https://a.example/live', tvgId: 'star1'),
        ],
        existing: [
          existing(10, 'https://a.example/live', tvgId: 'star1'),
          existing(20, 'https://b.example/live', tvgId: 'star1'),
        ],
      );

      expect(result, {0: 10});
    });

    test('falls back to URL when incoming ID is duplicated but absent in existing IDs', () {
      final result = matcher.match(
        incoming: [
          incoming('Channel A', 'https://a.example/live', tvgId: 'duplicate'),
          incoming('Channel B', 'https://b.example/live', tvgId: 'duplicate'),
        ],
        existing: [
          existing(10, 'https://a.example/live', tvgId: 'old-a'),
          existing(20, 'https://b.example/live', tvgId: 'old-b'),
        ],
      );

      expect(result, {0: 10, 1: 20});
    });

    test('uses exact URL when incoming tvg-id is blank and existing ID is duplicated', () {
      final result = matcher.match(
        incoming: [incoming('Channel A', 'https://a.example/live')],
        existing: [
          existing(10, 'https://a.example/live', tvgId: 'duplicate'),
          existing(20, 'https://other.example/live', tvgId: 'duplicate'),
        ],
      );

      expect(result, {0: 10});
    });

    test('does not match by channel name', () {
      final result = matcher.match(
        incoming: [incoming('Same Name', 'https://new.example/live')],
        existing: [existing(10, 'https://old.example/live')],
      );

      expect(result, isEmpty);
    });

    test('does not match when tvg-id is absent and URL differs', () {
      final result = matcher.match(
        incoming: [incoming('Channel A', 'https://new.example/live')],
        existing: [existing(10, 'https://old.example/live')],
      );

      expect(result, isEmpty);
    });

    test('aborts when duplicate ID fallback URL is duplicated incoming', () {
      expect(
        () => matcher.match(
          incoming: [
            incoming('A', 'https://same.example/live', tvgId: 'duplicate'),
            incoming('B', 'https://same.example/live', tvgId: 'duplicate'),
          ],
          existing: [
            existing(10, 'https://same.example/live', tvgId: 'duplicate'),
          ],
        ),
        throwsA(isA<PlaylistChannelMatchException>()),
      );
    });

    test('aborts when duplicate ID fallback URL is duplicated existing', () {
      expect(
        () => matcher.match(
          incoming: [
            incoming('A', 'https://same.example/live', tvgId: 'duplicate'),
          ],
          existing: [
            existing(10, 'https://same.example/live', tvgId: 'duplicate'),
            existing(20, 'https://same.example/live', tvgId: 'duplicate'),
          ],
        ),
        throwsA(isA<PlaylistChannelMatchException>()),
      );
    });

    test('does not reuse one existing channel twice', () {
      expect(
        () => matcher.match(
          incoming: [
            incoming('A', 'https://same.example/live', tvgId: 'duplicate'),
            incoming('B', 'https://same.example/live', tvgId: 'duplicate'),
          ],
          existing: [
            existing(10, 'https://same.example/live', tvgId: 'duplicate'),
          ],
        ),
        throwsA(isA<PlaylistChannelMatchException>()),
      );
    });

    test('does not normalize stream URLs', () {
      final result = matcher.match(
        incoming: [incoming('A', 'https://example.com/live/', tvgId: 'star1')],
        existing: [existing(10, 'https://example.com/live', tvgId: 'star1')],
      );

      expect(result, {0: 10});
    });

    test('returns no match for an ID not present in existing channels', () {
      final result = matcher.match(
        incoming: [incoming('A', 'https://a.example/live', tvgId: 'new-id')],
        existing: [existing(10, 'https://a.example/live', tvgId: 'old-id')],
      );

      expect(result, isEmpty);
    });
  });
}
