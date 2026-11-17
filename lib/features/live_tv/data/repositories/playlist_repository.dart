import 'package:drift/drift.dart';
import 'package:orixon/core/database/app_database.dart';
import 'package:orixon/features/live_tv/data/parsers/m3u_parser.dart';
import 'package:orixon/features/live_tv/data/repositories/category_repository.dart';
import 'package:orixon/features/live_tv/domain/constants/live_tv_categories.dart';
import 'package:orixon/features/live_tv/domain/services/category_range_allocator.dart';
import 'package:orixon/features/live_tv/domain/services/channel_number_allocator.dart';
import 'package:orixon/features/live_tv/domain/services/playlist_channel_matcher.dart';

class PlaylistManagementException implements Exception {
  final String message;
  const PlaylistManagementException(this.message);
  @override
  String toString() => 'PlaylistManagementException: $message';
}

class PlaylistImportException implements Exception {
  final String message;
  const PlaylistImportException(this.message);
  @override
  String toString() => 'PlaylistImportException: $message';
}

class PlaylistImportResult {
  final int inserted;
  final int updated;
  final int removed;

  const PlaylistImportResult({
    required this.inserted,
    required this.updated,
    required this.removed,
  });
}

class PlaylistRepository {
  final AppDatabase database;
  final PlaylistChannelMatcher matcher;
  final CategoryRangeAllocator categoryRangeAllocator;
  final ChannelNumberAllocator channelNumberAllocator;

  PlaylistRepository({
    required this.database,
    this.matcher = const PlaylistChannelMatcher(),
    this.categoryRangeAllocator = const CategoryRangeAllocator(),
    this.channelNumberAllocator = const ChannelNumberAllocator(),
  });

  Future<List<Playlist>> getAllPlaylists() {
    return (database.select(
      database.playlists,
    )..orderBy([(table) => OrderingTerm.desc(table.id)])).get();
  }

  Future<Playlist> createPlaylist({
    required String name,
    required String sourceUrlOrPath,
    String? epgUrl,
    int autoRefreshHours = 0,
  }) async {
    final normalizedName = name.trim();
    final normalizedSource = sourceUrlOrPath.trim();
    final normalizedEpgUrl = epgUrl?.trim();

    if (normalizedName.isEmpty) {
      throw const PlaylistManagementException('Playlist name cannot be empty.');
    }
    if (normalizedSource.isEmpty) {
      throw const PlaylistManagementException('Playlist URL or file path cannot be empty.');
    }

    return database.transaction(() async {
      // Prevent duplicate playlists: if source URL/path already exists, reuse it!
      final duplicate = await (database.select(database.playlists)
            ..where((table) => table.sourceUrlOrPath.equals(normalizedSource)))
          .getSingleOrNull();

      if (duplicate != null) {
        return duplicate;
      }

      final id = await database.into(database.playlists).insert(
            PlaylistsCompanion.insert(
              name: normalizedName,
              sourceUrlOrPath: normalizedSource,
              epgUrl: Value(
                normalizedEpgUrl == null || normalizedEpgUrl.isEmpty
                    ? null
                    : normalizedEpgUrl,
              ),
              autoRefreshHours: Value(autoRefreshHours < 0 ? 0 : autoRefreshHours),
            ),
          );

      return (database.select(database.playlists)
            ..where((table) => table.id.equals(id)))
          .getSingle();
    });
  }

  Future<int> getPlaylistChannelCount(int playlistId) async {
    final query = database.selectOnly(database.channels)
      ..addColumns([database.channels.id.count()])
      ..where(database.channels.playlistId.equals(playlistId));
    final result = await query.getSingle();
    return result.read(database.channels.id.count()) ?? 0;
  }

  String _cleanBaseUrl(String rawUrl) {
    final idx = rawUrl.indexOf('|');
    return (idx >= 0 ? rawUrl.substring(0, idx) : rawUrl).trim().toLowerCase();
  }

