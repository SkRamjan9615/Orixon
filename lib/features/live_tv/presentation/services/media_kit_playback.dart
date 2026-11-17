import 'dart:io';
import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import 'live_tv_playback.dart';

typedef LiveTvPlaybackFactory = LiveTvPlayback Function();

class MediaKitPlayback implements LiveTvPlayback {
  MediaKitPlayback() {
    MediaKit.ensureInitialized();
    _player = Player(
      configuration: const PlayerConfiguration(
        bufferSize: 128 * 1024 * 1024,
        protocolWhitelist: [
          'file', 'rtp', 'udp', 'tcp', 'tls', 'crypto',
          'http', 'https', 'hls', 'applehttp', 'rtmp', 'rtsp', 'mmsh', 'data',
        ],
      ),
    );
    _controller = VideoController(
      _player,
      configuration: const VideoControllerConfiguration(
        enableHardwareAcceleration: true,
      ),
    );
    _configureMpv();

    _subs.add(
      _player.stream.playing.listen((playing) {
        if (!playing) {
          _playingCtrl.add(false);
        } else if (_locked) {
          _playingCtrl.add(true);
        }
      }),
    );

    _subs.add(
      _player.stream.position.listen((pos) {
        if (pos > const Duration(milliseconds: 80)) {
          _markRealPlaybackStarted();
        }
        _positionsCtrl.add(pos);
      }),
    );

    _subs.add(
      _player.stream.videoParams.listen((params) {
        if ((params.w != null && params.w! > 0) ||
            (params.dw != null && params.dw! > 0)) {
          _markRealPlaybackStarted();
        }
      }),
    );

    _subs.add(
      _player.stream.tracks.listen((tracks) {
        // When real video or audio tracks (> 2) are parsed, the stream is ALIVE!
        // Cancel dead-channel timer so slow networks can buffer as long as needed!
        if (tracks.video.length > 2 || tracks.audio.length > 2) {
          _streamHasTracks = true;
          _deadCheckTimer?.cancel();
        }
      }),
    );

    _subs.add(
      _player.stream.buffering.listen((buffering) {
        if (buffering) {
          // Stream is actively buffering data on a slow network -> extend timer!
          _extendTimerForSlowNetwork();
        }
      }),
    );

    _subs.add(
      _player.stream.log.listen((log) {
        final msg = '${log.prefix}: ${log.text}';
        _logsCtrl.add(msg);
        if (_locked || _streamHasTracks) return;
        final lower = log.text.toLowerCase();
        // Only advance User-Agent stage if server explicitly rejects or stream is 404/dead
        if (lower.contains('http error 403') ||
            lower.contains('http error 401') ||
            lower.contains('http error 404') ||
            lower.contains('http error 410') ||
            lower.contains('http error 50') ||
            lower.contains('connection refused') ||
            lower.contains('name or service not known') ||
            lower.contains('failed to open')) {
          _tryNextUserAgentStage();
        }
      }),
    );

    _subs.add(
      _player.stream.error.listen((err) {
        final msg = err.trim();
        if (msg.isEmpty || _locked || _streamHasTracks) return;
        if (msg.toLowerCase().contains('abort')) return;
        _tryNextUserAgentStage();
      }),
    );
  }

  static String hwDecMode = 'auto';
  static String customUserAgent = 'Auto';
  static bool autoSkipDeadChannels = true;

  late final Player _player;
  late final VideoController _controller;
  final _errorsCtrl = StreamController<String>.broadcast();
  final _logsCtrl = StreamController<String>.broadcast();
  final _positionsCtrl = StreamController<Duration>.broadcast();
  final _playingCtrl = StreamController<bool>.broadcast();
  final _subs = <StreamSubscription<Object?>>[];

  String? _lastUrl;
  int _reqId = 0;
  int _uaStage = 0;
  bool _locked = false;
  bool _streamHasTracks = false;
  bool _switchingStage = false;
  Timer? _deadCheckTimer;

  static const List<String> _uaProfiles = [
    'VLC/3.0.20 LibVLC/3.0.20',
    'plaYtv/7.0.5 (Linux;Android 13) ExoPlayerLib/2.11.7',
    'TiviMate/4.7.0 (Linux; Android 13)',
    'OTTV/1.7.1 (Linux; Android 13) ExoPlayerLib/2.19.1',
  ];

  static String resolveUaString(String label) {
    if (label.startsWith('VLC')) return 'VLC/3.0.20 LibVLC/3.0.20';
    if (label.startsWith('TiviMate')) return 'TiviMate/4.7.0 (Linux; Android 13)';
    if (label.startsWith('OTTV')) return 'OTTV/1.7.1 (Linux; Android 13) ExoPlayerLib/2.19.1';
    if (label.startsWith('plaYtv')) return 'plaYtv/7.0.5 (Linux;Android 13) ExoPlayerLib/2.11.7';
    if (label.startsWith('IPTVSmarters')) return 'IPTVSmartersPlayer';
    if (label.startsWith('ExoPlayer')) return 'ExoPlayerLib/2.19.1 (Linux; Android 13; Android TV)';
    if (label.startsWith('Mozilla')) return 'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36';
    if (label.startsWith('Lavf')) return 'Lavf/60.16.100';
    if (label == 'Orixon') return 'Orixon/5.0 (Smart TV; Android 14)';
    return 'VLC/3.0.20 LibVLC/3.0.20';
  }

