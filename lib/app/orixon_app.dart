import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/app_database.dart';
import '../core/providers/app_providers.dart';
import '../core/theme/app_theme.dart';
import '../features/local_media/presentation/local_media_player_screen.dart';
import '../features/os_shell/presentation/orixon_os_launcher.dart';

class OrixonApp extends StatefulWidget {
  const OrixonApp({super.key, this.enablePlayback = true}) : database = null;

  const OrixonApp.withDatabase({
    super.key,
    required this.database,
    this.enablePlayback = true,
  });

  final AppDatabase? database;
  final bool enablePlayback;

  @override
  State<OrixonApp> createState() => _OrixonAppState();
}

class _OrixonAppState extends State<OrixonApp> {
  static const MethodChannel _intentChannel = MethodChannel('org.orixon.app/intents');
  final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();
  late final AppDatabase _database;
  late final bool _ownsDatabase;

  @override
  void initState() {
    super.initState();

    _ownsDatabase = widget.database == null;
    _database = widget.database ?? AppDatabase();

    _intentChannel.setMethodCallHandler((call) async {
      if (call.method == 'onExternalFile' && call.arguments is String) {
        _openIncomingFile(call.arguments as String);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final pending = await _intentChannel.invokeMethod<String>('getPendingExternalFile');
        if (pending != null && pending.isNotEmpty) {
          _openIncomingFile(pending);
        }
      } catch (_) {}
    });
  }

  void _openIncomingFile(String path) {
    if (path.isEmpty) return;
    final lower = path.toLowerCase();
    final isMedia = lower.startsWith('http://') ||
        lower.startsWith('https://') ||
        lower.endsWith('.mp4') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.m4v') ||
        lower.endsWith('.3gp') ||
        lower.endsWith('.ts') ||
        lower.endsWith('.m3u8') ||
        lower.endsWith('.mp3') ||
        lower.endsWith('.flac') ||
        lower.endsWith('.wav') ||
        lower.endsWith('.aac') ||
        lower.endsWith('.ogg') ||
        lower.endsWith('.m4a');

    final name = path.split('/').last.isNotEmpty ? path.split('/').last : 'External Media';
    int sizeBytes = 0;
    try {
      final f = File(path);
      if (f.existsSync()) sizeBytes = f.lengthSync();
    } catch (_) {}

    if (isMedia) {
      final item = MediaFile(
        id: -1,
        filePath: path,
        fileName: name,
        folderName: 'External',
        sizeBytes: sizeBytes,
        durationMs: 0,
        lastPositionMs: 0,
        isFavorite: false,
        dateAdded: DateTime.now(),
      );
      _navKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => LocalMediaPlayerScreen(video: item),
        ),
      );
    }
  }

  @override
  void dispose() {
    if (_ownsDatabase) {
      unawaited(_database.close());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(_database)],
      child: MaterialApp(
        navigatorKey: _navKey,
        title: 'ORIXON',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: OrixonOsLauncher(
          database: _database,
          enablePlayback: widget.enablePlayback,
        ),
      ),
    );
  }
}
