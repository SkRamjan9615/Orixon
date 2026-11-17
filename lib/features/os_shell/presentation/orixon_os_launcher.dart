import '../../live_tv/presentation/widgets/live_tv_player.dart';
import 'dart:typed_data';
import 'package:media_kit/media_kit.dart' as mk;
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/app_providers.dart';

import '../../live_tv/presentation/live_tv_screen.dart';
import '../../local_media/presentation/local_media_screen.dart';
import '../../local_media/presentation/local_media_player_screen.dart';
import '../../file_hub/presentation/file_hub_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../webx/presentation/webx_browser_screen.dart';

class OsTokens {
  static const Color bgBase = Colors.transparent;
  static const Color surface = Color(0xFF0C1526);
  static const Color cyan = Color(0xFF26E7FF);
  static const Color purple = Color(0xFFD552FF);
  static const Color gold = Color(0xFFF59E0B);
  static const Color liveGreen = Color(0xFF10B981);
  static const Color textSoft = Color(0xFFCBD5E1);
}

enum OsViewState { loaded, loading, empty, error }

class OrixonOsLauncher extends ConsumerStatefulWidget {
  const OrixonOsLauncher({
    super.key,
    required this.database,
    this.enablePlayback = true,
  });

  final AppDatabase database;
  final bool enablePlayback;

  @override
  ConsumerState<OrixonOsLauncher> createState() => _OrixonOsLauncherState();
}

