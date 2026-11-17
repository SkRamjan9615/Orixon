import 'dart:async';

import 'package:orixon/core/database/app_database.dart';
import 'package:orixon/features/live_tv/presentation/services/live_tv_playback.dart';
import 'package:orixon/features/live_tv/presentation/widgets/live_tv_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeLiveTvPlayback implements LiveTvPlayback {
  final errorController = StreamController<String>.broadcast();
  final logController = StreamController<String>.broadcast();
  final positionController = StreamController<Duration>.broadcast();
  final playingController = StreamController<bool>.broadcast();

  final List<String> openedUrls = [];
  final Set<String> failingUrls;
  bool isDisposed = false;
  bool isPlaying = true;
  int playCalls = 0;
  int pauseCalls = 0;
  final Set<String> deferredUrls;
  final Map<String, Completer<void>> pendingOpens = {};

  FakeLiveTvPlayback({required this.failingUrls, this.deferredUrls = const {}});

  void completeOpen(String url) {
    pendingOpens[url]!.complete();
  }

  @override
  Stream<String> get errors => errorController.stream;

  @override
  Stream<String> get logs => logController.stream;

  @override
  Stream<Duration> get positions => positionController.stream;

  @override
  Stream<bool> get playing => playingController.stream;

  @override
  Future<void> open(String url) async {
    openedUrls.add(url);

    if (deferredUrls.contains(url)) {
      final completer = Completer<void>();
      pendingOpens[url] = completer;
      await completer.future;
      isPlaying = true;
      playingController.add(true);
      return;
    }

    if (failingUrls.contains(url)) {
      errorController.add('$url failed');
      throw StateError('$url failed');
    }
    isPlaying = true;
    playingController.add(true);
  }

  @override
  Future<void> play() async {
    isPlaying = true;
    playingController.add(true);
    playCalls++;
  }

  @override
  Future<void> pause() async {
    isPlaying = false;
    playingController.add(false);
    pauseCalls++;
  }

  @override
  Future<void> stop() async {}

  @override
  Widget buildVideo({
    List<Widget> topButtonBar = const [],
    List<Widget> primaryButtonBar = const [],
    BoxFit fit = BoxFit.contain,
    int controlsRevision = 0,
  }) => const SizedBox(key: ValueKey('fake-video'));

  @override
  Future<void> dispose() async {
    isDisposed = true;
    await errorController.close();
    await logController.close();
    await positionController.close();
    await playingController.close();
  }
}

Channel createTestChannel({
  int id = 1,
  String primaryUrl = 'https://primary.example/live.m3u8',
}) {
  return Channel(
    id: id,
    channelNumber: id,
    name: 'Test Channel',
    categoryId: 1,
    logoUrl: '',
    primaryUrl: primaryUrl,
    backupUrl1: 'https://backup1.example/live.m3u8',
    backupUrl2: 'https://backup2.example/live.m3u8',
    epgChannelId: '',
    isFavorite: false,
    isEnabled: true,
    isLocked: false,
    favoriteOrder: 0,
  );
}

Future<void> pumpPlayer(
  WidgetTester tester,
  FakeLiveTvPlayback playback,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: LiveTvPlayer(
          channel: createTestChannel(),
          playbackFactory: () => playback,
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

Future<void> disposePlayer(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 1));
}

