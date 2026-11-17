class CategoryRange {
  final int start;
  final int end;

  const CategoryRange({required this.start, required this.end});

  @override
  String toString() => '$start-$end';
}

class CategoryRangeAllocator {
  const CategoryRangeAllocator();

  static const int _maxStart = 9223372036854775708;

  CategoryRange allocate({required List<CategoryRange> existingRanges}) {
    final ranges = [...existingRanges];

    for (final range in ranges) {
      if (range.start < 1 || range.end < range.start) {
        throw ArgumentError('Invalid existing category range.');
      }
    }

    ranges.sort((a, b) => a.start.compareTo(b.start));

    // Validate every range before allocating.
    for (var i = 1; i < ranges.length; i++) {
      if (ranges[i].start <= ranges[i - 1].end) {
        throw ArgumentError('Existing category ranges overlap.');
      }
    }

    var candidate = 1;

    for (final range in ranges) {
      if (range.start - candidate >= 100) {
        return CategoryRange(start: candidate, end: candidate + 99);
      }

      if (range.end >= candidate) {
        if (range.end >= _maxStart) {
          throw StateError('No available 100-number block.');
        }
        candidate = range.end + 1;
      }
    }

    if (candidate > _maxStart) {
      throw StateError('No available 100-number block.');
    }

    return CategoryRange(start: candidate, end: candidate + 99);
  }
}
