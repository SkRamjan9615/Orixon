import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show InsertMode;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import '../../../core/database/app_database.dart';
import '../../local_media/presentation/local_media_player_screen.dart';

class WebxBrowserScreen extends StatefulWidget {
  const WebxBrowserScreen({super.key, this.database, this.initialQuery});
  final AppDatabase? database;
  final String? initialQuery;

  @override
  State<WebxBrowserScreen> createState() => _WebxBrowserScreenState();
}

class _BrowserTab {
  _BrowserTab({required this.title, required this.url, this.showHome = true});
  String title;
  String url;
  bool showHome;
}

class _WebShortcut {
  const _WebShortcut({required this.title, required this.url});
  final String title;
  final String url;
  Map<String, String> toJson() => {'title': title, 'url': url};
  factory _WebShortcut.fromJson(Map<String, dynamic> m) => _WebShortcut(
    title: (m['title'] ?? 'Site').toString(),
    url: (m['url'] ?? 'https://duckduckgo.com').toString(),
  );
}

class _WebDownloadTask {
  _WebDownloadTask({required this.fileName, required this.url, required this.savePath});
  final String fileName;
  final String url;
  final String savePath;
  int downloadedBytes = 0;
  int totalBytes = 0;
  String status = 'Downloading...';
  bool canceled = false;
}

class _WebxBrowserScreenState extends State<WebxBrowserScreen> {
  static const MethodChannel _webxChannel = MethodChannel('com.example.orixon/webx');
  static const Color _ddgBg = Color(0xFF141414);
  static const Color _ddgBar = Color(0xFF1C1C1C);
  static const Color _ddgField = Color(0xFF282828);
  static const Color _ddgOrange = Color(0xFFDE5833);

  final TextEditingController _urlCtrl = TextEditingController();
  final TextEditingController _centerSearchCtrl = TextEditingController();
  final FocusNode _omnibarFocus = FocusNode();

  final List<_BrowserTab> _tabs = [
    _BrowserTab(title: 'DuckDuckGo', url: 'https://duckduckgo.com', showHome: true),
  ];
  int _activeTabIndex = 0;

  String _currentUrl = 'https://duckduckgo.com';
  int _progress = 0;
  final bool _adBlock = true;

  final List<_WebDownloadTask> _downloads = [];
  List<_WebShortcut> _shortcuts = [];

  _BrowserTab get _activeTab => _tabs[_activeTabIndex.clamp(0, _tabs.length - 1)];

