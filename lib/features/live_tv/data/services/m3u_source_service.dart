import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

/// Errors raised while loading an M3U playlist source.
class M3uSourceException implements Exception {
  final String message;

  const M3uSourceException(this.message);

  @override
  String toString() => 'M3uSourceException: $message';
}

/// Loads M3U content from HTTP/HTTPS URLs or a picked local file.
///
/// This service only loads and decodes the source.
/// Parsing and database import remain the responsibility of other classes.
class M3uSourceService {
  static const int defaultMaxBytes = 20 * 1024 * 1024;

  final http.Client _client;
  final Duration timeout;
  final int maxBytes;

  M3uSourceService({
    http.Client? client,
    this.timeout = const Duration(seconds: 30),
    this.maxBytes = defaultMaxBytes,
  }) : _client = client ?? http.Client() {
    if (maxBytes <= 0) {
      throw ArgumentError.value(maxBytes, 'maxBytes', 'Must be positive');
    }

    if (timeout <= Duration.zero) {
      throw ArgumentError.value(timeout, 'timeout', 'Must be positive');
    }
  }

  /// Downloads an M3U playlist from an HTTP or HTTPS URL.
  Future<String> loadFromUrl(String url) async {
    final trimmedUrl = url.trim();

    if (trimmedUrl.isEmpty) {
      throw const M3uSourceException('Playlist URL cannot be empty.');
    }

    final uri = Uri.tryParse(trimmedUrl);

    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw const M3uSourceException(
        'Invalid playlist URL. Only HTTP and HTTPS URLs are supported.',
      );
    }

    try {
      final request = http.Request('GET', uri);
      final response = await _client.send(request).timeout(timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw M3uSourceException(
          'Playlist download failed with HTTP status '
          '${response.statusCode}.',
        );
      }

      final contentLength = response.contentLength;

      if (contentLength != null && contentLength > maxBytes) {
        throw M3uSourceException(
          'Playlist is too large. Maximum allowed size is '
          '${_formatSize(maxBytes)}.',
        );
      }

      final bytes = await _readResponse(response).timeout(timeout);

      return _decodeUtf8(bytes);
    } on M3uSourceException {
      rethrow;
    } on TimeoutException {
      throw const M3uSourceException('Playlist download timed out.');
    } on FormatException {
      throw const M3uSourceException('Playlist contains invalid UTF-8 text.');
    } on http.ClientException catch (error) {
      throw M3uSourceException(
        'Network error while downloading playlist: ${error.message}',
      );
    } catch (error) {
      throw M3uSourceException('Unable to download playlist: $error');
    }
  }

  /// Reads an M3U playlist from a file selected with FilePicker.
  ///
  /// Does not depend on PlatformFile.path because Android may return
  /// a content URI without a normal filesystem path.
  Future<String> loadFromPickedFile(PlatformFile file) async {
    final extension = file.extension?.toLowerCase();

    if (extension != 'm3u' && extension != 'm3u8') {
      throw const M3uSourceException(
        'Unsupported file type. Please select an M3U or M3U8 file.',
      );
    }

    try {
      final knownLength = file.lengthSync();

      if (knownLength != null && knownLength > maxBytes) {
        throw M3uSourceException(
          'Playlist file is too large. Maximum allowed size is '
          '${_formatSize(maxBytes)}.',
        );
      }

      final actualLength = await file.length();

      if (actualLength != null && actualLength > maxBytes) {
        throw M3uSourceException(
          'Playlist file is too large. Maximum allowed size is '
          '${_formatSize(maxBytes)}.',
        );
      }

      final bytes = await file.readAsBytes();

      if (bytes.length > maxBytes) {
        throw M3uSourceException(
          'Playlist file is too large. Maximum allowed size is '
          '${_formatSize(maxBytes)}.',
        );
      }

      return _decodeUtf8(bytes);
    } on M3uSourceException {
      rethrow;
    } on FormatException {
      throw const M3uSourceException(
        'Playlist file contains invalid UTF-8 text.',
      );
    } catch (error) {
      throw M3uSourceException(
        'Unable to read playlist file "${file.name}": $error',
      );
    }
  }

  /// Reads an M3U playlist from an absolute local filesystem path.
  ///
  /// Android content URIs must be loaded through FilePicker instead.
  Future<String> loadFromPath(String path) async {
    final trimmedPath = path.trim();

    if (trimmedPath.isEmpty || !trimmedPath.startsWith('/')) {
      throw const M3uSourceException(
        'Please enter a valid absolute file path.',
      );
    }

    final lowerPath = trimmedPath.toLowerCase();
    if (!lowerPath.endsWith('.m3u') && !lowerPath.endsWith('.m3u8')) {
      throw const M3uSourceException(
        'Unsupported file type. Please use an M3U or M3U8 file.',
      );
    }

    final file = File(trimmedPath);

    try {
      if (!await file.exists()) {
        throw const M3uSourceException(
          'Playlist file does not exist or cannot be accessed.',
        );
      }

      final fileLength = await file.length();

      if (fileLength > maxBytes) {
        throw M3uSourceException(
          'Playlist file is too large. Maximum allowed size is '
          '${_formatSize(maxBytes)}.',
        );
      }

      final bytes = await file.readAsBytes();

      if (bytes.length > maxBytes) {
        throw M3uSourceException(
          'Playlist file is too large. Maximum allowed size is '
          '${_formatSize(maxBytes)}.',
        );
      }

      return _decodeUtf8(bytes);
    } on M3uSourceException {
      rethrow;
    } on FormatException {
      throw const M3uSourceException(
        'Playlist file contains invalid UTF-8 text.',
      );
    } on FileSystemException catch (error) {
      throw M3uSourceException(
        'Unable to access playlist file. Check file permissions: '
        '${error.message}',
      );
    } catch (error) {
      throw M3uSourceException('Unable to read playlist file: $error');
    }
  }

  Future<Uint8List> _readResponse(http.StreamedResponse response) async {
    final builder = BytesBuilder(copy: false);
    var totalBytes = 0;

    await for (final chunk in response.stream) {
      totalBytes += chunk.length;

      if (totalBytes > maxBytes) {
        throw M3uSourceException(
          'Playlist is too large. Maximum allowed size is '
          '${_formatSize(maxBytes)}.',
        );
      }

      builder.add(chunk);
    }

    return builder.takeBytes();
  }

  String _decodeUtf8(Uint8List bytes) {
    try {
      return utf8.decode(bytes, allowMalformed: false);
    } on FormatException {
      throw const M3uSourceException('Source is not valid UTF-8 text.');
    }
  }

  String _formatSize(int bytes) {
    final megabytes = bytes / (1024 * 1024);
    return '${megabytes.toStringAsFixed(1)} MB';
  }

  /// Closes the underlying HTTP client.
  void close() {
    _client.close();
  }
}
