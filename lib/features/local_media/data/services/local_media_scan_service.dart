import '../repositories/local_media_repository.dart';
import 'android_media_store_scanner.dart';

class LocalMediaScanResult {
  const LocalMediaScanResult({
    required this.permissionRequired,
    required this.discoveredCount,
    required this.importedCount,
  });

  final bool permissionRequired;
  final int discoveredCount;
  final int importedCount;
}

class LocalMediaScanService {
  const LocalMediaScanService({
    required this.scanner,
    required this.repository,
  });

  final AndroidMediaStoreScanner scanner;
  final LocalMediaRepository repository;

  Future<LocalMediaScanResult> scan() async {
    final hasPermission = await scanner.hasVideoPermission();

    if (!hasPermission) {
      return const LocalMediaScanResult(
        permissionRequired: true,
        discoveredCount: 0,
        importedCount: 0,
      );
    }

    final videos = await scanner.scanVideos();
    var importedCount = 0;

    for (final video in videos) {
      await repository.upsertScannedFile(
        filePath: video.uri,
        fileName: video.fileName,
        folderName: video.folderName,
        sizeBytes: video.sizeBytes,
        durationMs: video.durationMs,
      );
      importedCount++;
    }

    return LocalMediaScanResult(
      permissionRequired: false,
      discoveredCount: videos.length,
      importedCount: importedCount,
    );
  }
}
