import 'package:orixon/core/database/app_database.dart';
import 'package:orixon/features/local_media/data/repositories/local_media_repository.dart';
import 'package:orixon/features/local_media/data/services/android_media_store_scanner.dart';
import 'package:orixon/features/local_media/data/services/local_media_scan_service.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.example.orixon/local_media');

  late AppDatabase database;
  late LocalMediaRepository repository;
  late AndroidMediaStoreScanner scanner;

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    await database.close();
  });

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = LocalMediaRepository(database: database);
    scanner = AndroidMediaStoreScanner(channel: channel);
  });

  group('LocalMediaScanService', () {
    test('does not scan or modify database without permission', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            expect(call.method, 'hasVideoPermission');
            return false;
          });

      final service = LocalMediaScanService(
        scanner: scanner,
        repository: repository,
      );

      final result = await service.scan();
      final files = await database.select(database.mediaFiles).get();

      expect(result.permissionRequired, true);
      expect(result.discoveredCount, 0);
      expect(result.importedCount, 0);
      expect(files, isEmpty);
    });

    test(
      'imports every video discovered by MediaStore without decoder validation',
      () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
              if (call.method == 'hasVideoPermission') return true;
              if (call.method == 'scanVideos') {
                return <dynamic>[
                  <String, Object?>{
                    'uri': 'content://media/video/1',
                    'fileName': 'movie.mp4',
                    'mimeType': 'video/mp4',
                    'sizeBytes': 2048,
                    'dateModified': 1793900000,
                    'durationMs': 60000,
                    'folderName': 'Movies/',
                  },
                  <String, Object?>{
                    'uri': 'content://media/video/2',
                    'fileName': 'movie.odd',
                    'mimeType': 'video/x-matroska',
                    'sizeBytes': 4096,
                    'dateModified': 1793900001,
                    'durationMs': 90000,
                    'folderName': 'Downloads/',
                  },
                  <String, Object?>{
                    'uri': 'content://media/video/3',
                    'fileName': 'clip.unusual',
                    'mimeType': 'video/x-custom',
                    'sizeBytes': 512,
                    'dateModified': 1793900002,
                    'durationMs': 30000,
                    'folderName': 'Videos/Other/',
                  },
                ];
              }
              fail('Unexpected method: ${call.method}');
            });

        final service = LocalMediaScanService(
          scanner: scanner,
          repository: repository,
        );

        final result = await service.scan();
        final files = await database.select(database.mediaFiles).get();

        expect(result.permissionRequired, false);
        expect(result.discoveredCount, 3);
        expect(result.importedCount, 3);
        expect(files, hasLength(3));
        expect(files.map((file) => file.fileName).toSet(), {
          'movie.mp4',
          'movie.odd',
          'clip.unusual',
        });
      },
    );

    test('rescan updates existing video without creating duplicates', () async {
      await repository.upsertScannedFile(
        filePath: 'content://media/video/10',
        fileName: 'old-name.mp4',
        folderName: 'Movies/',
        sizeBytes: 1000,
      );

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'hasVideoPermission') return true;
            if (call.method == 'scanVideos') {
              return <dynamic>[
                <String, Object?>{
                  'uri': 'content://media/video/10',
                  'fileName': 'new-name.mp4',
                  'mimeType': 'video/mp4',
                  'sizeBytes': 2000,
                  'dateModified': 1793900000,
                  'durationMs': 70000,
                  'folderName': 'Movies/Edited/',
                },
              ];
            }
            fail('Unexpected method: ${call.method}');
          });

      final service = LocalMediaScanService(
        scanner: scanner,
        repository: repository,
      );

      await service.scan();
      final files = await database.select(database.mediaFiles).get();

      expect(files, hasLength(1));
      expect(files.single.fileName, 'new-name.mp4');
      expect(files.single.sizeBytes, 2000);
      expect(files.single.durationMs, 70000);
    });

    test('preserves playback progress and favorite on rescan', () async {
      await repository.upsertScannedFile(
        filePath: 'content://media/video/20',
        fileName: 'movie.mp4',
        folderName: 'Movies/',
        sizeBytes: 1000,
      );

      await repository.updatePlaybackProgress(
        filePath: 'content://media/video/20',
        positionMs: 45000,
        playedAt: DateTime(2026, 11, 5, 12),
      );

      final existing = await database.select(database.mediaFiles).getSingle();
      await repository.setFavorite(mediaId: existing.id, isFavorite: true);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'hasVideoPermission') return true;
            if (call.method == 'scanVideos') {
              return <dynamic>[
                <String, Object?>{
                  'uri': 'content://media/video/20',
                  'fileName': 'movie.mp4',
                  'mimeType': 'video/mp4',
                  'sizeBytes': 2000,
                  'dateModified': 1793900000,
                  'durationMs': 80000,
                  'folderName': 'Movies/',
                },
              ];
            }
            fail('Unexpected method: ${call.method}');
          });

      final service = LocalMediaScanService(
        scanner: scanner,
        repository: repository,
      );

      await service.scan();
      final updated = await database.select(database.mediaFiles).getSingle();

      expect(updated.lastPositionMs, 45000);
      expect(updated.isFavorite, true);
      expect(updated.fileName, 'movie.mp4');
      expect(updated.sizeBytes, 2000);
    });
  });
}
