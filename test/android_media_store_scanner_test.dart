import 'package:orixon/features/local_media/data/services/android_media_store_scanner.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.example.orixon/local_media');
  late AndroidMediaStoreScanner scanner;

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  setUp(() {
    scanner = AndroidMediaStoreScanner(channel: channel);
  });

  test('checks video permission', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'hasVideoPermission');
          return true;
        });

    expect(await scanner.hasVideoPermission(), isTrue);
  });

  test('requests video permission', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'requestVideoPermission');
          return false;
        });

    expect(await scanner.requestVideoPermission(), isFalse);
  });

  test('returns empty list when no videos are found', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => <dynamic>[]);

    expect(await scanner.scanVideos(), isEmpty);
  });

  test('parses scanned video metadata', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          return <dynamic>[
            <String, Object?>{
              'uri': 'content://media/external/video/media/42',
              'fileName': 'sample.mkv',
              'mimeType': 'video/x-matroska',
              'sizeBytes': 1024,
              'dateModified': 1793900000,
              'durationMs': 65000,
              'folderName': 'Movies/',
            },
          ];
        });

    final videos = await scanner.scanVideos();

    expect(videos, hasLength(1));
    expect(videos.single.uri, 'content://media/external/video/media/42');
    expect(videos.single.fileName, 'sample.mkv');
    expect(videos.single.mimeType, 'video/x-matroska');
    expect(videos.single.sizeBytes, 1024);
    expect(videos.single.durationMs, 65000);
    expect(videos.single.folderName, 'Movies/');
  });

  test('rejects invalid video metadata', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          return <dynamic>[
            <String, Object?>{'fileName': 'broken.mp4'},
          ];
        });

    expect(scanner.scanVideos(), throwsFormatException);
  });
}
