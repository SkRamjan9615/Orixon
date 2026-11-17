import 'package:orixon/core/database/app_database.dart';
import 'package:orixon/features/live_tv/data/repositories/playlist_repository.dart';
import 'package:orixon/features/live_tv/data/repositories/category_repository.dart';
import 'package:orixon/features/live_tv/domain/services/playlist_channel_matcher.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:orixon/features/live_tv/domain/services/channel_number_allocator.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late PlaylistRepository repository;

  Future<int> addPlaylist(String name) {
    return database
        .into(database.playlists)
        .insert(
          PlaylistsCompanion.insert(
            name: name,
            sourceUrlOrPath: 'local://$name',
          ),
        );
  }

  Future<int> addCategory(String name, {int start = 1, int end = 100}) {
    return database
        .into(database.categories)
        .insert(
          CategoriesCompanion.insert(
            name: name,
            rangeStart: start,
            rangeEnd: end,
            sortOrder: 0,
          ),
        );
  }

  Future<int> addChannel({
    required String name,
    required String url,
    required int categoryId,
    required int number,
    int? playlistId,
    String tvgId = '',
    bool favorite = false,
    bool locked = false,
    bool enabled = true,
    int favoriteOrder = 0,
    String backupUrl = '',
  }) {
    return database
        .into(database.channels)
        .insert(
          ChannelsCompanion.insert(
            name: name,
            primaryUrl: url,
            categoryId: categoryId,
            channelNumber: number,
            playlistId: Value(playlistId),
            epgChannelId: Value(tvgId),
            isFavorite: Value(favorite),
            isLocked: Value(locked),
            isEnabled: Value(enabled),
            favoriteOrder: Value(favoriteOrder),
            backupUrl1: Value(backupUrl),
          ),
        );
  }

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = PlaylistRepository(database: database);
  });

  tearDown(() async {
    await database.close();
  });

  group('Playlist Management API', () {
    test('lists playlists in descending ID order', () async {
      final first = await repository.createPlaylist(
        name: 'First',
        sourceUrlOrPath: 'https://example.com/first.m3u',
      );
      final second = await repository.createPlaylist(
        name: 'Second',
        sourceUrlOrPath: 'https://example.com/second.m3u',
      );

      final playlists = await repository.getAllPlaylists();

      expect(playlists.map((p) => p.id).toList(), [second.id, first.id]);
    });

    test('creates playlist with trimmed values and settings', () async {
      final playlist = await repository.createPlaylist(
        name: '  My Playlist  ',
        sourceUrlOrPath: '  https://example.com/list.m3u  ',
        epgUrl: '  https://example.com/guide.xml  ',
        autoRefreshHours: 12,
      );

      expect(playlist.name, 'My Playlist');
      expect(playlist.sourceUrlOrPath, 'https://example.com/list.m3u');
      expect(playlist.epgUrl, 'https://example.com/guide.xml');
      expect(playlist.autoRefreshHours, 12);
    });

    test('stores blank optional EPG URL as null', () async {
      final playlist = await repository.createPlaylist(
        name: 'No EPG',
        sourceUrlOrPath: 'https://example.com/no-epg.m3u',
        epgUrl: '   ',
      );

      expect(playlist.epgUrl, isNull);
    });

    test('rejects invalid name, source and refresh interval', () async {
      await expectLater(
        repository.createPlaylist(
          name: '   ',
          sourceUrlOrPath: 'https://example.com/list.m3u',
        ),
        throwsA(isA<PlaylistManagementException>()),
      );

      await expectLater(
        repository.createPlaylist(name: 'Valid Name', sourceUrlOrPath: '   '),
        throwsA(isA<PlaylistManagementException>()),
      );

      await expectLater(
        repository.createPlaylist(
          name: 'Valid Name',
          sourceUrlOrPath: 'https://example.com/list.m3u',
          autoRefreshHours: -1,
        ),
        throwsA(isA<PlaylistManagementException>()),
      );

      expect(await repository.getAllPlaylists(), isEmpty);
    });

    test('rejects duplicate source after trimming', () async {
      await repository.createPlaylist(
        name: 'Original',
        sourceUrlOrPath: 'https://example.com/list.m3u',
      );

      await expectLater(
        repository.createPlaylist(
          name: 'Duplicate',
          sourceUrlOrPath: '  https://example.com/list.m3u  ',
        ),
        throwsA(isA<PlaylistManagementException>()),
      );

      expect(await repository.getAllPlaylists(), hasLength(1));
    });

    test('returns correct playlist channel count', () async {
      final playlistId = await addPlaylist('Count Playlist');
      final categoryId = await addCategory('Count Category');

      expect(await repository.getPlaylistChannelCount(playlistId), 0);

      await addChannel(
        name: 'First Channel',
        url: 'https://example.com/count-1.m3u8',
        categoryId: categoryId,
        number: 1,
        playlistId: playlistId,
      );

      await addChannel(
        name: 'Second Channel',
        url: 'https://example.com/count-2.m3u8',
        categoryId: categoryId,
        number: 2,
        playlistId: playlistId,
      );

      expect(await repository.getPlaylistChannelCount(playlistId), 2);
      expect(await repository.getPlaylistChannelCount(-999), 0);
    });
  });

  group('Playlist deletion', () {
    test('deletes only selected playlist and its channels', () async {
      final targetId = await addPlaylist('Delete Target');
      final otherId = await addPlaylist('Keep Other');
      final categoryId = await addCategory('Delete Test');

      await addChannel(
        name: 'Target Channel',
        url: 'https://example.com/target.m3u8',
        categoryId: categoryId,
        number: 1,
        playlistId: targetId,
      );

      await addChannel(
        name: 'Other Playlist Channel',
        url: 'https://example.com/other.m3u8',
        categoryId: categoryId,
        number: 2,
        playlistId: otherId,
      );

      await addChannel(
        name: 'Standalone Channel',
        url: 'https://example.com/standalone.m3u8',
        categoryId: categoryId,
        number: 3,
      );

      expect(await repository.deletePlaylist(targetId), isTrue);

      final playlists = await database.select(database.playlists).get();
      final channels = await database.select(database.channels).get();

      expect(playlists.map((p) => p.id), [otherId]);
      expect(channels.map((c) => c.name).toSet(), {
        'Other Playlist Channel',
        'Standalone Channel',
      });
    });

    test('returns false when playlist does not exist', () async {
      expect(await repository.deletePlaylist(-999), isFalse);
    });

    test('rolls back channel deletion if playlist deletion fails', () async {
      final playlistId = await addPlaylist('Rollback Delete');
      final categoryId = await addCategory('Rollback Category');

      await addChannel(
        name: 'Must Survive Rollback',
        url: 'https://example.com/rollback.m3u8',
        categoryId: categoryId,
        number: 1,
        playlistId: playlistId,
      );

      await database.customStatement('''
        CREATE TRIGGER fail_playlist_delete
        BEFORE DELETE ON playlists
        BEGIN
          SELECT RAISE(ABORT, 'forced playlist delete failure');
        END;
      ''');

      await expectLater(
        repository.deletePlaylist(playlistId),
        throwsA(anything),
      );

      final playlist = await (database.select(
        database.playlists,
      )..where((table) => table.id.equals(playlistId))).getSingleOrNull();

      final channels = await (database.select(
        database.channels,
      )..where((table) => table.playlistId.equals(playlistId))).get();

      expect(playlist, isNotNull);
      expect(channels, hasLength(1));
      expect(channels.single.name, 'Must Survive Rollback');
    });
  });

  group('PlaylistRepository', () {
    test('inserts playlist channels and creates categories', () async {
      final playlistId = await addPlaylist('Test Playlist');

      final result = await repository.importM3u(
        playlistId: playlistId,
        content: '''
#EXTM3U
#EXTINF:-1 tvg-id="star1" group-title="Sports",Star Sports
https://example.com/star.m3u8
#EXTINF:-1 group-title="News",News Channel
https://example.com/news.m3u8
''',
      );

      final channels = await database.select(database.channels).get();
      final categories = await database.select(database.categories).get();
      final playlist = await (database.select(
        database.playlists,
      )..where((t) => t.id.equals(playlistId))).getSingle();

      expect(result.inserted, 2);
      expect(result.updated, 0);
      expect(result.removed, 0);
      expect(channels.length, 2);
      expect(categories.map((c) => c.name).toSet(), {
        'Movies',
        'Sports',
        'News',
        'Kids',
        'Music',
        'Entertainment',
        'General',
        'Others',
      });
      expect(categories.length, 8);
      expect(channels.map((c) => c.channelNumber).toSet(), {101, 201});
      expect(playlist.lastUpdated, isNotNull);
    });

    test('maps blank group-title to Others', () async {
      final playlistId = await addPlaylist('Blank Category');

      await repository.importM3u(
        playlistId: playlistId,
        content: '''
#EXTM3U
#EXTINF:-1 tvg-id="blank1",Channel Without Group
https://example.com/blank.m3u8
''',
      );

      final category = await (database.select(
        database.categories,
      )..where((t) => t.name.equals('Others'))).getSingle();

      final channel = await (database.select(
        database.channels,
      )..where((t) => t.playlistId.equals(playlistId))).getSingle();

      expect(channel.categoryId, category.id);
    });

    test('updates matching channel and preserves user settings', () async {
      final playlistId = await addPlaylist('Update Playlist');
      final categoryId = await addCategory('Sports');

      final channelId = await addChannel(
        name: 'Old Name',
        url: 'https://example.com/old.m3u8',
        categoryId: categoryId,
        number: 15,
        playlistId: playlistId,
        tvgId: 'star1',
        favorite: true,
        locked: true,
        enabled: false,
        favoriteOrder: 7,
        backupUrl: 'https://backup.example.com/old.m3u8',
      );

      final result = await repository.importM3u(
        playlistId: playlistId,
        content: '''
#EXTM3U
#EXTINF:-1 tvg-id="star1" tvg-logo="https://example.com/logo.png" group-title="Sports",New Name
https://example.com/new.m3u8
''',
      );

      final channel = await (database.select(
        database.channels,
      )..where((t) => t.id.equals(channelId))).getSingle();

      expect(result.updated, 1);
      expect(result.inserted, 0);
      expect(result.removed, 0);
      expect(channel.name, 'New Name');
      expect(channel.primaryUrl, 'https://example.com/new.m3u8');
      expect(channel.channelNumber, 15);
      expect(channel.isFavorite, isTrue);
      expect(channel.isLocked, isTrue);
      expect(channel.isEnabled, isFalse);
      expect(channel.favoriteOrder, 7);
      expect(channel.backupUrl1, 'https://backup.example.com/old.m3u8');
      expect(channel.logoUrl, 'https://example.com/logo.png');
    });

    test('removes stale target channels but preserves other playlists and standalone channels', () async {
      final targetId = await addPlaylist('Target');
      final otherId = await addPlaylist('Other');
      final categoryId = await addCategory('General');

      await addChannel(
        name: 'Keep',
        url: 'https://example.com/keep.m3u8',
        categoryId: categoryId,
        number: 1,
        playlistId: targetId,
        tvgId: 'keep',
      );

      await addChannel(
        name: 'Remove',
        url: 'https://example.com/remove.m3u8',
        categoryId: categoryId,
        number: 2,
        playlistId: targetId,
        tvgId: 'remove',
      );

      final otherChannelId = await addChannel(
        name: 'Other Playlist Channel',
        url: 'https://example.com/other.m3u8',
        categoryId: categoryId,
        number: 3,
        playlistId: otherId,
        tvgId: 'other',
      );

      final standaloneId = await addChannel(
        name: 'Manual Channel',
        url: 'https://example.com/manual.m3u8',
        categoryId: categoryId,
        number: 4,
      );

      final result = await repository.importM3u(
        playlistId: targetId,
        content: '''
#EXTM3U
#EXTINF:-1 tvg-id="keep" group-title="General",Keep Updated
https://example.com/keep.m3u8
''',
      );

      final channels = await database.select(database.channels).get();
      final ids = channels.map((c) => c.id).toSet();

      expect(result.updated, 1);
      expect(result.removed, 1);
      expect(ids.length, 3);
      expect(ids.contains(otherChannelId), isTrue);
      expect(ids.contains(standaloneId), isTrue);
      expect(channels.any((c) => c.name == 'Remove'), isFalse);
    });

    test(
      'aborts empty or invalid playlist without changing database',
      () async {
        final playlistId = await addPlaylist('Protected');
        final categoryId = await addCategory('Existing');

        await addChannel(
          name: 'Existing Channel',
          url: 'https://example.com/existing.m3u8',
          categoryId: categoryId,
          number: 1,
          playlistId: playlistId,
          tvgId: 'existing',
        );

        final beforeChannels = await database.select(database.channels).get();
        final beforeCategories = await database
            .select(database.categories)
            .get();
        final beforePlaylist = await (database.select(
          database.playlists,
        )..where((t) => t.id.equals(playlistId))).getSingle();

        for (final content in [
          '',
          '#EXTM3U\n',
          '''
#EXTM3U
#EXTINF:-1 tvg-id="bad",Invalid
not-a-valid-stream
''',
        ]) {
          await expectLater(
            repository.importM3u(playlistId: playlistId, content: content),
            throwsA(isA<PlaylistImportException>()),
          );
        }

        final afterChannels = await database.select(database.channels).get();
        final afterCategories = await database
            .select(database.categories)
            .get();
        final afterPlaylist = await (database.select(
          database.playlists,
        )..where((t) => t.id.equals(playlistId))).getSingle();

        expect(afterChannels.length, beforeChannels.length);
        expect(afterChannels.single.name, beforeChannels.single.name);
        expect(afterCategories.length, beforeCategories.length);
        expect(afterPlaylist.lastUpdated, beforePlaylist.lastUpdated);
      },
    );

    test('aborts ambiguous matching and rolls back all changes', () async {
      final playlistId = await addPlaylist('Ambiguous');
      final categoryId = await addCategory('Existing');

      await addChannel(
        name: 'Old A',
        url: 'https://example.com/same.m3u8',
        categoryId: categoryId,
        number: 1,
        playlistId: playlistId,
        tvgId: 'duplicate',
      );

      await addChannel(
        name: 'Old B',
        url: 'https://example.com/same.m3u8',
        categoryId: categoryId,
        number: 2,
        playlistId: playlistId,
        tvgId: 'duplicate',
      );

      final beforeChannels = await database.select(database.channels).get();
      final beforeCategories = await database.select(database.categories).get();

      await expectLater(
        repository.importM3u(
          playlistId: playlistId,
          content: '''
#EXTM3U
#EXTINF:-1 tvg-id="duplicate" group-title="New Category",New A
https://example.com/same.m3u8
#EXTINF:-1 tvg-id="duplicate" group-title="New Category",New B
https://example.com/same.m3u8
''',
        ),
        throwsA(isA<PlaylistChannelMatchException>()),
      );

      final afterChannels = await database.select(database.channels).get();
      final afterCategories = await database.select(database.categories).get();

      expect(afterChannels.length, beforeChannels.length);
      expect(
        afterChannels.map((c) => c.name).toSet(),
        beforeChannels.map((c) => c.name).toSet(),
      );
      expect(afterCategories.length, beforeCategories.length);
      expect(
        afterCategories.map((c) => c.name).toSet(),
        beforeCategories.map((c) => c.name).toSet(),
      );
    });

    test(
      'changes channel number when moving outside new category range',
      () async {
        final playlistId = await addPlaylist('Category Change');
        final oldCategory = await addCategory('Old', start: 1, end: 100);
        await addCategory('Sports', start: 101, end: 200);

        final channelId = await addChannel(
          name: 'Old Sports',
          url: 'https://example.com/sports.m3u8',
          categoryId: oldCategory,
          number: 5,
          playlistId: playlistId,
          tvgId: 'sports1',
        );

        await repository.importM3u(
          playlistId: playlistId,
          content: '''
#EXTM3U
#EXTINF:-1 tvg-id="sports1" group-title="Sports",Sports One
https://example.com/sports.m3u8
''',
        );

        final channel = await (database.select(
          database.channels,
        )..where((t) => t.id.equals(channelId))).getSingle();

        expect(channel.channelNumber, 101);
        expect(channel.categoryId, isNot(oldCategory));
      },
    );

    test('allocates new Others channel within 10000 limit', () async {
      await CategoryRepository(database: database).ensureStandardCategories();

      final playlistId = await addPlaylist('Others Unlimited Range');
      final others = await (database.select(
        database.categories,
      )..where((t) => t.name.equals('Others'))).getSingle();

      final oldCategory = await addCategory('Old', start: 701, end: 800);
      await addChannel(
        name: 'Old Channel',
        url: 'https://example.com/old.m3u8',
        categoryId: oldCategory,
        number: 700,
        playlistId: playlistId,
        tvgId: 'old-channel',
      );

      final result = await repository.importM3u(
        playlistId: playlistId,
        content: '''
#EXTM3U
#EXTINF:-1 tvg-id="new-others" group-title="Tiny",New Channel
https://example.com/new-others.m3u8
''',
      );

      final channels = await (database.select(database.channels)
            ..where((t) => t.playlistId.equals(playlistId)))
          .get();

      expect(result.inserted, 1);
      expect(result.removed, 1);
      expect(channels.length, 1);
      expect(channels.single.name, 'New Channel');
      expect(channels.single.categoryId, others.id);
      expect(channels.single.channelNumber, others.rangeStart);
      expect(others.rangeEnd, 10000);
    });

    test('matches duplicate tvg-id channels using unique exact URLs', () async {
      final playlistId = await addPlaylist('Duplicate IDs');
      final categoryId = await addCategory('Sports');

      final firstId = await addChannel(
        name: 'Old First',
        url: 'https://example.com/first.m3u8',
        categoryId: categoryId,
        number: 1,
        playlistId: playlistId,
        tvgId: 'duplicate',
      );

      final secondId = await addChannel(
        name: 'Old Second',
        url: 'https://example.com/second.m3u8',
        categoryId: categoryId,
        number: 2,
        playlistId: playlistId,
        tvgId: 'duplicate',
      );

      final result = await repository.importM3u(
        playlistId: playlistId,
        content: '''
#EXTM3U
#EXTINF:-1 tvg-id="duplicate" group-title="Sports",Updated First
https://example.com/first.m3u8
#EXTINF:-1 tvg-id="duplicate" group-title="Sports",Updated Second
https://example.com/second.m3u8
''',
      );

      final first = await (database.select(
        database.channels,
      )..where((t) => t.id.equals(firstId))).getSingle();

      final second = await (database.select(
        database.channels,
      )..where((t) => t.id.equals(secondId))).getSingle();

      expect(result.updated, 2);
      expect(result.inserted, 0);
      expect(result.removed, 0);
      expect(first.name, 'Updated First');
      expect(second.name, 'Updated Second');
    });

    test(
      'matches blank incoming tvg-id using URL in existing duplicate-ID group',
      () async {
        final playlistId = await addPlaylist('Blank Incoming ID');
        final categoryId = await addCategory('General');

        final matchedId = await addChannel(
          name: 'Old Channel',
          url: 'https://example.com/matched.m3u8',
          categoryId: categoryId,
          number: 1,
          playlistId: playlistId,
          tvgId: 'duplicate',
        );

        await addChannel(
          name: 'Other Duplicate',
          url: 'https://example.com/other.m3u8',
          categoryId: categoryId,
          number: 2,
          playlistId: playlistId,
          tvgId: 'duplicate',
        );

        final result = await repository.importM3u(
          playlistId: playlistId,
          content: '''
#EXTM3U
#EXTINF:-1 group-title="General",Updated Without ID
https://example.com/matched.m3u8
''',
        );

        final channel = await (database.select(
          database.channels,
        )..where((t) => t.id.equals(matchedId))).getSingle();

        final remaining = await (database.select(
          database.channels,
        )..where((t) => t.playlistId.equals(playlistId))).get();

        expect(result.updated, 1);
        expect(result.inserted, 0);
        expect(result.removed, 1);
        expect(channel.name, 'Updated Without ID');
        expect(channel.epgChannelId, '');
        expect(remaining.length, 1);
      },
    );

    test('allocates channel numbers globally across playlists and standalone channels', () async {
      final targetId = await addPlaylist('Target Global');
      final otherId = await addPlaylist('Other Global');
      final categoryId = await addCategory('General');

      await addChannel(
        name: 'Other Playlist Channel',
        url: 'https://example.com/other-global.m3u8',
        categoryId: categoryId,
        number: 1,
        playlistId: otherId,
      );

      await addChannel(
        name: 'Standalone Channel',
        url: 'https://example.com/standalone-global.m3u8',
        categoryId: categoryId,
        number: 2,
      );

      final result = await repository.importM3u(
        playlistId: targetId,
        content: '''
#EXTM3U
#EXTINF:-1 tvg-id="new-global" group-title="General",New Channel
https://example.com/new-global.m3u8
''',
      );

      final channel = await (database.select(
        database.channels,
      )..where((t) => t.playlistId.equals(targetId))).getSingle();

      expect(result.inserted, 1);
      expect(channel.channelNumber, 3);
    });

    test(
      're-importing the same M3U does not create duplicate channels',
      () async {
        final playlistId = await addPlaylist('Idempotent Playlist');

        const content = '''
#EXTM3U
#EXTINF:-1 tvg-id="stable1" group-title="News",News One
https://example.com/stable-news.m3u8
''';

        final firstResult = await repository.importM3u(
          playlistId: playlistId,
          content: content,
        );

        final secondResult = await repository.importM3u(
          playlistId: playlistId,
          content: content,
        );

        final channels = await (database.select(
          database.channels,
        )..where((t) => t.playlistId.equals(playlistId))).get();

        expect(firstResult.inserted, 1);
        expect(secondResult.inserted, 0);
        expect(secondResult.updated, 1);
        expect(secondResult.removed, 0);
        expect(channels.length, 1);
      },
    );

    test('rolls back stale deletion, inserted channels, categories and lastUpdated after mid-import failure', () async {
      await CategoryRepository(database: database).ensureStandardCategories();

      final playlistId = await addPlaylist('Mid Import Rollback');
      final others = await (database.select(
        database.categories,
      )..where((t) => t.name.equals('Others'))).getSingle();

      final obsoleteCategory = await addCategory(
        'Existing',
        start: 701,
        end: 800,
      );
      final previousUpdate = DateTime.utc(2026, 10, 1, 12);

      await (database.update(database.playlists)
            ..where((t) => t.id.equals(playlistId)))
          .write(PlaylistsCompanion(lastUpdated: Value(previousUpdate)));

      await addChannel(
        name: 'Stale Target Channel',
        url: 'https://example.com/stale.m3u8',
        categoryId: obsoleteCategory,
        number: 700,
        playlistId: playlistId,
        tvgId: 'stale',
      );

      for (
        var number = others.rangeStart;
        number <= others.rangeEnd;
        number++
      ) {
        await addChannel(
          name: 'Occupies Others $number',
          url: 'https://example.com/mid-occupied-$number.m3u8',
          categoryId: others.id,
          number: number,
        );
      }

      final beforeChannels = await database.select(database.channels).get();
      final beforeCategories = await database.select(database.categories).get();

      await expectLater(
        repository.importM3u(
          playlistId: playlistId,
          content: '''
#EXTM3U
#EXTINF:-1 tvg-id="new-first" group-title="Movies",First New Channel
https://example.com/new-first.m3u8
#EXTINF:-1 tvg-id="new-second" group-title="Tiny",Second New Channel
https://example.com/new-second.m3u8
''',
        ),
        throwsA(isA<ChannelNumberRangeFullException>()),
      );

      final afterChannels = await database.select(database.channels).get();
      final afterCategories = await database.select(database.categories).get();
      final playlist = await (database.select(
        database.playlists,
      )..where((t) => t.id.equals(playlistId))).getSingle();

      expect(afterChannels.length, beforeChannels.length);
      expect(
        afterChannels.map((c) => c.id).toSet(),
        beforeChannels.map((c) => c.id).toSet(),
      );
      expect(
        afterCategories.map((c) => c.id).toSet(),
        beforeCategories.map((c) => c.id).toSet(),
      );
      expect(
        afterChannels.any((c) => c.name == 'Stale Target Channel'),
        isTrue,
      );
      expect(afterChannels.any((c) => c.name == 'First New Channel'), isFalse);
      expect(playlist.lastUpdated?.isAtSameMomentAs(previousUpdate), isTrue);
    });
  });
}
