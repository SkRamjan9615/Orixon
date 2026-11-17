class ChannelNumberRangeFullException implements Exception {
  final int rangeStart;
  final int rangeEnd;

  const ChannelNumberRangeFullException({
    required this.rangeStart,
    required this.rangeEnd,
  });

  @override
  String toString() =>
      'No available channel number in range '
      '$rangeStart-$rangeEnd';
}

class ChannelNumberAllocator {
  const ChannelNumberAllocator();

  int allocate({
    required int rangeStart,
    required int rangeEnd,
    required Set<int> usedNumbers,
  }) {
    if (rangeStart < 1 || rangeEnd < rangeStart) {
      throw ArgumentError('Invalid channel number range.');
    }

    for (var number = rangeStart; number <= rangeEnd; number++) {
      if (!usedNumbers.contains(number)) {
        return number;
      }
    }

    throw ChannelNumberRangeFullException(
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
    );
  }

  int keepOrAllocate({
    required int? currentNumber,
    required int rangeStart,
    required int rangeEnd,
    required Set<int> usedNumbers,
  }) {
    if (rangeStart < 1 || rangeEnd < rangeStart) {
      throw ArgumentError('Invalid channel number range.');
    }

    if (currentNumber != null &&
        currentNumber >= rangeStart &&
        currentNumber <= rangeEnd &&
        !usedNumbers.contains(currentNumber)) {
      return currentNumber;
    }

    return allocate(
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
      usedNumbers: usedNumbers,
    );
  }
}
