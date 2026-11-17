import 'dart:typed_data';
import 'dart:async';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path/path.dart' as p;

import '../../../core/database/app_database.dart';
import '../../../core/providers/app_providers.dart';

class LocalMediaPlayerScreen extends ConsumerStatefulWidget {
  const LocalMediaPlayerScreen({
    super.key,
    required this.video,
    this.playlist,
    this.initialIndex = 0,
  });

  final MediaFile video;
  final List<MediaFile>? playlist;
  final int initialIndex;

  @override
  ConsumerState<LocalMediaPlayerScreen> createState() =>
      _LocalMediaPlayerScreenState();
}

class _LocalMediaPlayerScreenState
    extends ConsumerState<LocalMediaPlayerScreen> with WidgetsBindingObserver {
  String _pipModeSetting = 'Picture-in-Picture';
  static const _accent = Color(0xFF38BDF8);
  static const MethodChannel _sysChannel =
      MethodChannel('com.example.orixon/system_tools');

  late final Player _player;
  late final VideoController _videoController;
  final GlobalKey<VideoState> _videoKey = GlobalKey<VideoState>();
  late MediaFile _currentVideo;
  int _currentIndex = 0;
  bool _isSwitching = false;

  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<bool>? _playingSubscription;
  StreamSubscription<String>? _errorSubscription;
  StreamSubscription<VideoParams>? _videoParamsSubscription;
  StreamSubscription<Tracks>? _tracksSubscription;
  Timer? _hideControlsTimer;
  Timer? _hudTimer;
  Timer? _vrGyroTimer;
  Timer? _sleepTimer;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  bool _isReady = false;
  String? _error;

  int _lastSavedPositionMs = -1;
  bool _hasSuccessfulLoad = false;

  bool _showControls = true;
  bool _isDraggingSlider = false;
  bool _isHoldSlideSeeking = false;
  String _panMode = 'none';
  double _panStartX = 0.0;
  double _panStartY = 0.0;
  int _panStartPosMs = 0;
  double _holdStartX = 0.0;
  int _holdStartPosMs = 0;
  int _seekOriginPosMs = 0;
  Uint8List? _seekPreviewBytes;
  int _lastThumbReqEpochMs = 0;
  int _lastLiveScrubEpochMs = 0;
  bool _thumbBusy = false;
  Tracks _tracks = const Tracks();
  double _playbackSpeed = 1.0;
  double _savedSpeedBeforeHold = 1.0;
  bool _isHolding2x = false;

  double _volume = 100.0;
  double _brightness = 100.0;
  bool _isMuted = false;
  bool _isLocked = false;
  int _fitIndex = 0;

  bool _incognitoMode = false;
  bool _autoLoadSubtitles = true;
  double _subtitleFontSize = 22.0;
  Color _subtitleColor = Colors.white;

  String? _activeSideIndicator;
  double _sideIndicatorValue = 100.0;

  // HDR mode: 0 = Off, 1 = HDR10 Vivid, 2 = Cinema Warm HDR
  int _hdrMode = 0;
  static const List<String> _hdrLabels = ['HDR', 'HDR10', 'HDR+'];

  // VR mode: 0 = Off, 1 = VR 360 Sphere, 2 = VR 3D Headset (Side-by-Side)
  int _vrMode = 0;
  static const List<String> _vrLabels = ['VR', 'VR 360°', '3D Headset'];
  double _vrYaw = 0.0;
  double _vrPitch = 0.0;
  double _gyroYaw = 0.0;
  double _gyroPitch = 0.0;

  static const List<double> _hdr10VividMatrix = [
    1.22, -0.08, -0.04, 0, -8,
    -0.04, 1.18, -0.04, 0, -8,
    -0.04, -0.08, 1.26, 0, -8,
    0, 0, 0, 1, 0,
  ];

  static const List<double> _hdrCinemaMatrix = [
    1.16, -0.04, -0.02, 0, -5,
    -0.02, 1.12, -0.02, 0, -5,
    -0.04, -0.06, 1.08, 0, -5,
    0, 0, 0, 1, 0,
  ];

  static const List<(String, BoxFit)> _fitModes = [
    ('Fit', BoxFit.contain),
    ('Crop / Fill', BoxFit.cover),
    ('Stretch', BoxFit.fill),
  ];

  static const List<double> _speedOptions = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final playlist = widget.playlist;
    _currentIndex = playlist == null || playlist.isEmpty
        ? 0
        : widget.initialIndex.clamp(0, playlist.length - 1).toInt();
    _currentVideo = playlist == null || playlist.isEmpty
        ? widget.video
        : playlist[_currentIndex];

    _player = Player(
      configuration: const PlayerConfiguration(logLevel: MPVLogLevel.warn),
    );
    _videoController = VideoController(_player);

    _configureDolbyAndAudioPassthrough();
    _initDeviceVolumeSync();
    _loadPlayerUserSettings();

    _positionSubscription = _player.stream.position.listen((position) {
      if (!mounted) return;
      if (!_isDraggingSlider) {
        setState(() => _position = position);
      }
      if (_hasSuccessfulLoad && !_isSwitching) _saveProgress();
    });

    _durationSubscription = _player.stream.duration.listen((duration) {
      if (!mounted) return;
      setState(() => _duration = duration);
    });

    _playingSubscription = _player.stream.playing.listen((playing) {
      if (!mounted) return;
      setState(() => _isPlaying = playing);
      if (playing) {
        _scheduleHideControls();
      } else {
        _hideControlsTimer?.cancel();
        setState(() => _showControls = true);
      }
    });

    _errorSubscription = _player.stream.error.listen((message) {
      if (!mounted) return;
      setState(() {
        _error = message;
        _isReady = false;
        _isPlaying = false;
        _showControls = true;
      });
    });

    _videoParamsSubscription = _player.stream.videoParams.listen((params) {
      final hasVideoDimensions =
          (params.w != null && params.w! > 0 && params.h != null && params.h! > 0) ||
          (params.dw != null && params.dw! > 0 && params.dh != null && params.dh! > 0);
      if (hasVideoDimensions) _markSuccessfulLoad();
    });

    _tracksSubscription = _player.stream.tracks.listen((tracks) {
      if (!mounted) return;
      setState(() => _tracks = tracks);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openVideo();
    });
  }

  Future<void> _loadPlayerUserSettings() async {
    try {
      final db = ref.read(appDatabaseProvider);
      final rows = await db.select(db.appSettings).get();
      final map = {for (final r in rows) r.key: r.value};

      _incognitoMode = map['History & Privacy::Incognito mode'] == 'true';
      _pipModeSetting = map['Video & Playback::Background/PiP mode'] ?? 'Picture-in-Picture';

      // Hardware Acceleration ('Auto' default) connected directly to libmpv hwdec
      final hw = map['Video & Playback::Hardware Acceleration'] ?? 'Auto';
      try {
        final dynamic nativePlayer = _player.platform;
        if (hw == 'Auto') {
          await nativePlayer.setProperty('hwdec', 'auto-safe');
        } else if (hw == 'Full') {
          await nativePlayer.setProperty('hwdec', 'mediacodec');
        } else {
          await nativePlayer.setProperty('hwdec', 'no');
        }
      } catch (_) {}

      final ar = map['Video & Playback::Default aspect ratio'] ?? 'Fit to Screen';
      if (ar == 'Crop / Fill') {
        _fitIndex = 1;
      } else if (ar == 'Stretch') {
        _fitIndex = 2;
      } else {
        _fitIndex = 0;
      }

      final boostStr = map['Audio & Subtitles::Default audio boost'] ?? '100% (Normal)';
      final numMatch = RegExp(r'(\d+)').firstMatch(boostStr);
      if (numMatch != null) {
        final bVal = double.tryParse(numMatch.group(1)!) ?? 100.0;
        if (bVal > 100.0) {
          _applyVolumeTotal(bVal);
        }
      }

      _autoLoadSubtitles = map['Audio & Subtitles::Auto load subtitles'] != 'false';
      final subSize = map['Audio & Subtitles::Subtitles Size'] ?? 'Normal';
      _subtitleFontSize = subSize == 'Small'
          ? 17.0
          : (subSize == 'Large' ? 27.0 : (subSize == 'Very large' ? 33.0 : 22.0));
      final subCol = map['Audio & Subtitles::Subtitles Color'] ?? 'White';
      _subtitleColor = subCol == 'Yellow'
          ? const Color(0xFFFACC15)
          : (subCol == 'Cyan'
              ? const Color(0xFF38BDF8)
              : (subCol == 'Green' ? const Color(0xFF4ADE80) : Colors.white));

      final sleepStr = map['Display & Interface::Sleep timer'] ?? 'Disabled';
      final sleepMatch = RegExp(r'(\d+)').firstMatch(sleepStr);
      if (sleepMatch != null) {
        final mins = int.tryParse(sleepMatch.group(1)!) ?? 0;
        if (mins > 0) {
          _sleepTimer?.cancel();
          _sleepTimer = Timer(Duration(minutes: mins), () {
            if (mounted && _isPlaying) {
              _player.pause();
            }
          });
        }
      }

      if (mounted) setState(() {});
    } catch (_) {}
  }

  Future<void> _configureDolbyAndAudioPassthrough() async {
    try {
      final dynamic nativePlayer = _player.platform;
      await nativePlayer.setProperty('hwdec', 'auto-safe');
      await nativePlayer.setProperty('volume-max', '200');
      await nativePlayer.setProperty('audio-channels', 'auto-safe');
      await nativePlayer.setProperty(
        'audio-spdif',
        'ac3,eac3,truehd,dts,dts-hd,mlp',
      );
      await nativePlayer.setProperty('ad-lavc-downmix', 'no');
    } catch (_) {}
  }

  Future<void> _initDeviceVolumeSync() async {
    try {
      final devVol = await _sysChannel.invokeMethod<int>('getDeviceVolumePercent');
      if (devVol != null && mounted) {
        setState(() => _volume = devVol.toDouble().clamp(0.0, 100.0));
      }
    } catch (_) {}
  }

  Future<void> _applyVolumeTotal(double newVol) async {
    final clamped = newVol.clamp(0.0, 200.0);
    setState(() {
      _volume = clamped;
      _isMuted = clamped == 0.0;
      _activeSideIndicator = 'volume';
      _sideIndicatorValue = clamped;
    });
    _hudTimer?.cancel();
    _hudTimer = Timer(const Duration(milliseconds: 1100), () {
      if (mounted) setState(() => _activeSideIndicator = null);
    });

    try {
      if (clamped <= 100.0) {
        await _sysChannel.invokeMethod('setDeviceVolumePercent', {
          'percent': clamped.round(),
        });
        await _player.setVolume(100.0);
      } else {
        await _sysChannel.invokeMethod('setDeviceVolumePercent', {
          'percent': 100,
        });
        await _player.setVolume(clamped);
      }
    } catch (_) {
      await _player.setVolume(clamped.clamp(0.0, 100.0));
    }
  }

  Future<void> _applyBrightnessTotal(double newBri) async {
    final clamped = newBri.clamp(0.0, 200.0);
    setState(() {
      _brightness = clamped;
      _activeSideIndicator = 'brightness';
      _sideIndicatorValue = clamped;
    });
    _hudTimer?.cancel();
    _hudTimer = Timer(const Duration(milliseconds: 1100), () {
      if (mounted) setState(() => _activeSideIndicator = null);
    });

    try {
      await _sysChannel.invokeMethod('setWindowBrightness', {
        'brightness': (clamped / 200.0).clamp(0.02, 1.0),
      });
    } catch (_) {}
  }

  void _cycleHdrMode() {
    _revealControlsAndResetTimer();
    setState(() {
      _hdrMode = (_hdrMode + 1) % _hdrLabels.length;
    });
  }

  void _cycleVrMode() {
    _revealControlsAndResetTimer();
    setState(() {
      _vrMode = (_vrMode + 1) % _vrLabels.length;
      if (_vrMode == 0) {
        _vrYaw = 0.0;
        _vrPitch = 0.0;
        _gyroYaw = 0.0;
        _gyroPitch = 0.0;
      }
    });
    _syncVrGyroSensor();
  }

  void _syncVrGyroSensor() {
    _vrGyroTimer?.cancel();
    if (_vrMode == 0) {
      try {
        _sysChannel.invokeMethod('stopVrGyro');
      } catch (_) {}
      return;
    }
    try {
      _sysChannel.invokeMethod('startVrGyro');
    } catch (_) {}
    _vrGyroTimer = Timer.periodic(const Duration(milliseconds: 16), (_) async {
      if (!mounted || _vrMode == 0) return;
      try {
        final res = await _sysChannel.invokeMethod<Map<Object?, Object?>>('getVrGyroAngles');
        if (res != null && mounted) {
          final yaw = (res['yaw'] as num?)?.toDouble() ?? 0.0;
          final pitch = (res['pitch'] as num?)?.toDouble() ?? 0.0;
          if ((yaw - _gyroYaw).abs() > 0.002 || (pitch - _gyroPitch).abs() > 0.002) {
            setState(() {
              _gyroYaw = yaw;
              _gyroPitch = pitch;
            });
          }
        }
      } catch (_) {}
    });
  }


  void _updateLiveSeekPreview(int targetMs) {
    final maxMs = _duration.inMilliseconds;
    final clampedMs = targetMs.clamp(0, maxMs > 0 ? maxMs : 0);
    setState(() {
      _position = Duration(milliseconds: clampedMs);
    });

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (!_thumbBusy && (nowMs - _lastThumbReqEpochMs > 90)) {
      _lastThumbReqEpochMs = nowMs;
      _thumbBusy = true;
      const MethodChannel('com.example.orixon/local_media')
          .invokeMethod<Uint8List>(
            'getVideoThumbnail',
            <String, dynamic>{
              'uri': _currentVideo.filePath,
              'maxWidth': 240,
              'maxHeight': 135,
              'timeMs': clampedMs,
            },
          )
          .then((bytes) {
            _thumbBusy = false;
            if (mounted &&
                bytes != null &&
                bytes.isNotEmpty &&
                (_isDraggingSlider || _isHoldSlideSeeking)) {
              setState(() => _seekPreviewBytes = bytes);
            }
          })
          .catchError((_) {
            _thumbBusy = false;
          });
    }
  }

  Widget _buildLiveSeekPreviewOverlay() {
    final deltaSec = ((_position.inMilliseconds - _seekOriginPosMs) / 1000).round();
    final deltaStr = deltaSec >= 0 ? '+${deltaSec}s' : '${deltaSec}s';
    return Positioned(
      left: 0,
      right: 0,
      bottom: 92,
      child: IgnorePointer(
        child: Center(
          child: Container(
            width: 176,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF07101E).withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _accent.withValues(alpha: 0.75), width: 1.4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.65),
                  blurRadius: 16,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: SizedBox(
                    width: 164,
                    height: 92,
                    child: _seekPreviewBytes != null && _seekPreviewBytes!.isNotEmpty
                        ? Image.memory(
                            _seekPreviewBytes!,
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                          )
                        : Container(
                            color: const Color(0xFF0E1B31),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.fast_forward_rounded,
                              color: _accent,
                              size: 28,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _formatTime(_position),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        deltaStr,
                        style: const TextStyle(
                          color: _accent,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
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
    );
  }

  void _scheduleHideControls() {
    _hideControlsTimer?.cancel();
    if (!_isPlaying || _isDraggingSlider) return;
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _isPlaying && !_isDraggingSlider) {
        setState(() => _showControls = false);
      }
    });
  }

  void _revealControlsAndResetTimer() {
    if (!_showControls) {
      setState(() => _showControls = true);
    }
    _scheduleHideControls();
  }

  void _toggleControlsVisibility() {
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      _scheduleHideControls();
    } else {
      _hideControlsTimer?.cancel();
    }
  }


  Future<void> _triggerPipMode() async {
    setState(() => _showControls = false);
    try {
      await _sysChannel.invokeMethod('enterPipMode');
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      if (_pipModeSetting == 'Disabled' && _isPlaying) {
        _player.pause();
      } else if (_pipModeSetting == 'Picture-in-Picture' &&
          _isPlaying &&
          state == AppLifecycleState.inactive) {
        _triggerPipMode();
      }
    }
  }

  Future<void> _openVideo() async {
    if (!mounted) return;

    var startPosition = Duration.zero;
    final savedMs = _currentVideo.lastPositionMs;
    if (savedMs > 2000 &&
        (_currentVideo.durationMs == 0 || savedMs < _currentVideo.durationMs - 3000)) {
      startPosition = Duration(milliseconds: savedMs);
    }

    try {
      _lastSavedPositionMs = startPosition.inMilliseconds;
      setState(() {
        _position = startPosition;
        _isReady = false;
        _showControls = true;
      });

      await _player.open(Media(_currentVideo.filePath, start: startPosition));

      if (_autoLoadSubtitles && !_currentVideo.filePath.startsWith('content://')) {
        try {
          final baseNoExt = p.withoutExtension(_currentVideo.filePath);
          for (final ext in ['.srt', '.vtt', '.ass']) {
            final subFile = File('$baseNoExt$ext');
            if (subFile.existsSync()) {
              await _player.setSubtitleTrack(SubtitleTrack.uri(subFile.path));
              break;
            }
          }
        } catch (_) {}
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isReady = false;
        _isPlaying = false;
        _showControls = true;
      });
    }
  }

  bool get _hasPreviousVideo => widget.playlist != null && _currentIndex > 0;

  bool get _hasNextVideo =>
      widget.playlist != null && _currentIndex < widget.playlist!.length - 1;

  Future<void> _changeVideo(int nextIndex) async {
    final queue = widget.playlist;
    if (_isSwitching ||
        queue == null ||
        nextIndex < 0 ||
        nextIndex >= queue.length ||
        nextIndex == _currentIndex) {
      return;
    }

    setState(() => _isSwitching = true);
    try {
      await _player.pause();
      await _saveProgress(force: true);
      await _player.stop();
      if (!mounted) return;

      _hasSuccessfulLoad = false;
      _lastSavedPositionMs = -1;
      _currentIndex = nextIndex;
      _currentVideo = queue[nextIndex];

      setState(() {
        _position = Duration.zero;
        _duration = Duration.zero;
        _isReady = false;
        _isPlaying = false;
        _error = null;
        _showControls = true;
      });

      await _openVideo();
    } finally {
      if (mounted) setState(() => _isSwitching = false);
    }
  }

  void _markSuccessfulLoad() {
    if (_hasSuccessfulLoad || !mounted || _error != null) return;
    setState(() {
      _hasSuccessfulLoad = true;
      _isReady = true;
    });
    _scheduleHideControls();
    unawaited(_saveProgress(force: true));
  }

  Future<void> _saveProgress({bool force = false}) async {
    if (_incognitoMode || !_hasSuccessfulLoad || _error != null) return;
    final positionMs = _position.inMilliseconds;
    if (positionMs < 0) return;
    if (!force &&
        _lastSavedPositionMs >= 0 &&
        (positionMs - _lastSavedPositionMs).abs() < 5000) {
      return;
    }
    _lastSavedPositionMs = positionMs;
    try {
      await ref
          .read(localMediaRepositoryProvider)
          .updatePlaybackProgress(
            filePath: _currentVideo.filePath,
            positionMs: positionMs,
          );
    } catch (_) {}
  }

  String _formatTime(Duration value) {
    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60);
    final seconds = value.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _togglePlayback() async {
    _revealControlsAndResetTimer();
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> _seek(Duration position) async {
    _revealControlsAndResetTimer();
    await _player.seek(position);
  }

  Future<void> _seekRelative(Duration offset) async {
    if (!_isReady) return;
    final maxMs = _duration.inMilliseconds;
    final targetMs = (_position + offset)
        .inMilliseconds
        .clamp(0, maxMs > 0 ? maxMs : 0);
    await _seek(Duration(milliseconds: targetMs));
  }

  Future<void> _cycleSpeed() async {
    _revealControlsAndResetTimer();
    final nextIdx =
        (_speedOptions.indexOf(_playbackSpeed) + 1) % _speedOptions.length;
    final nextSpeed = _speedOptions[nextIdx];
    setState(() => _playbackSpeed = nextSpeed);
    await _player.setRate(nextSpeed);
  }

  void _cycleAspectRatio() {
    _revealControlsAndResetTimer();
    setState(() {
      _fitIndex = (_fitIndex + 1) % _fitModes.length;
    });
  }

  Future<void> _toggleMute() async {
    _revealControlsAndResetTimer();
    setState(() => _isMuted = !_isMuted);
    await _player.setVolume(_isMuted ? 0.0 : (_volume > 100.0 ? _volume : 100.0));
  }

  void _showAudioTrackSheet() {
    _revealControlsAndResetTimer();
    final audioTracks = _tracks.audio;
    final activeAudio = _player.state.track.audio;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0D172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Audio Track',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              if (audioTracks.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Default Audio Stream',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: audioTracks.length,
                    itemBuilder: (_, idx) {
                      final track = audioTracks[idx];
                      final isSelected = track == activeAudio;
                      final label = [
                        if (track.title != null && track.title!.isNotEmpty)
                          track.title!,
                        if (track.language != null && track.language!.isNotEmpty)
                          track.language!.toUpperCase(),
                        'Track ${idx + 1} (${track.id})',
                      ].join(' • ');

                      return ListTile(
                        dense: true,
                        leading: Icon(
                          isSelected
                              ? Icons.check_circle_rounded
                              : Icons.audiotrack_rounded,
                          color: isSelected ? _accent : Colors.white54,
                        ),
                        title: Text(
                          label,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight:
                                isSelected ? FontWeight.w800 : FontWeight.w500,
                          ),
                        ),
                        onTap: () {
                          _player.setAudioTrack(track);
                          Navigator.pop(sheetCtx);
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSubtitleTrackSheet() {
    _revealControlsAndResetTimer();
    final subTracks = _tracks.subtitle;
    final activeSub = _player.state.track.subtitle;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0D172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Subtitles & Captions',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                dense: true,
                leading: Icon(
                  activeSub == SubtitleTrack.no()
                      ? Icons.check_circle_rounded
                      : Icons.subtitles_off_outlined,
                  color: activeSub == SubtitleTrack.no()
                      ? _accent
                      : Colors.white54,
                ),
                title: const Text(
                  'Off (Disable Subtitles)',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  _player.setSubtitleTrack(SubtitleTrack.no());
                  Navigator.pop(sheetCtx);
                },
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: subTracks.length,
                  itemBuilder: (_, idx) {
                    final track = subTracks[idx];
                    if (track == SubtitleTrack.no()) {
                      return const SizedBox.shrink();
                    }
                    final isSelected = track == activeSub;
                    final label = [
                      if (track.title != null && track.title!.isNotEmpty)
                        track.title!,
                      if (track.language != null && track.language!.isNotEmpty)
                        track.language!.toUpperCase(),
                      'Subtitle ${idx + 1}',
                    ].join(' • ');

                    return ListTile(
                      dense: true,
                      leading: Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.subtitles_rounded,
                        color: isSelected ? _accent : Colors.white54,
                      ),
                      title: Text(
                        label,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w500,
                        ),
                      ),
                      onTap: () {
                        _player.setSubtitleTrack(track);
                        Navigator.pop(sheetCtx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRawVideoSurface(BoxFit fit) {
    Widget surface = Video(
      controller: _videoController,
      fit: fit,
      controls: NoVideoControls,
      subtitleViewConfiguration: SubtitleViewConfiguration(
        style: TextStyle(
          height: 1.35,
          fontSize: _subtitleFontSize,
          color: _subtitleColor,
          fontWeight: FontWeight.w700,
          backgroundColor: Colors.black.withValues(alpha: 0.55),
        ),
      ),
    );
    if (_hdrMode == 1) {
      surface = ColorFiltered(
        colorFilter: const ColorFilter.matrix(_hdr10VividMatrix),
        child: surface,
      );
    } else if (_hdrMode == 2) {
      surface = ColorFiltered(
        colorFilter: const ColorFilter.matrix(_hdrCinemaMatrix),
        child: surface,
      );
    }
    return surface;
  }

  Widget _buildVrTransformedVideo({
    required BoxFit fit,
    double eyeDisparity = 0.0,
    double zoomScale = 1.32,
  }) {
    final totalYaw = (_vrYaw + _gyroYaw + eyeDisparity).clamp(-1.35, 1.35);
    final totalPitch = (_vrPitch + _gyroPitch).clamp(-0.85, 0.85);
    final m = Matrix4.identity()
      ..setEntry(3, 2, 0.0012)
      ..scale(zoomScale, zoomScale, 1.0)
      ..rotateX(totalPitch * 0.42)
      ..rotateY(-totalYaw * 0.48);

    return ClipRect(
      child: Transform(
        alignment: Alignment.center,
        transform: m,
        child: _buildRawVideoSurface(fit),
      ),
    );
  }

  Widget _buildVideoCanvas(BoxFit fit) {
    if (_vrMode == 0) {
      return _buildRawVideoSurface(fit);
    }
    if (_vrMode == 1) {
      return _buildVrTransformedVideo(fit: BoxFit.cover, zoomScale: 1.36);
    }
    return Container(
      color: Colors.black,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          final eyeW = w * 0.5;
          final hPad = (eyeW * 0.065).clamp(10.0, 32.0);
          final vPad = (h * 0.11).clamp(14.0, 48.0);

          Widget buildEyeLens(double disparity) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.16),
                          width: 1.2,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _buildVrTransformedVideo(
                        fit: BoxFit.cover,
                        eyeDisparity: disparity,
                        zoomScale: 1.22,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }

          return Row(
            children: [
              buildEyeLens(-0.025),
              Container(
                width: 1.5,
                height: h * 0.72,
                color: Colors.white24,
              ),
              buildEyeLens(0.025),
            ],
          );
        },
      ),
    );
  }

  // Transparent text button in the Top Bar for HDR and VR only
  Widget _buildTopTransparentTextBtn({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.0,
            fontWeight: FontWeight.w800,
            color: active ? _accent : Colors.white.withValues(alpha: 0.85),
            letterSpacing: 0.5,
            shadows: const [
              Shadow(color: Colors.black, blurRadius: 6),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSideVerticalIndicator({
    required bool isLeftPosition,
    required IconData icon,
    required double value,
    required Color color,
  }) {
    final ratio = (value / 200.0).clamp(0.0, 1.0);
    return Positioned(
      left: isLeftPosition ? 24 : null,
      right: isLeftPosition ? null : 24,
      top: 0,
      bottom: 0,
      child: IgnorePointer(
        child: Center(
          child: Container(
            width: 36,
            height: 164,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.52),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 17),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          Container(width: 5, color: Colors.white24),
                          FractionallySizedBox(
                            heightFactor: ratio,
                            child: Container(width: 5, color: color),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Text(
                  '${value.round()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _hudTimer?.cancel();
    _vrGyroTimer?.cancel();
    _sleepTimer?.cancel();
    try {
      _sysChannel.invokeMethod('stopVrGyro');
    } catch (_) {}
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playingSubscription?.cancel();
    _errorSubscription?.cancel();
    _videoParamsSubscription?.cancel();
    _tracksSubscription?.cancel();

    unawaited(_saveProgress(force: true));
    unawaited(_player.dispose());

    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final maxMs = _duration.inMilliseconds;
    final currentMs = _position.inMilliseconds.clamp(0, maxMs > 0 ? maxMs : 0);
    final currentFit = _fitModes[_fitIndex];
    final overlayVisible = _showControls || !_isPlaying || _error != null;

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.space): () {
          if (!_isLocked && _isReady && !_isSwitching) _togglePlayback();
        },
        const SingleActivator(LogicalKeyboardKey.select): () {
          if (!_isLocked && _isReady && !_isSwitching) _togglePlayback();
        },
        const SingleActivator(LogicalKeyboardKey.enter): () {
          if (!_isLocked && _isReady && !_isSwitching) _togglePlayback();
        },
        const SingleActivator(LogicalKeyboardKey.numpadEnter): () {
          if (!_isLocked && _isReady && !_isSwitching) _togglePlayback();
        },
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () {
          if (!_isLocked) _seekRelative(const Duration(seconds: -10));
        },
        const SingleActivator(LogicalKeyboardKey.arrowRight): () {
          if (!_isLocked) _seekRelative(const Duration(seconds: 10));
        },
        const SingleActivator(LogicalKeyboardKey.arrowUp): () {
          if (!_isLocked) _applyVolumeTotal(_volume + 5);
        },
        const SingleActivator(LogicalKeyboardKey.arrowDown): () {
          if (!_isLocked) _applyVolumeTotal(_volume - 5);
        },
        const SingleActivator(LogicalKeyboardKey.keyM): () {
          if (!_isLocked) _toggleMute();
        },
        const SingleActivator(LogicalKeyboardKey.keyH): () {
          if (!_isLocked) _cycleHdrMode();
        },
        const SingleActivator(LogicalKeyboardKey.keyV): () {
          if (!_isLocked) _cycleVrMode();
        },
        const SingleActivator(LogicalKeyboardKey.keyF): () {
          if (!_isLocked) _cycleAspectRatio();
        },
      },
      child: Focus(
        autofocus: true,
        onKeyEvent: (_, _) {
          _revealControlsAndResetTimer();
          return KeyEventResult.ignored;
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Listener(
            onPointerSignal: (event) {
              if (event is PointerScrollEvent && !_isLocked) {
                if (event.scrollDelta.dy < 0) {
                  _applyVolumeTotal(_volume + 5);
                } else if (event.scrollDelta.dy > 0) {
                  _applyVolumeTotal(_volume - 5);
                }
              }
            },
            child: MouseRegion(
              onHover: (_) => _revealControlsAndResetTimer(),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _toggleControlsVisibility,
                onDoubleTapDown: _isLocked
                    ? null
                    : (details) {
                        final width = MediaQuery.sizeOf(context).width;
                        if (details.localPosition.dx < width / 2) {
                          _seekRelative(const Duration(seconds: -10));
                        } else {
                          _seekRelative(const Duration(seconds: 10));
                        }
                      },
                onLongPressStart: _isLocked
                    ? null
                    : (details) {
                        _holdStartX = details.localPosition.dx;
                        _holdStartPosMs = _position.inMilliseconds;
                        _seekOriginPosMs = _position.inMilliseconds;
                        final width = MediaQuery.sizeOf(context).width;
                        if (details.localPosition.dx >= width * 0.5) {
                          _savedSpeedBeforeHold = _playbackSpeed;
                          setState(() => _isHolding2x = true);
                          _player.setRate(2.0);
                        }
                      },
                onLongPressMoveUpdate: _isLocked
                    ? null
                    : (details) {
                        if (!_isReady || _duration.inMilliseconds <= 0) return;
                        final dx = details.localPosition.dx - _holdStartX;
                        if (!_isHoldSlideSeeking && dx.abs() > 12.0) {
                          if (_isHolding2x) {
                            _isHolding2x = false;
                            _player.setRate(_savedSpeedBeforeHold);
                          }
                          _hideControlsTimer?.cancel();
                          setState(() {
                            _isHoldSlideSeeking = true;
                            _showControls = true;
                          });
                        }
                        if (_isHoldSlideSeeking) {
                          final width = MediaQuery.sizeOf(context).width;
                          // Full screen width drag = 180 seconds (or 35% of video duration) smooth scrub
                          final rangeMs = (_duration.inMilliseconds * 0.25).clamp(45000.0, 120000.0);
                          final offsetMs = ((dx / width) * rangeMs).round();
                          _updateLiveSeekPreview(_holdStartPosMs + offsetMs);
                        }
                      },
                onLongPressEnd: _isLocked
                    ? null
                    : (_) {
                        if (_isHolding2x) {
                          setState(() => _isHolding2x = false);
                          _player.setRate(_savedSpeedBeforeHold);
                        }
                        if (_isHoldSlideSeeking) {
                          final target = _position;
                          setState(() {
                            _isHoldSlideSeeking = false;
                            _seekPreviewBytes = null;
                          });
                          _seek(target).then((_) {
                            if (mounted && !_isPlaying) {
                              _player.play();
                            }
                          });
                        }
                      },
                onPanStart: _isLocked
                    ? null
                    : (details) {
                        _panStartX = details.localPosition.dx;
                        _panStartY = details.localPosition.dy;
                        _panStartPosMs = _position.inMilliseconds;
                        _seekOriginPosMs = _position.inMilliseconds;
                        _panMode = 'none';
                      },
                onPanUpdate: _isLocked
                    ? null
                    : (details) {
                        final size = MediaQuery.sizeOf(context);
                        // Ignore bottom 88px control bar area so Slider handles its own drag
                        if (_panStartY > size.height - 88) return;

                        if (_vrMode != 0) {
                          setState(() {
                            _vrYaw = (_vrYaw - details.delta.dx * 0.005).clamp(-1.35, 1.35);
                            _vrPitch = (_vrPitch + details.delta.dy * 0.005).clamp(-0.85, 0.85);
                          });
                          return;
                        }

                        final totalDx = details.localPosition.dx - _panStartX;
                        final totalDy = details.localPosition.dy - _panStartY;

                        if (_panMode == 'none') {
                          if (totalDx.abs() < 10 && totalDy.abs() < 10) return;

                          if (totalDx.abs() > totalDy.abs() * 1.2) {
                            // Horizontal drag anywhere on screen -> Live Seek Preview!
                            if (!_isReady || _duration.inMilliseconds <= 0) return;
                            _panMode = 'seek';
                            _hideControlsTimer?.cancel();
                            setState(() {
                              _isHoldSlideSeeking = true;
                              _showControls = true;
                            });
                          } else if (totalDy.abs() > totalDx.abs() * 1.3) {
                            // Vertical drag ONLY in Left 22% edge (Brightness) or Right 22% edge (Volume)
                            if (_panStartX >= 20 && _panStartX <= size.width * 0.22) {
                              _panMode = 'brightness';
                            } else if (_panStartX >= size.width * 0.78 &&
                                _panStartX <= size.width - 20) {
                              _panMode = 'volume';
                            } else {
                              _panMode = 'ignore';
                            }
                          }
                        }

                        if (_panMode == 'seek') {
                          final rangeMs = (_duration.inMilliseconds * 0.25).clamp(45000.0, 120000.0);
                          final offsetMs = ((totalDx / size.width) * rangeMs).round();
                          _updateLiveSeekPreview(_panStartPosMs + offsetMs);
                        } else if (_panMode == 'brightness') {
                          final deltaPct = (-details.delta.dy / (size.height * 0.65)) * 200.0;
                          _applyBrightnessTotal(_brightness + deltaPct);
                        } else if (_panMode == 'volume') {
                          final deltaPct = (-details.delta.dy / (size.height * 0.65)) * 200.0;
                          _applyVolumeTotal(_volume + deltaPct);
                        }
                      },
                onPanEnd: _isLocked
                    ? null
                    : (_) {
                        if (_panMode == 'seek' && _isHoldSlideSeeking) {
                          final target = _position;
                          setState(() {
                            _isHoldSlideSeeking = false;
                            _seekPreviewBytes = null;
                            _panMode = 'none';
                          });
                          _seek(target).then((_) {
                            if (mounted && !_isPlaying) {
                              _player.play();
                            }
                          });
                        } else {
                          _panMode = 'none';
                        }
                      },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned.fill(
                      child: Center(
                        child: _error != null
                            ? Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  'Unable to play this video.\n$_error',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.redAccent),
                                ),
                              )
                            : _isReady
                                ? _buildVideoCanvas(currentFit.$2)
                                : const CircularProgressIndicator(color: _accent),
                      ),
                    ),

                    if (_isDraggingSlider || _isHoldSlideSeeking)
                      _buildLiveSeekPreviewOverlay(),

                    if (_isHolding2x)
                      Positioned(
                        top: 28,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: _accent.withValues(alpha: 0.6)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.fast_forward_rounded, color: _accent, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  '2.0x Speed',
                                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    if (_activeSideIndicator == 'volume')
                      _buildSideVerticalIndicator(
                        isLeftPosition: true,
                        icon: _volume > 100
                            ? Icons.graphic_eq_rounded
                            : (_volume == 0 ? Icons.volume_off_rounded : Icons.volume_up_rounded),
                        value: _sideIndicatorValue,
                        color: _volume > 100 ? const Color(0xFFF59E0B) : _accent,
                      ),
                    if (_activeSideIndicator == 'brightness')
                      _buildSideVerticalIndicator(
                        isLeftPosition: false,
                        icon: Icons.wb_sunny_rounded,
                        value: _sideIndicatorValue,
                        color: _accent,
                      ),

                    // TOP OVERLAY BAR: Back, Title, Transparent HDR & VR text, Lock, Audio, Subtitles, Aspect Ratio, Fullscreen
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: IgnorePointer(
                        ignoring: !overlayVisible,
                        child: AnimatedOpacity(
                          opacity: overlayVisible ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 220),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withValues(alpha: 0.78),
                                  Colors.transparent,
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                            child: SafeArea(
                              bottom: false,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(12, 6, 14, 18),
                                child: Row(
                                  children: [
                                    IconButton(
                                      tooltip: 'Back',
                                      onPressed: () => Navigator.of(context).maybePop(),
                                      icon: const Icon(
                                        Icons.arrow_back_rounded,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        _currentVideo.fileName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.w800,
                                          shadows: [
                                            Shadow(color: Colors.black, blurRadius: 8),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (!_isLocked) ...[
                                      _buildTopTransparentTextBtn(
                                        label: _hdrLabels[_hdrMode],
                                        active: _hdrMode != 0,
                                        onTap: _cycleHdrMode,
                                      ),
                                      const SizedBox(width: 4),
                                      _buildTopTransparentTextBtn(
                                        label: _vrLabels[_vrMode],
                                        active: _vrMode != 0,
                                        onTap: _cycleVrMode,
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                    IconButton(
                                      tooltip: 'Lock controls',
                                      onPressed: () {
                                        setState(() => _isLocked = !_isLocked);
                                        _revealControlsAndResetTimer();
                                      },
                                      icon: Icon(
                                        _isLocked
                                            ? Icons.lock_rounded
                                            : Icons.lock_open_rounded,
                                        color: _isLocked ? _accent : Colors.white,
                                      ),
                                    ),
                                    if (!_isLocked) ...[
                                      IconButton(
                                        tooltip: 'Audio tracks',
                                        onPressed: _isReady ? _showAudioTrackSheet : null,
                                        icon: const Icon(
                                          Icons.audiotrack_rounded,
                                          color: Colors.white,
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Subtitles',
                                        onPressed: _isReady ? _showSubtitleTrackSheet : null,
                                        icon: const Icon(
                                          Icons.subtitles_rounded,
                                          color: Colors.white,
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Aspect ratio (${currentFit.$1})',
                                        onPressed: _isReady ? _cycleAspectRatio : null,
                                        icon: const Icon(
                                          Icons.aspect_ratio_rounded,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                    IconButton(
                                      tooltip: 'Picture-in-Picture (PiP)',
                                      onPressed: _isReady ? _triggerPipMode : null,
                                      icon: const Icon(
                                        Icons.picture_in_picture_alt_rounded,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // CLEAN BOTTOM OVERLAY CONTROLS (No duplicate Fit, No EQ, No A-B)
                    if (!_isLocked)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: IgnorePointer(
                          ignoring: !overlayVisible,
                          child: AnimatedOpacity(
                            opacity: overlayVisible ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 220),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.55),
                                    Colors.black.withValues(alpha: 0.88),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                              child: SafeArea(
                                top: false,
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            _formatTime(_position),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          Expanded(
                                            child: SliderTheme(
                                              data: SliderTheme.of(context).copyWith(
                                                trackHeight: 3.5,
                                                thumbShape: const RoundSliderThumbShape(
                                                  enabledThumbRadius: 7,
                                                ),
                                              ),
                                              child: Slider(
                                                min: 0,
                                                max: maxMs > 0 ? maxMs.toDouble() : 1,
                                                value: currentMs.toDouble().clamp(
                                                  0,
                                                  maxMs > 0 ? maxMs.toDouble() : 1,
                                                ),
                                                onChangeStart: (_) {
                                                  _seekOriginPosMs = _position.inMilliseconds;
                                                  setState(() => _isDraggingSlider = true);
                                                  _hideControlsTimer?.cancel();
                                                },
                                                onChanged: maxMs > 0
                                                    ? (value) {
                                                        _updateLiveSeekPreview(value.round());
                                                      }
                                                    : null,
                                                onChangeEnd: maxMs > 0
                                                    ? (value) {
                                                        setState(() {
                                                          _isDraggingSlider = false;
                                                          _seekPreviewBytes = null;
                                                        });
                                                        _seek(
                                                          Duration(
                                                            milliseconds: value.round(),
                                                          ),
                                                        ).then((_) {
                                                          if (mounted && !_isPlaying) {
                                                            _player.play();
                                                          }
                                                        });
                                                      }
                                                    : null,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            _formatTime(_duration),
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          IconButton(
                                            visualDensity: VisualDensity.compact,
                                            tooltip: _isMuted ? 'Unmute' : 'Mute',
                                            onPressed: _isReady ? _toggleMute : null,
                                            icon: Icon(
                                              _isMuted
                                                  ? Icons.volume_off_rounded
                                                  : Icons.volume_up_rounded,
                                              color: Colors.white,
                                              size: 22,
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                tooltip: 'Previous video',
                                                onPressed: _hasPreviousVideo && !_isSwitching
                                                    ? () => _changeVideo(_currentIndex - 1)
                                                    : null,
                                                icon: const Icon(Icons.skip_previous),
                                                color: Colors.white,
                                              ),
                                              IconButton(
                                                tooltip: 'Rewind 10 seconds',
                                                onPressed: _isReady && !_isSwitching
                                                    ? () => _seekRelative(const Duration(seconds: -10))
                                                    : null,
                                                icon: const Icon(Icons.replay_10_rounded),
                                                color: Colors.white,
                                              ),
                                              const SizedBox(width: 8),
                                              IconButton.filled(
                                                style: IconButton.styleFrom(
                                                  backgroundColor: _accent,
                                                  foregroundColor: Colors.black,
                                                ),
                                                onPressed: _isReady && !_isSwitching
                                                    ? _togglePlayback
                                                    : null,
                                                icon: Icon(
                                                  _isPlaying ? Icons.pause : Icons.play_arrow,
                                                ),
                                                iconSize: 28,
                                              ),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                tooltip: 'Forward 10 seconds',
                                                onPressed: _isReady && !_isSwitching
                                                    ? () => _seekRelative(const Duration(seconds: 10))
                                                    : null,
                                                icon: const Icon(Icons.forward_10_rounded),
                                                color: Colors.white,
                                              ),
                                              IconButton(
                                                tooltip: 'Next video',
                                                onPressed: _hasNextVideo && !_isSwitching
                                                    ? () => _changeVideo(_currentIndex + 1)
                                                    : null,
                                                icon: const Icon(Icons.skip_next),
                                                color: Colors.white,
                                              ),
                                            ],
                                          ),
                                          TextButton(
                                            onPressed: _isReady ? _cycleSpeed : null,
                                            child: Text(
                                              '${_playbackSpeed}x',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white,
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
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
