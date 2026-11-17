import 'package:flutter/widgets.dart';

abstract interface class LiveTvPlayback {
  Stream<String> get errors;

  Stream<String> get logs;

  Stream<Duration> get positions;
  Stream<bool> get playing;

  Future<void> open(String url);

  Future<void> play();

  Future<void> pause();

  Future<void> stop();

  Widget buildVideo({
    List<Widget> topButtonBar = const [],
    List<Widget> primaryButtonBar = const [],
    BoxFit fit = BoxFit.contain,
    int controlsRevision = 0,
  });

  Future<void> dispose();
}
