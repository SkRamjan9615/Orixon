import '../../file_hub/presentation/file_hub_screen.dart';
import 'dart:io';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/database/app_database.dart';
import '../../os_shell/presentation/widgets/playlist_management_panel.dart';

class _Setting {
  const _Setting(
    this.title, {
    this.options,
    this.isAction = false,
    this.isDestructive = false,
    this.icon = Icons.tune_rounded,
  });

  final String title;
  final List<String>? options;
  final bool isAction;
  final bool isDestructive;
  final IconData icon;

  bool get isChoice => options != null;
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.database, this.initialCategory});
  final AppDatabase database;
  final String? initialCategory;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const MethodChannel _sysChannel =
      MethodChannel('com.example.orixon/system_tools');
  static const _accent = Color(0xFF38BDF8);
  static const _surface = Color(0xFF0C1526);

  final List<(String, IconData)> _categories = const [
    ('Playlist Management', Icons.playlist_play_rounded),
    ('Display & Interface', Icons.tv_rounded),
    ('Video & Playback', Icons.hd_rounded),
    ('Audio & Subtitles', Icons.surround_sound_rounded),
    ('Media Hub & Storage', Icons.folder_special_rounded),
    ('History & Privacy', Icons.shield_rounded),
    ('System & Advanced', Icons.memory_rounded),
    ('About', Icons.info_outline_rounded),
  ];

  final Map<String, List<_Setting>> _settings = const {
    'Display & Interface': [
      _Setting('Android TV interface', icon: Icons.tv_rounded),
      _Setting(
        'App Theme',
        options: [
          'Orixon Default',
          'Custom Photo (Choose from Gallery)',
          'Cosmic Nebula',
          'Cyberpunk Grid',
          'Aurora Borealis',
          'Deep Ocean',
          'Minimal OLED Pitch',
        ],
        icon: Icons.palette_rounded,
      ),
      _Setting(
        'Ambient Wallpaper',
        options: [
          'Orixon Default',
          'Custom Photo (Choose from Gallery)',
          'Cosmic Nebula',
          'Cyberpunk Grid',
          'Aurora Borealis',
          'Deep Ocean',
          'Minimal OLED Pitch',
        ],
        icon: Icons.auto_awesome_mosaic_rounded,
      ),
      _Setting(
        'Ambient Idle Timer',
        options: [
          '1 minute',
          '2 minutes',
          '5 minutes',
          '10 minutes',
          '15 minutes',
          '30 minutes',
          'Disabled',
        ],
        icon: Icons.timer_outlined,
      ),
      _Setting('Video thumbnails', icon: Icons.image_outlined),
      _Setting(
        'Sleep timer',
        options: [
          'Disabled',
          '15 minutes',
          '30 minutes',
          '45 minutes',
          '60 minutes',
          '90 minutes',
        ],
        icon: Icons.bedtime_rounded,
      ),
    ],
    'Video & Playback': [
      _Setting(
        'Hardware Acceleration',
        options: ['Auto', 'Full', 'Decoding', 'Disabled'],
        icon: Icons.speed_rounded,
      ),
      _Setting(
        'Default aspect ratio',
        options: ['Fit to Screen', 'Crop / Fill', '16:9 Widescreen', 'Stretch'],
        icon: Icons.aspect_ratio_rounded,
      ),
      _Setting('Low-data & fast stream lock', icon: Icons.bolt_rounded),
      _Setting(
        'Background/PiP mode',
        options: ['Picture-in-Picture', 'Background playback', 'Disabled'],
        icon: Icons.picture_in_picture_alt_rounded,
      ),
      _Setting('Show seen video marker', icon: Icons.check_circle_outline_rounded),
    ],
    'Audio & Subtitles': [
      _Setting(
        'Digital audio output (passthrough)',
        options: ['Auto (Dolby Atmos / HDMI eARC)', 'PCM Stereo', 'Disabled'],
        icon: Icons.speaker_group_rounded,
      ),
      _Setting(
        'Default audio boost',
        options: ['100% (Normal)', '125%', '150%', '175%', '200% (Max Boost)'],
        icon: Icons.volume_up_rounded,
      ),
      _Setting(
        'Preferred audio language',
        options: ['No language preference', 'English', 'বাংলা', 'हिन्दी'],
        icon: Icons.record_voice_over_rounded,
      ),
      _Setting('Auto load subtitles', icon: Icons.subtitles_rounded),
      _Setting(
        'Subtitles Size',
        options: ['Normal', 'Large', 'Very large', 'Small'],
        icon: Icons.format_size_rounded,
      ),
      _Setting(
        'Subtitles Color',
        options: ['White', 'Yellow', 'Cyan', 'Green'],
        icon: Icons.palette_outlined,
      ),
    ],
    'Media Hub & Storage': [
      _Setting('Auto rescan', icon: Icons.sync_rounded),
      _Setting('Show hidden files', icon: Icons.folder_off_outlined),
      _Setting(
        'Media library folders',
        isAction: true,
        icon: Icons.create_new_folder_rounded,
      ),
      _Setting(
        'Clear media database',
        isAction: true,
        isDestructive: true,
        icon: Icons.cleaning_services_rounded,
      ),
    ],
    'History & Privacy': [
      _Setting('Playback history', icon: Icons.history_rounded),
      _Setting('Incognito mode', icon: Icons.visibility_off_outlined),
      _Setting(
        'Clear playback history',
        isAction: true,
        isDestructive: true,
        icon: Icons.delete_sweep_rounded,
      ),
    ],
    'System & Advanced': [
      _Setting(
        'Network caching value',
        options: [
          '1500 ms (Recommended)',
          '500 ms (Low Latency)',
          '3000 ms (Stable)',
          '5000 ms (Slow Network)',
        ],
        icon: Icons.network_check_rounded,
      ),
      _Setting(
        'HTTP user agent',
        options: [
          'Auto',
          'Orixon',
          'LibVLC Media Player',
          'Android TV Native (ExoPlayer)',
          'Smart TV OTT Client',
          'Mozilla/5.0 Web Client',
          'FFmpeg Stream Engine (Lavf)',
        ],
        icon: Icons.dns_rounded,
      ),
      _Setting('Export settings', isAction: true, icon: Icons.upload_file_rounded),
      _Setting(
        'Restore settings',
        isAction: true,
        icon: Icons.settings_backup_restore_rounded,
      ),
      _Setting(
        'Clear app data',
        isAction: true,
        isDestructive: true,
        icon: Icons.restore_page_rounded,
      ),
    ],
  };

  int _selected = 0;
  bool _loading = true;
  bool _hasNewUpdate = false;
  String _remoteVersionTag = '';
  Map<String, String> _values = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      final idx = _categories.indexWhere((c) => c.$1 == widget.initialCategory);
      if (idx != -1) _selected = idx;
    }
    _loadSettings();
    _silentCheckUpdateStatus();
  }

  Future<void> _loadSettings() async {
    try {
      final rows = await widget.database
          .select(widget.database.appSettings)
          .get();
      if (!mounted) return;
      final map = {for (final row in rows) row.key: row.value};
      if (!map.containsKey('Display & Interface::App Theme') &&
          map.containsKey('Display & Interface::Home Screen Wallpaper')) {
        map['Display & Interface::App Theme'] =
            map['Display & Interface::Home Screen Wallpaper']!;
      }
      setState(() {
        _values = map;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _key(String section, String title) => '$section::$title';

  Future<void> _save(String section, _Setting setting, String value) async {
    final key = _key(section, setting.title);
    setState(() => _values[key] = value);
    try {
      await widget.database
          .into(widget.database.appSettings)
          .insertOnConflictUpdate(
            AppSettingsCompanion.insert(
              key: key,
              value: value,
              category: section,
            ),
          );
      if (setting.title == 'App Theme') {
        await widget.database
            .into(widget.database.appSettings)
            .insertOnConflictUpdate(
              AppSettingsCompanion.insert(
                key: 'Display & Interface::Home Screen Wallpaper',
                value: value,
                category: section,
              ),
            );
      }
    } catch (error) {
      _showToast('Could not save setting: $error', isError: true);
    }
  }

  bool _boolValue(String section, _Setting item) {
    final raw = _values[_key(section, item.title)];
    if (raw == null) {
      return item.title == 'Android TV interface' ||
          item.title == 'Video thumbnails' ||
          item.title == 'Show seen video marker' ||
          item.title == 'Auto load subtitles' ||
          item.title == 'Auto rescan' ||
          item.title == 'Playback history';
    }
    return raw == 'true';
  }

  void _showToast(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: isError
              ? Colors.red.shade900
              : const Color(0xFF0E223D),
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              Icon(
                isError
                    ? Icons.error_outline_rounded
                    : Icons.check_circle_rounded,
                color: isError ? Colors.white : _accent,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }


    Future<void> _silentCheckUpdateStatus() async {
    const currentVersion = '1.1.0';
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 10)
        ..badCertificateCallback = (_, _, _) => true;
      final req = await client.getUrl(
        Uri.parse('https://api.github.com/repos/SkRamjan9615/orixon/releases/latest'),
      );
      req.headers.set('User-Agent', 'ORIXON-InAppUpdater/1.0');
      req.headers.set('Accept', 'application/vnd.github+json');
      final resp = await req.close();
      if (resp.statusCode == 200) {
        final body = await utf8.decoder.bind(resp).join();
        final json = jsonDecode(body) as Map<String, dynamic>;
        final rawTag = (json['tag_name'] ?? '').toString().trim();
        final cleanLatest = rawTag.toLowerCase().replaceAll(RegExp(r'^v'), '').trim();
        if (cleanLatest.isNotEmpty && cleanLatest != currentVersion && mounted) {
          setState(() {
            _hasNewUpdate = true;
            _remoteVersionTag = rawTag;
          });
        }
      } else {
        await resp.drain<void>();
      }
      client.close();
    } catch (_) {}
  }

  Future<void> _checkAndInstallAppUpdate() async {
    const currentVersion = '1.1.0';
    _showToast('Checking for updates...');
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 12)
        ..badCertificateCallback = (_, _, _) => true;
      final req = await client.getUrl(
        Uri.parse('https://api.github.com/repos/SkRamjan9615/orixon/releases/latest'),
      );
      req.headers.set('User-Agent', 'ORIXON-InAppUpdater/1.0');
      req.headers.set('Accept', 'application/vnd.github+json');
      final resp = await req.close();

      if (resp.statusCode != 200) {
        await resp.drain<void>();
        client.close();
        _showToast('No update available');
        return;
      }

      final body = await utf8.decoder.bind(resp).join();
      final json = jsonDecode(body) as Map<String, dynamic>;
      final rawTag = (json['tag_name'] ?? '').toString().trim();
      final cleanLatest = rawTag.toLowerCase().replaceAll(RegExp(r'^v'), '').trim();

      String? apkDownloadUrl;
      final assets = (json['assets'] as List?) ?? const [];
      for (final a in assets) {
        final m = a as Map<String, dynamic>;
        final url = (m['browser_download_url'] ?? '').toString();
        if (url.toLowerCase().endsWith('.apk')) {
          apkDownloadUrl = url;
          break;
        }
      }

      if (cleanLatest.isEmpty ||
          cleanLatest == currentVersion ||
          apkDownloadUrl == null ||
          apkDownloadUrl.isEmpty) {
        client.close();
        if (mounted) {
          setState(() => _hasNewUpdate = false);
        }
        _showToast('No update available');
        return;
      }

      if (mounted) {
        setState(() {
          _hasNewUpdate = true;
          _remoteVersionTag = rawTag;
        });
      }

      int received = 0;
      int total = 1;
      void Function(void Function())? updateModal;

      if (mounted) {
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => StatefulBuilder(
            builder: (ctx, setModalState) {
              updateModal = setModalState;
              final pct = total > 0 ? ((received / total) * 100).clamp(0, 100).round() : 0;
              return AlertDialog(
                backgroundColor: const Color(0xFF081121),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: Color(0xFF38BDF8)),
                ),
                title: Text(
                  'Update Available ($rawTag) • Downloading',
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    LinearProgressIndicator(
                      value: total > 0 ? (received / total).clamp(0.0, 1.0) : null,
                      color: const Color(0xFF38BDF8),
                      backgroundColor: Colors.white12,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Downloading Orixon.apk... $pct%',
                      style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }

      final dlReq = await client.getUrl(Uri.parse(apkDownloadUrl));
      dlReq.headers.set('User-Agent', 'ORIXON-InAppUpdater/1.0');
      final dlResp = await dlReq.close();
      total = dlResp.contentLength > 0 ? dlResp.contentLength : 38000000;

      final outFile = File('/storage/emulated/0/Download/Orixon.apk');
      final sink = outFile.openWrite();
      await for (final chunk in dlResp) {
        sink.add(chunk);
        received += chunk.length;
        updateModal?.call(() {});
      }
      await sink.close();
      client.close();

      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      _showToast('Installing update $rawTag...');
      await _sysChannel.invokeMethod('openFileExternal', {'path': outFile.path});
    } catch (_) {
      _showToast('No update available');
    }
  }

  Future<void> _openExternalUrl(String url) async {
    try {
      await _sysChannel.invokeMethod('openUrlExternal', {'url': url});
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: url));
      _showToast('Link copied: $url');
    }
  }

  Future<void> _openChoicePicker(String section, _Setting item) async {
    final options = item.options!;
    final rawCurrent = _values[_key(section, item.title)] ?? options.first;
    final current = rawCurrent.startsWith('Custom Photo::')
        ? 'Custom Photo (Choose from Gallery)'
        : rawCurrent;

    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0B1528),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: _accent.withValues(alpha: 0.45)),
        ),
        title: Row(
          children: [
            Icon(item.icon, color: _accent, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.title,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 340,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: options.map((opt) {
                final selected = opt == current;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: ListTile(
                    dense: true,
                    autofocus: selected,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: selected ? _accent : Colors.white10,
                      ),
                    ),
                    tileColor: selected
                        ? _accent.withValues(alpha: 0.16)
                        : Colors.white.withValues(alpha: 0.03),
                    leading: Icon(
                      selected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      color: selected ? _accent : Colors.white54,
                      size: 19,
                    ),
                    title: Text(
                      opt,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                        fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                      ),
                    ),
                    onTap: () => Navigator.pop(ctx, opt),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );

    if (picked != null) {
      if (picked == 'Custom Photo (Choose from Gallery)') {
        try {
          final res = await FilePicker.pickFiles(type: FileType.image);
          final path = (res != null && res.isNotEmpty) ? res.first.path : null;
          if (path != null && path.isNotEmpty) {
            await _save(section, item, 'Custom Photo::$path');
            _showToast('${item.title} updated from Gallery');
          }
        } catch (e) {
          _showToast('Could not pick photo: $e', isError: true);
        }
        return;
      }
      await _save(section, item, picked);
    }
  }

  Future<void> _handleActionTap(String section, _Setting item) async {
    final title = item.title;

    if (title == 'Media library folders') {
      try {
        final selectedDir = await FilePicker.getDirectoryPath(
          dialogTitle: 'Select Media Library Folder',
        );
        if (selectedDir != null && selectedDir.isNotEmpty) {
          await _save(section, item, selectedDir);
          _showToast('Media folder saved: $selectedDir');
        }
      } catch (_) {
        _showToast('Folder picker is not available on this environment');
      }
      return;
    }

    if (title == 'Clear playback history') {
      await widget.database.delete(widget.database.playbackHistory).go();
      _showToast('Watch history cleared');
      return;
    }

    if (title == 'Clear media database') {
      await widget.database.delete(widget.database.mediaFiles).go();
      _showToast('Media Hub database cleared');
      return;
    }

    if (title == 'Clear app data') {
      await widget.database.delete(widget.database.appSettings).go();
      await widget.database.delete(widget.database.playbackHistory).go();
      if (mounted) setState(() => _values.clear());
      _showToast('All settings reset to factory defaults');
      return;
    }

    if (title == 'Export settings') {
      try {
        final backupDir = Directory(
          Platform.isAndroid
              ? '/storage/emulated/0/Download/Orixon_Backups'
              : '${Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? Directory.current.path}/Downloads/Orixon_Backups',
        );
        if (!backupDir.existsSync()) {
          backupDir.createSync(recursive: true);
        }

        final settingsRows =
            await widget.database.select(widget.database.appSettings).get();
        final playlistRows =
            await widget.database.select(widget.database.playlists).get();
        final channelRows =
            await widget.database.select(widget.database.channels).get();
        final mediaRows =
            await widget.database.select(widget.database.mediaFiles).get();

        final payload = <String, dynamic>{
          'orixonBackupFormat': 2,
          'exportedAt': DateTime.now().toIso8601String(),
          'appSettings': settingsRows.map((r) => r.toJson()).toList(),
          'playlists': playlistRows.map((r) => r.toJson()).toList(),
          'channels': channelRows.map((r) => r.toJson()).toList(),
          'mediaFiles': mediaRows.map((r) => r.toJson()).toList(),
        };

        final stamp = DateTime.now()
            .toIso8601String()
            .replaceAll(RegExp(r'[:.]'), '-')
            .substring(0, 19);
        final outFile = File('${backupDir.path}/ORIXON_Backup_$stamp.json');
        final jsonStr = const JsonEncoder.withIndent('  ').convert(payload);
        await outFile.writeAsString(jsonStr);

        _showToast(
          'Exported ${playlistRows.length} playlists, ${channelRows.length} channels & ${settingsRows.length} settings to Orixon_Backups!',
        );
      } catch (e) {
        _showToast('Export failed: $e', isError: true);
      }
      return;
    }

    if (title == 'Restore settings') {
      try {
        final backupDir = Directory(
          Platform.isAndroid
              ? '/storage/emulated/0/Download/Orixon_Backups'
              : '${Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? Directory.current.path}/Downloads/Orixon_Backups',
        );
        if (!backupDir.existsSync()) {
          backupDir.createSync(recursive: true);
        }

        if (!mounted) return;
        final pickedPath = await Navigator.of(context).push<String>(
          MaterialPageRoute<String>(
            builder: (_) => FileHubScreen(
              database: widget.database,
              initialDirectoryPath: backupDir.path,
              pickFileMode: true,
            ),
          ),
        );

        if (pickedPath == null || pickedPath.trim().isEmpty) return;
        final file = File(pickedPath.trim());
        if (!file.existsSync()) {
          _showToast('Selected backup file does not exist', isError: true);
          return;
        }

        final rawText = (await file.readAsString()).trim();
        final decoded = jsonDecode(rawText) as Map<String, dynamic>;

        int sCount = 0;
        int pCount = 0;
        int cCount = 0;

        if (decoded.containsKey('orixonBackupFormat')) {
          final sList = (decoded['appSettings'] as List?) ?? const [];
          for (final item in sList) {
            final m = Map<String, dynamic>.from(item as Map);
            await widget.database
                .into(widget.database.appSettings)
                .insertOnConflictUpdate(AppSetting.fromJson(m));
            sCount++;
          }

          final pList = (decoded['playlists'] as List?) ?? const [];
          for (final item in pList) {
            final m = Map<String, dynamic>.from(item as Map);
            await widget.database
                .into(widget.database.playlists)
                .insertOnConflictUpdate(Playlist.fromJson(m));
            pCount++;
          }

          final cList = (decoded['channels'] as List?) ?? const [];
          for (final item in cList) {
            final m = Map<String, dynamic>.from(item as Map);
            await widget.database
                .into(widget.database.channels)
                .insertOnConflictUpdate(Channel.fromJson(m));
            cCount++;
          }

          final mList = (decoded['mediaFiles'] as List?) ?? const [];
          for (final item in mList) {
            final m = Map<String, dynamic>.from(item as Map);
            await widget.database
                .into(widget.database.mediaFiles)
                .insertOnConflictUpdate(MediaFile.fromJson(m));
          }
        } else {
          // Legacy key-value settings backup support
          for (final entry in decoded.entries) {
            final parts = entry.key.split('::');
            final cat = parts.isNotEmpty ? parts.first : 'System & Advanced';
            await widget.database
                .into(widget.database.appSettings)
                .insertOnConflictUpdate(
                  AppSettingsCompanion.insert(
                    key: entry.key,
                    value: entry.value.toString(),
                    category: cat,
                  ),
                );
            sCount++;
          }
        }

        await _loadSettings();
        _showToast(
          'Restored $pCount playlists, $cCount channels & $sCount settings!',
        );
      } catch (e) {
        _showToast('Invalid backup file: $e', isError: true);
      }
    }
  }

  void _showCopyrightsAndDisclaimersDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF081121),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: _accent.withValues(alpha: 0.45)),
        ),
        title: const Row(
          children: [
            Icon(Icons.verified_user_rounded, color: _accent, size: 21),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Copyrights, License & Brand Policy',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 490,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Copyright Notice
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _accent.withValues(alpha: 0.3)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Copyright © 2026 ORIXON. All Rights Reserved.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Official Open-Source Cross-Platform Media Center & Smart TV OS.',
                        style: TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 2. Source Code License — Apache License 2.0
                const Text(
                  '1. Source Code License — Apache License 2.0',
                  style: TextStyle(color: _accent, fontSize: 12.5, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                const Text(
                  'The source code of ORIXON is licensed under the Apache License, Version 2.0. Anyone may use, modify, and distribute the source code free of charge in compliance with the Apache 2.0 license terms, provided that all original copyright notices and the NOTICE attribution crediting ORIXON are retained.',
                  style: TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.45),
                ),
                const SizedBox(height: 12),

                // 3. ORIXON Brand & Logo Protection
                const Text(
                  '2. ORIXON Brand & Logo Protection Policy',
                  style: TextStyle(color: _accent, fontSize: 12.5, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Per Section 6 of the Apache License 2.0, this license does NOT grant permission to use the "ORIXON" name, brand identity, or the copyrighted ORIXON 3D "O" Logo for derivative or modified distributions. No third-party or modified build may claim to be the "Official ORIXON" application.',
                  style: TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.45),
                ),
                const SizedBox(height: 12),

                // 4. DMCA & Stream Content Disclaimer
                const Text(
                  '3. DMCA & Stream Content Disclaimer',
                  style: TextStyle(color: _accent, fontSize: 12.5, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                const Text(
                  'ORIXON is strictly a general-purpose media player, playlist organizer, and OS launcher interface. ORIXON does NOT provide, host, bundle, or distribute any TV channels, M3U playlists, or copyrighted video content.',
                  style: TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.45),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              showLicensePage(
                context: context,
                applicationName: 'ORIXON',
                applicationVersion: 'v1.0.0',
                applicationLegalese: 'Copyright © 2026 ORIXON • Apache License 2.0',
              );
            },
            icon: const Icon(Icons.description_outlined, size: 15, color: _accent),
            label: const Text(
              'OPEN-SOURCE LICENSES',
              style: TextStyle(color: _accent, fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            style: FilledButton.styleFrom(backgroundColor: _accent, foregroundColor: Colors.black),
            child: const Text('CLOSE', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  void _showBugReportAndFeedbackDialog() {
    final titleCtrl = TextEditingController();
    final msgCtrl = TextEditingController();
    String feedbackType = 'Bug Report';

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF081121),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: _accent.withValues(alpha: 0.45)),
          ),
          title: const Row(
            children: [
              Icon(Icons.bug_report_rounded, color: _accent, size: 21),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Report a Bug / Feedback',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      for (final type in ['Bug Report', 'Feedback / Feature'])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            selected: feedbackType == type,
                            selectedColor: _accent.withValues(alpha: 0.24),
                            backgroundColor: const Color(0xFF0E1B31),
                            label: Text(
                              type,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: feedbackType == type ? _accent : Colors.white70,
                              ),
                            ),
                            onSelected: (_) => setModalState(() => feedbackType = type),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: titleCtrl,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Short Subject',
                      hintText: 'e.g. Playback / UI suggestion',
                      filled: true,
                      fillColor: const Color(0xFF0C172B),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: msgCtrl,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Describe the issue or feedback',
                      hintText: 'Write details here...',
                      filled: true,
                      fillColor: const Color(0xFF0C172B),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL', style: TextStyle(color: Colors.white60)),
            ),
            FilledButton.icon(
              onPressed: () {
                final title = Uri.encodeComponent('[$feedbackType] ${titleCtrl.text.trim()}');
                final body = Uri.encodeComponent(
                  '### $feedbackType\n**Platform:** ORIXON v1.0.0\n\n${msgCtrl.text.trim()}',
                );
                Navigator.pop(ctx);
                _openExternalUrl('https://github.com/Skramjan9615/orixon/issues/new?title=$title&body=$body');
              },
              style: FilledButton.styleFrom(backgroundColor: _accent, foregroundColor: Colors.black),
              icon: const Icon(Icons.send_rounded, size: 15),
              label: const Text(
                'SEND REPORT',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutPane() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. TOP: PURE 3D "O" LOGO (No extra outer circle!)
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: CustomPaint(
                      painter: _AboutOrixonLogoPainter(),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // 2. APP NAME
                  const Text(
                    'ORIXON',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4.5,
                      shadows: [
                        Shadow(color: Color(0x9938BDF8), blurRadius: 14),
                      ],
                    ),
                  ),
                  const SizedBox(height: 3),

                  // 3. SHORT PROFESSIONAL DESCRIPTION
                  const Text(
                    'ORIXON — One Platform. Endless Possibilities.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // 4. VERSION + SMALL IN-APP UPDATE BUTTON BESIDE IT
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                        decoration: BoxDecoration(
                          color: _accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _accent.withValues(alpha: 0.38)),
                        ),
                        child: const Text(
                          'Version 1.1.0',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: _checkAndInstallAppUpdate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFF10B981).withValues(alpha: 0.65),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.system_update_alt_rounded,
                                size: 12.5,
                                color: Color(0xFF10B981),
                              ),
                              SizedBox(width: 5),
                              Text(
                                'Update',
                                style: TextStyle(
                                  color: Color(0xFF10B981),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 5. LUXURY AUTHOR BADGE (ONLY place with Sk Ramjan Ali)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6.5),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0E2240), Color(0xFF091528), Color(0xFF1A1730)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.55),
                        width: 1.1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.14),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_rounded, color: Color(0xFFF59E0B), size: 15),
                        SizedBox(width: 8),
                        Text(
                          'AUTHOR',
                          style: TextStyle(
                            color: Color(0xFFF59E0B),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            '•',
                            style: TextStyle(color: Colors.white38, fontSize: 12),
                          ),
                        ),
                        Text(
                          'SK RAMJAN ALI',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 6. OFFICIAL WEBSITE
                  _buildCompactAboutCard(
                    icon: Icons.public_rounded,
                    accent: _accent,
                    title: 'Official Website',
                    onTap: () => _openExternalUrl('https://skramjan9615.github.io/orixon/'),
                  ),
                  const SizedBox(height: 7),

                  // 7. COPYRIGHTS & LEGAL DISCLAIMERS
                  _buildCompactAboutCard(
                    icon: Icons.copyright_rounded,
                    accent: _accent,
                    title: 'Copyrights & Legal Disclaimers',
                    onTap: _showCopyrightsAndDisclaimersDialog,
                  ),
                  const SizedBox(height: 7),

                  // 8. REPORT A BUG / FEEDBACK
                  _buildCompactAboutCard(
                    icon: Icons.bug_report_outlined,
                    accent: const Color(0xFF34D399),
                    title: 'Report a Bug / Feedback',
                    onTap: _showBugReportAndFeedbackDialog,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactAboutCard({
    required IconData icon,
    required Color accent,
    required String title,
    required VoidCallback onTap,
  }) {
    return _TvFocusableTile(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9.5),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: accent, size: 17),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: accent,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveThemeBackdrop() {
    final wp = _values['Display & Interface::App Theme'] ??
        _values['Display & Interface::Home Screen Wallpaper'] ??
        'Orixon Default';
    if (wp.startsWith('Custom Photo::')) {
      final path = wp.substring('Custom Photo::'.length).trim();
      final f = File(path);
      if (f.existsSync()) {
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.file(f, width: double.infinity, height: double.infinity, fit: BoxFit.fill, gaplessPlayback: true),
            Container(color: const Color(0xFF03060E).withValues(alpha: 0.55)),
          ],
        );
      }
    }
    if (wp == 'Minimal OLED Pitch') {
      return Container(color: Colors.black);
    }
    List<Color> cols = const [Color(0xFF0B203E), Color(0xFF03060E)];
    if (wp == 'Cosmic Nebula') {
      cols = const [Color(0xFF3B106C), Color(0xFF16072E), Color(0xFF040208)];
    } else if (wp == 'Cyberpunk Grid') {
      cols = const [Color(0xFF084C61), Color(0xFF320D47), Color(0xFF04060E)];
    } else if (wp == 'Aurora Borealis') {
      cols = const [Color(0xFF0A5C48), Color(0xFF082B3F), Color(0xFF02070D)];
    } else if (wp == 'Deep Ocean') {
      cols = const [Color(0xFF073B70), Color(0xFF041D3B), Color(0xFF020710)];
    }
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0.5, -0.4),
          radius: 1.3,
          colors: cols,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeCategory = _categories[_selected];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildActiveThemeBackdrop(),
          SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _accent))
            : LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 640;
                  if (isCompact) {
                    return Column(
                      children: [
                        SizedBox(
                          height: 48,
                          child: _buildMobileCategoryRow(),
                        ),
                        const Divider(height: 1, color: Colors.white12),
                        Expanded(child: _buildCategoryPane(activeCategory)),
                      ],
                    );
                  }

                  final railWidth =
                      (constraints.maxWidth * 0.27).clamp(220.0, 275.0);

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: railWidth,
                        child: _buildTvCategoryRail(),
                      ),
                      Container(width: 1, color: Colors.white10),
                      Expanded(
                        child: _buildCategoryPane(activeCategory),
                      ),
                    ],
                  );
                },
              ),
          ),
        ],
      ),
    );
  }

  Widget _buildTvCategoryRail() {
    return Container(
      color: const Color(0xFF050A14).withValues(alpha: 0.65),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: _accent.withValues(alpha: 0.45)),
                  ),
                  child: const Icon(
                    Icons.settings_rounded,
                    color: _accent,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'SETTINGS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.white10),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final selected = _selected == index;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: _TvFocusableTile(
                    autofocus: index == 0,
                    selected: selected,
                    onTap: () => setState(() => _selected = index),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 10.5,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            cat.$2,
                            size: 19,
                            color: selected ? _accent : Colors.white60,
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Text(
                              cat.$1,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.0,
                                fontWeight: selected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: selected ? Colors.white : Colors.white70,
                              ),
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

  Widget _buildMobileCategoryRow() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final cat = _categories[index];
        final selected = _selected == index;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            selected: selected,
            selectedColor: _accent.withValues(alpha: 0.25),
            backgroundColor: _surface,
            label: Text(
              cat.$1,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                color: selected ? _accent : Colors.white70,
              ),
            ),
            onSelected: (_) => setState(() => _selected = index),
          ),
        );
      },
    );
  }

  Widget _buildCategoryPane((String, IconData) category) {
    final section = category.$1;
    if (section == 'Playlist Management') {
      return const Padding(
        padding: EdgeInsets.all(14),
        child: PlaylistManagementPanel(),
      );
    }
    if (section == 'About') {
      return _buildAboutPane();
    }

    final items = _settings[section] ?? const <_Setting>[];

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      children: [
        for (final item in items) _buildSettingCard(section, item),
      ],
    );
  }

  Widget _buildSettingCard(String section, _Setting item) {
    final key = _key(section, item.title);
    final savedVal = _values[key];

    if (item.isAction) {
      final accentColor = item.isDestructive ? Colors.redAccent : _accent;

      return Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: _TvFocusableTile(
          onTap: () => _handleActionTap(section, item),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            child: Row(
              children: [
                Icon(item.icon, color: accentColor, size: 18),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 13.0,
                      fontWeight: FontWeight.w700,
                      color: item.isDestructive
                          ? Colors.redAccent
                          : Colors.white,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: accentColor,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (item.isChoice) {
      final String currentOption;
      if (savedVal != null && savedVal.startsWith('Custom Photo::')) {
        currentOption = 'Custom Photo';
      } else if (savedVal != null && item.options!.contains(savedVal)) {
        currentOption = savedVal;
      } else {
        currentOption = item.options!.first;
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: _TvFocusableTile(
          onTap: () => _openChoicePicker(section, item),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            child: Row(
              children: [
                Icon(item.icon, color: _accent, size: 18),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 13.0,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _accent.withValues(alpha: 0.42)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currentOption,
                        style: const TextStyle(
                          fontSize: 11.2,
                          fontWeight: FontWeight.w800,
                          color: _accent,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(
                        Icons.expand_more_rounded,
                        color: _accent,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final enabled = _boolValue(section, item);
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: _TvFocusableTile(
        onTap: () => _save(section, item, (!enabled).toString()),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7.5),
          child: Row(
            children: [
              Icon(
                item.icon,
                color: enabled ? _accent : Colors.white38,
                size: 18,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 13.0,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(
                height: 24,
                child: Transform.scale(
                  scale: 0.78,
                  child: Switch(
                    value: enabled,
                    activeThumbColor: _accent,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: (v) => _save(section, item, v.toString()),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AboutOrixonLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.39;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFF38BDF8).withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    final outerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.16
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        colors: [
          Color(0xFF0284C7),
          Color(0xFF38BDF8),
          Color(0xFFF8FAFC),
          Color(0xFF38BDF8),
          Color(0xFF0369A1),
          Color(0xFF0284C7),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, outerPaint);

    final starPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.048
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFE0F2FE);

    final d = radius * 0.48;
    canvas.drawLine(center + Offset(-d, -d), center + Offset(d, d), starPaint);
    canvas.drawLine(center + Offset(d, -d), center + Offset(-d, d), starPaint);
    canvas.drawCircle(
      center,
      size.width * 0.055,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TvFocusableTile extends StatefulWidget {
  const _TvFocusableTile({
    required this.child,
    required this.onTap,
    this.selected = false,
    this.autofocus = false,
  });

  final Widget child;
  final VoidCallback onTap;
  final bool selected;
  final bool autofocus;

  @override
  State<_TvFocusableTile> createState() => _TvFocusableTileState();
}

class _TvFocusableTileState extends State<_TvFocusableTile> {
  bool _focused = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = _focused || _hovered;
    const accent = Color(0xFF38BDF8);

    return FocusableActionDetector(
      autofocus: widget.autofocus,
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap();
            return null;
          },
        ),
        ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
          onInvoke: (_) {
            widget.onTap();
            return null;
          },
        ),
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: active ? 1.01 : 1.0,
            duration: const Duration(milliseconds: 140),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFF13233F)
                    : widget.selected
                        ? accent.withValues(alpha: 0.14)
                        : const Color(0xFF0C1526).withValues(alpha: 0.86),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: active
                      ? accent
                      : widget.selected
                          ? accent.withValues(alpha: 0.65)
                          : Colors.white.withValues(alpha: 0.08),
                  width: active ? 1.5 : 1.0,
                ),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.22),
                          blurRadius: 10,
                        ),
                      ]
                    : [],
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
