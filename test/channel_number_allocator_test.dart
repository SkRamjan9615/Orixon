import 'package:flutter_test/flutter_test.dart';
import 'package:orixon/features/live_tv/domain/services/channel_number_allocator.dart';

void main() {
  const allocator = ChannelNumberAllocator();

  group('ChannelNumberAllocator', () {
    test('allocates first available number', () {
      final result = allocator.allocate(
        rangeStart: 100,
        rangeEnd: 199,
        usedNumbers: {100, 101, 102},
      );

      expect(result, 103);
    });

    test('allocates range start when empty', () {
      final result = allocator.allocate(
        rangeStart: 200,
        rangeEnd: 299,
        usedNumbers: {},
      );

      expect(result, 200);
    });

    test('preserves current number inside category range', () {
      final result = allocator.keepOrAllocate(
        currentNumber: 105,
        rangeStart: 100,
        rangeEnd: 199,
        usedNumbers: {100, 101},
      );

      expect(result, 105);
    });

    test('allocates new number when category changes', () {
      final result = allocator.keepOrAllocate(
        currentNumber: 105,
        rangeStart: 200,
        rangeEnd: 299,
        usedNumbers: {200, 201},
      );

      expect(result, 202);
    });

    test('does not allocate a number used by another channel', () {
      final result = allocator.allocate(
        rangeStart: 100,
        rangeEnd: 102,
        usedNumbers: {100, 102},
      );

      expect(result, 101);
    });

    test('throws when category range is full', () {
      expect(
        () => allocator.allocate(
          rangeStart: 100,
          rangeEnd: 102,
          usedNumbers: {100, 101, 102},
        ),
        throwsA(isA<ChannelNumberRangeFullException>()),
      );
    });

    test('rejects invalid range', () {
      expect(
        () => allocator.allocate(rangeStart: 0, rangeEnd: 100, usedNumbers: {}),
        throwsArgumentError,
      );
    });
  });
}
