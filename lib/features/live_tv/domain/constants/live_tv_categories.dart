class LiveTvCategories {
  LiveTvCategories._();

  static const int othersRangeEnd = 10000;

  static const List<String> names = [
    'Movies',
    'Sports',
    'News',
    'Kids',
    'Music',
    'Entertainment',
    'General',
    'Others',
  ];

  static String resolve(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    if (normalized.isEmpty) return 'Others';

    for (final name in names) {
      if (name.toLowerCase() == normalized) return name;
    }

    if (normalized.contains('entertain')) return 'Entertainment';
    if (normalized.contains('general')) return 'General';
    if (normalized.contains('movie') ||
        normalized.contains('cinema') ||
        normalized.contains('film')) {
      return 'Movies';
    }
    if (normalized.contains('sport')) return 'Sports';
    if (normalized.contains('news')) return 'News';
    if (normalized.contains('kid') || normalized.contains('cartoon')) {
      return 'Kids';
    }
    if (normalized.contains('music') || normalized.contains('song')) {
      return 'Music';
    }

    return 'Others';
  }

  static int sortOrder(String name) => names.indexOf(name);
}
