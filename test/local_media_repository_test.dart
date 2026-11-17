import 'package:orixon/core/database/app_database.dart';
import 'package:orixon/features/local_media/data/repositories/local_media_repository.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late LocalMediaRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = LocalMediaRepository(database: database);
  });

  tearDown(() async {
    await database.close();
  });

  group('LocalMediaRepository', () {
    test('adds a newly scanned video', () async {
      final id = await repository.upsertScannedFile(
        filePath: '/storage/emulated/0/Movies/video.mp4',
        fileName: 'video.mp4',
        folderName: 'Movies',
        sizeBytes: 1024,
      );

      final file = await (database.select(
        database.mediaFiles,
      )..where((table) => table.id.equals(id))).getSingle();

      expect(file.fileName, 'video.mp4');
      expect(file.folderName, 'Movies');
      expect(file.sizeBytes, 1024);
      expect(file.lastPositionMs, 0);
      expect(file.isFavorite, false);
    });

    test('rescan updates metadata without creating duplicates', () async {
      final firstId = await repository.upsertScannedFile(
        filePath: '/storage/emulated/0/Movies/video.mp4',
        fileName: 'video.mp4',
        folderName: 'Movies',
        sizeBytes: 1024,
      );

      final secondId = await repository.upsertScannedFile(
        filePath: '/storage/emulated/0/Movies/video.mp4',
        fileName: 'renamed-video.mp4',
        folderName: 'Movies/New',
        sizeBytes: 2048,
      );

      final files = await database.select(database.mediaFiles).get();

      expect(secondId, firstId);
      expect(files, hasLength(1));
      expect(files.single.fileName, 'renamed-video.mp4');
      expect(files.single.sizeBytes, 2048);
    });

    test('rescan preserves playback progress and preferences', () async {
      final id = await repository.upsertScannedFile(
        filePath: '/storage/emulated/0/Movies/video.mp4',
        fileName: 'video.mp4',
        folderName: 'Movies',
        sizeBytes: 1024,
      );

      final playedAt = DateTime(2026, 11, 5, 12);
      await repository.updatePlaybackProgress(
        filePath: '/storage/emulated/0/Movies/video.mp4',
        positionMs: 45000,
        playedAt: playedAt,
      );

      await (database.update(
        database.mediaFiles,
      )..where((table) => table.id.equals(id))).write(
        const MediaFilesCompanion(
          isFavorite: Value(true),
          preferredAudioTrack: Value(2),
          preferredSubtitleTrack: Value(3),
        ),
      );

      await repository.upsertScannedFile(
        filePath: '/storage/emulated/0/Movies/video.mp4',
        fileName: 'video.mp4',
        folderName: 'Movies',
        sizeBytes: 2048,
      );

      final file = await (database.select(
        database.mediaFiles,
      )..where((table) => table.id.equals(id))).getSingle();

      expect(file.lastPositionMs, 45000);
      expect(file.lastPlayedAt, playedAt);
      expect(file.isFavorite, true);
      expect(file.preferredAudioTrack, 2);
      expect(file.preferredSubtitleTrack, 3);
    });

    test(
      'updates playback progress and returns false for missing file',
      () async {
        await repository.upsertScannedFile(
          filePath: '/storage/emulated/0/Movies/video.mp4',
          fileName: 'video.mp4',
          folderName: 'Movies',
          sizeBytes: 1024,
        );

        final updated = await repository.updatePlaybackProgress(
          filePath: '/storage/emulated/0/Movies/video.mp4',
          positionMs: 90000,
        );

        final missing = await repository.updatePlaybackProgress(
          filePath: '/missing/video.mp4',
          positionMs: 1000,
        );

        final file = await database.select(database.mediaFiles).getSingle();

        expect(updated, true);
        expect(missing, false);
        expect(file.lastPositionMs, 90000);
        expect(file.lastPlayedAt, isNotNull);
      },
    );

    test('sets and removes a video favorite', () async {
      final id = await repository.upsertScannedFile(
        filePath: '/storage/emulated/0/Movies/video.mp4',
        fileName: 'video.mp4',
        folderName: 'Movies',
        sizeBytes: 1024,
      );

      expect(await repository.setFavorite(mediaId: id, isFavorite: true), true);
      expect(
        await repository.setFavorite(mediaId: id, isFavorite: false),
        true,
      );
      expect(
        await repository.setFavorite(mediaId: -1, isFavorite: true),
        false,
      );

      final file = await database.select(database.mediaFiles).getSingle();
      expect(file.isFavorite, false);
    });

    test('watches recently played videos newest first with limit', () async {
      final paths = [
        '/Movies/one.mp4',
        '/Movies/two.mp4',
        '/Movies/three.mp4',
        '/Movies/four.mp4',
        '/Movies/five.mp4',
      ];

      for (var i = 0; i < paths.length; i++) {
        await repository.upsertScannedFile(
          filePath: paths[i],
          fileName: '${i + 1}.mp4',
          folderName: 'Movies',
          sizeBytes: 1024,
        );
        await repository.updatePlaybackProgress(
          filePath: paths[i],
          positionMs: 1000,
          playedAt: DateTime(2026, 11, 5, 10 + i),
        );
      }

      final recent = await repository.watchRecentlyPlayed().first;

      expect(recent, hasLength(5));
      expect(recent.map((file) => file.fileName).toList(), [
        '5.mp4',
        '4.mp4',
        '3.mp4',
        '2.mp4',
        '1.mp4',
      ]);
    });

    test('watchAll sorts by most recently played first', () async {
      await repository.upsertScannedFile(
        filePath: '/old.mp4',
        fileName: 'old.mp4',
        folderName: 'Movies',
        sizeBytes: 1000,
      );
      await repository.upsertScannedFile(
        filePath: '/new.mp4',
        fileName: 'new.mp4',
        folderName: 'Movies',
        sizeBytes: 1000,
      );
      await repository.upsertScannedFile(
        filePath: '/never.mp4',
        fileName: 'never.mp4',
        folderName: 'Movies',
        sizeBytes: 1000,
      );

      await repository.updatePlaybackProgress(
        filePath: '/old.mp4',
        positionMs: 1000,
        playedAt: DateTime(2026, 11, 4, 10),
      );
      await repository.updatePlaybackProgress(
        filePath: '/new.mp4',
        positionMs: 1000,
        playedAt: DateTime(2026, 11, 5, 10),
      );

      final videos = await repository.watchAll().first;

      expect(videos.map((file) => file.fileName).toList(), [
        'new.mp4',
        'old.mp4',
        'never.mp4',
      ]);
    });

    test('rejects invalid file metadata', () async {
      await expectLater(
        repository.upsertScannedFile(
          filePath: '',
          fileName: 'video.mp4',
          folderName: 'Movies',
          sizeBytes: 100,
        ),
        throwsArgumentError,
      );

      await expectLater(
        repository.upsertScannedFile(
          filePath: '/Movies/video.mp4',
          fileName: 'video.mp4',
          folderName: 'Movies',
          sizeBytes: -1,
        ),
        throwsArgumentError,
      );

      await expectLater(
        repository.updatePlaybackProgress(
          filePath: '/Movies/video.mp4',
          positionMs: -1,
        ),
        throwsArgumentError,
      );
    });
  });
}