  void _markRealPlaybackStarted() {
    if (_locked) return;
    _locked = true;
    _streamHasTracks = true;
    _deadCheckTimer?.cancel();
    _playingCtrl.add(true);
  }

  void _extendTimerForSlowNetwork() {
    if (_locked || _streamHasTracks) return;
    final id = _reqId;
    _deadCheckTimer?.cancel();
    _deadCheckTimer = Timer(const Duration(seconds: 12), () {
      if (id == _reqId && !_locked && !_streamHasTracks) {
        _tryNextUserAgentStage();
      }
    });
  }

  Future<void> _configureMpv() async {
    final dynamic native = _player.platform;
    if (native == null) return;
    final props = <String, String>{
      'hwdec': hwDecMode,
      'hwdec-codecs': 'all',
      'gpu-context': 'android',
      'vd-lavc-dr': 'yes',
      'vd-lavc-fast': 'yes',
      'vd-lavc-skiploopfilter': 'nonref',
      'vd-lavc-threads': '0',
      // 128 MB Background Pre-Load Cache + Low-Bitrate Start for Slow Networks
      'cache': 'yes',
      'cache-secs': '60',
      'demuxer-max-bytes': '134217728',
      'demuxer-max-back-bytes': '33554432',
      'demuxer-readahead-secs': '30',
      'cache-pause': 'no',
      'cache-pause-initial': 'no',
      // Start with lowest bitrate variant on slow networks so it opens fast, then scales
      'hls-bitrate': 'min',
      'framedrop': 'vo',
      'video-sync': 'audio',
      'audio-stream-silence': 'yes',
      'volume-max': '200',
      'ad-lavc-downmix': 'no',
      'audio-channels': 'auto-safe',
      'audio-spdif': 'ac3,eac3,dts,dts-hd,truehd',
      'network-timeout': '15',
      'tls-verify': 'no',
      'http-header-fields': 'Connection: keep-alive',
      'demuxer-lavf-o':
          'reconnect=1,reconnect_streamed=1,reconnect_on_network_error=1,reconnect_delay_max=3',
      'demuxer-lavf-analyzeduration': '0.25',
      'demuxer-lavf-probesize': '65536',
    };
    for (final e in props.entries) {
      try {
        await native.setProperty(e.key, e.value);
      } catch (_) {}
    }
  }

  @override
  Stream<String> get errors => _errorsCtrl.stream;
  @override
  Stream<String> get logs => _logsCtrl.stream;
  @override
  Stream<Duration> get positions => _positionsCtrl.stream;
  @override
  Stream<bool> get playing => _playingCtrl.stream;

  @override
  Future<void> open(String url) async {
    final clean = url.trim();
    if (clean.isEmpty) {
      _errorsCtrl.add('DEAD_CHANNEL');
      return;
    }
    _reqId++;
    final id = _reqId;
    _lastUrl = clean;
    _uaStage = 0;
    _locked = false;
    _streamHasTracks = false;
    _switchingStage = false;
    _deadCheckTimer?.cancel();
    _playingCtrl.add(false);

    await _openWithStage(id, 0);
  }

