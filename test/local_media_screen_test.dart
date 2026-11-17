import 'package:orixon/core/database/app_database.dart';
import 'package:orixon/core/providers/app_providers.dart';
import 'package:orixon/features/local_media/data/repositories/local_media_repository.dart';
import 'package:orixon/features/local_media/presentation/local_media_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late LocalMediaRepository repository;
  late int scanCalls;

  const mediaChannel = MethodChannel('com.example.orixon/local_media');

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = LocalMediaRepository(database: database);
    scanCalls = 0;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(mediaChannel, (call) async {
          switch (call.method) {
            case 'hasVideoPermission':
              return true;
            case 'requestVideoPermission':
              return true;
            case 'scanVideos':
              scanCalls++;
              return <dynamic>[];
            case 'getVideoThumbnail':
              return null;
            default:
              throw PlatformException(
                code: 'UNIMPLEMENTED',
                message: 'Unexpected method: ${call.method}',
              );
          }
        });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(mediaChannel, null);
    await database.close();
  });

  Widget buildScreen() {
    return ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(database)],
      child: const MaterialApp(home: LocalMediaScreen()),
    );
  }

  testWidgets('shows empty state when no videos exist', (tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('MEDIA HUB'), findsOneWidget);
    expect(find.text('VIDEO LIBRARY'), findsOneWidget);
    expect(find.text('No videos found'), findsOneWidget);
    expect(find.text('Scan Videos'), findsNothing);
    expect(scanCalls, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets('displays scanned videos without favorite controls', (
    tester,
  ) async {
    await repository.upsertScannedFile(
      filePath: 'content://media/external/video/media/101',
      fileName: 'sample-video.mp4',
      folderName: 'Movies',
      sizeBytes: 1024 * 1024,
    );

    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('sample-video.mp4'), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);
    expect(find.text('Scan Videos'), findsNothing);
    expect(scanCalls, 1);
    expect(find.byTooltip('Add to favorites'), findsNothing);
    expect(find.byTooltip('Remove from favorites'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
  });
}
