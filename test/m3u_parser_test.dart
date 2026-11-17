import 'package:flutter_test/flutter_test.dart';
import 'package:orixon/features/live_tv/data/parsers/m3u_parser.dart';

void main() {
  group('M3uParser', () {
    test('parses multiple channels and their metadata', () {
      const playlist = '''
#EXTM3U
#EXTINF:-1 tvg-id="star1" tvg-name="Star Sports" group-title="Sports" tvg-logo="https://example.com/star.png",Star Sports 1
https://example.com/live/star1.m3u8
#EXTINF:-1 group-title="News",News Channel
https://example.com/live/news.m3u8
''';

      final channels = M3uParser.parse(playlist);

      expect(channels.length, 2);

      expect(channels[0].name, 'Star Sports 1');
      expect(channels[0].streamUrl, 'https://example.com/live/star1.m3u8');
      expect(channels[0].tvgId, 'star1');
      expect(channels[0].tvgName, 'Star Sports');
      expect(channels[0].groupTitle, 'Sports');
      expect(channels[0].logoUrl, 'https://example.com/star.png');

      expect(channels[1].name, 'News Channel');
      expect(channels[1].groupTitle, 'News');
      expect(channels[1].tvgId, '');
    });

    test('supports single quoted attributes and VLC directives', () {
      const playlist = '''
#EXTM3U
#EXTINF:-1 tvg-id='movie1' group-title='Movies',Movie Channel
#EXTVLCOPT:http-user-agent=TestPlayer
https://example.com/movie.m3u8
''';

      final channels = M3uParser.parse(playlist);

      expect(channels.length, 1);
      expect(channels.first.name, 'Movie Channel');
      expect(channels.first.tvgId, 'movie1');
      expect(channels.first.groupTitle, 'Movies');
    });

    test('ignores URLs without EXTINF metadata', () {
      const playlist = '''
#EXTM3U
https://example.com/without-info.m3u8
''';

      expect(M3uParser.parse(playlist), isEmpty);
    });

    test('handles BOM and Windows line endings', () {
      const playlist =
          '\uFEFF#EXTM3U\r\n'
          '#EXTINF:-1,Test Channel\r\n'
          'https://example.com/test.m3u8\r\n';

      final channels = M3uParser.parse(playlist);

      expect(channels.length, 1);
      expect(channels.first.name, 'Test Channel');
    });

    test('does not attach an orphan URL to invalid pending metadata', () {
      const playlist = '''
#EXTM3U
#EXTINF:-1,Invalid Channel
not-a-valid-stream
https://example.com/orphan.m3u8
#EXTINF:-1,Valid Channel
https://example.com/valid.m3u8
''';

      final channels = M3uParser.parse(playlist);

      expect(channels.length, 1);
      expect(channels.single.name, 'Valid Channel');
      expect(channels.single.streamUrl, 'https://example.com/valid.m3u8');
    });

    test('ignores invalid entries without a URI scheme', () {
      const playlist = '''
#EXTM3U
#EXTINF:-1,Invalid Channel
not-a-valid-stream
#EXTINF:-1,Valid Channel
https://example.com/valid.m3u8
''';

      final channels = M3uParser.parse(playlist);

      expect(channels.length, 1);
      expect(channels.first.name, 'Valid Channel');
    });
  });
}
