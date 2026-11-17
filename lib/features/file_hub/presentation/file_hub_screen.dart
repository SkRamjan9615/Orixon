import 'package:file_picker/file_picker.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import '../../../core/database/app_database.dart';
import '../../live_tv/data/repositories/playlist_repository.dart';
import '../../local_media/presentation/local_media_player_screen.dart';
import 'file_hub_services.dart';

class FileHubScreen extends StatefulWidget {
  const FileHubScreen({super.key, this.database, this.initialShareFilePath, this.initialDirectoryPath, this.pickFileMode = false});
  final AppDatabase? database;
  final String? initialShareFilePath;
  final String? initialDirectoryPath;
  final bool pickFileMode;

  @override
  State<FileHubScreen> createState() => _FileHubScreenState();
}

enum _FileSection {
  explorer('Storage Explorer', 'Browse folders & USB drives', Icons.folder_open_rounded, Color(0xFF26E7FF)),
  downloads('Downloads', 'Downloaded files & videos', Icons.download_rounded, Color(0xFF34D399)),
  videos('Videos & Movies', '4K, HD & local video files', Icons.movie_creation_outlined, Color(0xFFD552FF)),
  audio('Audio & Music', 'MP3, FLAC, AAC & soundtracks', Icons.headphones_rounded, Color(0xFFF59E0B)),
  images('Pictures & Art', 'Photos, wallpapers & covers', Icons.image_outlined, Color(0xFFEC4899)),
  apks('Apps (APK)', 'Android packages & installers', Icons.android_rounded, Color(0xFF10B981)),
  archives('ZIP & Playlists', 'Extract .ZIP or import .M3U8', Icons.folder_zip_outlined, Color(0xFF60A5FA)),
  shareHub('Universal Share Hub', 'Nearby, Orixon Beam, Wi-Fi & FTP', Icons.hub_rounded, Color(0xFF26E7FF));

  const _FileSection(this.title, this.subtitle, this.icon, this.color);
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
}

class _StorageVolumeInfo {
  const _StorageVolumeInfo({
    required this.name,
    required this.path,
    required this.totalBytes,
    required this.freeBytes,
  });
  final String name;
  final String path;
  final int totalBytes;
  final int freeBytes;
  int get usedBytes => (totalBytes - freeBytes).clamp(0, totalBytes);
  double get ratio => totalBytes > 0 ? (usedBytes / totalBytes).clamp(0.0, 1.0) : 0.35;
}

class _LanPeer {
  _LanPeer({required this.name, required this.ip, required this.httpPort});
  final String name;
  final String ip;
  final int httpPort;
}

class _FileHubScreenState extends State<FileHubScreen> {
  static const MethodChannel _sysChannel = MethodChannel('com.example.orixon/system_tools');
  static const Color _bg = Colors.transparent;
  static const Color _surface = Color(0xFF0C1526);
  static const Color _cyan = Color(0xFF26E7FF);
  static const Color _gold = Color(0xFFF59E0B);

  _FileSection _activeSection = _FileSection.explorer;
  String _currentPath = '/storage/emulated/0';
  String _searchQuery = '';
  bool _gridView = false;
  bool _showHidden = false;
  bool _hasAllFilesAccess = true;
  bool _isLoading = true;

  List<_StorageVolumeInfo> _volumes = [];
  List<FileSystemEntity> _entries = [];
  final Set<String> _selectedPaths = {};
  final List<String> _clipboardPaths = [];
  bool _clipboardIsCut = false;

