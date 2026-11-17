import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/database/app_database.dart';
import '../services/live_tv_playback.dart';
import '../services/media_kit_playback.dart';

class LiveTvPlayer extends StatefulWidget {
  const LiveTvPlayer({
    super.key,
    required this.channel,
    this.playbackFactory,
    this.paused = false,
    this.fullscreen = false,
    this.onPlaybackThresholdReached,
    this.onChannelFailed,
    this.controlsTopBar = const [],
    this.controlsCenterBar = const [],
    this.videoFit = BoxFit.contain,
    this.onFitFillToggle,
    this.controlsRevision = 0,
  });

  final Channel? channel;
  final LiveTvPlaybackFactory? playbackFactory;
  final bool paused;
  final bool fullscreen;
  final ValueChanged<Channel>? onPlaybackThresholdReached;
  final VoidCallback? onChannelFailed;
  final List<Widget> controlsTopBar;
  final List<Widget> controlsCenterBar;
  final BoxFit videoFit;
  final VoidCallback? onFitFillToggle;
  final int controlsRevision;

  @override
  State<LiveTvPlayer> createState() => _LiveTvPlayerState();
}

class _LiveTvPlayerState extends State<LiveTvPlayer>
    with SingleTickerProviderStateMixin {
  late final LiveTvPlayback _playback;
  late final AnimationController _lightAnimController;
  StreamSubscription<String>? _errorSubscription;
  StreamSubscription<String>? _logSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<bool>? _playingSubscription;
  Timer? _historyTimer;

  List<String> _urls = [];
  int _urlIndex = 0;
  int _generation = 0;
  bool _isOpening = false;
  bool _hasOpened = false;
  bool _attemptFailed = false;
  bool _disposed = false;
  bool _isActuallyPlaying = false;
  bool _historyReported = false;
  String? _errorMessage;
  String _status = 'Select a channel to start watching';

  @override
  void initState() {
    super.initState();

    _lightAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..repeat();

    _playback = widget.playbackFactory?.call() ?? MediaKitPlayback();

    _errorSubscription = _playback.errors.listen(_handlePlayerError);
    _logSubscription = _playback.logs.listen((entry) {
      // Silenced in release for 1GB/2GB RAM efficiency
    });
    _playingSubscription = _playback.playing.listen(_handlePlayingChanged);
    _positionSubscription = _playback.positions.listen((position) {
      if (!_disposed && _hasOpened && position > Duration.zero) {
        if (mounted && (!_isActuallyPlaying || _status != 'Playback progressing')) {
          setState(() {
            _isActuallyPlaying = true;
            _status = 'Playback progressing';
          });
          _startHistoryTimerIfEligible(_generation);
        }
      }
    });
    _updateChannel(widget.channel);
  }

  @override
  void didUpdateWidget(covariant LiveTvPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.channel?.id != widget.channel?.id ||
        oldWidget.channel?.primaryUrl != widget.channel?.primaryUrl ||
        oldWidget.channel?.backupUrl1 != widget.channel?.backupUrl1 ||
        oldWidget.channel?.backupUrl2 != widget.channel?.backupUrl2) {
      _updateChannel(widget.channel);
    }

    if (oldWidget.paused != widget.paused && _hasOpened) {
      unawaited(widget.paused ? _playback.pause() : _playback.play());
    }
  }

  void _updateChannel(Channel? channel) {
    _generation++;
    _cancelHistoryTimer();
    _isActuallyPlaying = false;
    _historyReported = false;
    _urlIndex = 0;
    _isOpening = false;
    _hasOpened = false;
    _attemptFailed = false;
    _errorMessage = null;

    _urls = channel == null
        ? []
        : [
            channel.primaryUrl,
            channel.backupUrl1,
            channel.backupUrl2,
          ].map((url) => url.trim()).where((url) => url.isNotEmpty).toList();

    if (_urls.isEmpty) {
      _status = channel == null
          ? 'Select a channel to start watching'
          : 'No stream URL available';
      unawaited(_playback.stop());
      if (mounted) setState(() {});
      return;
    }

    _status = 'Streaming...';
    if (mounted) setState(() {});
    unawaited(_tryUrl(0, _generation));
  }

  void _retryCurrentChannel({int startIndex = 0}) {
    if (_disposed || _urls.isEmpty) return;
    _generation++;
    _cancelHistoryTimer();
    _isActuallyPlaying = false;
    _attemptFailed = false;
    _errorMessage = null;
    unawaited(_tryUrl(startIndex.clamp(0, _urls.length - 1), _generation));
  }

  Future<void> _tryUrl(int index, int generation) async {
    if (_disposed || generation != _generation) return;

    if (index >= _urls.length) {
      if (mounted) {
        setState(() {
          _isOpening = false;
          _hasOpened = false;
          _status = 'Unable to play this channel';
          _errorMessage ??= 'Stream unavailable.';
        });
        if (widget.channel != null) {
          widget.onChannelFailed?.call();
        }
      }
      return;
    }

    _cancelHistoryTimer();
    _isActuallyPlaying = false;
    _urlIndex = index;
    _isOpening = true;
    _attemptFailed = false;

    if (mounted) {
      setState(() {
        _hasOpened = false;
        _status = 'Streaming...';
        _errorMessage = null;
      });
    }

    try {
      await _playback.open(_urls[index]);
      if (_disposed || generation != _generation) return;

      _isOpening = false;

      if (_attemptFailed) {
        await _tryUrl(index + 1, generation);
        return;
      }

      if (mounted) {
        setState(() {
          _hasOpened = true;
          _status = 'Streaming...';
        });
      }
      _startHistoryTimerIfEligible(generation);
      if (widget.paused) await _playback.pause();
    } catch (error) {
      if (_disposed || generation != _generation) return;

      _isOpening = false;
      _attemptFailed = true;
      _errorMessage = error.toString();
      await _tryUrl(index + 1, generation);
    }
  }

  void _handlePlayerError(String error) {
    if (_disposed || _attemptFailed) return;
    _cancelHistoryTimer();
    _isActuallyPlaying = false;

    _attemptFailed = true;
    _errorMessage = error;

    if (_isOpening) {
      if (mounted) {
        setState(() {
          _status = 'Switching stream source...';
        });
      }
      return;
    }

    if (_urlIndex + 1 < _urls.length) {
      if (mounted) {
        setState(() {
          _hasOpened = false;
          _status = 'Switching stream source...';
        });
      }
      unawaited(_tryUrl(_urlIndex + 1, _generation));
    } else if (mounted) {
      setState(() {
        _status = 'Stream unavailable';
      });
      if (widget.channel != null) {
        widget.onChannelFailed?.call();
      }
    }
  }

  void _handlePlayingChanged(bool playing) {
    if (_disposed) return;
    if (mounted && _isActuallyPlaying != playing) {
      setState(() {
        _isActuallyPlaying = playing;
      });
    } else {
      _isActuallyPlaying = playing;
    }
    if (!playing) {
      _cancelHistoryTimer();
      return;
    }
    _startHistoryTimerIfEligible(_generation);
  }

  void _cancelHistoryTimer() {
    _historyTimer?.cancel();
    _historyTimer = null;
  }

  void _startHistoryTimerIfEligible(int generation) {
    if (_disposed ||
        !mounted ||
        !_hasOpened ||
        !_isActuallyPlaying ||
        _historyReported ||
        _historyTimer != null ||
        widget.channel == null) {
      return;
    }

    final channel = widget.channel!;
    _historyTimer = Timer(const Duration(seconds: 30), () {
      _historyTimer = null;
      if (_disposed ||
          !mounted ||
          generation != _generation ||
          !_hasOpened ||
          !_isActuallyPlaying ||
          _historyReported ||
          widget.channel?.id != channel.id) {
        return;
      }
      _historyReported = true;
      widget.onPlaybackThresholdReached?.call(channel);
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _cancelHistoryTimer();
    _lightAnimController.dispose();
    _logSubscription?.cancel();
    _errorSubscription?.cancel();
    _positionSubscription?.cancel();
    _playingSubscription?.cancel();
    unawaited(_playback.dispose());
    super.dispose();
  }

  Widget _buildAnimatedChannelLogoWaitingOverlay(bool canRetry) {
    final ch = widget.channel;
    final logoUrl = ch?.logoUrl?.trim() ?? '';
    final chNum = ch?.channelNumber ?? 0;

    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 0.95,
          colors: [Color(0xFF0B1D3A), Color(0xFF030710)],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated Light Aura & Shimmer Beam Emanating from Channel Logo
              AnimatedBuilder(
                animation: _lightAnimController,
                builder: (context, child) {
                  final t = _lightAnimController.value;
                  final pulse = 0.5 + 0.5 * math.sin(t * math.pi * 2);
                  final sweepPos = -1.2 + (t * 3.4);

                  return SizedBox(
                    width: 156,
                    height: 156,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Expanding Light Wave Ring 1
                        Transform.scale(
                          scale: 0.85 + (t * 0.65),
                          child: Container(
                            width: 112,
                            height: 112,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF38BDF8)
                                    .withValues(alpha: (1.0 - t) * 0.55),
                                width: 2.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF38BDF8)
                                      .withValues(alpha: (1.0 - t) * 0.35),
                                  blurRadius: 24,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Expanding Light Wave Ring 2 (offset phase)
                        Transform.scale(
                          scale: 0.85 + (((t + 0.5) % 1.0) * 0.65),
                          child: Container(
                            width: 112,
                            height: 112,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF26E7FF).withValues(
                                  alpha: (1.0 - ((t + 0.5) % 1.0)) * 0.45,
                                ),
                                width: 1.8,
                              ),
                            ),
                          ),
                        ),
                        // Glowing Logo Container with Sweeping Light Shimmer Beam
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B162C),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Color.lerp(
                                const Color(0xFF38BDF8).withValues(alpha: 0.45),
                                Colors.white,
                                pulse * 0.6,
                              )!,
                              width: 1.8,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF38BDF8)
                                    .withValues(alpha: 0.25 + pulse * 0.35),
                                blurRadius: 28 + (pulse * 14),
                                spreadRadius: 2 + (pulse * 4),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(14),
                                child: child!,
                              ),
                              // Diagonal Light Shimmer Ray across Channel Logo
                              IgnorePointer(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment(sweepPos - 0.6, -1.0),
                                      end: Alignment(sweepPos + 0.6, 1.0),
                                      colors: [
                                        Colors.white.withValues(alpha: 0.0),
                                        const Color(0xFF38BDF8)
                                            .withValues(alpha: 0.22),
                                        Colors.white.withValues(alpha: 0.55),
                                        const Color(0xFF38BDF8)
                                            .withValues(alpha: 0.22),
                                        Colors.white.withValues(alpha: 0.0),
                                      ],
                                      stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
                child: logoUrl.isNotEmpty
                    ? Image.network(
                        logoUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.live_tv_rounded,
                          size: 44,
                          color: Color(0xFF38BDF8),
                        ),
                      )
                    : const Icon(
                        Icons.live_tv_rounded,
                        size: 44,
                        color: Color(0xFF38BDF8),
                      ),
              ),
              const SizedBox(height: 10),
              if (chNum > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.45),
                    ),
                  ),
                  child: Text(
                    'CH $chNum',
                    style: const TextStyle(
                      color: Color(0xFF38BDF8),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                ch?.name ?? 'LIVE TV',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _errorMessage != null ? _status : 'Streaming...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _errorMessage != null
                      ? Colors.redAccent
                      : const Color(0xFF38BDF8),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              if (canRetry) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _retryCurrentChannel(startIndex: 0),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text(
                    'RETRY STREAM',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canRetry = !_isOpening && !_hasOpened && _urls.isNotEmpty;
    final showWaitingOverlay = !_isActuallyPlaying;

    return Container(
      width: double.infinity,
      margin: widget.fullscreen ? EdgeInsets.zero : const EdgeInsets.all(10),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(widget.fullscreen ? 0 : 14),
        border: widget.fullscreen
            ? null
            : Border.all(color: const Color(0xFF26344A)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_hasOpened)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onDoubleTap: widget.onFitFillToggle,
              child: _playback.buildVideo(
                topButtonBar: widget.controlsTopBar,
                primaryButtonBar: const [],
                fit: widget.videoFit,
                controlsRevision: widget.controlsRevision,
              ),
            ),

          // Animated Channel Logo Light Overlay while waiting for real video frames
          if (showWaitingOverlay)
            Positioned.fill(
              child: _buildAnimatedChannelLogoWaitingOverlay(canRetry),
            ),

          if (_hasOpened && _urls.length > 1)
            Positioned(
              top: 10,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(_urls.length, (idx) {
                    final active = _urlIndex == idx;
                    final label = idx == 0 ? 'SRC 1' : 'BKP $idx';
                    return Padding(
                      padding: EdgeInsets.only(right: idx < _urls.length - 1 ? 6 : 0),
                      child: GestureDetector(
                        onTap: () => _retryCurrentChannel(startIndex: idx),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: active ? const Color(0xFF38BDF8) : Colors.white54,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),

          if (widget.controlsCenterBar.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 18,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: widget.controlsCenterBar,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