void main() {
  group('LiveTvPlayer failover', () {
    testWidgets('uses backup 1 when primary fails', (tester) async {
      final playback = FakeLiveTvPlayback(
        failingUrls: {'https://primary.example/live.m3u8'},
      );

      await pumpPlayer(tester, playback);

      expect(playback.openedUrls, [
        'https://primary.example/live.m3u8',
        'https://backup1.example/live.m3u8',
      ]);
      expect(find.byKey(const ValueKey('fake-video')), findsOneWidget);

      await disposePlayer(tester);
    });

    testWidgets('uses backup 2 when primary and backup 1 fail', (tester) async {
      final playback = FakeLiveTvPlayback(
        failingUrls: {
          'https://primary.example/live.m3u8',
          'https://backup1.example/live.m3u8',
        },
      );

      await pumpPlayer(tester, playback);

      expect(playback.openedUrls, [
        'https://primary.example/live.m3u8',
        'https://backup1.example/live.m3u8',
        'https://backup2.example/live.m3u8',
      ]);
      expect(find.byKey(const ValueKey('fake-video')), findsOneWidget);

      await disposePlayer(tester);
    });

    testWidgets('ignores an old pending open after the channel changes', (
      tester,
    ) async {
      const oldUrl = 'https://primary.example/live.m3u8';
      const newUrl = 'https://new-channel.example/live.m3u8';

      final playback = FakeLiveTvPlayback(
        failingUrls: {},
        deferredUrls: {oldUrl},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiveTvPlayer(
              channel: createTestChannel(),
              playbackFactory: () => playback,
            ),
          ),
        ),
      );

      await tester.pump();

      expect(playback.openedUrls, [oldUrl]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiveTvPlayer(
              channel: createTestChannel(id: 2, primaryUrl: newUrl),
              playbackFactory: () => playback,
            ),
          ),
        ),
      );

      await tester.pump();

      expect(playback.openedUrls, [oldUrl, newUrl]);
      expect(find.byKey(const ValueKey('fake-video')), findsOneWidget);

      playback.completeOpen(oldUrl);
      await tester.pump();

      expect(find.byKey(const ValueKey('fake-video')), findsOneWidget);

      await disposePlayer(tester);
    });

    testWidgets('disposes playback and cancels stream subscriptions', (
      tester,
    ) async {
      final playback = FakeLiveTvPlayback(failingUrls: {});

      await pumpPlayer(tester, playback);

      expect(playback.errorController.hasListener, isTrue);
      expect(playback.logController.hasListener, isTrue);
      expect(playback.positionController.hasListener, isTrue);
      expect(playback.playingController.hasListener, isTrue);

      await disposePlayer(tester);

      expect(playback.isDisposed, isTrue);
      expect(playback.errorController.hasListener, isFalse);
      expect(playback.logController.hasListener, isFalse);
      expect(playback.positionController.hasListener, isFalse);
      expect(playback.playingController.hasListener, isFalse);
    });

    testWidgets('pauses and resumes playback when paused changes', (
      tester,
    ) async {
      final playback = FakeLiveTvPlayback(failingUrls: {});

      await pumpPlayer(tester, playback);

      expect(playback.isPlaying, isTrue);
      expect(playback.pauseCalls, 0);
      expect(playback.playCalls, 0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiveTvPlayer(
              channel: createTestChannel(),
              playbackFactory: () => playback,
              paused: true,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(playback.isPlaying, isFalse);
      expect(playback.pauseCalls, 1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiveTvPlayer(
              channel: createTestChannel(),
              playbackFactory: () => playback,
              paused: false,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(playback.isPlaying, isTrue);
      expect(playback.playCalls, 1);

      await disposePlayer(tester);
    });

    testWidgets('records only after 30 seconds of actual playback', (
      tester,
    ) async {
      final playback = FakeLiveTvPlayback(failingUrls: {});
      final recorded = <Channel>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiveTvPlayer(
              channel: createTestChannel(),
              playbackFactory: () => playback,
              onPlaybackThresholdReached: recorded.add,
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.pump(const Duration(seconds: 29));
      expect(recorded, isEmpty);

      await tester.pump(const Duration(seconds: 1));
      expect(recorded, hasLength(1));
      expect(recorded.single.id, 1);

      await tester.pump(const Duration(seconds: 10));
      expect(recorded, hasLength(1));
      await disposePlayer(tester);
    });

    testWidgets('does not count a channel changed before 30 seconds', (
      tester,
    ) async {
      final playback = FakeLiveTvPlayback(failingUrls: {});
      final recorded = <Channel>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiveTvPlayer(
              channel: createTestChannel(),
              playbackFactory: () => playback,
              onPlaybackThresholdReached: recorded.add,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 20));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiveTvPlayer(
              channel: createTestChannel(id: 2),
              playbackFactory: () => playback,
              onPlaybackThresholdReached: recorded.add,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 29));
      expect(recorded, isEmpty);

      await tester.pump(const Duration(seconds: 1));
      expect(recorded, hasLength(1));
      expect(recorded.single.id, 2);
      await disposePlayer(tester);
    });

    testWidgets('does not count a stream that fails', (tester) async {
      final playback = FakeLiveTvPlayback(
        failingUrls: {
          'https://primary.example/live.m3u8',
          'https://backup1.example/live.m3u8',
          'https://backup2.example/live.m3u8',
        },
      );
      final recorded = <Channel>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiveTvPlayer(
              channel: createTestChannel(),
              playbackFactory: () => playback,
              onPlaybackThresholdReached: recorded.add,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 31));

      expect(recorded, isEmpty);
      await disposePlayer(tester);
    });

    testWidgets('counts playback from a successful backup URL', (tester) async {
      final playback = FakeLiveTvPlayback(
        failingUrls: {'https://primary.example/live.m3u8'},
      );
      final recorded = <Channel>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiveTvPlayer(
              channel: createTestChannel(),
              playbackFactory: () => playback,
              onPlaybackThresholdReached: recorded.add,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 30));

      expect(playback.openedUrls, hasLength(2));
      expect(recorded, hasLength(1));
      expect(recorded.single.id, 1);
      await disposePlayer(tester);
    });

    testWidgets('shows failure status when all URLs fail', (tester) async {
      final playback = FakeLiveTvPlayback(
        failingUrls: {
          'https://primary.example/live.m3u8',
          'https://backup1.example/live.m3u8',
          'https://backup2.example/live.m3u8',
        },
      );

      await pumpPlayer(tester, playback);

      expect(playback.openedUrls.length, 3);
      expect(find.text('Unable to play this channel'), findsOneWidget);
      expect(find.byKey(const ValueKey('fake-video')), findsNothing);

      await disposePlayer(tester);
    });
  });
}