  HttpServer? _httpShareServer;
  ServerSocket? _ftpServer;
  RawDatagramSocket? _lanRadarSocket;
  Timer? _lanBroadcastTimer;
  String _localIp = '127.0.0.1';
  final int _httpPort = 8888;
  final int _ftpPort = 2121;
  bool _httpShareRunning = false;
  bool _ftpRunning = false;
  bool _lanRadarRunning = false;
  final Map<String, _LanPeer> _lanPeers = {};
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialShareFilePath != null &&
        widget.initialShareFilePath!.trim().isNotEmpty) {
      _activeSection = _FileSection.shareHub;
      _selectedPaths.add(widget.initialShareFilePath!.trim());
    }
    if (widget.initialDirectoryPath != null &&
        widget.initialDirectoryPath!.trim().isNotEmpty) {
      final dir = Directory(widget.initialDirectoryPath!.trim());
      if (!dir.existsSync()) {
        try {
          dir.createSync(recursive: true);
        } catch (_) {}
      }
      _activeSection = _FileSection.explorer;
      _currentPath = dir.path;
    }
    _initFileHub();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _lanBroadcastTimer?.cancel();
    _lanRadarSocket?.close();
    _httpShareServer?.close(force: true);
    _ftpServer?.close();
    super.dispose();
  }

  Future<void> _initFileHub() async {
    setState(() => _isLoading = true);
    await _detectLocalIp();
    await _checkStorageAccessAndVolumes();
    await _loadSavedSettings();
    await _loadEntries();
  }

  Future<void> _loadSavedSettings() async {
    final db = widget.database;
    if (db == null) return;
    try {
      final rows = await db.select(db.appSettings).get();
      for (final r in rows) {
        if (r.key.endsWith('Auto-start FTP Server') && r.value == 'true' && !_ftpRunning) {
          unawaited(_toggleFtpServer(true));
        } else if (r.key.endsWith('Auto-start Wi-Fi Share') && r.value == 'true' && !_httpShareRunning) {
          unawaited(_toggleHttpShare(true));
        } else if (r.key.endsWith('Show hidden files')) {
          _showHidden = r.value == 'true';
        }
      }
    } catch (_) {}
  }

  Future<void> _detectLocalIp() async {
    try {
      final ifaces = await NetworkInterface.list(type: InternetAddressType.IPv4, includeLoopback: false);
      for (final iface in ifaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback && (addr.address.startsWith('192.168.') || addr.address.startsWith('10.') || addr.address.startsWith('172.'))) {
            _localIp = addr.address;
            return;
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _checkStorageAccessAndVolumes() async {
    if (Platform.isAndroid) {
      try {
        _hasAllFilesAccess = await _sysChannel.invokeMethod<bool>('hasAllFilesPermission') ?? false;
        final rawVols = await _sysChannel.invokeMethod<List<dynamic>>('getStorageRoots');
        if (rawVols != null && rawVols.isNotEmpty) {
          _volumes = rawVols.map((item) {
            final m = Map<String, dynamic>.from(item as Map);
            return _StorageVolumeInfo(
              name: (m['name'] ?? 'Storage').toString(),
              path: (m['path'] ?? '/storage/emulated/0').toString(),
              totalBytes: (m['totalBytes'] as num?)?.toInt() ?? 0,
              freeBytes: (m['freeBytes'] as num?)?.toInt() ?? 0,
            );
          }).toList();
        }
      } catch (_) {}
    }
    if (_volumes.isEmpty) {
      final p0 = Directory('/storage/emulated/0').existsSync() ? '/storage/emulated/0' : Directory.current.path;
      _volumes = [_StorageVolumeInfo(name: 'Internal Storage', path: p0, totalBytes: 64 << 30, freeBytes: 24 << 30)];
    }
    if (!Directory(_currentPath).existsSync()) _currentPath = _volumes.first.path;
  }

  Future<void> _requestFullStoragePermission() async {
    if (!Platform.isAndroid) return;
    try {
      await _sysChannel.invokeMethod('requestAllFilesPermission');
      await Future<void>.delayed(const Duration(seconds: 1));
      await _checkStorageAccessAndVolumes();
      await _loadEntries();
    } catch (_) {}
  }

  Future<void> _loadEntries() async {
    await _loadSavedSettings();
    if (!mounted || _activeSection == _FileSection.shareHub) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    final results = <FileSystemEntity>[];
    try {
      if (_activeSection == _FileSection.explorer) {
        final d = Directory(_currentPath);
        if (d.existsSync()) {
          results.addAll(
            d.listSync(followLinks: false).where(
                  (e) => _showHidden || !p.basename(e.path).startsWith('.'),
                ),
          );
        }
      } else if (_activeSection == _FileSection.downloads) {
        final dl = Directory(p.join(_volumes.first.path, 'Download'));
        if (dl.existsSync()) {
          results.addAll(
            dl.listSync(followLinks: false).where(
                  (e) => _showHidden || !p.basename(e.path).startsWith('.'),
                ),
          );
        }
      } else {
        final root = _volumes.first.path;
        final scanDirs = <Directory>[
          for (final sub in ['Download', 'Movies', 'Video', 'DCIM', 'Pictures', 'Music', 'Documents', 'Bluetooth'])
            Directory(p.join(root, sub)),
        ];
        if (_showHidden && Directory(root).existsSync()) {
          for (final ent in Directory(root).listSync(followLinks: false)) {
            if (ent is Directory && p.basename(ent.path).startsWith('.')) {
              scanDirs.add(ent);
            }
          }
        }
        for (final d in scanDirs) {
          if (d.existsSync()) _collectFiles(d, results, 0, 3);
        }
      }
    } catch (_) {}

    final q = _searchQuery.trim().toLowerCase();
    final filtered = results.where((e) => q.isEmpty || p.basename(e.path).toLowerCase().contains(q)).toList();
    filtered.sort((a, b) {
      final aDir = a is Directory;
      final bDir = b is Directory;
      if (aDir != bDir) return aDir ? -1 : 1;
      return p.basename(a.path).toLowerCase().compareTo(p.basename(b.path).toLowerCase());
    });
    if (mounted) setState(() { _entries = filtered; _isLoading = false; });
  }

  void _collectFiles(Directory dir, List<FileSystemEntity> out, int depth, int maxD) {
    if (depth > maxD || out.length >= 500) return;
    try {
      for (final ent in dir.listSync(followLinks: false)) {
        if (!_showHidden && p.basename(ent.path).startsWith('.')) continue;
        if (ent is File && _matchesSection(ent.path, _activeSection)) {
          out.add(ent);
        } else if (ent is Directory && depth < maxD) {
          _collectFiles(ent, out, depth + 1, maxD);
        }
      }
    } catch (_) {}
  }

  bool _matchesSection(String path, _FileSection sec) {
    final ext = p.extension(path).toLowerCase();
    switch (sec) {
      case _FileSection.videos: return const {'.mp4', '.mkv', '.avi', '.mov', '.webm', '.ts', '.flv', '.m4v'}.contains(ext);
      case _FileSection.audio: return const {'.mp3', '.aac', '.wav', '.flac', '.ogg', '.m4a'}.contains(ext);
      case _FileSection.images: return const {'.jpg', '.jpeg', '.png', '.webp', '.gif'}.contains(ext);
      case _FileSection.apks: return ext == '.apk' || ext == '.apks' || ext == '.xapk';
      case _FileSection.archives: return const {'.zip', '.tar', '.gz', '.m3u', '.m3u8'}.contains(ext);
      default: return true;
    }
  }

  int _safeSize(File f) { try { return f.lengthSync(); } catch (_) { return 0; } }

  String _formatBytes(int b) {
    if (b <= 0) return '0 B';
    const u = ['B', 'KB', 'MB', 'GB', 'TB'];
    var v = b.toDouble();
    var i = 0;
    while (v >= 1024 && i < u.length - 1) { v /= 1024; i++; }
    return '${v.toStringAsFixed(i == 0 ? 0 : 1)} ${u[i]}';
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
  }

  MediaFile _toMediaFile(String filePath, String displayTitle) {
    return MediaFile(
      id: 0,
      filePath: filePath,
      fileName: displayTitle,
      folderName: 'File Hub',
      sizeBytes: 0,
      durationMs: 0,
      lastPositionMs: 0,
      isFavorite: false,
      lastPlayedAt: null,
      dateAdded: DateTime.now(),
      preferredAudioTrack: null,
      preferredSubtitleTrack: null,
    );
  }

  Future<void> _onTapEntity(FileSystemEntity entity) async {
    if (widget.pickFileMode && entity is File) {
      Navigator.of(context).pop(entity.path);
      return;
    }
    if (_selectedPaths.isNotEmpty) {
      setState(() => _selectedPaths.contains(entity.path) ? _selectedPaths.remove(entity.path) : _selectedPaths.add(entity.path));
      return;
    }
    if (entity is Directory) {
      setState(() { _activeSection = _FileSection.explorer; _currentPath = entity.path; });
      await _loadEntries();
      return;
    }
    if (entity is File) {
      final ext = p.extension(entity.path).toLowerCase();
      if (_matchesSection(entity.path, _FileSection.videos)) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => LocalMediaPlayerScreen(video: _toMediaFile(entity.path, p.basename(entity.path)))),
        );
        return;
      }
      if (ext == '.zip') {
        final targetDir = Directory(p.join(p.dirname(entity.path), p.basenameWithoutExtension(entity.path)));
        try {
          final count = await PureDartZipEngine.extractZip(entity, targetDir);
          _showSnack('Extracted $count files to ${targetDir.path}');
          await _loadEntries();
        } catch (e) { _showSnack('ZIP extract error: $e'); }
        return;
      }
      if (ext == '.m3u' || ext == '.m3u8') {
        await _importM3uToLiveTv(entity);
        return;
      }
      if (Platform.isAndroid) {
        await _sysChannel.invokeMethod('openFileExternal', {'path': entity.path, 'mimeType': ext == '.apk' ? 'application/vnd.android.package-archive' : '*/*'});
      }
    }
  }

  Future<void> _importM3uToLiveTv(File m3uFile) async {
    final db = widget.database;
    if (db == null) return;
    try {
      var content = await m3uFile.readAsString();
      final name = p.basenameWithoutExtension(m3uFile.path);
      if (!content.contains('#EXTINF:')) {
        content = '#EXTM3U\n#EXTINF:-1 group-title="Live TV",$name\n${m3uFile.path}\n';
      }
      final playlistRepo = PlaylistRepository(database: db);
      final created = await playlistRepo.createPlaylist(name: name, sourceUrlOrPath: m3uFile.path);
      final res = await playlistRepo.importM3u(playlistId: created.id, content: content);
      _showSnack('Imported ${res.inserted} channels from $name into Live TV!');
    } catch (e) { _showSnack('Import error: $e'); }
  }

  Future<void> _createZipFromSelected() async {
    if (_selectedPaths.isEmpty) return;
    final outFile = File(p.join(_currentPath, 'orixon_archive_${DateTime.now().millisecondsSinceEpoch ~/ 1000}.zip'));
    try {
      final added = await PureDartZipEngine.createZip(_selectedPaths.toList(), outFile);
      setState(() => _selectedPaths.clear());
      _showSnack('Created ${p.basename(outFile.path)} ($added files)');
      await _loadEntries();
    } catch (e) { _showSnack('ZIP error: $e'); }
  }

  Future<void> _pasteClipboardHere() async {
    if (_clipboardPaths.isEmpty) return;
    int count = 0;
    for (final src in _clipboardPaths) {
      final dest = p.join(_currentPath, p.basename(src));
      if (src == dest) continue;
      try {
        if (FileSystemEntity.isFileSync(src)) {
          File(src).copySync(dest);
          if (_clipboardIsCut) File(src).deleteSync();
          count++;
        }
      } catch (_) {}
    }
    setState(() { _clipboardPaths.clear(); _clipboardIsCut = false; _selectedPaths.clear(); });
    _showSnack('Pasted $count item(s)');
    await _loadEntries();
  }

  Future<void> _deleteSelected() async {
    for (final path in _selectedPaths) {
      try {
        if (FileSystemEntity.isDirectorySync(path)) {
          Directory(path).deleteSync(recursive: true);
        } else {
          File(path).deleteSync();
        }
      } catch (_) {}
    }
    setState(() => _selectedPaths.clear());
    await _loadEntries();
  }

  Future<void> _cleanJunkFiles() async {
    int count = 0;
    try {
      for (final dName in ['Download', 'Movies', 'DCIM']) {
        final d = Directory(p.join(_volumes.first.path, dName));
        if (!d.existsSync()) continue;
        for (final ent in d.listSync(recursive: true, followLinks: false)) {
          if (ent is File && const {'.tmp', '.temp', '.log', '.bak', '.old'}.contains(p.extension(ent.path).toLowerCase())) {
            try { ent.deleteSync(); count++; } catch (_) {}
          }
        }
      }
    } catch (_) {}
    _showSnack('Cleaned $count junk files!');
    await _loadEntries();
  }

    Future<void> _shareViaGlobalCloudLink(List<String> currentSelected) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A1426),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFF38BDF8)),
        ),
        title: const Row(
          children: [
            Icon(Icons.public_rounded, color: Color(0xFF38BDF8)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Global Cloud Share (Send & Receive)',
                style: TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFF38BDF8)),
              ),
              tileColor: const Color(0xFF38BDF8).withValues(alpha: 0.12),
              leading: const Icon(Icons.cloud_upload_rounded, color: Color(0xFF38BDF8), size: 26),
              title: const Text(
                'Send File (Create Share Code & Link)',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13.5),
              ),
              subtitle: const Text(
                'Upload any file to get a 6-digit code & browser download link',
                style: TextStyle(color: Colors.white60, fontSize: 11.5),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _performCloudUpload(currentSelected);
              },
            ),
            const SizedBox(height: 10),
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFA855F7)),
              ),
              tileColor: const Color(0xFFA855F7).withValues(alpha: 0.12),
              leading: const Icon(Icons.cloud_download_rounded, color: Color(0xFFA855F7), size: 26),
              title: const Text(
                'Receive File (Enter Code or Link)',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13.5),
              ),
              subtitle: const Text(
                'Enter 6-digit share code or paste link to download into Orixon',
                style: TextStyle(color: Colors.white60, fontSize: 11.5),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _receiveFileFromLinkDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performCloudUpload(List<String> currentSelected) async {
    String? filePath = currentSelected.isNotEmpty ? currentSelected.first : null;
    if (filePath == null || !File(filePath).existsSync()) {
      try {
        final picked = await FilePicker.pickFiles();
        if (picked != null && picked.isNotEmpty && picked.first.path != null) {
          filePath = picked.first.path!;
        }
      } catch (_) {}
    }
    if (filePath == null || !File(filePath).existsSync()) {
      _showSnack('No file selected.');
      return;
    }

    final file = File(filePath);
    final rawName = p.basename(filePath).replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final code6 = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
    final binId = 'orx$code6';

    _showSnack('Uploading $rawName...');
    String? shareUrl;

    // Primary Unblocked Global Cloud Relay: filebin.net (works across Jio/Airtel/Wi-Fi/Worldwide)
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 30)
        ..badCertificateCallback = (_, _, _) => true;
      final targetUri = Uri.parse('https://filebin.net/$binId/$rawName');
      final req = await client.postUrl(targetUri);
      req.headers.set('User-Agent', 'Orixon/1.0');
      req.headers.set('cid', binId);
      req.headers.set(HttpHeaders.contentTypeHeader, 'application/octet-stream');
      req.contentLength = file.lengthSync();
      await req.addStream(file.openRead());
      final resp = await req.close();
      await resp.drain<void>();
      client.close();
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        shareUrl = 'https://filebin.net/$binId/$rawName';
      }
    } catch (_) {}

    // Fallback Relay 2: bashupload.com
    if (shareUrl == null) {
      try {
        final client = HttpClient()
          ..connectionTimeout = const Duration(seconds: 30)
          ..badCertificateCallback = (_, _, _) => true;
        final req = await client.putUrl(Uri.parse('https://bashupload.com/$rawName'));
        req.contentLength = file.lengthSync();
        await req.addStream(file.openRead());
        final resp = await req.close();
        final text = await utf8.decoder.bind(resp).join();
        client.close();
        final m = RegExp(r'https://bashupload\.com/\S+').firstMatch(text);
        if (m != null) {
          shareUrl = m.group(0);
        }
      } catch (_) {}
    }

    // Fallback Relay 3: Local Wi-Fi HTTP Direct Link (always works offline/LAN)
    if (shareUrl == null) {
      if (!_httpShareRunning) {
        await _toggleHttpShare(true);
      }
      shareUrl = 'http://$_localIp:$_httpPort';
    }

    if (!mounted) return;
    await Clipboard.setData(ClipboardData(text: shareUrl));
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A1426),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFF38BDF8)),
        ),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF38BDF8)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Share Link & Receive Code Ready',
                style: TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF38BDF8)),
              ),
              child: Column(
                children: [
                  const Text(
                    '6-DIGIT RECEIVE CODE (ORIXON TO ORIXON)',
                    style: TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    '$code6|$rawName',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Direct Browser Link (Copied to Clipboard):',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF050B16),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white24),
              ),
              child: SelectableText(
                shareUrl!,
                style: const TextStyle(
                  color: Color(0xFF38BDF8),
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

    Future<void> _receiveFileFromLinkDialog() async {
    final ctrl = TextEditingController();
    if (!mounted) return;
    final rawInput = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A1426),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFF38BDF8)),
        ),
        title: const Text(
          'Receive File (Enter Code or Link)',
          style: TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w800),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Paste https://... link or Code|filename',
            labelText: 'Share Link or Receive Code',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('RECEIVE FILE'),
          ),
        ],
      ),
    );
    if (rawInput == null || rawInput.isEmpty) return;

    String url = rawInput;
    if (!url.startsWith('http') && url.contains('|')) {
      final parts = url.split('|');
      final code = parts.first.trim().replaceAll('ORX-', '');
      final fName = parts.last.trim();
      url = 'https://filebin.net/orx$code/$fName';
    }
    if (!url.startsWith('http')) {
      _showSnack('Please enter a valid Share Link or Code|filename.');
      return;
    }

    _showSnack('Receiving file...');
    try {
      final uri = Uri.parse(url);
      final name = uri.pathSegments.isNotEmpty && uri.pathSegments.last.isNotEmpty
          ? uri.pathSegments.last
          : 'orixon_received_${DateTime.now().millisecondsSinceEpoch}.bin';
      final saveDir = Directory(Platform.isAndroid ? '/storage/emulated/0/Download' : '${Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? Directory.current.path}/Downloads');
      if (!saveDir.existsSync()) saveDir.createSync(recursive: true);
      final savePath = p.join(saveDir.path, name);
      final client = HttpClient()..badCertificateCallback = (_, _, _) => true;
      final req = await client.getUrl(uri);
      req.headers.set('User-Agent', 'Orixon/1.0');
      req.headers.set('Cookie', 'verified=2024-05-24');
      final resp = await req.close();
      final out = File(savePath).openWrite();
      await resp.pipe(out);
      await out.close();
      client.close();
      _showSnack('Received & saved to $savePath');
      _loadEntries();
    } catch (e) {
      _showSnack('Receive failed: $e');
    }
  }

  Future<void> _shareNative(List<String> paths, {bool preferNearby = false}) async {
    if (paths.isEmpty) { _showSnack('Select files first to share via Orixon Share.'); return; }
    if (Platform.isAndroid) {
      await _sysChannel.invokeMethod('shareFiles', {'paths': paths, 'preferNearby': preferNearby});
    }
  }

  Future<void> _toggleHttpShare(bool enable) async {
    if (!enable) {
      await _httpShareServer?.close(force: true);
      _httpShareServer = null;
      if (mounted) setState(() => _httpShareRunning = false);
      return;
    }
    try {
      await _detectLocalIp();
      _httpShareServer = await HttpServer.bind(InternetAddress.anyIPv4, _httpPort, shared: true);
      _httpShareServer!.listen((req) async {
        if (req.method == 'GET' && req.uri.path == '/download') {
          final f = File(req.uri.queryParameters['path'] ?? '');
          if (f.existsSync()) {
            req.response.headers.set('Content-Disposition', 'attachment; filename="${Uri.encodeComponent(p.basename(f.path))}"');
            await req.response.addStream(f.openRead());
            await req.response.close();
            return;
          }
        }
        if (req.method == 'POST' && req.uri.path == '/upload') {
          final safe = p.basename(req.uri.queryParameters['name'] ?? 'upload.bin');
          final dl = Directory(p.join(_volumes.first.path, 'Download'))..createSync(recursive: true);
          final sink = File(p.join(dl.path, safe)).openWrite();
          await req.forEach(sink.add);
          await sink.close();
          unawaited(_loadEntries());
          req.response..statusCode = 200..write('OK')..close();
          return;
        }
        final items = Directory(_currentPath).existsSync() ? Directory(_currentPath).listSync(followLinks: false) : <FileSystemEntity>[];
        final rows = items.whereType<File>().map((f) => '<div style="padding:8px;border-bottom:1px solid #1E293B">📄 ${p.basename(f.path)} <a style="color:#26E7FF;float:right" href="/download?path=${Uri.encodeComponent(f.path)}">Download</a></div>').join();
        req.response.headers.contentType = ContentType.html;
        req.response.write('<html><body style="background:#050B14;color:#fff;font-family:sans-serif;padding:24px"><h2>⚡ ORIXON Wi-Fi File Hub</h2><input type="file" id="f"><button onclick="fetch(\'/upload?name=\'+encodeURIComponent(f.files[0].name),{method:\'POST\',body:f.files[0]}).then(()=>location.reload())">Upload to ORIXON</button><hr>$rows</body></html>');
        await req.response.close();
      });
      if (mounted) setState(() => _httpShareRunning = true);
    } catch (e) { _showSnack('Wi-Fi Share error: $e'); }
  }

  Future<void> _toggleFtpServer(bool enable) async {
    if (!enable) {
      await _ftpServer?.close();
      _ftpServer = null;
      if (mounted) setState(() => _ftpRunning = false);
      return;
    }
    try {
      await _detectLocalIp();
      _ftpServer = await ServerSocket.bind(InternetAddress.anyIPv4, _ftpPort, shared: true);
      _ftpServer!.listen((client) => FtpClientSession(socket: client, localIp: _localIp, rootPath: _volumes.first.path).start());
      if (mounted) setState(() => _ftpRunning = true);
    } catch (e) { _showSnack('FTP error: $e'); }
  }

  Future<void> _toggleLanRadar(bool enable) async {
    if (!enable) {
      _lanBroadcastTimer?.cancel();
      _lanRadarSocket?.close();
      _lanRadarSocket = null;
      if (mounted) setState(() => _lanRadarRunning = false);
      return;
    }
    try {
      await _detectLocalIp();
      if (!_httpShareRunning) await _toggleHttpShare(true);
      _lanRadarSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 48888, reuseAddress: true)..broadcastEnabled = true;
      _lanRadarSocket!.listen((ev) {
        if (ev == RawSocketEvent.read) {
          final dg = _lanRadarSocket?.receive();
          if (dg == null || dg.address.address == _localIp) return;
          final msg = utf8.decode(dg.data, allowMalformed: true);
          if (msg.startsWith('ORIXON_PEER|')) {
            final parts = msg.split('|');
            if (mounted) setState(() => _lanPeers[dg.address.address] = _LanPeer(name: parts.length > 1 ? parts[1] : 'ORIXON', ip: dg.address.address, httpPort: _httpPort));
          }
        }
      });
      _lanBroadcastTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        try { _lanRadarSocket?.send(utf8.encode('ORIXON_PEER|ORIXON|$_httpPort'), InternetAddress('255.255.255.255'), 48888); } catch (_) {}
      });
      if (mounted) setState(() => _lanRadarRunning = true);
    } catch (_) {}
  }

  Widget _buildLeftSliderRail(_StorageVolumeInfo vol) {
    return Container(
      color: const Color(0xFF070D19),
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: CustomPaint(painter: _OrixonBrandLogoPainter()),
              ),
              const SizedBox(width: 10),
              const Text(
                'FILE HUB',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(vol.name, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800)),
                    Text('${_formatBytes(vol.freeBytes)} Free', style: const TextStyle(fontSize: 10.5, color: _cyan, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: vol.ratio,
                    minHeight: 5,
                    backgroundColor: Colors.white12,
                    color: _cyan,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: _FileSection.values.length,
              separatorBuilder: (_, _) => const SizedBox(height: 6),
              itemBuilder: (context, idx) {
                final sec = _FileSection.values[idx];
                final selected = _activeSection == sec;
                return FocusableActionDetector(
                  onShowFocusHighlight: (_) {},
                  child: InkWell(
                    borderRadius: BorderRadius.circular(13),
                    onTap: () {
                      setState(() => _activeSection = sec);
                      _loadEntries();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: selected
                            ? LinearGradient(colors: [sec.color.withValues(alpha: 0.28), Colors.transparent])
                            : null,
                        color: selected ? null : Colors.white.withValues(alpha: 0.02),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: selected ? sec.color : Colors.transparent,
                          width: 1.4,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(sec.icon, color: selected ? sec.color : Colors.white70, size: 20),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sec.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  sec.subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 9.5, color: Colors.white54),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  

  

  Widget _buildShareHubPane() {
    final files = _selectedPaths.where((p0) => FileSystemEntity.isFileSync(p0)).toList();
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            _shareCard(
              icon: Icons.public_rounded,
              title: 'Global Cloud Share (Send & Receive)',
              subtitle: 'Pick or use selected file to create a direct browser download link across any network',
              badge: files.isEmpty ? 'TAP TO PICK FILE' : 'READY (${files.length})',
              color: const Color(0xFF38BDF8),
              active: true,
              onTap: () => _shareViaGlobalCloudLink(files),
            ),
            _shareCard(
              icon: Icons.cloud_download_rounded,
              title: 'Receive File by Link',
              subtitle: 'Paste any shared cloud link or direct URL to download directly into storage',
              badge: 'RECEIVE ANYWHERE',
              color: const Color(0xFFA855F7),
              active: true,
              onTap: _receiveFileFromLinkDialog,
            ),
            _shareCard(
              icon: Icons.wifi_tethering_rounded,
              title: 'Orixon Direct Beam (Send & Receive)',
              subtitle: 'Instant wireless file transfer to phones, tablets or TVs',
              badge: files.isEmpty ? 'TAP TO PICK FILE' : 'READY (${files.length})',
              color: _cyan,
              active: true,
              onTap: () async {
                if (files.isEmpty) {
                  try {
                    final picked = await FilePicker.pickFiles();
                    if (picked != null && picked.isNotEmpty) {
                      final paths = picked.map((e) => e.path).whereType<String>().toList();
                      if (paths.isNotEmpty) {
                        await _shareNative(paths);
                      }
                    }
                  } catch (_) {}
                } else {
                  await _shareNative(files);
                }
              },
            ),
            _shareCard(
              icon: Icons.language_rounded,
              title: 'Wi-Fi Web Portal (Send & Receive)',
              subtitle: _httpShareRunning
                  ? 'Open http://$_localIp:$_httpPort on any browser to send or receive files'
                  : 'Start instant local web server for browser upload & download',
              badge: _httpShareRunning ? 'ACTIVE • :$_httpPort' : 'TAP TO START',
              color: const Color(0xFF34D399),
              active: _httpShareRunning,
              onTap: () => _toggleHttpShare(!_httpShareRunning),
            ),
            _shareCard(
              icon: Icons.dns_rounded,
              title: 'Wireless FTP (Send & Receive)',
              subtitle: _ftpRunning
                  ? 'Connect to ftp://$_localIp:$_ftpPort from PC, Mac or File Manager'
                  : 'Start FTP server for full wireless storage management',
              badge: _ftpRunning ? 'ONLINE • :$_ftpPort' : 'TAP TO START',
              color: _gold,
              active: _ftpRunning,
              onTap: () => _toggleFtpServer(!_ftpRunning),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _lanRadarRunning ? _cyan : Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.radar_rounded, color: _cyan),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Same-Network ORIXON Radar (Auto-Discover Devices on Wi-Fi)',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                    ),
                  ),
                  Switch(value: _lanRadarRunning, onChanged: _toggleLanRadar),
                ],
              ),
              Text(
                _lanPeers.isEmpty
                    ? (_lanRadarRunning
                          ? 'Scanning Wi-Fi ($_localIp)... Turn ON Radar on your other ORIXON device.'
                          : 'Enable Radar to automatically connect two ORIXON devices on the same Wi-Fi.')
                    : 'Found ${_lanPeers.length} ORIXON device(s) on your network:',
                style: const TextStyle(fontSize: 11.5, color: Colors.white60),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _shareCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String badge,
    required Color color,
    required bool active,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 280,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: active ? color.withValues(alpha: 0.16) : _surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: active ? color : Colors.white12, width: active ? 1.6 : 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 28),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(badge, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: color)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(fontSize: 11.5, color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRightFilePane() {
    if (_activeSection == _FileSection.shareHub) {
      return _buildShareHubPane();
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          decoration: const BoxDecoration(
            color: Color(0xFF08101E),
            border: Border(bottom: BorderSide(color: Colors.white10)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  if (_activeSection == _FileSection.explorer)
                    IconButton(
                      tooltip: 'Up One Folder',
                      onPressed: () {
                        final parent = p.dirname(_currentPath);
                        if (parent != _currentPath && Directory(parent).existsSync()) {
                          setState(() => _currentPath = parent);
                          _loadEntries();
                        }
                      },
                      icon: const Icon(Icons.arrow_upward_rounded, size: 18, color: _cyan),
                    ),
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) { _searchQuery = v; _loadEntries(); },
                        style: const TextStyle(fontSize: 12.5),
                        decoration: InputDecoration(
                          hintText: 'Search in ${_activeSection == _FileSection.explorer ? p.basename(_currentPath) : _activeSection.title}...',
                          prefixIcon: const Icon(Icons.search, size: 17, color: _cyan),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          filled: true,
                          fillColor: _surface,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: _showHidden ? 'Hide Hidden Files' : 'Show Hidden Files',
                    onPressed: () async {
                      setState(() => _showHidden = !_showHidden);
                      final db = widget.database;
                      if (db != null) {
                        try {
                          await db.into(db.appSettings).insertOnConflictUpdate(
                            AppSettingsCompanion.insert(
                              key: 'Media Hub & Storage::Show hidden files',
                              value: _showHidden ? 'true' : 'false',
                              category: 'Media Hub & Storage',
                            ),
                          );
                        } catch (_) {}
                      }
                      await _loadEntries();
                    },
                    icon: Icon(
                      _showHidden ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                      color: _showHidden ? _cyan : Colors.white54,
                    ),
                  ),
                  IconButton(
                    tooltip: _gridView ? 'List View' : 'Grid View',
                    onPressed: () => setState(() => _gridView = !_gridView),
                    icon: Icon(_gridView ? Icons.view_list_rounded : Icons.grid_view_rounded, color: _cyan),
                  ),
                  if (!_hasAllFilesAccess)
                    FilledButton.tonal(
                      onPressed: _requestFullStoragePermission,
                      child: const Text('Allow Storage'),
                    ),
                  const SizedBox(width: 6),
                  OutlinedButton.icon(
                    onPressed: _cleanJunkFiles,
                    icon: const Icon(Icons.cleaning_services_rounded, size: 15),
                    label: const Text('Clean Junk', style: TextStyle(fontSize: 11.5)),
                  ),
                ],
              ),
              if (_selectedPaths.isNotEmpty || _clipboardPaths.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (_selectedPaths.isNotEmpty) ...[
                      FilledButton.tonalIcon(
                        onPressed: _createZipFromSelected,
                        icon: const Icon(Icons.folder_zip_rounded, size: 15),
                        label: Text('ZIP (${_selectedPaths.length})'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () => _shareNative(_selectedPaths.toList()),
                        icon: const Icon(Icons.share_rounded, size: 15),
                        label: const Text('Orixon Beam'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => setState(() {
                          _clipboardPaths..clear()..addAll(_selectedPaths);
                          _clipboardIsCut = false;
                          _selectedPaths.clear();
                        }),
                        icon: const Icon(Icons.copy_rounded, size: 15),
                        label: const Text('Copy'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => setState(() {
                          _clipboardPaths..clear()..addAll(_selectedPaths);
                          _clipboardIsCut = true;
                          _selectedPaths.clear();
                        }),
                        icon: const Icon(Icons.content_cut_rounded, size: 15),
                        label: const Text('Move'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _deleteSelected,
                        icon: const Icon(Icons.delete_outline, size: 15, color: Colors.redAccent),
                        label: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                      ),
                    ],
                    if (_clipboardPaths.isNotEmpty)
                      FilledButton.icon(
                        onPressed: _pasteClipboardHere,
                        icon: const Icon(Icons.content_paste_rounded, size: 15),
                        label: Text('Paste (${_clipboardPaths.length}) Here'),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: _cyan))
              : _entries.isEmpty
                  ? const Center(child: Text('No files in this section', style: TextStyle(color: Colors.white54)))
                  : _gridView
                      ? GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 190,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.25,
                          ),
                          itemCount: _entries.length,
                          itemBuilder: (_, idx) => _buildFileTile(_entries[idx], isGrid: true),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(14),
                          itemCount: _entries.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 6),
                          itemBuilder: (_, idx) => _buildFileTile(_entries[idx], isGrid: false),
                        ),
        ),
      ],
    );
  }

  Widget _buildFileTile(FileSystemEntity ent, {required bool isGrid}) {
    final isDir = ent is Directory;
    final ext = p.extension(ent.path).toLowerCase();
    final sel = _selectedPaths.contains(ent.path);
    final icon = isDir
        ? Icons.folder_rounded
        : (ext == '.zip'
              ? Icons.folder_zip_rounded
              : (_matchesSection(ent.path, _FileSection.videos)
                    ? Icons.play_circle_fill_rounded
                    : Icons.insert_drive_file_rounded));
    final color = isDir ? _cyan : (ext == '.zip' ? const Color(0xFF60A5FA) : const Color(0xFFD552FF));

    if (isGrid) {
      return InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _onTapEntity(ent),
        onLongPress: () => setState(() => sel ? _selectedPaths.remove(ent.path) : _selectedPaths.add(ent.path)),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: sel ? const Color(0xFF17314F) : _surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: sel ? _cyan : Colors.white10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 34),
              const SizedBox(height: 8),
              Text(p.basename(ent.path), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
              Text(isDir ? 'Folder' : _formatBytes(_safeSize(ent as File)), style: const TextStyle(fontSize: 10, color: Colors.white54)),
            ],
          ),
        ),
      );
    }

    return ListTile(
      dense: true,
      tileColor: sel ? const Color(0xFF17314F) : _surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: sel ? _cyan : Colors.white10),
      ),
      onTap: () => _onTapEntity(ent),
      leading: Checkbox(
        value: sel,
        onChanged: (v) => setState(() => v == true ? _selectedPaths.add(ent.path) : _selectedPaths.remove(ent.path)),
      ),
      title: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(p.basename(ent.path), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      subtitle: Text(isDir ? 'Folder • ${ent.path}' : '${_formatBytes(_safeSize(ent as File))} • ${ext.isEmpty ? "FILE" : ext.substring(1).toUpperCase()}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isDir && ext == '.zip')
            TextButton(onPressed: () => _onTapEntity(ent), child: const Text('Extract')),
          if (!isDir && (ext == '.m3u' || ext == '.m3u8'))
            TextButton(onPressed: () => _importM3uToLiveTv(ent as File), child: const Text('Import TV')),
          if (!isDir)
            IconButton(onPressed: () => _shareNative([ent.path]), icon: const Icon(Icons.share_outlined, size: 18)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vol = _volumes.isNotEmpty
        ? _volumes.first
        : const _StorageVolumeInfo(name: 'Internal Storage', path: '/storage/emulated/0', totalBytes: 100, freeBytes: 50);

    return Scaffold(
      backgroundColor: _bg,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.6, -0.5),
            radius: 1.2,
            colors: [Color(0xFF0B203E), _bg],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 680;
              if (isCompact) {
                return Column(
                  children: [
                    SizedBox(
                      height: 48,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        itemCount: _FileSection.values.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (_, idx) {
                          final sec = _FileSection.values[idx];
                          return ChoiceChip(
                            selected: _activeSection == sec,
                            avatar: Icon(sec.icon, size: 15, color: sec.color),
                            label: Text(sec.title, style: const TextStyle(fontSize: 11.5)),
                            onSelected: (_) { setState(() => _activeSection = sec); _loadEntries(); },
                          );
                        },
                      ),
                    ),
                    const Divider(height: 1, color: Colors.white10),
                    Expanded(child: _buildRightFilePane()),
                  ],
                );
              }

              final railW = (constraints.maxWidth * 0.27).clamp(225.0, 290.0);
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(width: railW, child: _buildLeftSliderRail(vol)),
                  Container(width: 1, color: Colors.white10),
                  Expanded(child: _buildRightFilePane()),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _OrixonBrandLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.40;
    final stroke = size.width * 0.17;
    final rect = Rect.fromCircle(center: c, radius: r);
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..shader = const SweepGradient(
        colors: [
          Color(0xFF0284C7),
          Color(0xFF38BDF8),
          Color(0xFFF8FAFC),
          Color(0xFF0284C7),
          Color(0xFF38BDF8),
          Color(0xFF0284C7),
        ],
      ).createShader(rect);
    canvas.drawArc(rect, 0, 6.283185, false, ringPaint);
    final xr = r * 0.44;
    final xPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.88)
      ..strokeWidth = (size.width * 0.05).clamp(1.2, 2.5)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(c + Offset(-xr, -xr), c + Offset(xr, xr), xPaint);
    canvas.drawLine(c + Offset(xr, -xr), c + Offset(-xr, xr), xPaint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