  int _allocateSafeChannelNumber({
    required Category category,
    required Category othersCategory,
    required Set<int> usedNumbers,
    int? currentNumber,
  }) {
    if (currentNumber != null && !usedNumbers.contains(currentNumber)) {
      return currentNumber;
    }
    try {
      return currentNumber != null
          ? channelNumberAllocator.keepOrAllocate(
              currentNumber: currentNumber,
              rangeStart: category.rangeStart,
              rangeEnd: category.rangeEnd,
              usedNumbers: usedNumbers,
            )
          : channelNumberAllocator.allocate(
              rangeStart: category.rangeStart,
              rangeEnd: category.rangeEnd,
              usedNumbers: usedNumbers,
            );
    } catch (_) {
      // IMPORTANT: Keep the channel's true category! Only allocate an available number!
      try {
        return channelNumberAllocator.allocate(
          rangeStart: othersCategory.rangeStart,
          rangeEnd: LiveTvCategories.othersRangeEnd,
          usedNumbers: usedNumbers,
        );
      } catch (_) {
        var next = usedNumbers.isEmpty
            ? 1000
            : (usedNumbers.reduce((a, b) => a > b ? a : b) + 1);
        while (usedNumbers.contains(next)) {
          next++;
        }
        return next;
      }
    }
  }

