import 'dart:io';
import 'dart:typed_data';

import 'package:orixon/features/live_tv/data/services/m3u_source_service.dart';
import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

base class TestPlatformFile extends PlatformFile {
  TestPlatformFile({
    required this.name,
    required this.bytes,
    this.reportedLength,
  }) : uri = Uri.parse('content://test/$name');

  @override
  final String name;

  @override
  final Uri uri;

  final Uint8List bytes;
  final int? reportedLength;

  @override
  XFile get xFile => XFile('');

  @override
  int? lengthSync() => reportedLength ?? bytes.length;

  @override
  Future<int?> length() async => reportedLength ?? bytes.length;

  @override
  Future<Uint8List> readAsBytes() async => bytes;

  @override
  Stream<Uint8List> readAsByteStream() async* {
    yield bytes;
  }
}

class FixedStreamedClient extends http.BaseClient {
  FixedStreamedClient(this.response);

  final http.StreamedResponse response;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return response;
  }

  @override
  void close() {}
}

void main() {
  group('M3uSourceService', () {
    group('constructor', () {
      test('rejects non-positive maximum size', () {
        expect(() => M3uSourceService(maxBytes: 0), throwsArgumentError);
      });

      test('rejects non-positive timeout', () {
        expect(
          () => M3uSourceService(timeout: Duration.zero),
          throwsArgumentError,
        );
      });
    });

    group('loadFromPickedFile', () {
      test('rejects file exceeding reported length limit', () async {
        final service = M3uSourceService(maxBytes: 5);

        final file = TestPlatformFile(
          name: 'large.m3u',
          bytes: Uint8List.fromList([1, 2, 3]),
          reportedLength: 6,
        );

        await expectLater(
          service.loadFromPickedFile(file),
          throwsA(isA<M3uSourceException>()),
        );

        service.close();
      });

      test('rejects actual file bytes exceeding size limit', () async {
        final service = M3uSourceService(maxBytes: 5);

        final file = TestPlatformFile(
          name: 'actual-large.m3u',
          bytes: Uint8List.fromList([1, 2, 3, 4, 5, 6]),
          reportedLength: 4,
        );

        await expectLater(
          service.loadFromPickedFile(file),
          throwsA(isA<M3uSourceException>()),
        );

        service.close();
      });

      test('rejects invalid UTF-8 file content', () async {
        final service = M3uSourceService();

        final file = TestPlatformFile(
          name: 'invalid.m3u',
          bytes: Uint8List.fromList([0xFF]),
        );

        await expectLater(
          service.loadFromPickedFile(file),
          throwsA(isA<M3uSourceException>()),
        );

        service.close();
      });

      test('rejects unsupported file extension', () async {
        final service = M3uSourceService();

        final file = TestPlatformFile(
          name: 'channels.txt',
          bytes: Uint8List.fromList('#EXTM3U'.codeUnits),
        );

        await expectLater(
          service.loadFromPickedFile(file),
          throwsA(isA<M3uSourceException>()),
        );

        service.close();
      });

      test('loads valid M3U file', () async {
        const playlist = '#EXTM3U\nhttps://example.com/live.m3u8';
        final service = M3uSourceService();

        final file = TestPlatformFile(
          name: 'channels.m3u',
          bytes: Uint8List.fromList(playlist.codeUnits),
        );

        expect(await service.loadFromPickedFile(file), playlist);

        service.close();
      });

      test('loads valid M3U8 file', () async {
        const playlist = '#EXTM3U\nhttps://example.com/live.m3u8';
        final service = M3uSourceService();

        final file = TestPlatformFile(
          name: 'channels.m3u8',
          bytes: Uint8List.fromList(playlist.codeUnits),
        );

        expect(await service.loadFromPickedFile(file), playlist);

        service.close();
      });
    });

    group('loadFromPath', () {
      test('loads a valid M3U file from an absolute path', () async {
        const playlist = '#EXTM3U\nhttps://example.com/live.m3u8';
        final directory = await Directory.systemTemp.createTemp('m3u_path_');
        final file = File('${directory.path}/channels.m3u');
        await file.writeAsString(playlist);
        final service = M3uSourceService();

        try {
          expect(await service.loadFromPath(file.path), playlist);
        } finally {
          service.close();
          await directory.delete(recursive: true);
        }
      });

      test('loads a valid M3U8 file from an absolute path', () async {
        const playlist = '#EXTM3U\nhttps://example.com/live.m3u8';
        final directory = await Directory.systemTemp.createTemp('m3u_path_');
        final file = File('${directory.path}/channels.m3u8');
        await file.writeAsString(playlist);
        final service = M3uSourceService();

        try {
          expect(await service.loadFromPath(file.path), playlist);
        } finally {
          service.close();
          await directory.delete(recursive: true);
        }
      });

      test('rejects an empty or relative path', () async {
        final service = M3uSourceService();

        try {
          await expectLater(
            service.loadFromPath('  '),
            throwsA(isA<M3uSourceException>()),
          );
          await expectLater(
            service.loadFromPath('channels.m3u'),
            throwsA(isA<M3uSourceException>()),
          );
        } finally {
          service.close();
        }
      });

      test('rejects unsupported file extension', () async {
        final directory = await Directory.systemTemp.createTemp('m3u_path_');
        final file = File('${directory.path}/channels.txt');
        await file.writeAsString('#EXTM3U');
        final service = M3uSourceService();

        try {
          await expectLater(
            service.loadFromPath(file.path),
            throwsA(isA<M3uSourceException>()),
          );
        } finally {
          service.close();
          await directory.delete(recursive: true);
        }
      });

      test('rejects a missing file', () async {
        final directory = await Directory.systemTemp.createTemp('m3u_path_');
        final file = File('${directory.path}/missing.m3u');
        final service = M3uSourceService();

        try {
          await expectLater(
            service.loadFromPath(file.path),
            throwsA(isA<M3uSourceException>()),
          );
        } finally {
          service.close();
          await directory.delete(recursive: true);
        }
      });

      test('rejects a file exceeding the size limit', () async {
        final directory = await Directory.systemTemp.createTemp('m3u_path_');
        final file = File('${directory.path}/large.m3u');
        await file.writeAsBytes(List<int>.filled(6, 65));
        final service = M3uSourceService(maxBytes: 5);

        try {
          await expectLater(
            service.loadFromPath(file.path),
            throwsA(isA<M3uSourceException>()),
          );
        } finally {
          service.close();
          await directory.delete(recursive: true);
        }
      });

      test('rejects invalid UTF-8 content', () async {
        final directory = await Directory.systemTemp.createTemp('m3u_path_');
        final file = File('${directory.path}/invalid.m3u');
        await file.writeAsBytes([0xFF]);
        final service = M3uSourceService();

        try {
          await expectLater(
            service.loadFromPath(file.path),
            throwsA(isA<M3uSourceException>()),
          );
        } finally {
          service.close();
          await directory.delete(recursive: true);
        }
      });
    });

    group('loadFromUrl', () {
      test('downloads playlist from HTTP URL', () async {
        const playlist = '#EXTM3U\nhttps://example.com/live.m3u8';

        final client = MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.toString(), 'https://example.com/list.m3u');
          return http.Response(playlist, 200);
        });

        final service = M3uSourceService(client: client);

        expect(
          await service.loadFromUrl(' https://example.com/list.m3u '),
          playlist,
        );

        service.close();
      });

      test('downloads playlist from HTTPS URL', () async {
        const playlist = '#EXTM3U';

        final client = MockClient((_) async => http.Response(playlist, 200));

        final service = M3uSourceService(client: client);

        expect(
          await service.loadFromUrl('https://example.com/list.m3u8'),
          playlist,
        );

        service.close();
      });

      test('rejects empty URL', () async {
        final service = M3uSourceService(
          client: MockClient((_) async => http.Response('', 200)),
        );

        await expectLater(
          service.loadFromUrl('  '),
          throwsA(isA<M3uSourceException>()),
        );

        service.close();
      });

      test('rejects unsupported URL schemes', () async {
        final service = M3uSourceService(
          client: MockClient((_) async => http.Response('', 200)),
        );

        for (final url in [
          'ftp://example.com/list.m3u',
          'file:///playlist.m3u',
          'example.com/list.m3u',
        ]) {
          await expectLater(
            service.loadFromUrl(url),
            throwsA(isA<M3uSourceException>()),
          );
        }

        service.close();
      });

      test('rejects response exceeding Content-Length limit', () async {
        final service = M3uSourceService(
          maxBytes: 5,
          client: MockClient(
            (_) async =>
                http.Response('123456', 200, headers: {'content-length': '6'}),
          ),
        );

        await expectLater(
          service.loadFromUrl('https://example.com/large.m3u'),
          throwsA(isA<M3uSourceException>()),
        );

        service.close();
      });

      test('rejects streamed response exceeding size limit', () async {
        final client = MockClient((_) async {
          return http.Response(
            '123456',
            200,
            headers: {'content-type': 'application/octet-stream'},
          );
        });

        final service = M3uSourceService(maxBytes: 5, client: client);

        await expectLater(
          service.loadFromUrl('https://example.com/stream.m3u'),
          throwsA(isA<M3uSourceException>()),
        );

        service.close();
      });

      test(
        'rejects streamed bytes without Content-Length when over limit',
        () async {
          final client = FixedStreamedClient(
            http.StreamedResponse(
              Stream<Uint8List>.fromIterable([
                Uint8List.fromList([1, 2, 3]),
                Uint8List.fromList([4, 5, 6]),
              ]),
              200,
            ),
          );

          final service = M3uSourceService(maxBytes: 5, client: client);

          await expectLater(
            service.loadFromUrl('https://example.com/chunked.m3u'),
            throwsA(isA<M3uSourceException>()),
          );

          service.close();
        },
      );

      test('rejects unsuccessful HTTP status', () async {
        final service = M3uSourceService(
          client: MockClient((_) async => http.Response('Not found', 404)),
        );

        await expectLater(
          service.loadFromUrl('https://example.com/missing.m3u'),
          throwsA(
            isA<M3uSourceException>().having(
              (error) => error.message,
              'message',
              contains('404'),
            ),
          ),
        );

        service.close();
      });
    });
  });
}