  @override
  void initState() {
    super.initState();
    _webxChannel.setMethodCallHandler(_onNativeCall);
    _loadSavedShortcuts();
    if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateTo(widget.initialQuery!);
      });
    }
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _centerSearchCtrl.dispose();
    _omnibarFocus.dispose();
    super.dispose();
  }

  Future<void> _loadSavedShortcuts() async {
    final db = widget.database;
    if (db == null) return;
    try {
      final rows = await db.select(db.appSettings).get();
      for (final r in rows) {
        if (r.key == 'WEBX::shortcuts') {
          final list = (jsonDecode(r.value) as List)
              .map((e) => _WebShortcut.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
          if (mounted) {
            setState(() => _shortcuts = list);
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _saveShortcuts() async {
    final db = widget.database;
    if (db == null) return;
    try {
      await db.into(db.appSettings).insert(
        AppSettingsCompanion.insert(
          key: 'WEBX::shortcuts',
          value: jsonEncode(_shortcuts.map((e) => e.toJson()).toList()),
          category: 'WEBX',
        ),
        mode: InsertMode.insertOrReplace,
      );
    } catch (_) {}
  }

  Future<dynamic> _onNativeCall(MethodCall call) async {
    if (!mounted) return;
    if (call.method == 'onPageChanged') {
      final args = Map<String, dynamic>.from(call.arguments as Map);
      final url = (args['url'] ?? '').toString();
      final title = (args['title'] ?? '').toString();
      setState(() {
        if (url.isNotEmpty) {
          _currentUrl = url;
          _activeTab.url = url;
          if (!_activeTab.showHome && !_omnibarFocus.hasFocus) {
            _urlCtrl.text = url;
          }
        }
        if (title.isNotEmpty && !_activeTab.showHome) {
          _activeTab.title = title;
        }
      });
    } else if (call.method == 'onProgress') {
      setState(() => _progress = (call.arguments as int?) ?? 0);
    } else if (call.method == 'onDownloadStart') {
      final args = Map<String, dynamic>.from(call.arguments as Map);
      final url = (args['url'] ?? '').toString();
      final name = (args['fileName'] ?? 'download.bin').toString();
      if (url.isNotEmpty) {
        _startDownload(url, name);
      }
    }
  }

  void _navigateTo(String rawInput) {
    final input = rawInput.trim();
    if (input.isEmpty) return;

    String url;
    final looksLikeDomain = !input.contains(' ') &&
        (input.contains('.') || input.startsWith('http://') || input.startsWith('https://'));
    if (looksLikeDomain) {
      url = input.startsWith('http') ? input : 'https://$input';
    } else {
      final q = Uri.encodeQueryComponent(input);
      url = 'https://duckduckgo.com/?q=$q';
    }

    setState(() {
      _currentUrl = url;
      _activeTab.url = url;
      _activeTab.showHome = false;
      _activeTab.title = input;
      _urlCtrl.text = url;
      _centerSearchCtrl.clear();
    });
    if (Platform.isAndroid) {
      _webxChannel.invokeMethod('loadUrl', {'url': url});
    }
  }

  Future<void> _showAddShortcutDialog() async {
    final nameCtrl = TextEditingController();
    final urlCtrl = TextEditingController(text: 'https://');
    final added = await showDialog<_WebShortcut>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _ddgBar,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _ddgOrange.withValues(alpha: 0.5)),
        ),
        title: const Text('Add Shortcut', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(labelText: 'URL'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _ddgOrange, foregroundColor: Colors.white),
            onPressed: () {
              final t = nameCtrl.text.trim();
              var u = urlCtrl.text.trim();
              if (t.isEmpty || u.isEmpty) return;
              if (!u.startsWith('http')) u = 'https://$u';
              Navigator.pop(ctx, _WebShortcut(title: t, url: u));
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (added != null) {
      setState(() => _shortcuts.add(added));
      await _saveShortcuts();
    }
  }

  Future<void> _startDownload(String url, String name) async {
    final dir = Directory('/storage/emulated/0/Download');
    final folder = dir.existsSync() ? dir.path : Directory.current.path;
    final cleanName = name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final task = _WebDownloadTask(fileName: cleanName, url: url, savePath: p.join(folder, cleanName));
    setState(() => _downloads.insert(0, task));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Downloading $cleanName...')));
    final client = HttpClient()..badCertificateCallback = (_, _, _) => true;
    try {
      final req = await client.getUrl(Uri.parse(url));
      final resp = await req.close();
      task.totalBytes = resp.contentLength > 0 ? resp.contentLength : 0;
      final sink = File(task.savePath).openWrite();
      await for (final chunk in resp) {
        if (task.canceled) {
          await sink.close();
          return;
        }
        sink.add(chunk);
        task.downloadedBytes += chunk.length;
      }
      await sink.close();
      if (mounted) setState(() => task.status = 'Completed');
    } catch (_) {
      if (mounted) setState(() => task.status = 'Failed');
    } finally {
      client.close();
    }
  }

  void _openTabsSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _ddgBar,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.tab_rounded, color: _ddgOrange, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Tabs (${_tabs.length})',
                      style: const TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w800),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: () {
                        setState(() {
                          _tabs.add(_BrowserTab(title: 'DuckDuckGo', url: 'https://duckduckgo.com', showHome: true));
                          _activeTabIndex = _tabs.length - 1;
                          _urlCtrl.clear();
                        });
                        Navigator.pop(ctx);
                      },
                      style: FilledButton.styleFrom(backgroundColor: _ddgOrange, foregroundColor: Colors.white),
                      icon: const Icon(Icons.add_rounded, size: 17),
                      label: const Text('New Tab', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _tabs.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 6),
                    itemBuilder: (_, idx) {
                      final tab = _tabs[idx];
                      final active = idx == _activeTabIndex;
                      return ListTile(
                        dense: true,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: active ? _ddgOrange : Colors.white10),
                        ),
                        tileColor: active ? _ddgOrange.withValues(alpha: 0.14) : _ddgField,
                        leading: Icon(
                          tab.showHome ? Icons.shield_rounded : Icons.public_rounded,
                          color: active ? _ddgOrange : Colors.white54,
                          size: 19,
                        ),
                        title: Text(
                          tab.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.close_rounded, size: 17, color: Colors.white60),
                          onPressed: () {
                            if (_tabs.length <= 1) {
                              setState(() {
                                _tabs[0].showHome = true;
                                _tabs[0].title = 'DuckDuckGo';
                                _urlCtrl.clear();
                              });
                              Navigator.pop(ctx);
                              return;
                            }
                            setState(() {
                              _tabs.removeAt(idx);
                              _activeTabIndex = _activeTabIndex.clamp(0, _tabs.length - 1);
                            });
                            setModalState(() {});
                          },
                        ),
                        onTap: () {
                          setState(() {
                            _activeTabIndex = idx;
                            _currentUrl = tab.url;
                            _urlCtrl.text = tab.showHome ? '' : tab.url;
                          });
                          if (!tab.showHome && Platform.isAndroid) {
                            _webxChannel.invokeMethod('loadUrl', {'url': tab.url});
                          }
                          Navigator.pop(ctx);
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

  void _openDownloadsSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _ddgBar,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Downloads (${_downloads.length})', style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            if (_downloads.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('No downloads yet.', style: TextStyle(color: Colors.white54)),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _downloads.length,
                  itemBuilder: (_, i) {
                    final d = _downloads[i];
                    return ListTile(
                      title: Text(d.fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(d.status),
                      trailing: d.status == 'Completed'
                          ? FilledButton.tonal(
                              onPressed: () {
                                Navigator.pop(ctx);
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => LocalMediaPlayerScreen(
                                      video: MediaFile(
                                        id: 0,
                                        filePath: d.savePath,
                                        fileName: d.fileName,
                                        folderName: 'WEBX',
                                        sizeBytes: 0,
                                        durationMs: 0,
                                        lastPositionMs: 0,
                                        isFavorite: false,
                                        lastPlayedAt: null,
                                        dateAdded: DateTime.now(),
                                        preferredAudioTrack: null,
                                        preferredSubtitleTrack: null,
                                      ),
                                    ),
                                  ),
                                );
                              },
                              child: const Text('Play'),
                            )
                          : null,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Authentic DuckDuckGo Home Screen with the Search Bar right in the center below DuckDuckGo!
  Widget _buildDuckDuckGoHome() {
    return Container(
      color: _ddgBg,
      child: Stack(
        children: [
          // Top-right minimal Tabs & Downloads buttons on Home Page
          Positioned(
            top: 10,
            right: 12,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: _openTabsSheet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: _ddgField,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(
                      '${_tabs.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Downloads',
                  onPressed: _openDownloadsSheet,
                  icon: Badge(
                    isLabelVisible: _downloads.isNotEmpty,
                    label: Text('${_downloads.length}'),
                    child: const Icon(Icons.download_rounded, size: 19, color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),

          // Centered DuckDuckGo Logo + Name + Center Search Bar + User Shortcuts
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: _ddgOrange,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _ddgOrange.withValues(alpha: 0.35),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.shield_rounded, color: Colors.white, size: 36),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'DuckDuckGo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // CENTER SEARCH BAR DIRECTLY BELOW DUCKDUCKGO
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: _ddgField,
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                          color: _ddgOrange.withValues(alpha: 0.65),
                          width: 1.3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          const Icon(Icons.search_rounded, color: _ddgOrange, size: 21),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _centerSearchCtrl,
                              onSubmitted: _navigateTo,
                              style: const TextStyle(color: Colors.white, fontSize: 14.5),
                              decoration: const InputDecoration(
                                hintText: 'Search the web without being tracked...',
                                hintStyle: TextStyle(color: Colors.white38, fontSize: 13.5),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _navigateTo(_centerSearchCtrl.text),
                            icon: const Icon(Icons.arrow_forward_rounded, color: _ddgOrange, size: 20),
                          ),
                          const SizedBox(width: 4),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // User-Addable Shortcuts Grid (Empty by default until user adds)
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        ...List.generate(_shortcuts.length, (idx) {
                          final s = _shortcuts[idx];
                          return InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => _navigateTo(s.url),
                            onLongPress: () async {
                              setState(() => _shortcuts.removeAt(idx));
                              await _saveShortcuts();
                            },
                            child: Container(
                              width: 88,
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                              decoration: BoxDecoration(
                                color: _ddgBar,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _ddgOrange.withValues(alpha: 0.18),
                                    ),
                                    child: Text(
                                      s.title.isNotEmpty ? s.title[0].toUpperCase() : 'D',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                        color: _ddgOrange,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    s.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: _showAddShortcutDialog,
                          child: Container(
                            width: 88,
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                            decoration: BoxDecoration(
                              color: _ddgBar,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.06),
                                  ),
                                  child: const Icon(Icons.add_rounded, color: Colors.white70, size: 19),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Add Site',
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ddgBg,
      body: SafeArea(
        child: Column(
          children: [
            // Show Top Bar ONLY when browsing a webpage (!_activeTab.showHome)
            if (!_activeTab.showHome)
              Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: const BoxDecoration(
                  color: _ddgBar,
                  border: Border(bottom: BorderSide(color: Colors.white10)),
                ),
                child: Row(
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Back',
                      onPressed: () => _webxChannel.invokeMethod('goBack'),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: Colors.white70),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Forward',
                      onPressed: () => _webxChannel.invokeMethod('goForward'),
                      icon: const Icon(Icons.arrow_forward_ios_rounded, size: 15, color: Colors.white70),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'DuckDuckGo Home',
                      onPressed: () => setState(() {
                        _activeTab.showHome = true;
                        _urlCtrl.clear();
                      }),
                      icon: const Icon(Icons.home_rounded, size: 19, color: _ddgOrange),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Container(
                        height: 34,
                        decoration: BoxDecoration(
                          color: _ddgField,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: _ddgOrange.withValues(alpha: 0.45)),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 10),
                            const Icon(Icons.shield_rounded, size: 15, color: _ddgOrange),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _urlCtrl,
                                focusNode: _omnibarFocus,
                                onSubmitted: _navigateTo,
                                style: const TextStyle(color: Colors.white, fontSize: 12.5),
                                decoration: const InputDecoration(
                                  hintText: 'Search DuckDuckGo or type a URL...',
                                  hintStyle: TextStyle(color: Colors.white38, fontSize: 12),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                                ),
                              ),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              onPressed: () => _webxChannel.invokeMethod('reload'),
                              icon: const Icon(Icons.refresh_rounded, size: 16, color: _ddgOrange),
                            ),
                            const SizedBox(width: 4),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: _openTabsSheet,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _ddgField,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Text(
                          '${_tabs.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Downloads',
                      onPressed: _openDownloadsSheet,
                      icon: Badge(
                        isLabelVisible: _downloads.isNotEmpty,
                        label: Text('${_downloads.length}'),
                        child: const Icon(Icons.download_rounded, size: 18, color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),

            if (_progress > 0 && _progress < 100 && !_activeTab.showHome)
              LinearProgressIndicator(value: _progress / 100.0, minHeight: 2, color: _ddgOrange),

            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (Platform.isAndroid)
                    PlatformViewLink(
                      viewType: 'orixon/webx_webview',
                      surfaceFactory: (ctx, ctrl) => AndroidViewSurface(
                        controller: ctrl as AndroidViewController,
                        gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
                        hitTestBehavior: PlatformViewHitTestBehavior.opaque,
                      ),
                      onCreatePlatformView: (params) => PlatformViewsService.initSurfaceAndroidView(
                        id: params.id,
                        viewType: 'orixon/webx_webview',
                        layoutDirection: TextDirection.ltr,
                        creationParams: <String, dynamic>{
                          'initialUrl': _currentUrl,
                          'adBlock': _adBlock,
                        },
                        creationParamsCodec: const StandardMessageCodec(),
                        onFocus: () => params.onFocusChanged(true),
                      )..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)..create(),
                    )
                  else
                    Center(child: Text('DuckDuckGo URL: $_currentUrl')),

                  if (_activeTab.showHome) _buildDuckDuckGoHome(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
