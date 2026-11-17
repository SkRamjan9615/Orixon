import '../../file_hub/presentation/file_hub_screen.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart' show Value;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import 'local_media_player_screen.dart';

class LocalMediaScreen extends ConsumerStatefulWidget {
  const LocalMediaScreen({super.key});

  @override
  ConsumerState<LocalMediaScreen> createState() => _LocalMediaScreenState();
}

class _LocalMediaScreenState extends ConsumerState<LocalMediaScreen> {
  bool _isScanning = false;
  bool _isListView = false;
  int _selectedFilterIndex = 0; // 0 = All Videos, 1 = Continue Watching
  String _searchQuery = '';
  final Map<String, Future<Uint8List?>> _thumbnailCache = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scanVideos();
    });
  }

  void _showScanMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message, maxLines: 2, overflow: TextOverflow.ellipsis),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isError
              ? Colors.red.shade800
              : AppTheme.surfaceLight,
          margin: const EdgeInsets.all(12),
        ),
      );
  }

  Future<void> _scanVideos() async {
    if (_isScanning) return;

    setState(() => _isScanning = true);

    try {
      final scanner = ref.read(androidMediaStoreScannerProvider);
      var hasPermission = await scanner.hasVideoPermission();

      if (!hasPermission) {
        hasPermission = await scanner.requestVideoPermission();
      }

      if (!hasPermission) {
        _showScanMessage(
          'Video access permission was not granted.',
          isError: true,
        );
        return;
      }

      final result = await ref.read(localMediaScanServiceProvider).scan();

      if (!mounted) return;

      if (result.permissionRequired) {
        _showScanMessage('Video access permission is required.', isError: true);
      } else {
        _showScanMessage(
          'Found ${result.discoveredCount} items • Imported ${result.importedCount} playable videos.',
        );
      }

      _thumbnailCache.clear();
      ref.invalidate(localMediaFilesProvider);
    } catch (error) {
      _showScanMessage('Scan failed: $error', isError: true);
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Future<Uint8List?> _getCachedThumbnail(String filePath) {
    return _thumbnailCache.putIfAbsent(
      filePath,
      () => ref
          .read(androidMediaStoreScannerProvider)
          .getVideoThumbnail(filePath, maxWidth: 320, maxHeight: 180),
    );
  }

  String _formatPosition(int ms) {
    final d = Duration(milliseconds: ms);
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return 'Unknown size';
    final mb = bytes / (1024 * 1024);
    if (mb >= 1024) return '${(mb / 1024).toStringAsFixed(2)} GB';
    return '${mb.toStringAsFixed(1)} MB';
  }

  Future<void> _showVideoOptionsSheet(List<MediaFile> playlist, int index) async {
    final video = playlist[index];
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0A1324),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CustomPaint(painter: _OrixonBrandLogoPainter()),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      video.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(height: 1, color: Colors.white12),
              ListTile(
                dense: true,
                leading: const Icon(Icons.play_circle_fill_rounded, color: Color(0xFF38BDF8)),
                title: const Text('Play Video', style: TextStyle(fontWeight: FontWeight.w700)),
                onTap: () {
                  Navigator.pop(ctx);
                  _openPlayer(playlist, index);
                },
              ),
              ListTile(
                dense: true,
                leading: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                title: const Text(
                  'Delete Video',
                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeleteVideo(video);
                },
              ),
              ListTile(
                dense: true,
                leading: const Icon(Icons.drive_file_rename_outline_rounded, color: Colors.white70),
                title: const Text('Rename Video', style: TextStyle(fontWeight: FontWeight.w700)),
                onTap: () {
                  Navigator.pop(ctx);
                  _promptRenameVideo(video);
                },
              ),
              ListTile(
                leading: const Icon(Icons.hub_rounded, color: Color(0xFF38BDF8)),
                title: const Text(
                  'Share via Orixon Share Hub',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                ),
                subtitle: const Text(
                  'Global Cloud Link, Direct Beam, Wi-Fi Portal & FTP',
                  style: TextStyle(color: Colors.white54, fontSize: 11.5),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => FileHubScreen(
                        database: ref.read(appDatabaseProvider),
                        initialShareFilePath: video.filePath,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                dense: true,
                leading: const Icon(Icons.share_rounded, color: Colors.white70),
                title: const Text('Share Video', style: TextStyle(fontWeight: FontWeight.w700)),
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    const ch = MethodChannel('com.example.orixon/system_tools');
                    await ch.invokeMethod('shareFiles', {
                      'paths': [video.filePath],
                      'preferNearby': false,
                    });
                  } catch (e) {
                    _showScanMessage('Share not available: $e', isError: true);
                  }
                },
              ),
              ListTile(
                dense: true,
                leading: const Icon(Icons.info_outline_rounded, color: Colors.white70),
                title: const Text('File Details', style: TextStyle(fontWeight: FontWeight.w700)),
                onTap: () {
                  Navigator.pop(ctx);
                  showDialog<void>(
                    context: context,
                    builder: (dCtx) => AlertDialog(
                      backgroundColor: const Color(0xFF0D172A),
                      title: const Text('Video Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Name: ${video.fileName}', style: const TextStyle(fontSize: 13)),
                          const SizedBox(height: 6),
                          Text('Folder: ${video.folderName}', style: const TextStyle(fontSize: 13, color: Colors.white70)),
                          const SizedBox(height: 6),
                          Text('Size: ${_formatFileSize(video.sizeBytes)}', style: const TextStyle(fontSize: 13, color: Colors.white70)),
                          const SizedBox(height: 6),
                          Text('Duration: ${_formatPosition(video.durationMs)}', style: const TextStyle(fontSize: 13, color: Colors.white70)),
                          const SizedBox(height: 6),
                          Text('Path: ${video.filePath}', style: const TextStyle(fontSize: 11.5, color: Colors.white54)),
                        ],
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('CLOSE')),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _promptRenameVideo(MediaFile video) async {
    final ctrl = TextEditingController(text: video.fileName);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D172A),
        title: const Text('Rename Video', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'New file name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('RENAME'),
          ),
        ],
      ),
    );
    if (newName == null || newName.isEmpty || newName == video.fileName) return;
    try {
      final db = ref.read(appDatabaseProvider);
      var newPath = video.filePath;
      if (!video.filePath.startsWith('content://')) {
        final f = File(video.filePath);
        if (f.existsSync()) {
          final renamed = await f.rename('${f.parent.path}/$newName');
          newPath = renamed.path;
        }
      }
      await (db.update(db.mediaFiles)..where((t) => t.id.equals(video.id))).write(
        MediaFilesCompanion(
          fileName: Value(newName),
          filePath: Value(newPath),
        ),
      );
      ref.invalidate(localMediaFilesProvider);
      _showScanMessage('Renamed to $newName');
    } catch (e) {
      _showScanMessage('Could not rename: $e', isError: true);
    }
  }

  Future<void> _confirmDeleteVideo(MediaFile video) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0D172A),
        title: const Text('Delete Video?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: Text('Delete "${video.fileName}" permanently?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      const sysCh = MethodChannel('com.example.orixon/system_tools');
      await sysCh.invokeMethod('deleteMediaUri', {'uri': video.filePath});
    } catch (_) {}
    try {
      final db = ref.read(appDatabaseProvider);
      await (db.delete(db.mediaFiles)..where((t) => t.id.equals(video.id))).go();
      _thumbnailCache.remove(video.filePath);
      ref.invalidate(localMediaFilesProvider);
      _showScanMessage('Deleted ${video.fileName}');
    } catch (e) {
      _showScanMessage('Delete failed: $e', isError: true);
    }
  }

  void _openPlayer(List<MediaFile> playlist, int index) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LocalMediaPlayerScreen(
          video: playlist[index],
          playlist: playlist,
          initialIndex: index,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaAsync = ref.watch(localMediaFilesProvider);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppTheme.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.55, -0.65),
            radius: 1.25,
            colors: [Color(0x331A1238), Colors.transparent],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Android TV OS Media Hub Header Bar
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 36,
                          height: 36,
                          child: CustomPaint(painter: _OrixonBrandLogoPainter()),
                        ),
                        const SizedBox(width: 14),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MEDIA HUB',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 23,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.1,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Your videos, all in one place',
                              style: TextStyle(
                                color: AppTheme.muted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: _isListView ? 'Grid view' : 'List view',
                          onPressed: () =>
                              setState(() => _isListView = !_isListView),
                          icon: Icon(
                            _isListView
                                ? Icons.grid_view_rounded
                                : Icons.view_list_rounded,
                            color: AppTheme.accent,
                          ),
                        ),
                        const SizedBox(width: 4),
                        OutlinedButton.icon(
                          onPressed: _isScanning ? null : _scanVideos,
                          icon: _isScanning
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.refresh_rounded, size: 17),
                          label: Text(
                            _isScanning ? 'SCANNING...' : 'RESCAN',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Filter Chips & Section Label Row
                Row(
                  children: [
                    const Text(
                      'VIDEO LIBRARY',
                      style: TextStyle(
                        color: AppTheme.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(width: 16),
                    _buildFilterChip('All Videos', 0),
                    const SizedBox(width: 8),
                    _buildFilterChip('Continue Watching', 1),
                  ],
                ),
                const SizedBox(height: 12),

                Expanded(
                  child: mediaAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stackTrace) => Center(
                      child: Text(
                        'Could not load video library.\n$error',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppTheme.muted),
                      ),
                    ),
                    data: (mediaFiles) {
                      if (mediaFiles.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.video_library_outlined,
                                size: 58,
                                color: AppTheme.muted.withValues(alpha: 0.65),
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'No videos found',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 7),
                              const Text(
                                'Videos on this device will appear here after scanning.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppTheme.muted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final filtered = mediaFiles.where((v) {
                        if (_selectedFilterIndex == 1 &&
                            v.lastPositionMs <= 10000) {
                          return false;
                        }
                        if (_searchQuery.trim().isNotEmpty &&
                            !v.fileName.toLowerCase().contains(
                              _searchQuery.trim().toLowerCase(),
                            )) {
                          return false;
                        }
                        return true;
                      }).toList();

                      if (filtered.isEmpty) {
                        return const Center(
                          child: Text(
                            'No matching videos in this filter.',
                            style: TextStyle(color: AppTheme.muted),
                          ),
                        );
                      }

                      if (_isListView) {
                        return ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final video = filtered[index];
                            return _MediaHubCard(
                              video: video,
                              isList: true,
                              thumbnailFuture: _getCachedThumbnail(
                                video.filePath,
                              ),
                              resumeLabel: video.lastPositionMs > 10000
                                  ? _formatPosition(video.lastPositionMs)
                                  : null,
                              onTap: () => _openPlayer(filtered, index),
                              onLongPress: () => _showVideoOptionsSheet(filtered, index),
                            );
                          },
                        );
                      }

                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          final cols = width >= 1100
                              ? 5
                              : width >= 800
                              ? 4
                              : width >= 520
                              ? 3
                              : 2;
                          final rowExtent = width >= 700
                              ? ((constraints.maxHeight - 20) / 2.6).clamp(
                                  135.0,
                                  210.0,
                                )
                              : 155.0;

                          return GridView.builder(
                            padding: const EdgeInsets.only(bottom: 8),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: cols,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  mainAxisExtent: rowExtent,
                                ),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final video = filtered[index];
                              return _MediaHubCard(
                                video: video,
                                isList: false,
                                thumbnailFuture: _getCachedThumbnail(
                                  video.filePath,
                                ),
                                resumeLabel: video.lastPositionMs > 10000
                                    ? _formatPosition(video.lastPositionMs)
                                    : null,
                                onTap: () => _openPlayer(filtered, index),
                              onLongPress: () => _showVideoOptionsSheet(filtered, index),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int index) {
    final selected = _selectedFilterIndex == index;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => setState(() => _selectedFilterIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.accent.withValues(alpha: 0.2)
              : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.accent : Colors.white12,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
            color: selected ? AppTheme.accent : Colors.white70,
          ),
        ),
      ),
    );
  }
}

