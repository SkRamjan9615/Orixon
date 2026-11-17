import 'package:orixon/core/database/app_database.dart';
import 'package:orixon/features/live_tv/data/repositories/channel_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late ChannelRepository repository;
  late int categoryId;
  late int channelId;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    repository = ChannelRepository(database: database);

    categoryId = await database
        .into(database.categories)
        .insert(
          CategoriesCompanion.insert(
            name: 'Entertainment',
            rangeStart: 1,
            rangeEnd: 100,
            sortOrder: 0,
          ),
        );

    channelId = await database
        .into(database.channels)
        .insert(
          ChannelsCompanion.insert(
            name: 'Test Channel',
            primaryUrl: 'https://example.com/live.m3u8',
            categoryId: categoryId,
            channelNumber: 1,
          ),
        );
  });

  tearDown(() async {
    await database.close();
  });

  group('ChannelRepository', () {
    test('sets channel as favorite', () async {
      final updated = await repository.setFavorite(
        channelId: channelId,
        isFavorite: true,
      );

      final channel = await (database.select(
        database.channels,
      )..where((table) => table.id.equals(channelId))).getSingle();

      expect(updated, isTrue);
      expect(channel.isFavorite, isTrue);
    });

    test('removes channel from favorites', () async {
      await repository.setFavorite(channelId: channelId, isFavorite: true);

      final updated = await repository.setFavorite(
        channelId: channelId,
        isFavorite: false,
      );

      final channel = await (database.select(
        database.channels,
      )..where((table) => table.id.equals(channelId))).getSingle();

      expect(updated, isTrue);
      expect(channel.isFavorite, isFalse);
    });

    test('records Live TV playback history', () async {
      await repository.recordLiveTvPlayback(
        channelId: channelId,
        channelName: 'Test Channel',
      );

      final rows = await (database.select(
        database.playbackHistory,
      )..where((table) => table.itemType.equals('live_tv'))).get();

      expect(rows, hasLength(1));
      expect(rows.single.referenceId, channelId.toString());
      expect(rows.single.title, 'Test Channel');
    });

    test(
      'updates existing Live TV history instead of inserting duplicate',
      () async {
        await repository.recordLiveTvPlayback(
          channelId: channelId,
          channelName: 'Old Channel Name',
        );
        final first = await (database.select(
          database.playbackHistory,
        )..where((table) => table.itemType.equals('live_tv'))).getSingle();

        await repository.recordLiveTvPlayback(
          channelId: channelId,
          channelName: 'Updated Channel Name',
        );

        final rows = await (database.select(
          database.playbackHistory,
        )..where((table) => table.itemType.equals('live_tv'))).get();

        expect(rows, hasLength(1));
        expect(rows.single.id, first.id);
        expect(rows.single.title, 'Updated Channel Name');
        expect(
          rows.single.watchedAt.isAfter(first.watchedAt) ||
              rows.single.watchedAt.isAtSameMomentAs(first.watchedAt),
          isTrue,
        );
      },
    );

    test('keeps different Live TV channels as separate history rows', () async {
      await repository.recordLiveTvPlayback(
        channelId: channelId,
        channelName: 'Test Channel',
      );
      await repository.recordLiveTvPlayback(
        channelId: channelId + 100,
        channelName: 'Another Channel',
      );

      final rows = await (database.select(
        database.playbackHistory,
      )..where((table) => table.itemType.equals('live_tv'))).get();

      expect(rows, hasLength(2));
    });

    test('returns false for nonexistent channel ID', () async {
      final updated = await repository.setFavorite(
        channelId: -1,
        isFavorite: true,
      );

      expect(updated, isFalse);
    });
  });
}
