import 'package:flutter/services.dart';

class ScannedVideo {
  const ScannedVideo({
    required this.uri,
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
    required this.dateModifiedSeconds,
    required this.durationMs,
    required this.folderName,
  });

  final String uri;
  final String fileName;
  final String? mimeType;
  final int sizeBytes;
  final int dateModifiedSeconds;
  final int durationMs;
  final String folderName;

  factory ScannedVideo.fromMap(Map<Object?, Object?> map) {
    final uri = map['uri'];
    final fileName = map['fileName'];
    final sizeBytes = map['sizeBytes'];
    final dateModified = map['dateModified'];
    final durationMs = map['durationMs'];

    if (uri is! String ||
        uri.isEmpty ||
        fileName is! String ||
        fileName.isEmpty ||
        sizeBytes is! num ||
        dateModified is! num ||
        durationMs is! num) {
      throw const FormatException('Invalid video metadata from Android.');
    }

    final mimeType = map['mimeType'];
    final folderName = map['folderName'];

    return ScannedVideo(
      uri: uri,
      fileName: fileName,
      mimeType: mimeType is String ? mimeType : null,
      sizeBytes: sizeBytes.toInt(),
      dateModifiedSeconds: dateModified.toInt(),
      durationMs: durationMs.toInt(),
      folderName: folderName is String ? folderName : '',
    );
  }
}

class AndroidMediaStoreScanner {
  AndroidMediaStoreScanner({MethodChannel? channel})
    : _channel =
          channel ?? const MethodChannel('com.example.orixon/local_media');

  final MethodChannel _channel;
  final Map<String, Future<Uint8List?>> _thumbnailCache = {};

  Future<Uint8List?> getVideoThumbnail(
    String uri, {
    int maxWidth = 480,
    int maxHeight = 270,
  }) {
    if (uri.isEmpty) return Future.value(null);

    final cacheKey = '$uri|$maxWidth|$maxHeight';
    return _thumbnailCache.putIfAbsent(cacheKey, () async {
      try {
        return await _channel.invokeMethod<Uint8List>('getVideoThumbnail', {
          'uri': uri,
          'maxWidth': maxWidth,
          'maxHeight': maxHeight,
        });
      } on PlatformException {
        return null;
      } on MissingPluginException {
        return null;
      }
    });
  }

  Future<bool> hasVideoPermission() async {
    return await _channel.invokeMethod<bool>('hasVideoPermission') ?? false;
  }

  Future<bool> requestVideoPermission() async {
    return await _channel.invokeMethod<bool>('requestVideoPermission') ?? false;
  }

  Future<List<ScannedVideo>> scanVideos() async {
    final result = await _channel.invokeMethod<List<dynamic>>('scanVideos');

    if (result == null) {
      return const [];
    }

    return result
        .map((item) {
          if (item is! Map) {
            throw const FormatException('Invalid video entry from Android.');
          }
          return ScannedVideo.fromMap(Map<Object?, Object?>.from(item));
        })
        .toList(growable: false);
  }
}
