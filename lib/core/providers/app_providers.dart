import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../../features/live_tv/data/repositories/playlist_repository.dart';
import '../../features/live_tv/data/repositories/category_repository.dart';
import '../../features/live_tv/data/repositories/channel_repository.dart';
import '../../features/live_tv/data/services/m3u_source_service.dart';
import '../../features/local_media/data/repositories/local_media_repository.dart';
import '../../features/local_media/data/services/android_media_store_scanner.dart';
import '../../features/local_media/data/services/local_media_scan_service.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError(
    'appDatabaseProvider must be overridden in OrixonApp.',
  );
});

final playlistRepositoryProvider = Provider<PlaylistRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return PlaylistRepository(database: database);
});

final m3uSourceServiceProvider = Provider<M3uSourceService>((ref) {
  final service = M3uSourceService();
  ref.onDispose(service.close);
  return service;
});

final channelRepositoryProvider = Provider<ChannelRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return ChannelRepository(database: database);
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return CategoryRepository(database: database);
});

final categoriesProvider = StreamProvider((ref) async* {
  final database = ref.watch(appDatabaseProvider);
  final repository = ref.watch(categoryRepositoryProvider);
  await repository.ensureStandardCategories();
  yield* (database.select(
    database.categories,
  )..orderBy([(table) => OrderingTerm.asc(table.sortOrder)])).watch();
});

final channelsProvider = StreamProvider((ref) {
  final database = ref.watch(appDatabaseProvider);
  return (database.select(database.channels)
        ..where((table) => table.isEnabled.equals(true))
        ..orderBy([(table) => OrderingTerm.asc(table.channelNumber)]))
      .watch();
});

final totalChannelCountProvider = StreamProvider<int>((ref) {
  final database = ref.watch(appDatabaseProvider);
  final countExpression = database.channels.id.count();

  return (database.selectOnly(database.channels)..addColumns([countExpression]))
      .watchSingle()
      .map((row) => row.read(countExpression) ?? 0);
});

class RecentLiveTvChannelEntry {
  const RecentLiveTvChannelEntry({
    required this.history,
    required this.channel,
  });

  final PlaybackHistoryData history;
  final Channel? channel;
}

final recentLiveTvChannelsProvider =
    StreamProvider<List<RecentLiveTvChannelEntry>>((ref) {
      final database = ref.watch(appDatabaseProvider);

      return (database.select(database.playbackHistory)
            ..where((table) => table.itemType.equals('live_tv'))
            ..orderBy([(table) => OrderingTerm.desc(table.watchedAt)])
            ..limit(5))
          .watch()
          .asyncMap((historyItems) async {
            final channelIds = historyItems
                .map((item) => int.tryParse(item.referenceId))
                .whereType<int>()
                .toSet()
                .toList();

            final channels = channelIds.isEmpty
                ? <Channel>[]
                : await (database.select(
                    database.channels,
                  )..where((table) => table.id.isIn(channelIds))).get();

            final channelsById = {
              for (final channel in channels) channel.id: channel,
            };

            return historyItems
                .map(
                  (history) => RecentLiveTvChannelEntry(
                    history: history,
                    channel: channelsById[int.tryParse(history.referenceId)],
                  ),
                )
                .toList(growable: false);
          });
    });

final launcherRecentLiveTvChannelsProvider =
    StreamProvider<List<RecentLiveTvChannelEntry>>((ref) {
      final database = ref.watch(appDatabaseProvider);

      return (database.select(database.playbackHistory)
            ..where((table) => table.itemType.equals('live_tv'))
            ..orderBy([(table) => OrderingTerm.desc(table.watchedAt)]))
          .watch()
          .asyncMap((historyItems) async {
            final channelIds = historyItems
                .map((item) => int.tryParse(item.referenceId))
                .whereType<int>()
                .toSet()
                .toList();

            final channels = channelIds.isEmpty
                ? <Channel>[]
                : await (database.select(
                    database.channels,
                  )..where((table) => table.id.isIn(channelIds))).get();

            final channelsById = {
              for (final channel in channels) channel.id: channel,
            };

            return historyItems
                .map(
                  (history) => RecentLiveTvChannelEntry(
                    history: history,
                    channel: channelsById[int.tryParse(history.referenceId)],
                  ),
                )
                .toList(growable: false);
          });
    });

final localMediaRepositoryProvider = Provider<LocalMediaRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return LocalMediaRepository(database: database);
});

final localMediaFilesProvider = StreamProvider((ref) {
  return ref.watch(localMediaRepositoryProvider).watchAll();
});

final recentLocalMediaProvider = StreamProvider((ref) {
  return ref.watch(localMediaRepositoryProvider).watchRecentlyPlayed();
});

final androidMediaStoreScannerProvider = Provider<AndroidMediaStoreScanner>((
  ref,
) {
  return AndroidMediaStoreScanner();
});

final localMediaScanServiceProvider = Provider<LocalMediaScanService>((ref) {
  return LocalMediaScanService(
    scanner: ref.watch(androidMediaStoreScannerProvider),
    repository: ref.watch(localMediaRepositoryProvider),
  );
});
