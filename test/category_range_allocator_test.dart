import 'package:flutter_test/flutter_test.dart';
import 'package:orixon/features/live_tv/domain/services/category_range_allocator.dart';

void main() {
  const allocator = CategoryRangeAllocator();

  group('CategoryRangeAllocator', () {
    test('allocates first 100-number block when empty', () {
      final result = allocator.allocate(existingRanges: []);
      expect(result.start, 1);
      expect(result.end, 100);
    });

    test('allocates next block after existing range', () {
      final result = allocator.allocate(
        existingRanges: [const CategoryRange(start: 1, end: 100)],
      );
      expect(result.start, 101);
      expect(result.end, 200);
    });

    test('finds first available gap', () {
      final result = allocator.allocate(
        existingRanges: [
          const CategoryRange(start: 1, end: 100),
          const CategoryRange(start: 201, end: 300),
        ],
      );
      expect(result.start, 101);
      expect(result.end, 200);
    });

    test('sorts ranges before allocation', () {
      final result = allocator.allocate(
        existingRanges: [
          const CategoryRange(start: 201, end: 300),
          const CategoryRange(start: 1, end: 100),
        ],
      );
      expect(result.start, 101);
      expect(result.end, 200);
    });

    test('rejects overlapping ranges', () {
      expect(
        () => allocator.allocate(
          existingRanges: [
            const CategoryRange(start: 1, end: 150),
            const CategoryRange(start: 100, end: 200),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('rejects invalid existing range', () {
      expect(
        () => allocator.allocate(
          existingRanges: [const CategoryRange(start: 0, end: 100)],
        ),
        throwsArgumentError,
      );
    });

    test('rejects overlap even after an available gap', () {
      expect(
        () => allocator.allocate(
          existingRanges: [
            const CategoryRange(start: 1, end: 100),
            const CategoryRange(start: 201, end: 300),
            const CategoryRange(start: 250, end: 350),
          ],
        ),
        throwsArgumentError,
      );
    });
  });
}
