import 'package:orixon/core/database/app_database.dart';
import 'package:drift/drift.dart';

class LocalMediaRepository {
  const LocalMediaRepository({required this.database});

  final AppDatabase database;

  Stream<List<MediaFile>> watchAll() {
    return (database.select(database.mediaFiles)..orderBy([
          (table) => OrderingTerm.desc(table.lastPlayedAt),
          (table) => OrderingTerm.asc(table.fileName),
        ]))
        .watch();
  }

  Future<void> removeScannedFile(String filePath) async {
    await (database.delete(
      database.mediaFiles,
    )..where((table) => table.filePath.equals(filePath))).go();
  }

  Stream<List<MediaFile>> watchRecentlyPlayed({int limit = 5}) {
    if (limit < 1) {
      throw ArgumentError.value(limit, 'limit', 'Must be greater than zero.');
    }

    return (database.select(database.mediaFiles)
          ..where((table) => table.lastPlayedAt.isNotNull())
          ..orderBy([(table) => OrderingTerm.desc(table.lastPlayedAt)])
          ..limit(limit))
        .watch();
  }

  Future<int> upsertScannedFile({
    required String filePath,
    required String fileName,
    required String folderName,
    required int sizeBytes,
    int durationMs = 0,
    DateTime? dateAdded,
  }) async {
    if (filePath.trim().isEmpty) {
      throw ArgumentError.value(filePath, 'filePath', 'Must not be empty.');
    }
    if (fileName.trim().isEmpty) {
      throw ArgumentError.value(fileName, 'fileName', 'Must not be empty.');
    }
    if (sizeBytes < 0 || durationMs < 0) {
      throw ArgumentError('File size and duration cannot be negative.');
    }

    return database.transaction(() async {
      final existing = await (database.select(
        database.mediaFiles,
      )..where((table) => table.filePath.equals(filePath))).getSingleOrNull();

      if (existing == null) {
        return database
            .into(database.mediaFiles)
            .insert(
              MediaFilesCompanion.insert(
                filePath: filePath,
                fileName: fileName,
                folderName: folderName,
                sizeBytes: sizeBytes,
                durationMs: Value(durationMs),
                dateAdded: dateAdded ?? DateTime.now(),
              ),
            );
      }

      await (database.update(
        database.mediaFiles,
      )..where((table) => table.id.equals(existing.id))).write(
        MediaFilesCompanion(
          fileName: Value(fileName),
          folderName: Value(folderName),
          sizeBytes: Value(sizeBytes),
          durationMs: durationMs > 0 ? Value(durationMs) : const Value.absent(),
        ),
      );

      return existing.id;
    });
  }

  Future<bool> updatePlaybackProgress({
    required String filePath,
    required int positionMs,
    DateTime? playedAt,
  }) async {
    if (positionMs < 0) {
      throw ArgumentError.value(
        positionMs,
        'positionMs',
        'Cannot be negative.',
      );
    }

    final updatedRows =
        await (database.update(
          database.mediaFiles,
        )..where((table) => table.filePath.equals(filePath))).write(
          MediaFilesCompanion(
            lastPositionMs: Value(positionMs),
            lastPlayedAt: Value(playedAt ?? DateTime.now()),
          ),
        );

    return updatedRows == 1;
  }

  Future<bool> setFavorite({
    required int mediaId,
    required bool isFavorite,
  }) async {
    final updatedRows =
        await (database.update(database.mediaFiles)
              ..where((table) => table.id.equals(mediaId)))
            .write(MediaFilesCompanion(isFavorite: Value(isFavorite)));

    return updatedRows == 1;
  }
}
