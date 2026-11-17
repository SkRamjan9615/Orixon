import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:orixon/core/database/app_database.dart';
import 'package:orixon/core/providers/app_providers.dart';
import 'package:orixon/features/live_tv/data/repositories/playlist_repository.dart';
import 'package:orixon/features/live_tv/data/repositories/category_repository.dart';
import 'package:orixon/features/live_tv/data/services/m3u_source_service.dart';
import 'package:orixon/features/live_tv/presentation/live_tv_screen.dart';
import 'package:orixon/features/os_shell/presentation/widgets/playlist_management_panel.dart';

const validPlaylist = '''
#EXTM3U
#EXTINF:-1 tvg-id="news1" group-title="News",News Channel
https://example.com/news.m3u8
''';

class _TestM3uSourceService extends M3uSourceService {
  _TestM3uSourceService({required super.client});

  String? localPath;
  String? localContent;
  String? requestedLocalPath;

  @override
  Future<String> loadFromPath(String path) async {
    requestedLocalPath = path;
    if (path == localPath && localContent != null) {
      return localContent!;
    }
    return super.loadFromPath(path);
  }
}

void main() {
  late AppDatabase database;
  late _TestM3uSourceService sourceService;
  late String responseBody;
  late int responseStatus;
  late int requestCount;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());

    responseBody = validPlaylist;
    responseStatus = 200;
    requestCount = 0;

    sourceService = _TestM3uSourceService(
      client: MockClient((request) async {
        requestCount++;
        return http.Response(responseBody, responseStatus);
      }),
    );
  });

  tearDown(() async {
    sourceService.close();
    await database.close();
  });

  Future<void> openLiveTv(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          m3uSourceServiceProvider.overrideWithValue(sourceService),
        ],
        child: MaterialApp(
          home: LiveTvScreen(database: database, enablePlayback: false),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  Future<void> openPlaylistPanel(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          m3uSourceServiceProvider.overrideWithValue(sourceService),
        ],
        child: const MaterialApp(
          home: Scaffold(body: PlaylistManagementPanel()),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  Future<void> openAddPlaylistDialog(WidgetTester tester) async {
    await tester.tap(find.text('ADD PLAYLIST'));
    await tester.pumpAndSettle();
  }

  Future<void> enterPlaylistDetails(
    WidgetTester tester, {
    required String name,
    required String url,
  }) async {
    await tester.enterText(find.byType(TextFormField).at(0), name);
    await tester.enterText(find.byType(TextFormField).at(1), url);
  }

  Future<void> pumpUntilVisible(WidgetTester tester, Finder finder) async {
    for (var attempt = 0; attempt < 40; attempt++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (finder.evaluate().isNotEmpty) return;
    }
    fail('Timed out waiting for widget: $finder');
  }

  Future<void> disposeLiveTv(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }

  group('Settings playlist management UI', () {
    testWidgets('rejects invalid URL without making a request', (tester) async {
      await openPlaylistPanel(tester);
      await openAddPlaylistDialog(tester);

      await enterPlaylistDetails(
        tester,
        name: 'Test Playlist',
        url: 'ftp://example.com/list.m3u',
      );

      await tester.tap(find.widgetWithText(FilledButton, 'IMPORT & SYNC'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid HTTP or HTTPS URL'), findsOneWidget);
      expect(requestCount, 0);

      await disposeLiveTv(tester);
    });

    testWidgets('imports valid URL and saves playlist and channels', (
      tester,
    ) async {
      await openPlaylistPanel(tester);
      await openAddPlaylistDialog(tester);

      await enterPlaylistDetails(
        tester,
        name: 'News Playlist',
        url: 'https://example.com/list.m3u',
      );

      await tester.tap(find.widgetWithText(FilledButton, 'IMPORT & SYNC'));
      await tester.pumpAndSettle();

      final playlists = await database.select(database.playlists).get();
      final channels = await database.select(database.channels).get();

      expect(requestCount, 1);
      expect(playlists, hasLength(1));
      expect(playlists.single.name, 'News Playlist');
      expect(playlists.single.sourceUrlOrPath, 'https://example.com/list.m3u');
      expect(channels, hasLength(1));
      expect(channels.single.name, 'News Channel');

      await disposeLiveTv(tester);
    });

    testWidgets('asks before updating an existing playlist', (tester) async {
      await PlaylistRepository(database: database).createPlaylist(
        name: 'Existing Playlist',
        sourceUrlOrPath: 'https://example.com/list.m3u',
      );

      await openPlaylistPanel(tester);
      await openAddPlaylistDialog(tester);

      await enterPlaylistDetails(
        tester,
        name: 'Another Name',
        url: 'https://example.com/list.m3u',
      );

      await tester.tap(find.widgetWithText(FilledButton, 'IMPORT & SYNC'));
      await pumpUntilVisible(tester, find.text('Playlist already exists'));

      expect(find.text('Playlist already exists'), findsOneWidget);
      expect(find.text('Update'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Update'));
      await pumpUntilVisible(tester, find.textContaining('Playlist updated:'));

      final playlists = await database.select(database.playlists).get();
      final channels = await database.select(database.channels).get();

      expect(playlists, hasLength(1));
      expect(playlists.single.name, 'Existing Playlist');
      expect(channels, hasLength(1));
      expect(channels.single.name, 'News Channel');

      await disposeLiveTv(tester);
    });

    testWidgets('does not create a playlist when download fails', (
      tester,
    ) async {
      responseStatus = 503;
      responseBody = 'Service unavailable';

      await openPlaylistPanel(tester);
      await openAddPlaylistDialog(tester);

      await enterPlaylistDetails(
        tester,
        name: 'Failed Playlist',
        url: 'https://example.com/failed.m3u',
      );

      await tester.tap(find.widgetWithText(FilledButton, 'IMPORT & SYNC'));
      await tester.pumpAndSettle();

      final playlists = await database.select(database.playlists).get();

      expect(requestCount, 1);
      expect(playlists, isEmpty);
      expect(
        find.text('Playlist download failed with HTTP status 503.'),
        findsOneWidget,
      );

      await disposeLiveTv(tester);
    });

    testWidgets('shows playlist details and channel count', (tester) async {
      final repository = PlaylistRepository(database: database);
      final playlist = await repository.createPlaylist(
        name: 'Managed Playlist',
        sourceUrlOrPath: 'https://example.com/managed.m3u',
      );
      await repository.importM3u(
        playlistId: playlist.id,
        content: validPlaylist,
      );

      await openPlaylistPanel(tester);
      await tester.pumpAndSettle();

      expect(find.text('Managed Playlist'), findsOneWidget);
      expect(find.text('https://example.com/managed.m3u'), findsOneWidget);
      expect(find.text('1 CHANNELS'), findsOneWidget);

      await tester.pumpAndSettle();
      await disposeLiveTv(tester);
    });

    testWidgets('canceling playlist deletion keeps playlist and channels', (
      tester,
    ) async {
      final repository = PlaylistRepository(database: database);
      final playlist = await repository.createPlaylist(
        name: 'Keep Playlist',
        sourceUrlOrPath: 'https://example.com/keep.m3u',
      );
      await repository.importM3u(
        playlistId: playlist.id,
        content: validPlaylist,
      );

      await openPlaylistPanel(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Delete Playlist'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Playlist?'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'CANCEL'));
      await tester.pumpAndSettle();

      expect(await database.select(database.playlists).get(), hasLength(1));
      expect(await database.select(database.channels).get(), hasLength(1));

      await disposeLiveTv(tester);
    });

    testWidgets('confirming playlist deletion removes playlist and channels', (
      tester,
    ) async {
      final repository = PlaylistRepository(database: database);
      final playlist = await repository.createPlaylist(
        name: 'Delete Playlist',
        sourceUrlOrPath: 'https://example.com/delete.m3u',
      );
      await repository.importM3u(
        playlistId: playlist.id,
        content: validPlaylist,
      );

      await openPlaylistPanel(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Delete Playlist'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'DELETE'));
      await tester.pumpAndSettle();

      expect(await database.select(database.playlists).get(), isEmpty);
      expect(await database.select(database.channels).get(), isEmpty);
      expect(find.text('No IPTV Playlists Configured'), findsOneWidget);

      await disposeLiveTv(tester);
    });

    testWidgets('updates playlist from Manage Playlists', (tester) async {
      await PlaylistRepository(database: database).createPlaylist(
        name: 'Existing Managed Playlist',
        sourceUrlOrPath: 'https://example.com/list.m3u',
      );

      await openPlaylistPanel(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Sync / Reload Playlist'));

      await pumpUntilVisible(tester, find.text('Playlist already exists'));
      expect(requestCount, 1);

      await tester.tap(find.widgetWithText(FilledButton, 'Update'));
      await pumpUntilVisible(tester, find.textContaining('Playlist updated:'));

      final playlists = await database.select(database.playlists).get();
      final channels = await database.select(database.channels).get();

      expect(playlists, hasLength(1));
      expect(playlists.single.name, 'Existing Managed Playlist');
      expect(channels, hasLength(1));
      expect(channels.single.name, 'News Channel');

      await disposeLiveTv(tester);
    });
  });

  testWidgets('imports a local M3U file from the File Path mode', (
    tester,
  ) async {
    const localPath = '/tmp/local-list.m3u';
    sourceService
      ..localPath = localPath
      ..localContent = validPlaylist;

    await openPlaylistPanel(tester);
    await openAddPlaylistDialog(tester);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Local News Playlist',
    );
    await tester.tap(find.text('Path'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(1), localPath);
    await tester.tap(find.widgetWithText(FilledButton, 'IMPORT & SYNC'));
    await tester.pumpAndSettle();

    final playlists = await database.select(database.playlists).get();
    final channels = await database.select(database.channels).get();

    expect(sourceService.requestedLocalPath, localPath);
    expect(requestCount, 0);
    expect(playlists, hasLength(1));
    expect(playlists.single.name, 'Local News Playlist');
    expect(playlists.single.sourceUrlOrPath, localPath);
    expect(channels, hasLength(1));
    expect(channels.single.name, 'News Channel');

    await disposeLiveTv(tester);
  });

  group('Live TV channel search UI', () {
    Future<void> seedSearchChannels() async {
      final categoryRepository = CategoryRepository(database: database);
      final news = await categoryRepository.getOrCreateCategory('News');
      final sports = await categoryRepository.getOrCreateCategory('Sports');

      await database
          .into(database.channels)
          .insert(
            ChannelsCompanion.insert(
              channelNumber: 12,
              name: 'World News',
              categoryId: news.id,
              primaryUrl: 'https://example.com/world-news.m3u8',
            ),
          );

      await database
          .into(database.channels)
          .insert(
            ChannelsCompanion.insert(
              channelNumber: 120,
              name: 'Sports HD',
              categoryId: sports.id,
              primaryUrl: 'https://example.com/sports.m3u8',
            ),
          );

      await database
          .into(database.channels)
          .insert(
            ChannelsCompanion.insert(
              channelNumber: 121,
              name: 'News Sports',
              categoryId: sports.id,
              primaryUrl: 'https://example.com/news-sports.m3u8',
            ),
          );
    }

    Future<void> openSearch(WidgetTester tester, String query) async {
      await tester.enterText(
        find.byKey(const ValueKey('channel-search-field')),
        query,
      );
      await tester.pumpAndSettle();
    }

    testWidgets('searches channel names case-insensitively', (tester) async {
      await seedSearchChannels();
      await openLiveTv(tester);

      await openSearch(tester, 'wOrLd');

      expect(find.text('World News'), findsOneWidget);
      expect(find.text('Sports HD'), findsNothing);
      expect(find.text('News Sports'), findsNothing);

      await disposeLiveTv(tester);
    });

    testWidgets('searches partial channel numbers', (tester) async {
      await seedSearchChannels();
      await openLiveTv(tester);

      await openSearch(tester, '20');

      expect(find.text('Sports HD'), findsOneWidget);
      expect(find.text('120'), findsOneWidget);
      expect(find.text('World News'), findsNothing);
      expect(find.text('News Sports'), findsNothing);

      await disposeLiveTv(tester);
    });

    testWidgets('shows a message when no channel matches', (tester) async {
      await seedSearchChannels();
      await openLiveTv(tester);

      await openSearch(tester, 'not-a-channel');

      expect(find.text('No match'), findsOneWidget);
      expect(find.text('World News'), findsNothing);
      expect(find.text('Sports HD'), findsNothing);

      await disposeLiveTv(tester);
    });

    testWidgets('combines category and search filters', (tester) async {
      await seedSearchChannels();
      await openLiveTv(tester);

      await tester.tap(find.text('News').first);
      await tester.pumpAndSettle();

      await openSearch(tester, 'news');

      expect(find.text('World News'), findsOneWidget);
      expect(find.text('News Sports'), findsNothing);
      expect(find.text('Sports HD'), findsNothing);

      await disposeLiveTv(tester);
    });

    testWidgets('saves favorite status when the heart button is tapped', (
      tester,
    ) async {
      await seedSearchChannels();
      await openLiveTv(tester);

      await tester.tap(find.byIcon(Icons.favorite_border).first);
      await pumpUntilVisible(tester, find.byIcon(Icons.favorite));

      final channels = await database.select(database.channels).get();
      final favoriteChannels = channels
          .where((channel) => channel.isFavorite)
          .toList();

      expect(favoriteChannels, hasLength(1));
      expect(favoriteChannels.single.name, 'World News');

      await disposeLiveTv(tester);
    });

    testWidgets('shows only favorite channels in Favorites filter', (
      tester,
    ) async {
      await seedSearchChannels();
      await (database.update(database.channels)
            ..where((table) => table.name.equals('Sports HD')))
          .write(const ChannelsCompanion(isFavorite: Value(true)));

      await openLiveTv(tester);
      await tester.tap(find.text('Favourite'));
      await tester.pumpAndSettle();

      expect(find.text('Sports HD'), findsOneWidget);
      expect(find.text('World News'), findsNothing);
      expect(find.text('News Sports'), findsNothing);

      await disposeLiveTv(tester);
    });

    testWidgets('selecting a category clears the Favorites filter', (tester) async {
      await seedSearchChannels();
      await (database.update(database.channels)
            ..where((table) => table.name.isIn(['World News', 'Sports HD'])))
          .write(const ChannelsCompanion(isFavorite: Value(true)));

      await openLiveTv(tester);
      await tester.tap(find.text('Favourite'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sports').first);
      await tester.pumpAndSettle();

      expect(find.text('World News'), findsNothing);
      expect(find.text('Sports HD'), findsOneWidget);
      expect(find.text('News Sports'), findsOneWidget);

      await disposeLiveTv(tester);
    });

    testWidgets('shows an empty state when there are no favorites', (
      tester,
    ) async {
      await seedSearchChannels();
      await openLiveTv(tester);

      await tester.tap(find.text('Favourite'));
      await tester.pumpAndSettle();

      expect(find.text('No channels'), findsOneWidget);
      expect(find.text('World News'), findsNothing);
      expect(find.text('Sports HD'), findsNothing);

      await disposeLiveTv(tester);
    });
  });
}