class _OrixonOsLauncherState extends ConsumerState<OrixonOsLauncher>
    with SingleTickerProviderStateMixin {
  int _navIndex = 0;
  bool _showAllRecentChannels = false;
  String _networkType = 'offline';
  bool _screensaverActive = false;
  bool _showStartupIntro = true;
  double _introProgress = 0.0;
  Timer? _introTimer;
  mk.Player? _chimePlayer;

  void _startNetflixStyleIntro() {
    if (!widget.enablePlayback) {
      _showStartupIntro = false;
      return;
    }
    _playSoftStartupChime();
    const totalMs = 2200;
    const stepMs = 16;
    var elapsed = 0;
    _introTimer = Timer.periodic(const Duration(milliseconds: stepMs), (t) {
      elapsed += stepMs;
      if (!mounted) {
        t.cancel();
        return;
      }
      if (elapsed >= totalMs) {
        t.cancel();
        setState(() {
          _introProgress = 1.0;
          _showStartupIntro = false;
        });
      } else {
        setState(() => _introProgress = elapsed / totalMs);
      }
    });
  }

  Future<void> _playSoftStartupChime() async {
    try {
      if (Platform.isAndroid) {
        const sysCh = MethodChannel('com.example.orixon/system_tools');
        unawaited(sysCh.invokeMethod('setStartupVolume75'));
      }
      final tmpFile = File('${Directory.systemTemp.path}/orixon_startup_chime_75.wav');
      if (!tmpFile.existsSync()) {
        const sampleRate = 22050;
        const durationSec = 1.45;
        final numSamples = (sampleRate * durationSec).toInt();
        final pcm = ByteData(numSamples * 2);
        for (var i = 0; i < numSamples; i++) {
          final t = i / sampleRate;
          final attack = (t / 0.08).clamp(0.0, 1.0);
          final decay = math.exp(-t * 1.85);
          final env = attack * decay * 0.92; // Full rich 92% normalized wave
          // Rich Netflix/Cinema harmonic chord (A2, E3, A3, C#4, E4, A4)
          final wave = 0.28 * math.sin(2 * math.pi * 110.0 * t) +
              0.24 * math.sin(2 * math.pi * 220.0 * t) +
              0.20 * math.sin(2 * math.pi * 329.63 * t) +
              0.14 * math.sin(2 * math.pi * 440.0 * t) +
              0.09 * math.sin(2 * math.pi * 554.37 * t) +
              0.05 * math.sin(2 * math.pi * 659.25 * t);
          final sample = (wave * env * 32767).round().clamp(-32768, 32767);
          pcm.setInt16(i * 2, sample, Endian.little);
        }
        final wavHeader = ByteData(44);
        final dataSize = numSamples * 2;
        wavHeader.setUint32(0, 0x52494646, Endian.big);
        wavHeader.setUint32(4, 36 + dataSize, Endian.little);
        wavHeader.setUint32(8, 0x57415645, Endian.big);
        wavHeader.setUint32(12, 0x666d7420, Endian.big);
        wavHeader.setUint32(16, 16, Endian.little);
        wavHeader.setUint16(20, 1, Endian.little);
        wavHeader.setUint16(22, 1, Endian.little);
        wavHeader.setUint32(24, sampleRate, Endian.little);
        wavHeader.setUint32(28, sampleRate * 2, Endian.little);
        wavHeader.setUint16(32, 2, Endian.little);
        wavHeader.setUint16(34, 16, Endian.little);
        wavHeader.setUint32(36, 0x64617461, Endian.big);
        wavHeader.setUint32(40, dataSize, Endian.little);

        final wavBytes = Uint8List(44 + dataSize);
        wavBytes.setRange(0, 44, wavHeader.buffer.asUint8List());
        wavBytes.setRange(44, 44 + dataSize, pcm.buffer.asUint8List());
        await tmpFile.writeAsBytes(wavBytes, flush: true);
      }

      mk.MediaKit.ensureInitialized();
      _chimePlayer = mk.Player();
      await _chimePlayer!.setVolume(75.0);
      await _chimePlayer!.open(mk.Media(tmpFile.path), play: true);
      Future.delayed(const Duration(milliseconds: 1900), () {
        _chimePlayer?.dispose();
        _chimePlayer = null;
      });
    } catch (_) {}
  }

  Widget _buildNetflixStyleStartupOverlay() {
    // 0.0 -> 0.45: Ribbon 'O' spins & scales in from 0.4 to 1.0
    // 0.45 -> 0.75: 'ORIXON' wordmark glows & expands letter-spacing
    // 0.75 -> 1.0: Netflix-style zoom-through (scale 1.0 -> 9.0) & fade out!
    final p = _introProgress.clamp(0.0, 1.0);
    final isZoomPhase = p > 0.74;
    final zoomT = isZoomPhase ? ((p - 0.74) / 0.26).clamp(0.0, 1.0) : 0.0;
    final entryT = (p / 0.45).clamp(0.0, 1.0);
    final easeEntry = 1.0 - math.pow(1.0 - entryT, 3).toDouble();

    final oScale = isZoomPhase
        ? 1.0 + (zoomT * zoomT) * 11.0
        : 0.35 + 0.65 * easeEntry;
    final bgOpacity = isZoomPhase ? (1.0 - zoomT).clamp(0.0, 1.0) : 1.0;
    final textOpacity = p < 0.30
        ? 0.0
        : isZoomPhase
        ? (1.0 - zoomT * 2.0).clamp(0.0, 1.0)
        : ((p - 0.30) / 0.30).clamp(0.0, 1.0);

    return Positioned.fill(
      child: IgnorePointer(
        child: Opacity(
          opacity: bgOpacity,
          child: Container(
            color: const Color(0xFF020409),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: oScale,
                    child: Transform.rotate(
                      angle: (1.0 - easeEntry) * -1.4,
                      child: Container(
                        width: 128,
                        height: 128,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF38BDF8).withValues(alpha: 0.38 * easeEntry),
                              blurRadius: 42,
                              spreadRadius: 6,
                            ),
                          ],
                        ),
                        child: CustomPaint(painter: _LogoPainter()),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Opacity(
                    opacity: textOpacity,
                    child: Text(
                      'ORIXON',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4.0 + 6.0 * easeEntry,
                        color: Colors.white,
                        shadows: const [
                          Shadow(color: Color(0xFF38BDF8), blurRadius: 22),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  String _ambientWallpaperTheme = 'Cyberpunk Cyan';
  String _ambientCustomPhotoPath = '';
  String _homeWallpaperTheme = 'Orixon Default';
  String _homeCustomPhotoPath = '';
  String _appLocale = 'System default';

  String _tr(String en, String bn, String hi) {
    if (_appLocale.contains('বাংলা')) return bn;
    if (_appLocale.contains('हिन्दी')) return hi;
    return en;
  }

  Future<void> _loadAmbientAndLocaleSettings() async {
    try {
      final db = ref.read(appDatabaseProvider);
      final rows = await db.select(db.appSettings).get();
      for (final r in rows) {
        if (r.key.endsWith('Ambient Wallpaper') || r.key.endsWith('Ambient Wallpaper Theme')) {
          _ambientWallpaperTheme = r.value;
        } else if (r.key.endsWith('Home Screen Wallpaper')) {
          _homeWallpaperTheme = r.value;
        } else if (r.key == 'home_custom_wallpaper_path') {
          _homeCustomPhotoPath = r.value;
        } else if (r.key.endsWith('Ambient Wallpaper Theme')) {
          _ambientWallpaperTheme = r.value;
        } else if (r.key == 'ambient_custom_wallpaper_path') {
          _ambientCustomPhotoPath = r.value;
        } else if (r.key.endsWith('Set locale')) {
          _appLocale = r.value;
        }
      }
      if (mounted) setState(() {});
    } catch (_) {}
  }
  bool _showSearchModal = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final SpeechToText _speech = SpeechToText();
  String _searchQuery = '';
  String _searchFilter = 'All';
  String? _webxInitialQuery;
  bool _speechAvailable = false;
  bool _isListening = false;
  int? _searchInitialChannelId;
  OsViewState _viewState = OsViewState.loaded;
  String? _subScreen;
  String? _pipTitle;
  bool _pipPlaying = true;

  Color _ambientColor = const Color(0xFF00A8E8);
  String _statusText = 'ORIXON OS 4.5 • Adaptive TV, Phone & Desktop Engine';

  late Timer _clockTimer;
  late Timer _networkTimer;
  Timer? _inactivityTimer;
  static const MethodChannel _networkChannel = MethodChannel(
    'com.example.orixon/local_media',
  );
  DateTime _now = DateTime.now();
  late AnimationController _pulseCtrl;

  static const _channels = [
    (
      'Star Sports',
      '1 HD',
      'LIVE • IND vs AUS • 1080p 60fps',
      Color(0xFF00B4D8),
      true,
      0,
    ),
    (
      'LIVE',
      'TEN 1',
      'LIVE • Champions League • Dolby Audio',
      Color(0xFF2563EB),
      true,
      1,
    ),
    (
      'ZEE',
      'TV HD',
      'NOW • Prime Time Cinema • HD',
      Color(0xFFF97316),
      true,
      2,
    ),
    (
      'STREAM',
      'HD',
      'UP NEXT • Grand Finale • 9:00 PM',
      Color(0xFFEC4899),
      false,
      3,
    ),
    (
      'LIVE',
      'TV',
      'LIVE • Premier Sports • 60fps',
      Color(0xFF3B82F6),
      true,
      4,
    ),
  ];

  static const _videos = [
    (
      'Eternal Horizon',
      '4K HDR • 28m left',
      '1:32:17',
      0.72,
      Color(0xFFD97736),
      [Color(0xFF4A2511), Color(0xFFD97736), Color(0xFF1A141E)],
      'https://images.unsplash.com/photo-1536440136628-849c177e76a1?w=700&q=80',
    ),
    (
      'Crimson Dynasty',
      'Dolby Vision • 1h 12m left',
      '2:48:20',
      0.48,
      Color(0xFFDC2626),
      [Color(0xFF3B1216), Color(0xFF9E2A2B), Color(0xFF141820)],
      'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=700&q=80',
    ),
    (
      'Solaris Rising',
      '4K UHD • 18m left',
      '2:40:15',
      0.88,
      Color(0xFFF59E0B),
      [Color(0xFF5A2A0C), Color(0xFFF58529), Color(0xFF120D0A)],
      'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=700&q=80',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _refreshNetworkStatus();
    _startNetflixStyleIntro();
    _syncTvInterfaceSetting();
    _syncTvInterfaceMode();
    _networkTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _refreshNetworkStatus();
      _syncTvInterfaceSetting();
      _syncTvInterfaceMode();
    });
    _clockTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _introTimer?.cancel();
    _chimePlayer?.dispose();
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
    _clockTimer.cancel();
    _networkTimer.cancel();
    unawaited(_speech.cancel());
    _searchController.dispose();
    _searchFocusNode.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _syncTvInterfaceMode() async {
    try {
      final rows = await widget.database
          .select(widget.database.appSettings)
          .get();
      final map = {for (final r in rows) r.key: r.value};
      final raw =
          map['Display & Interface::Android TV interface'] ??
          map['Interface::Android TV interface'];
      final forceTv = raw == null ? false : raw == 'true';
      if (forceTv) {
        await SystemChrome.setPreferredOrientations(const [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      } else {
        await SystemChrome.setPreferredOrientations(const [
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      }
    } catch (_) {}
  }

  bool _forceTvInterface = false;

  Future<void> _syncTvInterfaceSetting() async {
    try {
      final rows = await widget.database
          .select(widget.database.appSettings)
          .get();
      final map = {for (final r in rows) r.key: r.value};
      final raw =
          map['Display & Interface::Android TV interface'] ??
          map['Interface::Android TV interface'];
      final enabled = raw == null ? false : raw == 'true';
      if (mounted && _forceTvInterface != enabled) {
        setState(() => _forceTvInterface = enabled);
      }
      if (enabled) {
        await SystemChrome.setPreferredOrientations(const [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      } else {
        await SystemChrome.setPreferredOrientations(const [
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      }
    } catch (_) {}
  }

  Future<void> _refreshNetworkStatus() async {
    try {
      final status = await _networkChannel.invokeMethod<String>(
        'getNetworkStatus',
      );
      if (!mounted) return;
      final next = switch (status) {
        'wifi' || 'mobile' || 'ethernet' => status!,
        _ => 'offline',
      };
      if (_networkType != next) setState(() => _networkType = next);
    } catch (_) {
      if (mounted && _networkType != 'offline') {
        setState(() => _networkType = 'offline');
      }
    }
  }

  void _setAmbient(Color c, String text) {
    if (_ambientColor != c || _statusText != text) {
      setState(() {
        _ambientColor = c;
        _statusText = text;
      });
    }
  }

  void _startPlayback(String title) {
    setState(() {
      _pipTitle = title;
      _pipPlaying = true;
      _subScreen = null;
    });
  }

  void _handleBack() {
    if (_screensaverActive) {
      setState(() => _screensaverActive = false);
    } else if (_showSearchModal) {
      setState(() => _showSearchModal = false);
    } else if (_subScreen != null) {
      setState(() {
        _subScreen = null;
        _searchInitialChannelId = null;
      });
    } else if (_navIndex != 0) {
      setState(() => _navIndex = 0);
    }
  }

  String _fmtDate(DateTime d) {
    const w = ['Mon.', 'Tue.', 'Wed.', 'Thu.', 'Fri.', 'Sat.', 'Sun.'];
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${w[d.weekday - 1]} ${m[d.month - 1]} ${d.day}';
  }

  String _fmtTime(DateTime d) {
    final h = (d.hour % 12 == 0 ? 12 : d.hour % 12).toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$h:$min ${d.hour >= 12 ? 'PM' : 'AM'}';
  }

  bool get _isHomeScreen => _navIndex == 0 && _subScreen == null;

  void _syncInactivityTimer() {
    final isPlayingTvOrPip = (_subScreen == 'LIVE TV') || (_pipTitle != null && _pipPlaying);
    final shouldRun =
        mounted &&
        !_screensaverActive &&
        !isPlayingTvOrPip &&
        (ModalRoute.of(context)?.isCurrent ?? true);

    if (!shouldRun) {
      _inactivityTimer?.cancel();
      _inactivityTimer = null;
      return;
    }

    if (_inactivityTimer?.isActive ?? false) return;

    _inactivityTimer = Timer(const Duration(minutes: 1), () {
      _inactivityTimer = null;
      final stillIdle = mounted &&
          !_screensaverActive &&
          !((_subScreen == 'LIVE TV') || (_pipTitle != null && _pipPlaying)) &&
          (ModalRoute.of(context)?.isCurrent ?? true);
      if (!stillIdle) return;
      _loadAmbientAndLocaleSettings();
      setState(() => _screensaverActive = true);
    });
  }

  void _registerActivity() {
    if (!mounted) return;
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
    if (_screensaverActive) {
      setState(() => _screensaverActive = false);
    }
    _syncInactivityTimer();
    _loadAmbientAndLocaleSettings();
  }

    @override
  Widget build(BuildContext context) {
    final db = ref.watch(appDatabaseProvider);
    return StreamBuilder<List<AppSetting>>(
      stream: db.select(db.appSettings).watch(),
      builder: (context, snap) {
        String wp = 'Orixon Default';
        final rows = snap.data;
        if (rows != null) {
          for (final r in rows) {
            if (r.key == 'Display & Interface::App Theme') {
              wp = r.value;
              break;
            } else if (r.key == 'Display & Interface::Home Screen Wallpaper' &&
                wp == 'Orixon Default') {
              wp = r.value;
            }
          }
        }
        Widget bg;
        if (wp.startsWith('Custom Photo::')) {
          final path = wp.substring('Custom Photo::'.length).trim();
          final f = File(path);
          if (f.existsSync()) {
            bg = Stack(
              fit: StackFit.expand,
              children: [
                Image.file(
                  f,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.fill,
                  gaplessPlayback: true,
                ),
                Container(color: Colors.black.withValues(alpha: 0.28)),
              ],
            );
          } else {
            bg = Container(color: const Color(0xFF03060E));
          }
        } else if (wp == 'Minimal OLED Pitch') {
          bg = Container(color: Colors.black);
        } else if (wp == 'Cosmic Nebula') {
          bg = Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.2, -0.4),
                radius: 1.35,
                colors: [Color(0xFF4C1D95), Color(0xFF1E0B3B), Color(0xFF05020A)],
              ),
            ),
          );
        } else if (wp == 'Cyberpunk Grid') {
          bg = Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.2, -0.4),
                radius: 1.35,
                colors: [Color(0xFF0E7490), Color(0xFF4A044E), Color(0xFF04060E)],
              ),
            ),
          );
        } else if (wp == 'Aurora Borealis') {
          bg = Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.2, -0.4),
                radius: 1.35,
                colors: [Color(0xFF047857), Color(0xFF0F3443), Color(0xFF02070D)],
              ),
            ),
          );
        } else if (wp == 'Deep Ocean') {
          bg = Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.0, -0.3),
                radius: 1.35,
                colors: [Color(0xFF0369A1), Color(0xFF082F49), Color(0xFF020710)],
              ),
            ),
          );
        } else {
          bg = Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.25, -0.45),
                radius: 1.35,
                colors: [Color(0xFF0B2244), Color(0xFF050D1C), Color(0xFF03060E)],
              ),
            ),
          );
        }
        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(child: bg),
            _buildLauncherCore(context),
          ],
        );
      },
    );
  }

  Widget _buildLauncherCore(BuildContext context) {
    _syncInactivityTimer();
    if (_subScreen != null) {
      final Widget subChild = switch (_subScreen) {
        'LIVE TV' => LiveTvScreen(
            database: widget.database,
            enablePlayback: widget.enablePlayback,
            initialChannelId: _searchInitialChannelId,
          ),
        'MEDIA HUB' => const LocalMediaScreen(),
        'FILE HUB' => FileHubScreen(database: widget.database),
        'WEBX' => WebxBrowserScreen(
            database: widget.database,
            initialQuery: _webxInitialQuery,
          ),
        'SETTINGS' => SettingsScreen(database: widget.database),
        _ => _buildRoutedScreen(_subScreen!),
      };
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _handleBack();
        },
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (_) => _registerActivity(),
          onPointerMove: (_) => _registerActivity(),
          onPointerHover: (_) => _registerActivity(),
          onPointerSignal: (_) => _registerActivity(),
          child: Focus(
            canRequestFocus: false,
            onKeyEvent: (_, event) {
              if (event is KeyDownEvent || event is KeyRepeatEvent) {
                _registerActivity();
              }
              return KeyEventResult.ignored;
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                subChild,
                if (_screensaverActive) _buildAmbientScreensaver(),
              ],
            ),
          ),
        ),
      );
    }

    final canExit =
        !_screensaverActive &&
        !_showSearchModal &&
        _subScreen == null &&
        _navIndex == 0;

    return PopScope(
      canPop: canExit,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: LayoutBuilder(
          builder: (context, box) {
            // Responsive breakpoint: Widescreen (TV, Google TV, Windows, Mac, Landscape Phone) vs Portrait Phone
            final isWide = _forceTvInterface || box.maxWidth >= 700;
            final compactH = box.maxHeight < 500;
            final hPad = (box.maxWidth * 0.026).clamp(14.0, 34.0);
            final vPad = (box.maxHeight * 0.022).clamp(8.0, 18.0);
            final railW = (box.maxWidth * 0.17).clamp(155.0, 205.0);

            return Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (_) => _registerActivity(),
              onPointerHover: (_) => _registerActivity(),
              onPointerSignal: (_) => _registerActivity(),
              child: Focus(
                canRequestFocus: false,
                onKeyEvent: (_, event) {
                  if (event is KeyDownEvent) _registerActivity();
                  return KeyEventResult.ignored;
                },
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onDoubleTap: () {
                          _loadAmbientAndLocaleSettings();
                          setState(() => _screensaverActive = true);
                        },
                        child: (_homeCustomPhotoPath.isNotEmpty && File(_homeCustomPhotoPath).existsSync())
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.file(
                                    File(_homeCustomPhotoPath),
                                    fit: BoxFit.cover,
                                  ),
                                  Container(
                                    color: Colors.black.withValues(alpha: 0.38),
                                  ),
                                ],
                              )
                            : RepaintBoundary(
                                child: CustomPaint(
                                  painter: _OsBackgroundPainter(
                                    switch (_homeWallpaperTheme) {
                                      'Aurora Purple' => const Color(0xFFA855F7),
                                      'Sunset Gold' => const Color(0xFFF59E0B),
                                      'Emerald Matrix' => const Color(0xFF10B981),
                                      'Cyberpunk Cyan' => OsTokens.cyan,
                                      _ => _ambientColor,
                                    },
                                  ),
                                ),
                              ),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: hPad,
                          vertical: vPad,
                        ),
                        child: Column(
                          children: [
                            _buildTopBar(isWide, compactH),
                            SizedBox(height: compactH ? 10 : 14),
                            Expanded(
                              child: isWide
                                  ? Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        SizedBox(
                                          width: railW,
                                          child: _buildLeftDock(compactH),
                                        ),
                                        SizedBox(width: hPad * 0.8),
                                        Expanded(
                                          child: _subScreen != null
                                              ? _buildRoutedScreen(_subScreen!)
                                              : _buildMainContent(
                                                  isWide: true,
                                                  compact: compactH,
                                                ),
                                        ),
                                      ],
                                    )
                                  : (_subScreen != null
                                        ? _buildRoutedScreen(_subScreen!)
                                        : _buildMainContent(
                                            isWide: false,
                                            compact: false,
                                          )),
                            ),
                            const SizedBox(height: 6),
                            if (!isWide) _buildMobileBottomDock(),
                          ],
                        ),
                      ),
                    ),

                    // Floating Mini Picture-in-Picture (PiP) Player
                    if (_pipTitle != null) _buildMiniPipPlayer(isWide),

                    // Global Search & Voice Assistant Overlay
                    if (_showSearchModal) _buildSearchModal(),

                    // Full-screen Ambient Screensaver Mode
                    if (_screensaverActive) _buildAmbientScreensaver(),

                    // Netflix-style 'O' Startup Intro Overlay
                    if (_showStartupIntro) _buildNetflixStyleStartupOverlay(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ===========================================================================
  // TOP SYSTEM BAR (Responsive for TV, Desktop & Mobile)
  // ===========================================================================
  Widget _buildTopBar(bool isWide, bool compact) {
    return Row(
      children: [
        if (_subScreen != null) ...[
          _OsFocus(
            onTap: _handleBack,
            builder: (_, f) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: f ? OsTokens.cyan : Colors.white12,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                size: 16,
                color: f ? Colors.black : Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
        SizedBox(
          width: isWide ? 32 : 26,
          height: isWide ? 32 : 26,
          child: CustomPaint(painter: _LogoPainter()),
        ),
        const SizedBox(width: 10),
        Text(
          'ORIXON',
          style: TextStyle(
            fontSize: isWide ? (compact ? 21 : 26) : 20,
            fontWeight: FontWeight.w900,
            letterSpacing: 3.5,
            color: Colors.white,
            shadows: const [
              Shadow(color: Color(0xFF38BDF8), blurRadius: 16),
            ],
          ),
        ),
        if (isWide) ...[
          const SizedBox(width: 14),
          Container(height: 22, width: 1.2, color: Colors.white24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Your World. Your Entertainment.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 11.5 : 13.5,
                    fontStyle: FontStyle.italic,
                    color: OsTokens.textSoft,
                  ),
                ),
              ],
            ),
          ),
        ] else
          const Spacer(),

        // Unified System Tray Pill (Search, Favorites, Notifications, Wi-Fi, Clock, Quick Settings)
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isWide ? 12 : 8,
            vertical: 5,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1426).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _trayIconBtn(
                Icons.search_rounded,
                'Search',
                () => setState(() => _showSearchModal = true),
              ),

              Tooltip(
                message: switch (_networkType) {
                  'ethernet' => 'Ethernet',
                  'mobile' => 'Mobile Data',
                  'wifi' => 'Wi-Fi',
                  _ => 'No Internet',
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: CircleAvatar(
                    radius: 15,
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    child: Icon(
                      switch (_networkType) {
                        'ethernet' => Icons.settings_ethernet_rounded,
                        'mobile' => Icons.signal_cellular_alt_rounded,
                        'wifi' => Icons.wifi_rounded,
                        _ => Icons.wifi_off_rounded,
                      },
                      size: 18,
                      color: _networkType == 'offline'
                          ? Colors.redAccent
                          : Colors.white,
                    ),
                  ),
                ),
              ),
              if (isWide) ...[
                const SizedBox(width: 8),
                Container(height: 20, width: 1, color: Colors.white24),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _fmtDate(_now),
                      style: const TextStyle(
                        fontSize: 9.5,
                        color: OsTokens.textSoft,
                      ),
                    ),
                    Text(
                      _fmtTime(_now),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
              if (isWide) ...[
                const SizedBox(width: 8),
                Container(height: 20, width: 1, color: Colors.white24),
                const SizedBox(width: 6),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _trayIconBtn(
    IconData icon,
    String tip,
    VoidCallback onTap, {
    int badgeCount = 0,
    Color badgeColor = OsTokens.cyan,
    Color iconColor = Colors.white,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: _OsFocus(
        onTap: onTap,
        builder: (_, f) => Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: f
                  ? OsTokens.cyan
                  : Colors.white.withValues(alpha: 0.05),
              child: Icon(icon, size: 18, color: f ? Colors.black : iconColor),
            ),
            if (badgeCount > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // LEFT NAVIGATION DOCK (TV / Desktop / Landscape) & MOBILE BOTTOM DOCK
  // ===========================================================================
  Widget _buildLeftDock(bool compact) {
    final channelLabel = ref
        .watch(totalChannelCountProvider)
        .when(
          data: (count) => '$count Channels',
          loading: () => 'Loading channels...',
          error: (_, __) => 'Channels',
        );
    final items = [
      ('TV', Icons.live_tv_rounded, OsTokens.cyan, 'TV • $channelLabel Ready'),
      (
        'MEDIA HUB',
        Icons.movie_creation_outlined,
        OsTokens.purple,
        'MEDIA HUB • 4K Hardware Player',
      ),
      (
        'FILE HUB',
        Icons.folder_copy_rounded,
        Color(0xFF34D399),
        'FILE HUB • Explorer, ZIP, Quick Share & FTP',
      ),
      (
        'WEBX',
        Icons.public_rounded,
        Color(0xFFF59E0B),
        'WEBX • Smart Browser & SuperX Video Downloader',
      ),
      (
        'Settings',
        Icons.settings,
        Color(0xFF38BDF8),
        'ADVANCED SETTINGS • Picture, Audio & System',
      ),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...List.generate(items.length, (i) {
          final item = items[i];
          final sel = _navIndex == i;
          return Padding(
            padding: EdgeInsets.only(bottom: compact ? 8 : 12),
            child: _OsFocus(
              autofocus: i == 0,
              onFocus: () => _setAmbient(item.$3, item.$4),
              onTap: () => setState(() {
                _navIndex = i;
                if (i == 0) {
                  _subScreen = 'LIVE TV';
                } else if (i == 1) {
                  _subScreen = 'MEDIA HUB';
                } else if (i == 2) {
                  _subScreen = 'FILE HUB';
                } else if (i == 3) {
                  _subScreen = 'WEBX';
                } else if (i == 4) {
                  _subScreen = 'SETTINGS';
                }
              }),
              builder: (_, f) {
                final active = sel || f;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: compact ? 9 : 12,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: active
                        ? LinearGradient(
                            colors: [
                              OsTokens.cyan.withValues(alpha: f ? 0.34 : 0.2),
                              Colors.transparent,
                            ],
                          )
                        : null,
                    border: Border.all(
                      color: active
                          ? (f ? Colors.white : OsTokens.cyan)
                          : Colors.transparent,
                      width: f ? 2.0 : 1.4,
                    ),
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color: OsTokens.cyan.withValues(
                                alpha: f ? 0.38 : 0.2,
                              ),
                              blurRadius: 14,
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        item.$2,
                        size: compact ? 20 : 23,
                        color: active ? OsTokens.cyan : OsTokens.textSoft,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.$1,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: compact ? 13 : 14.5,
                            fontWeight: active
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMobileBottomDock() {
    const items = [
      ('TV', Icons.live_tv_rounded),
      ('Media', Icons.movie_creation_outlined),
      ('File Hub', Icons.folder_copy_rounded),
      ('WebX', Icons.public_rounded),
      ('Settings', Icons.tune_rounded),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1426).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final sel = _navIndex == i;
          return GestureDetector(
            onTap: () => setState(() {
              _navIndex = i;
              if (i == 0) _subScreen = 'LIVE TV';
              if (i == 1) _subScreen = 'MEDIA HUB';
              if (i == 2) _subScreen = 'FILE HUB';
              if (i == 3) _subScreen = 'WEBX';
              if (i == 4) _subScreen = 'SETTINGS';
            }),
            child: Row(
              children: [
                Icon(
                  items[i].$2,
                  size: 20,
                  color: sel ? OsTokens.cyan : OsTokens.textSoft,
                ),
                if (sel) ...[
                  const SizedBox(width: 6),
                  Text(
                    items[i].$1,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: OsTokens.cyan,
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBottomOsHintBar() {
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        _hintBadge('OK / Enter', 'Play & Open'),
        _hintBadge('Long Press / ★', 'Toggle Favorite'),
        _hintBadge('Back / Esc', 'Previous Screen'),
      ],
    );
  }

  Widget _hintBadge(String keyLabel, String action) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white12,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white24),
          ),
          child: Text(
            keyLabel,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          action,
          style: const TextStyle(fontSize: 10.5, color: OsTokens.textSoft),
        ),
      ],
    );
  }

  // ===========================================================================
  // MAIN CONTENT CANVAS (Adaptive for Widescreen TV/Desktop & Portrait Phone)
  // ===========================================================================
  Widget _buildMainContent({required bool isWide, required bool compact}) {
    const loading = false;
    if (!isWide) {
      // Portrait Mobile Scrollable View
      return ListView(
        children: [
          _buildHeader(
            'Recently Used Channels',
            _showAllRecentChannels ? 'Show Less' : 'See All',

            () => setState(() {
              _showAllRecentChannels = !_showAllRecentChannels;
            }),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: _showAllRecentChannels ? 256 : 80,
            child: loading ? _buildSkeleton(3, 10) : _buildChannelsRow(),
          ),
          const SizedBox(height: 16),
          _buildHeader(
            'Recently Watched Videos',
            'See All',
            () => setState(() {
              _navIndex = 1;
              _subScreen = 'MEDIA HUB';
            }),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 130,
            child: loading ? _buildSkeleton(2, 12) : _buildVideosRow(),
          ),
        ],
      );
    }

    // Widescreen TV / Google TV / Windows / Mac Flex Layout
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(flex: 8),
        _buildHeader(
          'Recently Used Channels',
          _showAllRecentChannels ? 'Show Less' : 'See All',
          () => setState(() {
            _showAllRecentChannels = !_showAllRecentChannels;
          }),
        ),
        SizedBox(height: compact ? 5 : 7),
        Expanded(
          flex: _showAllRecentChannels ? 40 : 23,
          child: loading ? _buildSkeleton(5, 10) : _buildChannelsRow(),
        ),
        SizedBox(height: compact ? 8 : 12),
        _buildHeader(
          'Recently Watched Videos',
          'See All',
          () => setState(() {
            _navIndex = 1;
            _subScreen = 'MEDIA HUB';
          }),
        ),
        SizedBox(height: compact ? 5 : 7),
        Expanded(
          flex: _showAllRecentChannels ? 21 : 30,
          child: loading ? _buildSkeleton(3, 12) : _buildVideosRow(),
        ),
      ],
    );
  }

  Widget _buildHeroBannerRow(bool loading) {
    if (loading) return _buildSkeleton(2, 16);

    final channelBadge = ref
        .watch(totalChannelCountProvider)
        .when(
          data: (count) => '$count CHANNELS',
          loading: () => '... CHANNELS',
          error: (_, _) => 'CHANNELS',
        );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _buildHeroCard(
            title: 'TV',
            sub: 'Television Experience',
            badge: channelBadge,
            accent: OsTokens.cyan,
            colors: const [
              Color(0xFF0A2338),
              Color(0xFF0E3B5C),
              Color(0xFF061626),
            ],
            icon: CustomPaint(painter: _TvIconPainter(OsTokens.cyan)),
            art: CustomPaint(painter: _StadiumPainter()),
            onFocus: () => _setAmbient(
              OsTokens.cyan,
              'TV • Sports, News & Entertainment in Full HD',
            ),
            onTap: () => setState(() {
              _navIndex = 0;
              _subScreen = 'LIVE TV';
            }),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildHeroCard(
            title: 'MEDIA HUB',
            sub: 'Your Personal Library',
            badge: '4K HDR PLAYER',
            accent: OsTokens.purple,
            colors: const [
              Color(0xFF22133A),
              Color(0xFF3E1D68),
              Color(0xFF160B28),
            ],
            icon: CustomPaint(painter: _FolderIconPainter(OsTokens.purple)),
            art: CustomPaint(painter: _ReelPainter()),
            onFocus: () => _setAmbient(
              OsTokens.purple,
              'MEDIA HUB • Play 4K Movies from Storage',
            ),
            onTap: () => setState(() {
              _navIndex = 1;
              _subScreen = 'MEDIA HUB';
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard({
    required String title,
    required String sub,
    required String badge,
    required Color accent,
    required List<Color> colors,
    required Widget icon,
    required Widget art,
    required VoidCallback onFocus,
    required VoidCallback onTap,
  }) {
    return _OsFocus(
      scale: 1.02,
      onFocus: onFocus,
      onTap: onTap,
      builder: (_, f) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: f ? Colors.white : accent.withValues(alpha: 0.65),
            width: f ? 2.2 : 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: f ? 0.42 : 0.16),
              blurRadius: f ? 18 : 10,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            children: [
              Positioned.fill(child: RepaintBoundary(child: art)),
              Positioned(
                top: 8,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2.5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: accent.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: accent,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Center(
                  child: Row(
                    children: [
                      SizedBox(width: 50, height: 44, child: icon),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                sub,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: OsTokens.textSoft,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String title, String trailing, VoidCallback onTap) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 15,
          decoration: BoxDecoration(
            color: OsTokens.cyan,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        _OsFocus(
          onTap: onTap,
          builder: (_, f) => Row(
            children: [
              Text(
                trailing,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: f ? OsTokens.cyan : OsTokens.textSoft,
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 17,
                color: f ? OsTokens.cyan : OsTokens.textSoft,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChannelsRow() {
    return ref
        .watch(launcherRecentLiveTvChannelsProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const Center(
            child: Text(
              'Could not load recent channels',
              style: TextStyle(color: OsTokens.textSoft),
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0C1526).withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'No recently used channels',
                  style: TextStyle(color: OsTokens.textSoft, fontSize: 13),
                ),
              );
            }

            final visibleItems = items
                .take(_showAllRecentChannels ? items.length : 6)
                .toList(growable: false);

            if (_showAllRecentChannels) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  final cardHeight = math.min(
                    84.0,
                    math.max(44.0, (constraints.maxHeight - 16) / 3),
                  );

                  return GridView.builder(
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 10,
                      mainAxisExtent: cardHeight,
                    ),
                    itemCount: visibleItems.length,
                    itemBuilder: (context, index) =>
                        _buildRecentChannelCard(visibleItems[index]),
                  );
                },
              );
            }

            const totalSlots = 6;
            return Row(
              children: List.generate(totalSlots, (index) {
                if (index >= visibleItems.length) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: index == totalSlots - 1 ? 0 : 12,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  );
                }
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: index == totalSlots - 1 ? 0 : 12,
                    ),
                    child: _buildRecentChannelCard(visibleItems[index]),
                  ),
                );
              }),
            );
          },
        );
  }

  Widget _buildRecentChannelCard(RecentLiveTvChannelEntry item) {
    final title = item.channel?.name ?? item.history.title;
    final logo = item.channel?.logoUrl;

    Widget buildStylizedFallback() {
      final words = title.trim().split(' ').where((w) => w.isNotEmpty).toList();
      final mainWord = words.isNotEmpty ? words.first.toUpperCase() : 'TV';
      final subWord = words.length > 1
          ? words.skip(1).join(' ').toUpperCase()
          : 'LIVE HD';
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00B4D8), Color(0xFF0077B6)],
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              mainWord,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subWord,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: OsTokens.textSoft,
            ),
          ),
        ],
      );
    }

    return _OsFocus(
      scale: 1.045,
      onFocus: () => _setAmbient(OsTokens.cyan, title),
      onTap: () => setState(() {
        _navIndex = 0;
        _searchInitialChannelId =
            item.channel?.id ?? int.tryParse(item.history.referenceId);
        _subScreen = 'LIVE TV';
      }),
      builder: (_, focused) => AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Color(0xFF15223B), Color(0xFF0B1324)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border.all(
            color: focused
                ? OsTokens.cyan
                : Colors.white.withValues(alpha: 0.14),
            width: focused ? 2.0 : 1.0,
          ),
          boxShadow: focused
              ? [
                  BoxShadow(
                    color: OsTokens.cyan.withValues(alpha: 0.35),
                    blurRadius: 14,
                  ),
                ]
              : [],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Center(
                child: logo != null && logo.trim().isNotEmpty
                    ? Image.network(
                        logo.trim(),
                        headers: const {'User-Agent': 'Mozilla/5.0'},
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => buildStylizedFallback(),
                      )
                    : buildStylizedFallback(),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: focused ? Colors.white : OsTokens.textSoft,
                fontSize: 10,
                fontWeight: focused ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelLogo(String name, String sub, int type) {
    if (type == 0) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star_border_purple500_rounded,
            color: Colors.white,
            size: 24,
          ),
          Text(
            name,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          Text(
            sub,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: OsTokens.textSoft,
            ),
          ),
        ],
      );
    }
    if (type == 1 || type == 4) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 1.5),
            color: Colors.black,
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.6,
                color: Colors.white,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 1.5),
            color: Colors.white,
            child: Text(
              sub,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: Color(0xFF0A2885),
              ),
            ),
          ),
        ],
      );
    }
    if (type == 2) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFFF9800), Color(0xFFE65100)],
              ),
            ),
            child: const Text(
              'ZEE',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            'TV ',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFFFF6D00),
            ),
          ),
          const Text(
            'HD',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.white38,
            ),
          ),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.filter_vintage_rounded,
          color: Color(0xFFE91E63),
          size: 18,
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'colors ',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFFAD1457),
                borderRadius: BorderRadius.circular(3),
              ),
              child: const Text(
                'HD',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVideosRow() {
    return ref
        .watch(recentLocalMediaProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const Center(
            child: Text(
              'Could not load recent videos',
              style: TextStyle(color: OsTokens.textSoft),
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0C1526).withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'No recently watched videos',
                  style: TextStyle(color: OsTokens.textSoft, fontSize: 13),
                ),
              );
            }
            String durationLabel(int milliseconds) {
              final d = Duration(
                milliseconds: milliseconds < 0 ? 0 : milliseconds,
              );
              final h = d.inHours;
              final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
              final sec = d.inSeconds.remainder(60).toString().padLeft(2, '0');
              return h > 0 ? '$h:$m:$sec' : '${d.inMinutes}:$sec';
            }

            final visibleVideos = items.take(4).toList(growable: false);
            const totalSlots = 4;

            return Row(
              children: List.generate(totalSlots, (i) {
                if (i >= visibleVideos.length) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: i == totalSlots - 1 ? 0 : 14,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  );
                }
                final video = visibleVideos[i];
                final progress = video.durationMs > 0
                    ? (video.lastPositionMs / video.durationMs).clamp(0.0, 1.0)
                    : 0.0;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: i == totalSlots - 1 ? 0 : 14,
                    ),
                    child: _OsFocus(
                      scale: 1.035,
                      onFocus: () => _setAmbient(
                        OsTokens.purple,
                        'RESUME PLAYBACK • ${video.fileName}',
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                LocalMediaPlayerScreen(video: video),
                          ),
                        );
                      },
                      builder: (_, focused) => AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: focused
                                ? OsTokens.cyan
                                : Colors.white.withValues(alpha: 0.18),
                            width: focused ? 2.2 : 1.0,
                          ),
                          boxShadow: focused
                              ? [
                                  BoxShadow(
                                    color: OsTokens.cyan.withValues(
                                      alpha: 0.35,
                                    ),
                                    blurRadius: 16,
                                  ),
                                ]
                              : [],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              FutureBuilder(
                                future: ref
                                    .read(androidMediaStoreScannerProvider)
                                    .getVideoThumbnail(video.filePath),
                                builder: (context, snapshot) {
                                  final bytes = snapshot.data;
                                  if (bytes != null && bytes.isNotEmpty) {
                                    return Image.memory(
                                      bytes,
                                      fit: BoxFit.cover,
                                      gaplessPlayback: true,
                                    );
                                  }
                                  return const DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFF263653),
                                          Color(0xFF101827),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.movie_rounded,
                                        color: OsTokens.cyan,
                                        size: 38,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.78),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),
                              Center(
                                child: CircleAvatar(
                                  radius: focused ? 21 : 19,
                                  backgroundColor: focused
                                      ? OsTokens.cyan
                                      : Colors.black54,
                                  child: Icon(
                                    Icons.play_arrow_rounded,
                                    color: focused
                                        ? Colors.black
                                        : Colors.white,
                                    size: 25,
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 10,
                                right: 74,
                                bottom: 9,
                                child: Text(
                                  video.fileName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 8,
                                bottom: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 2.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.82),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(
                                    durationLabel(video.durationMs),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              if (progress > 0)
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 0,
                                  child: SizedBox(
                                    height: 3.5,
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      backgroundColor: Colors.white24,
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                            OsTokens.cyan,
                                          ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        );
  }

  Widget _buildMiniPipPlayer(bool isWide) {
    return Positioned(
      right: isWide ? 28 : 14,
      bottom: isWide ? 36 : 64,
      child: Container(
        width: isWide ? 250 : 210,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF0E192D).withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: OsTokens.cyan, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 16,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: OsTokens.cyan.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _pipPlaying ? Icons.equalizer_rounded : Icons.pause_rounded,
                color: OsTokens.cyan,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'MINI PiP PLAYER',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      color: OsTokens.cyan,
                    ),
                  ),
                  Text(
                    _pipTitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: () => setState(() => _pipPlaying = !_pipPlaying),
              icon: Icon(
                _pipPlaying
                    ? Icons.pause_circle_filled_rounded
                    : Icons.play_circle_fill_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: () => setState(() => _pipTitle = null),
              icon: const Icon(
                Icons.close_rounded,
                color: Colors.white70,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // DATABASE-BACKED VOICE & TEXT SEARCH
  String _normalizeSearchText(String value) {
    return value
        .toLowerCase()
        .replaceAll(
          RegExp(r'\b(open|play|watch|show)\b', caseSensitive: false),
          '',
        )
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  Future<void> _startVoiceSearch() async {
    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    try {
      final available = await _speech.initialize(
        onStatus: (status) {
          if (!mounted) return;
          setState(() => _isListening = status == 'listening');
        },
        onError: (_) {
          if (mounted) setState(() => _isListening = false);
        },
        options: [SpeechToText.androidNoBluetooth],
      );

      if (!mounted) return;
      setState(() => _speechAvailable = available);

      if (!available) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Voice search unavailable. You can still type to search.',
            ),
          ),
        );
        return;
      }

      await _speech.listen(
        onResult: (result) {
          if (!mounted) return;
          final words = result.recognizedWords;
          _searchController.value = TextEditingValue(
            text: words,
            selection: TextSelection.collapsed(offset: words.length),
          );
          setState(() => _searchQuery = words);
          if (result.finalResult && words.trim().isNotEmpty) {
            _playExactVoiceMatch(words);
          }
        },
        listenOptions: SpeechListenOptions(
          partialResults: true,
          listenMode: ListenMode.confirmation,
          cancelOnError: true,
          listenFor: const Duration(seconds: 15),
          pauseFor: const Duration(seconds: 3),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isListening = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Voice search failed. Please type your search.'),
        ),
      );
    }
  }

  Future<void> _playExactVoiceMatch(String query) async {
    try {
      final normalized = _normalizeSearchText(query);
      if (normalized.isEmpty) return;

      final channels = await ref.read(channelsProvider.future);
      final media = await ref.read(localMediaFilesProvider.future);

      final channelMatches = channels.where((channel) {
        return _normalizeSearchText(channel.name) == normalized ||
            channel.channelNumber.toString() == normalized;
      }).toList();

      final mediaMatches = media.where((video) {
        final name = video.fileName.replaceFirst(RegExp(r'\.[^.]+$'), '');
        return _normalizeSearchText(video.fileName) == normalized ||
            _normalizeSearchText(name) == normalized;
      }).toList();

      if (channelMatches.length + mediaMatches.length != 1) return;

      if (channelMatches.length == 1) {
        _openSearchChannel(channelMatches.single);
      } else {
        await _openSearchMedia(mediaMatches.single);
      }
    } catch (_) {
      // Keep the recognized text visible; the user can select a result.
    }
  }

  void _openSearchChannel(Channel channel) {
    if (!mounted) return;
    if (_isListening) unawaited(_speech.stop());
    setState(() {
      _showSearchModal = false;
      _isListening = false;
      _searchInitialChannelId = channel.id;
      _subScreen = 'LIVE TV';
    });
  }

  Future<void> _openSearchMedia(MediaFile video) async {
    if (!mounted) return;
    if (!await File(video.filePath).exists()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This video file is no longer available.'),
        ),
      );
      return;
    }
    if (_isListening) await _speech.stop();
    if (!mounted) return;
    setState(() {
      _showSearchModal = false;
      _isListening = false;
    });
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LocalMediaPlayerScreen(video: video),
      ),
    );
  }

  List<FileSystemEntity> _searchFileHubFiles(String q) {
    if (q.isEmpty) return const [];
    final out = <FileSystemEntity>[];
    final root = Directory('/storage/emulated/0').existsSync()
        ? '/storage/emulated/0'
        : Directory.current.path;
    for (final sub in ['Download', 'Movies', 'Music', 'Documents', 'DCIM']) {
      final d = Directory('$root/$sub');
      if (!d.existsSync()) continue;
      try {
        for (final ent in d.listSync(recursive: true, followLinks: false)) {
          final name = ent.path.split('/').last;
          if (!name.startsWith('.') && _normalizeSearchText(name).contains(q)) {
            out.add(ent);
            if (out.length >= 25) return out;
          }
        }
      } catch (_) {}
    }
    return out;
  }


  Widget _buildReactiveGlobalThemeLayer(Color fallbackColor) {
    final db = ref.watch(appDatabaseProvider);
    return StreamBuilder<List<AppSetting>>(
      stream: db.select(db.appSettings).watch(),
      builder: (context, snap) {
        String themeVal = 'Orixon Default';
        final rows = snap.data;
        if (rows != null) {
          for (final r in rows) {
            if (r.key == 'Display & Interface::App Theme') {
              themeVal = r.value;
              break;
            } else if (r.key == 'Display & Interface::Home Screen Wallpaper' &&
                themeVal == 'Orixon Default') {
              themeVal = r.value;
            }
          }
        }
        if (themeVal.startsWith('Custom Photo::')) {
          final photoPath = themeVal.substring('Custom Photo::'.length).trim();
          final file = File(photoPath);
          if (file.existsSync()) {
            return Stack(
              fit: StackFit.expand,
              children: [
                Image.file(file, width: double.infinity, height: double.infinity, fit: BoxFit.fill, gaplessPlayback: true),
                Container(color: const Color(0xFF03060E).withValues(alpha: 0.48)),
              ],
            );
          }
        }
        if (themeVal == 'Minimal OLED Pitch') {
          return Container(color: Colors.black);
        }
        List<Color> gradColors;
        if (themeVal == 'Cosmic Nebula') {
          gradColors = const [Color(0xFF28104E), Color(0xFF12072B), Color(0xFF05030A)];
        } else if (themeVal == 'Cyberpunk Grid') {
          gradColors = const [Color(0xFF073649), Color(0xFF240B36), Color(0xFF040711)];
        } else if (themeVal == 'Aurora Borealis') {
          gradColors = const [Color(0xFF063B33), Color(0xFF082233), Color(0xFF030810)];
        } else if (themeVal == 'Deep Ocean') {
          gradColors = const [Color(0xFF062C54), Color(0xFF041830), Color(0xFF020710)];
        } else {
          // Orixon Default
          return RepaintBoundary(
            child: CustomPaint(painter: _OsBackgroundPainter(fallbackColor)),
          );
        }
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.25, -0.45),
              radius: 1.35,
              colors: gradColors,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchModal() {
    final db = ref.watch(appDatabaseProvider);
    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: 0.86),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720, maxHeight: 500),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF081120),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.55),
                    width: 1.4,
                  ),
                ),
                child: _RealTimeUniversalSearchBody(
                  database: db,
                  onClose: () => setState(() => _showSearchModal = false),
                  onPlayChannel: (ch, allCh) {
                    setState(() => _showSearchModal = false);
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => _DirectSearchTvPlayerPage(
                          initialChannel: ch,
                          allChannels: allCh,
                        ),
                      ),
                    );
                  },
                  onPlayVideo: (v, allVids) {
                    setState(() => _showSearchModal = false);
                    final idx = allVids.indexWhere((x) => x.id == v.id);
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => LocalMediaPlayerScreen(
                          video: v,
                          playlist: allVids,
                          initialIndex: idx < 0 ? 0 : idx,
                        ),
                      ),
                    );
                  },
                  onOpenFile: (fileEntity) {
                    setState(() => _showSearchModal = false);
                    final path = fileEntity.path;
                    final lower = path.toLowerCase();
                    if (lower.endsWith('.mp4') ||
                        lower.endsWith('.mkv') ||
                        lower.endsWith('.avi') ||
                        lower.endsWith('.mov') ||
                        lower.endsWith('.webm') ||
                        lower.endsWith('.mp3')) {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => LocalMediaPlayerScreen(
                            video: MediaFile(
                              id: 0,
                              filePath: path,
                              fileName: path.split('/').last,
                              folderName: 'Storage',
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
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => FileHubScreen(database: db),
                        ),
                      );
                    }
                  },
                  onOpenWebx: (qStr) {
                    setState(() => _showSearchModal = false);
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => WebxBrowserScreen(
                          database: db,
                          initialQuery: qStr.trim().isEmpty ? null : qStr.trim(),
                        ),
                      ),
                    );
                  },
                  onOpenSettingCategory: (catName) {
                    setState(() => _showSearchModal = false);
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => SettingsScreen(
                          database: db,
                          initialCategory: catName,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmbientScreensaver() {
    final db = ref.watch(appDatabaseProvider);
    return Positioned.fill(
      child: Material(
        type: MaterialType.transparency,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _screensaverActive = false),
          child: StreamBuilder<List<AppSetting>>(
            stream: db.select(db.appSettings).watch(),
            builder: (context, snap) {
              String wp = 'Orixon Default';
              final rows = snap.data;
              if (rows != null) {
                for (final r in rows) {
                  if (r.key == 'Display & Interface::Ambient Wallpaper') {
                    wp = r.value;
                    break;
                  }
                }
              }

              Widget bgLayer;
              if (wp.startsWith('Custom Photo::')) {
                final path = wp.substring('Custom Photo::'.length).trim();
                final file = File(path);
                if (file.existsSync()) {
                  bgLayer = Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(
                        file,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.fill,
                        gaplessPlayback: true,
                      ),
                      Container(color: Colors.black.withValues(alpha: 0.32)),
                    ],
                  );
                } else {
                  bgLayer = Container(color: const Color(0xFF02040A));
                }
              } else if (wp == 'Minimal OLED Pitch') {
                bgLayer = Container(color: Colors.black);
              } else if (wp == 'Cosmic Nebula') {
                bgLayer = Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0.0, -0.3),
                      radius: 1.25,
                      colors: [Color(0xFF3B106C), Color(0xFF16072E), Color(0xFF040208)],
                    ),
                  ),
                );
              } else if (wp == 'Cyberpunk Grid') {
                bgLayer = Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0.2, -0.3),
                      radius: 1.25,
                      colors: [Color(0xFF084C61), Color(0xFF320D47), Color(0xFF04060E)],
                    ),
                  ),
                );
              } else if (wp == 'Aurora Borealis') {
                bgLayer = Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(-0.2, -0.3),
                      radius: 1.25,
                      colors: [Color(0xFF0A5C48), Color(0xFF082B3F), Color(0xFF02070D)],
                    ),
                  ),
                );
              } else if (wp == 'Deep Ocean') {
                bgLayer = Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0.0, -0.2),
                      radius: 1.25,
                      colors: [Color(0xFF073B70), Color(0xFF041D3B), Color(0xFF020710)],
                    ),
                  ),
                );
              } else {
                bgLayer = Container(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(0.0, -0.25),
                      radius: 1.25,
                      colors: [Color(0xFF0B2548), Color(0xFF050F20), Color(0xFF02040A)],
                    ),
                  ),
                );
              }

              return Stack(
                fit: StackFit.expand,
                children: [
                  bgLayer,
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Orixon 3D Logo ONLY (No "ORIXON AMBIENT" text)
                        SizedBox(
                          width: 58,
                          height: 58,
                          child: CustomPaint(painter: _LogoPainter()),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _fmtTime(_now),
                          style: const TextStyle(
                            fontSize: 64,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            color: Colors.white,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _fmtDate(_now),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF38BDF8),
                            letterSpacing: 1.4,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSkeleton(int count, double radius) {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (_, __) => Row(
        children: List.generate(
          count,
          (i) => Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i == count - 1 ? 0 : 12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: 0.06 + _pulseCtrl.value * 0.1,
                  ),
                  borderRadius: BorderRadius.circular(radius),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStateMessage(
    IconData icon,
    String title,
    String sub,
    VoidCallback onRetry,
  ) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: OsTokens.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: OsTokens.cyan),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              sub,
              style: const TextStyle(fontSize: 12.5, color: OsTokens.textSoft),
            ),
            const SizedBox(height: 14),
            _OsFocus(
              autofocus: true,
              onTap: onRetry,
              builder: (_, f) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: f ? OsTokens.cyan : Colors.white12,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Restore',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: f ? Colors.black : Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutedScreen(String title) {
    switch (title) {
      case 'LIVE TV':
        return LiveTvScreen(
          database: widget.database,
          enablePlayback: widget.enablePlayback,
        );
      case 'MEDIA HUB':
        return const LocalMediaScreen();
      case 'FILE HUB':
        return FileHubScreen(database: widget.database);
      case 'WEBX':
        return WebxBrowserScreen(database: widget.database, initialQuery: _webxInitialQuery);
      case 'SETTINGS':
        return SettingsScreen(database: widget.database);
      default:
        return _buildSubScreen(title);
    }
  }

  Widget _buildSubScreen(String title) {
    return Container(
      key: ValueKey(title),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: OsTokens.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: OsTokens.cyan.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tv_rounded, color: OsTokens.cyan, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _OsFocus(
                autofocus: true,
                onTap: _handleBack,
                builder: (_, f) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: f ? OsTokens.cyan : Colors.white10,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Back to Home',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: f ? Colors.black : Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildChannelsRow()),
        ],
      ),
    );
  }
}

class _OsFocus extends StatefulWidget {
  final Widget Function(BuildContext, bool) builder;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onFocus;
  final double scale;
  final bool autofocus;

  const _OsFocus({
    required this.builder,
    required this.onTap,
    this.onLongPress,
    this.onFocus,
    this.scale = 1.03,
    this.autofocus = false,
  });

  @override
  State<_OsFocus> createState() => _OsFocusState();
}

class _OsFocusState extends State<_OsFocus> {
  bool _f = false;
  bool _h = false;

  @override
  Widget build(BuildContext context) {
    final active = _f || _h;
    return FocusableActionDetector(
      autofocus: widget.autofocus,
      onShowFocusHighlight: (v) {
        setState(() => _f = v);
        if (v) widget.onFocus?.call();
      },
      onShowHoverHighlight: (v) {
        setState(() => _h = v);
        if (v) widget.onFocus?.call();
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) => widget.onTap(),
        ),
      },
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedScale(
          scale: active ? widget.scale : 1.0,
          duration: const Duration(milliseconds: 180),
          child: widget.builder(context, active),
        ),
      ),
    );
  }
}

