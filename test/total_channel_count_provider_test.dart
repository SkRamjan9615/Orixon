import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orixon/core/database/app_database.dart';
import 'package:orixon/core/providers/app_providers.dart';

void main() {
  test('counts all channels and updates after insert and delete', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
      ],
    );

    final updates = <int, Completer<int>>{};

    final subscription = container.listen(
      totalChannelCountProvider,
      (previous, next) {
        next.whenData((count) {
          final waiter = updates.remove(count);
          if (waiter != null && !waiter.isCompleted) {
            waiter.complete(count);
          }
        });
      },
    );

    try {
      expect(
        await container.read(totalChannelCountProvider.future),
        0,
      );

      final categoryId = await database.into(database.categories).insert(
            CategoriesCompanion.insert(
              name: 'Test Category',
              rangeStart: 1,
              rangeEnd: 100,
              sortOrder: 0,
            ),
          );

      updates[2] = Completer<int>();

      await database.into(database.channels).insert(
            ChannelsCompanion.insert(
              name: 'Enabled Channel',
              primaryUrl: 'https://example.com/enabled.m3u8',
              categoryId: categoryId,
              channelNumber: 1,
            ),
          );

      final disabledChannelId =
          await database.into(database.channels).insert(
                ChannelsCompanion.insert(
                  name: 'Disabled Channel',
                  primaryUrl: 'https://example.com/disabled.m3u8',
                  categoryId: categoryId,
                  channelNumber: 2,
                  isEnabled: const Value(false),
                ),
              );

      expect(await updates[2]!.future, 2);

      updates[1] = Completer<int>();

      await (database.delete(database.channels)
            ..where((table) => table.id.equals(disabledChannelId)))
          .go();

      expect(await updates[1]!.future, 1);
    } finally {
      subscription.close();
      container.dispose();
      await database.close();
    }
  });
}