  Future<PlaylistImportResult> importM3u({
    required int playlistId,
    required String content,
  }) async {
    final incoming = M3uParser.parse(content);
    if (incoming.isEmpty) {
      throw const PlaylistImportException(
        'Playlist contains no valid channels. Existing data was not changed.',
      );
    }

    return database.transaction(() async {
      await CategoryRepository(database: database).ensureStandardCategories();

      final playlist = await (database.select(database.playlists)
            ..where((table) => table.id.equals(playlistId)))
          .getSingleOrNull();
      if (playlist == null) {
        throw PlaylistImportException('Playlist not found: $playlistId');
      }

      final existing = await (database.select(database.channels)
            ..where((table) => table.playlistId.equals(playlistId)))
          .get();

      // Match existing channels in this playlist by exact name or URL so dynamic links update cleanly
      final existingByName = <String, Channel>{};
      final existingByUrl = <String, Channel>{};
      for (final ch in existing) {
        existingByName.putIfAbsent(ch.name.trim().toLowerCase(), () => ch);
        existingByUrl.putIfAbsent(_cleanBaseUrl(ch.primaryUrl), () => ch);
      }

      final matchedExistingIds = <int>{};
      final incomingToExistingId = <int, int>{};

      for (var i = 0; i < incoming.length; i++) {
        final src = incoming[i];
        final byUrl = existingByUrl[_cleanBaseUrl(src.streamUrl)];
        if (byUrl != null && !matchedExistingIds.contains(byUrl.id)) {
          incomingToExistingId[i] = byUrl.id;
          matchedExistingIds.add(byUrl.id);
          continue;
        }
        final byName = existingByName[src.name.trim().toLowerCase()];
        if (byName != null && !matchedExistingIds.contains(byName.id)) {
          incomingToExistingId[i] = byName.id;
          matchedExistingIds.add(byName.id);
        }
      }

      final staleIds = existing
          .where((ch) => !matchedExistingIds.contains(ch.id))
          .map((ch) => ch.id)
          .toList();
      if (staleIds.isNotEmpty) {
        await (database.delete(database.channels)
              ..where((t) => t.id.isIn(staleIds)))
            .go();
      }

      final allChannels = await database.select(database.channels).get();
      final otherPlaylistChannels = allChannels
          .where((ch) => ch.playlistId != playlistId)
          .toList();

      // Track (name + baseUrl) across other playlists to prevent exact duplicates
      // while allowing same channel name if the stream link is different!
      final otherPlaylistsNameAndUrl = <String>{
        for (final ch in otherPlaylistChannels)
          '${ch.name.trim().toLowerCase()}||${_cleanBaseUrl(ch.primaryUrl)}',
      };

      final usedNumbers = allChannels.map((c) => c.channelNumber).toSet();
      final othersCategory = await _getOrCreateCategory('Others');

      var inserted = 0;
      var updated = 0;
      final isRemotePlaylist = playlist.sourceUrlOrPath.startsWith('http://') ||
          playlist.sourceUrlOrPath.startsWith('https://');

      for (var i = 0; i < incoming.length; i++) {
        final source = incoming[i];
        final normName = source.name.trim().toLowerCase();
        final baseUrl = _cleanBaseUrl(source.streamUrl);

        // If another playlist already has this EXACT same channel name AND exact same link,
        // skip duplicating it (unless this is a local custom playlist the user built)
        if (isRemotePlaylist &&
            otherPlaylistsNameAndUrl.contains('$normName||$baseUrl')) {
          continue;
        }

        final requestedCategory = LiveTvCategories.resolve(source.groupTitle);
        final category = await _getOrCreateCategory(requestedCategory);
        final existingId = incomingToExistingId[i];

        if (existingId != null) {
          final oldCh = existing.firstWhere((c) => c.id == existingId);
          usedNumbers.remove(oldCh.channelNumber);
          final chNum = _allocateSafeChannelNumber(
            category: category,
            othersCategory: othersCategory,
            usedNumbers: usedNumbers,
            currentNumber: oldCh.channelNumber,
          );
          usedNumbers.add(chNum);

          await (database.update(database.channels)
                ..where((t) => t.id.equals(existingId)))
              .write(
            ChannelsCompanion(
              channelNumber: Value(chNum),
              name: Value(source.name),
              categoryId: Value(category.id),
              logoUrl: Value(source.logoUrl),
              primaryUrl: Value(source.streamUrl),
              epgChannelId: Value(source.tvgId),
            ),
          );
          updated++;
        } else {
          final chNum = _allocateSafeChannelNumber(
            category: category,
            othersCategory: othersCategory,
            usedNumbers: usedNumbers,
          );
          usedNumbers.add(chNum);

          await database.into(database.channels).insert(
                ChannelsCompanion.insert(
                  channelNumber: chNum,
                  name: source.name,
                  categoryId: category.id,
                  playlistId: Value(playlistId),
                  logoUrl: Value(source.logoUrl),
                  primaryUrl: source.streamUrl,
                  epgChannelId: Value(source.tvgId),
                ),
              );
          inserted++;
        }

        // If this is a remote IPTV playlist, also propagate fresh dynamic stream links
        // and true categories to any matching channel inside Custom/Local Playlists!
        if (isRemotePlaylist) {
          for (final otherCh in otherPlaylistChannels) {
            if (otherCh.name.trim().toLowerCase() == normName) {
              await (database.update(database.channels)
                    ..where((t) => t.id.equals(otherCh.id)))
                  .write(
                ChannelsCompanion(
                  primaryUrl: Value(source.streamUrl),
                  categoryId: Value(
                    otherCh.categoryId == othersCategory.id
                        ? category.id
                        : otherCh.categoryId,
                  ),
                  logoUrl: Value(
                    source.logoUrl.isNotEmpty ? source.logoUrl : otherCh.logoUrl,
                  ),
                ),
              );
            }
          }
        }
      }

      await (database.update(database.playlists)
            ..where((t) => t.id.equals(playlistId)))
          .write(PlaylistsCompanion(lastUpdated: Value(DateTime.now())));

      return PlaylistImportResult(
        inserted: inserted,
        updated: updated,
        removed: staleIds.length,
      );
    });
  }

  Future<bool> deletePlaylist(int playlistId) async {
    return database.transaction(() async {
      final playlist = await (database.select(database.playlists)
            ..where((t) => t.id.equals(playlistId)))
          .getSingleOrNull();
      if (playlist == null) return false;

      await (database.delete(database.channels)
            ..where((t) => t.playlistId.equals(playlistId)))
          .go();
      final deleted = await (database.delete(database.playlists)
            ..where((t) => t.id.equals(playlistId)))
          .go();
      return deleted == 1;
    });
  }

  Future<Category> _getOrCreateCategory(String name) {
    final canonicalName = LiveTvCategories.resolve(name);
    return (database.select(database.categories)
          ..where((t) => t.name.equals(canonicalName)))
        .getSingle();
  }
}
