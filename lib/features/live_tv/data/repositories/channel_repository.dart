import 'package:orixon/core/database/app_database.dart';
import 'package:drift/drift.dart';

class ChannelRepository {
  final AppDatabase database;

  const ChannelRepository({required this.database});

  Future<void> recordLiveTvPlayback({
    required int channelId,
    required String channelName,
  }) async {
    await database.transaction(() async {
      final referenceId = channelId.toString();
      final existing =
          await (database.select(database.playbackHistory)..where(
                (table) =>
                    table.itemType.equals('live_tv') &
                    table.referenceId.equals(referenceId),
              ))
              .getSingleOrNull();

      final watchedAt = DateTime.now();
      if (existing == null) {
        await database
            .into(database.playbackHistory)
            .insert(
              PlaybackHistoryCompanion.insert(
                itemType: 'live_tv',
                referenceId: referenceId,
                title: channelName,
                watchedAt: watchedAt,
              ),
            );
      } else {
        await (database.update(
          database.playbackHistory,
        )..where((table) => table.id.equals(existing.id))).write(
          PlaybackHistoryCompanion(
            title: Value(channelName),
            watchedAt: Value(watchedAt),
          ),
        );
      }
    });
  }

  Future<bool> setFavorite({
    required int channelId,
    required bool isFavorite,
  }) async {
    final updatedRows =
        await (database.update(database.channels)
              ..where((table) => table.id.equals(channelId)))
            .write(ChannelsCompanion(isFavorite: Value(isFavorite)));

    return updatedRows == 1;
  }
}