class _OsBackgroundPainter extends CustomPainter {
  const _OsBackgroundPainter(this.glow);
  final Color glow;
  @override
  void paint(Canvas canvas, Size size) {}
  @override
  bool shouldRepaint(covariant _OsBackgroundPainter old) => false;
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.40;
    final stroke = size.width * 0.17;

    // Outer ambient ice-blue glow
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = const Color(0xFF38BDF8).withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke * 1.35
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // 3D Folded Ice-Sapphire & Platinum Ribbon 'O'
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
          Color(0xFF0369A1),
          Color(0xFF38BDF8),
          Color(0xFF0284C7),
        ],
      ).createShader(rect);
    canvas.drawArc(rect, 0, math.pi * 2, false, ringPaint);

    // Inner razor-sharp 'X' star flare
    final xr = r * 0.44;
    final xPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.88)
      ..strokeWidth = (size.width * 0.04).clamp(1.2, 3.0)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(c + Offset(-xr, -xr), c + Offset(xr, xr), xPaint);
    canvas.drawLine(c + Offset(xr, -xr), c + Offset(-xr, xr), xPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TvIconPainter extends CustomPainter {
  final Color color;
  const _TvIconPainter(this.color);

  @override
  void paint(Canvas canvas, Size s) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(s.width * 0.34, s.height * 0.06)
        ..lineTo(s.width * 0.5, s.height * 0.24)
        ..lineTo(s.width * 0.66, s.height * 0.06),
      stroke,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          s.width * 0.06,
          s.height * 0.24,
          s.width * 0.88,
          s.height * 0.68,
        ),
        const Radius.circular(10),
      ),
      stroke,
    );
    canvas.drawPath(
      Path()
        ..moveTo(s.width * 0.43, s.height * 0.44)
        ..lineTo(s.width * 0.62, s.height * 0.58)
        ..lineTo(s.width * 0.43, s.height * 0.72)
        ..close(),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FolderIconPainter extends CustomPainter {
  final Color color;
  const _FolderIconPainter(this.color);

  @override
  void paint(Canvas canvas, Size s) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()
        ..moveTo(s.width * 0.08, s.height * 0.28)
        ..lineTo(s.width * 0.38, s.height * 0.28)
        ..lineTo(s.width * 0.46, s.height * 0.38)
        ..lineTo(s.width * 0.92, s.height * 0.38)
        ..lineTo(s.width * 0.92, s.height * 0.86)
        ..lineTo(s.width * 0.08, s.height * 0.86)
        ..close(),
      stroke,
    );
    canvas.drawPath(
      Path()
        ..moveTo(s.width * 0.43, s.height * 0.5)
        ..lineTo(s.width * 0.62, s.height * 0.63)
        ..lineTo(s.width * 0.43, s.height * 0.76)
        ..close(),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StadiumPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final arc = Paint()
      ..color = Colors.white.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (int i = 0; i < 4; i++) {
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(s.width * 0.92, s.height * 0.55),
          width: s.width * (0.45 + i * 0.12),
          height: s.height * (0.7 + i * 0.22),
        ),
        math.pi * 0.55,
        math.pi * 0.75,
        false,
        arc,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ReelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final c = Offset(s.width * 0.84, s.height * 0.46);
    final r = s.height * 0.35;
    canvas.drawCircle(
      c,
      r,
      Paint()..color = Colors.white.withValues(alpha: 0.18),
    );
    for (int i = 0; i < 6; i++) {
      final a = i * math.pi / 3;
      canvas.drawCircle(
        Offset(c.dx + math.cos(a) * r * 0.55, c.dy + math.sin(a) * r * 0.55),
        r * 0.2,
        Paint()..color = const Color(0xFF231338),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}






class _DirectSearchTvPlayerPage extends StatefulWidget {
  const _DirectSearchTvPlayerPage({
    required this.initialChannel,
    required this.allChannels,
  });

  final Channel initialChannel;
  final List<Channel> allChannels;

  @override
  State<_DirectSearchTvPlayerPage> createState() =>
      _DirectSearchTvPlayerPageState();
}

class _DirectSearchTvPlayerPageState extends State<_DirectSearchTvPlayerPage> {
  late Channel _current;
  BoxFit _fit = BoxFit.contain;

  @override
  void initState() {
    super.initState();
    _current = widget.initialChannel;
  }

  void _stepChannel(int delta) {
    if (widget.allChannels.isEmpty) return;
    final idx = widget.allChannels.indexWhere((c) => c.id == _current.id);
    final nextIdx = ((idx < 0 ? 0 : idx) + delta) % widget.allChannels.length;
    setState(() {
      _current = widget.allChannels[nextIdx < 0 ? widget.allChannels.length - 1 : nextIdx];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          LiveTvPlayer(
            channel: _current,
            fullscreen: true,
            videoFit: _fit,
            onFitFillToggle: () {
              setState(() {
                _fit = _fit == BoxFit.contain ? BoxFit.cover : BoxFit.contain;
              });
            },
          ),
          Positioned(
            top: 14,
            left: 14,
            right: 14,
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                    ),
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(
                      'CH ${_current.channelNumber} • ${_current.name}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    style: IconButton.styleFrom(backgroundColor: Colors.black54),
                    tooltip: 'Previous Channel',
                    onPressed: () => _stepChannel(-1),
                    icon: const Icon(Icons.skip_previous_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    style: IconButton.styleFrom(backgroundColor: Colors.black54),
                    tooltip: 'Next Channel',
                    onPressed: () => _stepChannel(1),
                    icon: const Icon(Icons.skip_next_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RealTimeUniversalSearchBody extends StatefulWidget {
  const _RealTimeUniversalSearchBody({
    required this.database,
    required this.onClose,
    required this.onPlayChannel,
    required this.onPlayVideo,
    required this.onOpenFile,
    required this.onOpenWebx,
    required this.onOpenSettingCategory,
  });

  final AppDatabase database;
  final VoidCallback onClose;
  final void Function(Channel, List<Channel>) onPlayChannel;
  final void Function(MediaFile, List<MediaFile>) onPlayVideo;
  final ValueChanged<FileSystemEntity> onOpenFile;
  final ValueChanged<String> onOpenWebx;
  final ValueChanged<String> onOpenSettingCategory;

  @override
  State<_RealTimeUniversalSearchBody> createState() =>
      _RealTimeUniversalSearchBodyState();
}

class _RealTimeUniversalSearchBodyState
    extends State<_RealTimeUniversalSearchBody> {
  static const _accent = Color(0xFF38BDF8);
  final TextEditingController _ctrl = TextEditingController();
  final SpeechToText _speech = SpeechToText();

  String _filter = 'All';
  String _query = '';
  bool _isListening = false;

  List<Channel> _channels = [];
  List<MediaFile> _videos = [];
  List<FileSystemEntity> _files = [];
  bool _loading = true;

  static const List<(String, String, IconData)> _liveSettings = [
    ('Playlist Management', 'Playlist Management', Icons.playlist_play_rounded),
    ('Android TV interface', 'Display & Interface', Icons.tv_rounded),
    ('App Theme', 'Display & Interface', Icons.palette_rounded),
    ('Ambient Wallpaper', 'Display & Interface', Icons.auto_awesome_mosaic_rounded),
    ('Ambient Idle Timer', 'Display & Interface', Icons.timer_outlined),
    ('Video thumbnails', 'Display & Interface', Icons.image_outlined),
    ('Sleep timer', 'Display & Interface', Icons.bedtime_rounded),
    ('Hardware Acceleration', 'Video & Playback', Icons.speed_rounded),
    ('Default aspect ratio', 'Video & Playback', Icons.aspect_ratio_rounded),
    ('Low-data & fast stream lock', 'Video & Playback', Icons.bolt_rounded),
    ('Background/PiP mode', 'Video & Playback', Icons.picture_in_picture_alt_rounded),
    ('Show seen video marker', 'Video & Playback', Icons.check_circle_outline_rounded),
    ('Digital audio output (passthrough)', 'Audio & Subtitles', Icons.speaker_group_rounded),
    ('Default audio boost', 'Audio & Subtitles', Icons.volume_up_rounded),
    ('Preferred audio language', 'Audio & Subtitles', Icons.record_voice_over_rounded),
    ('Auto load subtitles', 'Audio & Subtitles', Icons.subtitles_rounded),
    ('Subtitles Size', 'Audio & Subtitles', Icons.format_size_rounded),
    ('Subtitles Color', 'Audio & Subtitles', Icons.palette_outlined),
    ('Auto rescan', 'Media Hub & Storage', Icons.sync_rounded),
    ('Show hidden files', 'Media Hub & Storage', Icons.folder_off_outlined),
    ('Media library folders', 'Media Hub & Storage', Icons.create_new_folder_rounded),
    ('Clear media database', 'Media Hub & Storage', Icons.cleaning_services_rounded),
    ('Playback history', 'History & Privacy', Icons.history_rounded),
    ('Incognito mode', 'History & Privacy', Icons.visibility_off_outlined),
    ('Clear playback history', 'History & Privacy', Icons.delete_sweep_rounded),
    ('Network caching value', 'System & Advanced', Icons.network_check_rounded),
    ('HTTP user agent', 'System & Advanced', Icons.dns_rounded),
    ('Export settings', 'System & Advanced', Icons.upload_file_rounded),
    ('Restore settings', 'System & Advanced', Icons.settings_backup_restore_rounded),
    ('Clear app data', 'System & Advanced', Icons.restore_page_rounded),
    ('About Orixon', 'About', Icons.info_outline_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _loadRealTimeData();
  }

  @override
  void dispose() {
    _speech.stop();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _loadRealTimeData() async {
    try {
      final chRows = await widget.database.select(widget.database.channels).get();
      final vidRows = await widget.database.select(widget.database.mediaFiles).get();
      final foundFiles = <FileSystemEntity>[];
      for (final pStr in ['/storage/emulated/0/Download', '/storage/emulated/0/Movies']) {
        final d = Directory(pStr);
        if (d.existsSync()) {
          try {
            foundFiles.addAll(d.listSync().take(60));
          } catch (_) {}
        }
      }
      if (!mounted) return;
      setState(() {
        _channels = chRows;
        _videos = vidRows;
        _files = foundFiles;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleVoiceSearch() async {
    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }
    try {
      final available = await _speech.initialize(
        onStatus: (status) {
          if ((status == 'done' || status == 'notListening') && mounted) {
            setState(() => _isListening = false);
          }
        },
        onError: (_) {
          if (mounted) setState(() => _isListening = false);
        },
      );
      if (!available) return;
      setState(() => _isListening = true);
      await _speech.listen(
        onResult: (res) {
          final spoken = res.recognizedWords.trim();
          if (spoken.isEmpty || !mounted) return;
          setState(() {
            _ctrl.text = spoken;
            _query = spoken;
          });
          if (res.finalResult) {
            setState(() => _isListening = false);
            _tryAutoExecuteExactMatch(spoken);
          }
        },
      );
    } catch (_) {
      if (mounted) setState(() => _isListening = false);
    }
  }

  void _tryAutoExecuteExactMatch(String rawText) {
    final clean = rawText
        .toLowerCase()
        .replaceAll(RegExp(r'^(play|open|channel|ch)\s+'), '')
        .trim();
    if (clean.isEmpty) return;

    // 1. Exact channel number match (e.g. "1" or "channel 1")
    final numVal = int.tryParse(clean);
    if (numVal != null) {
      for (final c in _channels) {
        if (c.channelNumber == numVal) {
          widget.onPlayChannel(c, _channels);
          return;
        }
      }
    }

    // 2. Exact channel name match
    for (final c in _channels) {
      if (c.name.toLowerCase().trim() == clean) {
        widget.onPlayChannel(c, _channels);
        return;
      }
    }

    // 3. Single unambiguous channel match
    final chMatches = _channels.where((c) => c.name.toLowerCase().contains(clean)).toList();
    if (chMatches.length == 1) {
      widget.onPlayChannel(chMatches.first, _channels);
      return;
    }

    // 4. Exact or single video match
    final vidMatches = _videos.where((v) => v.fileName.toLowerCase().contains(clean)).toList();
    if (vidMatches.length == 1) {
      widget.onPlayVideo(vidMatches.first, _videos);
      return;
    }

    // 5. Exact setting match
    for (final s in _liveSettings) {
      if (s.$1.toLowerCase() == clean || s.$2.toLowerCase() == clean) {
        widget.onOpenSettingCategory(s.$2);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final hasQuery = q.isNotEmpty;

    // ONLY compute suggestions when the user has typed or spoken something (hasQuery == true)!
    final List<Channel> matchedChannels;
    if (hasQuery && (_filter == 'All' || _filter == 'TV')) {
      final list = _channels
          .where((c) =>
              c.channelNumber.toString() == q ||
              c.channelNumber.toString().startsWith(q) ||
              c.name.toLowerCase().contains(q))
          .toList();
      list.sort((a, b) {
        final aExactNum = a.channelNumber.toString() == q ? 0 : 1;
        final bExactNum = b.channelNumber.toString() == q ? 0 : 1;
        if (aExactNum != bExactNum) return aExactNum.compareTo(bExactNum);
        final aStarts = a.name.toLowerCase().startsWith(q) ? 0 : 1;
        final bStarts = b.name.toLowerCase().startsWith(q) ? 0 : 1;
        if (aStarts != bStarts) return aStarts.compareTo(bStarts);
        return a.channelNumber.compareTo(b.channelNumber);
      });
      matchedChannels = list.take(25).toList();
    } else {
      matchedChannels = const <Channel>[];
    }

    final matchedVideos = (hasQuery && (_filter == 'All' || _filter == 'Media Hub'))
        ? _videos
            .where((v) =>
                v.fileName.toLowerCase().contains(q) ||
                v.folderName.toLowerCase().contains(q))
            .take(20)
            .toList()
        : const <MediaFile>[];

    final matchedFiles = (hasQuery && (_filter == 'All' || _filter == 'File Hub'))
        ? _files
            .where((f) {
              final name = f.path.split('/').last.toLowerCase();
              return !name.startsWith('.') && name.contains(q);
            })
            .take(15)
            .toList()
        : const <FileSystemEntity>[];

    final matchedSettings = (hasQuery && (_filter == 'All' || _filter == 'Settings'))
        ? _liveSettings
            .where((s) =>
                s.$1.toLowerCase().contains(q) ||
                s.$2.toLowerCase().contains(q))
            .toList()
        : const <(String, String, IconData)>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Search Input + Voice Mic + Close Button
        Row(
          children: [
            Expanded(
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF0E1B31),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: _isListening ? Colors.redAccent : _accent.withValues(alpha: 0.55),
                    width: 1.3,
                  ),
                ),
                child: TextField(
                  controller: _ctrl,
                  autofocus: true,
                  onChanged: (v) => setState(() => _query = v),
                  onSubmitted: (v) {
                    if (matchedChannels.isNotEmpty &&
                        (matchedChannels.first.channelNumber.toString() == q ||
                            matchedChannels.first.name.toLowerCase() == q)) {
                      widget.onPlayChannel(matchedChannels.first, _channels);
                    } else if (_filter == 'WebX' && v.trim().isNotEmpty) {
                      widget.onOpenWebx(v);
                    } else {
                      _tryAutoExecuteExactMatch(v);
                    }
                  },
                  style: const TextStyle(color: Colors.white, fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: _isListening
                        ? 'Listening... Speak channel number, name or video'
                        : 'Type channel number (e.g. 1), channel name, video, file or setting...',
                    hintStyle: TextStyle(
                      color: _isListening ? Colors.redAccent : Colors.white38,
                      fontSize: 12.5,
                    ),
                    prefixIcon: const Icon(Icons.search_rounded, color: _accent, size: 19),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_query.isNotEmpty)
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            onPressed: () {
                              _ctrl.clear();
                              setState(() => _query = '');
                            },
                            icon: const Icon(Icons.close_rounded, size: 16, color: Colors.white54),
                          ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          tooltip: 'Voice Search',
                          onPressed: _toggleVoiceSearch,
                          icon: Icon(
                            _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                            size: 19,
                            color: _isListening ? Colors.redAccent : _accent,
                          ),
                        ),
                      ],
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: widget.onClose,
              icon: const Icon(Icons.close_rounded, color: Colors.white70),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Filter Chips: All | TV | Media Hub | File Hub | WebX | Settings
        SizedBox(
          height: 30,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final fName in const ['All', 'TV', 'Media Hub', 'File Hub', 'WebX', 'Settings'])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    selected: _filter == fName,
                    selectedColor: _accent.withValues(alpha: 0.24),
                    backgroundColor: const Color(0xFF0D1729),
                    side: BorderSide(
                      color: _filter == fName ? _accent : Colors.white12,
                    ),
                    label: Text(
                      fName,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: _filter == fName ? _accent : Colors.white70,
                      ),
                    ),
                    onSelected: (_) => setState(() => _filter = fName),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Divider(height: 1, color: Colors.white10),
        const SizedBox(height: 6),

        // Suggestions Area (Empty until user types!)
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: _accent))
              : !hasQuery
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isListening ? Icons.graphic_eq_rounded : Icons.manage_search_rounded,
                            size: 42,
                            color: _isListening ? Colors.redAccent : Colors.white24,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _isListening
                                ? 'Speak now — Exact match will play automatically!'
                                : 'Type to see live suggestions for $_filter',
                            style: const TextStyle(color: Colors.white54, fontSize: 12.5),
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      children: [
                        for (final ch in matchedChannels)
                          ListTile(
                            dense: true,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            leading: const Icon(Icons.live_tv_rounded, color: _accent, size: 20),
                            title: Text(
                              'CH ${ch.channelNumber} • ${ch.name}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: const Text(
                              'Tap to play Live TV channel immediately',
                              style: TextStyle(color: Colors.white54, fontSize: 11),
                            ),
                            trailing: const Icon(Icons.play_circle_fill_rounded, color: _accent, size: 22),
                            onTap: () => widget.onPlayChannel(ch, _channels),
                          ),

                        for (final v in matchedVideos)
                          ListTile(
                            dense: true,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            leading: const Icon(Icons.movie_creation_outlined, color: Color(0xFFD552FF), size: 20),
                            title: Text(
                              v.fileName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: Text(
                              'Media Hub • ${v.folderName}',
                              style: const TextStyle(color: Colors.white54, fontSize: 11),
                            ),
                            trailing: const Icon(Icons.play_circle_fill_rounded, color: Color(0xFFD552FF), size: 22),
                            onTap: () => widget.onPlayVideo(v, _videos),
                          ),

                        for (final f in matchedFiles)
                          ListTile(
                            dense: true,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            leading: const Icon(Icons.folder_open_rounded, color: Color(0xFF34D399), size: 20),
                            title: Text(
                              f.path.split('/').last,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              'File Hub • ${f.path}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white54, fontSize: 11),
                            ),
                            trailing: const Icon(Icons.open_in_new_rounded, color: Color(0xFF34D399), size: 18),
                            onTap: () => widget.onOpenFile(f),
                          ),

                        for (final s in matchedSettings)
                          ListTile(
                            dense: true,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            leading: Icon(s.$3, color: const Color(0xFFF59E0B), size: 20),
                            title: Text(
                              s.$1,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              'Settings • ${s.$2}',
                              style: const TextStyle(color: Colors.white54, fontSize: 11),
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white54, size: 18),
                            onTap: () => widget.onOpenSettingCategory(s.$2),
                          ),

                        if (_filter == 'All' || _filter == 'WebX') ...[
                          ListTile(
                            dense: true,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            tileColor: const Color(0xFF38BDF8).withValues(alpha: 0.12),
                            leading: const Icon(Icons.language_rounded, color: Color(0xFF38BDF8), size: 20),
                            title: Text(
                              _query.contains('.')
                                  ? 'Open Website "${_query.trim()}"'
                                  : 'Open Website "https://${_query.trim().toLowerCase().replaceAll(' ', '')}.com"',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: const Text(
                              'Tap to open website directly in WebX Browser',
                              style: TextStyle(color: Colors.white54, fontSize: 11),
                            ),
                            trailing: const Icon(Icons.open_in_new_rounded, color: Color(0xFF38BDF8), size: 18),
                            onTap: () {
                              final raw = _query.trim();
                              final site = raw.contains('.')
                                  ? raw
                                  : 'https://${raw.toLowerCase().replaceAll(' ', '')}.com';
                              widget.onOpenWebx(site);
                            },
                          ),
                          const SizedBox(height: 4),
                          ListTile(
                            dense: true,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            tileColor: const Color(0xFFDE5833).withValues(alpha: 0.12),
                            leading: const Icon(Icons.shield_rounded, color: Color(0xFFDE5833), size: 20),
                            title: Text(
                              'Search DuckDuckGo for "$_query"',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: const Text(
                              'Tap to view web search results in WebX Browser',
                              style: TextStyle(color: Colors.white54, fontSize: 11),
                            ),
                            trailing: const Icon(Icons.arrow_forward_rounded, color: Color(0xFFDE5833), size: 18),
                            onTap: () => widget.onOpenWebx(_query),
                          ),
                        ],
                      ],
                    ),
        ),
      ],
    );
  }
}