class _MediaHubCard extends StatefulWidget {
  const _MediaHubCard({
    required this.video,
    required this.isList,
    required this.thumbnailFuture,
    required this.onTap,
    this.onLongPress,
    this.resumeLabel,
  });

  final MediaFile video;
  final bool isList;
  final Future<Uint8List?> thumbnailFuture;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final String? resumeLabel;

  @override
  State<_MediaHubCard> createState() => _MediaHubCardState();
}

class _MediaHubCardState extends State<_MediaHubCard> {
  bool _focused = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = _focused || _hovered;

    return FocusableActionDetector(
      onShowFocusHighlight: (v) => setState(() => _focused = v),
      onShowHoverHighlight: (v) => setState(() => _hovered = v),
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedScale(
          scale: active ? 1.03 : 1.0,
          duration: const Duration(milliseconds: 180),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: active
                    ? AppTheme.accent
                    : AppTheme.accent.withValues(alpha: 0.16),
                width: active ? 2.0 : 1.0,
              ),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: AppTheme.accent.withValues(alpha: 0.32),
                        blurRadius: 14,
                      ),
                    ]
                  : [],
            ),
            child: widget.isList
                ? _buildListRow(active)
                : _buildGridColumn(active),
          ),
        ),
      ),
    );
  }

  Widget _buildGridColumn(bool active) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: _buildThumbnailStack(active)),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 4, right: 2),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.video.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
              if (widget.onLongPress != null)
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: widget.onLongPress,
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(
                      Icons.more_vert_rounded,
                      size: 16,
                      color: Colors.white70,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListRow(bool active) {
    return SizedBox(
      height: 74,
      child: Row(
        children: [
          AspectRatio(aspectRatio: 16 / 9, child: _buildThumbnailStack(active)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.video.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.resumeLabel != null
                      ? 'Resume from ${widget.resumeLabel}'
                      : 'Ready to play • Local Storage',
                  style: const TextStyle(
                    color: AppTheme.accent,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.play_circle_fill_rounded,
            color: AppTheme.accent,
            size: 28,
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildThumbnailStack(bool active) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: AppTheme.surfaceLight,
            child: FutureBuilder<Uint8List?>(
              future: widget.thumbnailFuture,
              builder: (context, snapshot) {
                final bytes = snapshot.data;
                if (bytes == null || bytes.isEmpty) {
                  return const Center(
                    child: Icon(
                      Icons.movie_outlined,
                      color: AppTheme.accent,
                      size: 28,
                    ),
                  );
                }
                return Image.memory(
                  bytes,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                );
              },
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.65),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Center(
            child: CircleAvatar(
              radius: active ? 19 : 16,
              backgroundColor: active
                  ? AppTheme.accent
                  : Colors.black.withValues(alpha: 0.55),
              child: Icon(
                Icons.play_arrow_rounded,
                size: 22,
                color: active ? Colors.black : Colors.white,
              ),
            ),
          ),
          if (widget.resumeLabel != null)
            Positioned(
              right: 6,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: AppTheme.accent.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  'RESUME ${widget.resumeLabel}',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.accent,
                  ),
                ),
              ),
            ),
        ],
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