  Future<String?> _resolveHexClearKey(String rawKey, String ua) async {
    var trimmed = rawKey.trim();
    if (trimmed.isEmpty) return null;

    // If license_key is an HTTP/HTTPS URL returning ClearKey JSON, fetch it!
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 4)
        ..badCertificateCallback = (_, _, _) => true;
      try {
        final req = await client.getUrl(Uri.parse(trimmed));
        req.headers.set('User-Agent', ua);
        final resp = await req.close().timeout(const Duration(seconds: 4));
        if (resp.statusCode >= 200 && resp.statusCode < 300) {
          final body = await resp.transform(utf8.decoder).join();
          trimmed = body.trim();
        }
      } catch (_) {
      } finally {
        client.close(force: true);
      }
    }

    // Case 1: hex kid:key (or multiple separated by comma)
    final firstPair = trimmed.split(',').first.trim();
    if (firstPair.contains(':') && !firstPair.startsWith('{') && !firstPair.startsWith('http')) {
      final parts = firstPair.split(':');
      final candidate = parts.last.trim().replaceAll('-', '');
      if (RegExp(r'^[0-9a-fA-F]{32}$').hasMatch(candidate)) {
        return candidate.toLowerCase();
      }
    }

    // Case 2: Base64-encoded JSON {"keys":[...]}
    if (!trimmed.startsWith('{') && !trimmed.contains(':')) {
      try {
        final decodedText = utf8.decode(base64Url.decode(base64Url.normalize(trimmed)));
        if (decodedText.trim().startsWith('{')) trimmed = decodedText.trim();
      } catch (_) {}
    }

    // Case 3: JSON ClearKey {"keys":[{"kty":"oct","k":"base64url","kid":"base64url"}]}
    if (trimmed.startsWith('{')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map && decoded['keys'] is List && (decoded['keys'] as List).isNotEmpty) {
          final firstKey = (decoded['keys'] as List).first;
          if (firstKey is Map && firstKey['k'] is String) {
            final b64 = base64Url.normalize(firstKey['k'] as String);
            final bytes = base64Url.decode(b64);
            return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
          }
        }
      } catch (_) {}
    }

    final cleanHex = trimmed.replaceAll('-', '');
    if (RegExp(r'^[0-9a-fA-F]{32}$').hasMatch(cleanHex)) {
      return cleanHex.toLowerCase();
    }
    return null;
  }


  Future<void> _openWithStage(int id, int stage) async {
    if (id != _reqId || _lastUrl == null) return;
    _deadCheckTimer?.cancel();

    final rawUrl = _lastUrl!;
    final pipeIdx = rawUrl.indexOf('|');
    final cleanUrl = (pipeIdx >= 0 ? rawUrl.substring(0, pipeIdx) : rawUrl).trim();
    final extraParams = <String, String>{};
    if (pipeIdx >= 0) {
      final tail = rawUrl.substring(pipeIdx + 1).trim();
      for (final part in tail.split('&')) {
        final eq = part.indexOf('=');
        if (eq > 0) {
          final k = part.substring(0, eq).trim();
          final v = Uri.decodeComponent(part.substring(eq + 1).trim());
          extraParams[k] = v;
        }
      }
    }

    final isAuto = customUserAgent.startsWith('Auto');
    final defaultUa = isAuto
        ? _uaProfiles[stage % _uaProfiles.length]
        : resolveUaString(customUserAgent);
    final ua = (stage == 0 && extraParams['User-Agent']?.isNotEmpty == true)
        ? extraParams['User-Agent']!
        : defaultUa;

    final headers = <String, String>{
      'User-Agent': ua,
      'Accept': '*/*',
      'Connection': 'keep-alive',
    };
    for (final entry in extraParams.entries) {
      if (entry.key != 'Orixon-Drm-Type' &&
          entry.key != 'Orixon-Drm-Key' &&
          entry.value.isNotEmpty) {
        headers[entry.key] = entry.value;
      }
    }

    final clearKeyHex = await _resolveHexClearKey(extraParams['Orixon-Drm-Key'] ?? '', ua);

    try {
      final dynamic native = _player.platform;
      if (native != null) {
        await native.setProperty('user-agent', ua);
        await native.setProperty('hwdec', hwDecMode);
        if (clearKeyHex != null && clearKeyHex.isNotEmpty) {
          await native.setProperty('demuxer-lavf-o',
              'reconnect=1,reconnect_streamed=1,reconnect_on_network_error=1,reconnect_delay_max=3,decryption_key=$clearKeyHex');
        } else {
          await native.setProperty('demuxer-lavf-o',
              'reconnect=1,reconnect_streamed=1,reconnect_on_network_error=1,reconnect_delay_max=3');
        }
      }
    } catch (_) {}

    try {
      await _player.open(
        Media(cleanUrl, httpHeaders: headers),
        play: true,
      );
    } catch (_) {
      _tryNextUserAgentStage();
      return;
    }

    // Generous 9s window per stage if zero tracks & zero buffering occur
    _deadCheckTimer = Timer(const Duration(seconds: 9), () {
      if (id == _reqId && !_locked && !_streamHasTracks) {
        _tryNextUserAgentStage();
      }
    });
  }

  void _tryNextUserAgentStage() {
    if (_switchingStage || _locked || _streamHasTracks || _lastUrl == null) return;
    _switchingStage = true;
    final id = _reqId;
    final maxStages = customUserAgent.startsWith('Auto') ? 2 : 1;
    if (_uaStage + 1 < maxStages) {
      _uaStage++;
      Future<void>.delayed(const Duration(milliseconds: 120), () {
        _switchingStage = false;
        if (id == _reqId && !_locked && !_streamHasTracks) {
          _openWithStage(id, _uaStage);
        }
      });
    } else {
      _switchingStage = false;
      _deadCheckTimer?.cancel();
      _errorsCtrl.add('DEAD_CHANNEL');
    }
  }

  @override
  Future<void> play() => _player.play();
  @override
  Future<void> pause() => _player.pause();
  @override
  Future<void> stop() async {
    _reqId++;
    _deadCheckTimer?.cancel();
    await _player.stop();
  }

  @override
  Widget buildVideo({
    List<Widget> topButtonBar = const [],
    List<Widget> primaryButtonBar = const [],
    BoxFit fit = BoxFit.contain,
    int controlsRevision = 0,
  }) {
    return Video(
      controller: _controller,
      fit: fit,
      controls: NoVideoControls,
      fill: Colors.black,
    );
  }

  @override
  Future<void> dispose() async {
    _reqId++;
    _deadCheckTimer?.cancel();
    for (final s in _subs) {
      await s.cancel();
    }
    await _errorsCtrl.close();
    await _logsCtrl.close();
    await _positionsCtrl.close();
    await _playingCtrl.close();
    await _player.dispose();
  }
}
