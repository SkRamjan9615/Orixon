import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:orixon/core/database/app_database.dart';
import 'package:orixon/core/providers/app_providers.dart';
import 'package:orixon/features/live_tv/presentation/live_tv_screen.dart';

void main() {
  late AppDatabase database;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());

    final categoryId = await database
        .into(database.categories)
        .insert(
          CategoriesCompanion.insert(
            name: 'Entertainment',
            rangeStart: 1,
            rangeEnd: 200,
            sortOrder: 0,
          ),
        );

    for (final number in [101, 102, 103]) {
      await database
          .into(database.channels)
          .insert(
            ChannelsCompanion.insert(
              channelNumber: number,
              name: 'Channel $number',
              categoryId: categoryId,
              primaryUrl: 'https://example.com/$number.m3u8',
            ),
          );
    }
  });

  tearDown(() async {
    await database.close();
  });

  Future<void> openLiveTv(
    WidgetTester tester, {
    Size screenSize = const Size(800, 1200),
  }) async {
    tester.view.physicalSize = screenSize;
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(database)],
        child: MaterialApp(
          home: LiveTvScreen(database: database, enablePlayback: false),
        ),
      ),
    );

    await tester.pumpAndSettle();
  }

  Future<void> disposeLiveTv(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  }

  Future<void> sendDigit(WidgetTester tester, LogicalKeyboardKey key) async {
    await tester.sendKeyEvent(key);
    await tester.pump();
  }

  void expectCurrentChannel(WidgetTester tester, int number) {
    expect(find.text('$number'), findsOneWidget);
    expect(find.text('Channel $number'), findsOneWidget);
  }

  group('Live TV channel navigation', () {
    testWidgets('compact screen has no layout overflow', (tester) async {
      await openLiveTv(tester, screenSize: const Size(360, 640));

      expect(tester.takeException(), isNull);

      await disposeLiveTv(tester);
    });

    testWidgets('CH+ and CH- navigate between channels', (tester) async {
      await openLiveTv(tester);

      expectCurrentChannel(tester, 101);

      await tester.sendKeyEvent(LogicalKeyboardKey.channelUp);
      await tester.pump();

      expectCurrentChannel(tester, 102);

      await tester.sendKeyEvent(LogicalKeyboardKey.channelDown);
      await tester.pump();

      expectCurrentChannel(tester, 101);

      await disposeLiveTv(tester);
    });

    testWidgets('CH+ starts from the displayed first channel', (tester) async {
      await openLiveTv(tester);

      expectCurrentChannel(tester, 101);

      await tester.sendKeyEvent(LogicalKeyboardKey.channelUp);
      await tester.pump();

      expectCurrentChannel(tester, 102);

      await disposeLiveTv(tester);
    });

    testWidgets('channel number commits after 1800 milliseconds', (
      tester,
    ) async {
      await openLiveTv(tester);

      await sendDigit(tester, LogicalKeyboardKey.digit1);
      await sendDigit(tester, LogicalKeyboardKey.digit0);
      await sendDigit(tester, LogicalKeyboardKey.digit3);

      expect(find.text('103'), findsNWidgets(2));
      expectCurrentChannel(tester, 101);

      await tester.pump(const Duration(milliseconds: 1799));

      expectCurrentChannel(tester, 101);

      await tester.pump(const Duration(milliseconds: 1));

      expectCurrentChannel(tester, 103);
      expect(find.text('103  •  Channel 103'), findsOneWidget);
      expect(find.text('103'), findsOneWidget);

      await disposeLiveTv(tester);
    });

    testWidgets('invalid channel number preserves current channel', (
      tester,
    ) async {
      await openLiveTv(tester);

      for (final key in [
        LogicalKeyboardKey.digit9,
        LogicalKeyboardKey.digit9,
        LogicalKeyboardKey.digit9,
      ]) {
        await sendDigit(tester, key);
      }

      await tester.pump(const Duration(milliseconds: 1800));
      await tester.pump();

      expectCurrentChannel(tester, 101);
      expect(find.text('Channel 999 not found'), findsNWidgets(2));

      await disposeLiveTv(tester);
    });
  });
}
