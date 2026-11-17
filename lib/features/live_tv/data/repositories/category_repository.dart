import 'dart:math' as math;
import 'package:drift/drift.dart';
import 'package:orixon/core/database/app_database.dart';
import 'package:orixon/features/live_tv/domain/constants/live_tv_categories.dart';
import 'package:orixon/features/live_tv/domain/services/category_range_allocator.dart';

class CategoryRepository {
  final AppDatabase database;
  final CategoryRangeAllocator rangeAllocator;

  CategoryRepository({
    required this.database,
    this.rangeAllocator = const CategoryRangeAllocator(),
  });

  Future<List<Category>> getAllCategories() async {
    await ensureStandardCategories();
    return (database.select(database.categories)
          ..orderBy([(table) => OrderingTerm.asc(table.sortOrder)]))
        .get();
  }

  Future<void> ensureStandardCategories() async {
    await database.transaction(() async {
      var categories = await database.select(database.categories).get();
      final selected = <String, Category>{};

      // First ensure all standard bounded categories (excluding Others)
      final boundedNames = LiveTvCategories.names.where((n) => n != 'Others');
      for (final name in boundedNames) {
        final matches = categories
            .where((c) => c.name.trim().toLowerCase() == name.toLowerCase())
            .toList()
          ..sort((a, b) {
            final aExact = a.name == name ? 0 : 1;
            final bExact = b.name == name ? 0 : 1;
            return aExact != bExact ? aExact.compareTo(bExact) : a.id.compareTo(b.id);
          });

        if (matches.isNotEmpty) {
          selected[name] = matches.first;
        } else {
          final nonOthersRanges = categories
              .where((c) => c.name.trim().toLowerCase() != 'others')
              .map((c) => CategoryRange(start: c.rangeStart, end: c.rangeEnd))
              .toList();
          final range = rangeAllocator.allocate(existingRanges: nonOthersRanges);
          final id = await database.into(database.categories).insert(
                CategoriesCompanion.insert(
                  name: name,
                  rangeStart: range.start,
                  rangeEnd: range.end,
                  sortOrder: LiveTvCategories.sortOrder(name),
                ),
              );
          final created = await (database.select(database.categories)
                ..where((t) => t.id.equals(id)))
              .getSingle();
          selected[name] = created;
          categories = [...categories, created];
        }
      }

      // Now ensure Others with unlimited upper bound
      final othersMatches = categories
          .where((c) => c.name.trim().toLowerCase() == 'others')
          .toList()
        ..sort((a, b) => a.id.compareTo(b.id));

      final maxBoundedEnd = selected.values.fold<int>(
        0,
        (prev, c) => math.max(prev, c.rangeEnd),
      );

      if (othersMatches.isNotEmpty) {
        final existingOthers = othersMatches.first;
        final safeStart = existingOthers.rangeStart <= maxBoundedEnd
            ? maxBoundedEnd + 1
            : existingOthers.rangeStart;
        await (database.update(database.categories)
              ..where((t) => t.id.equals(existingOthers.id)))
            .write(CategoriesCompanion(
          name: const Value('Others'),
          rangeStart: Value(safeStart),
          rangeEnd: const Value(LiveTvCategories.othersRangeEnd),
          sortOrder: Value(LiveTvCategories.sortOrder('Others')),
        ));
        selected['Others'] = await (database.select(database.categories)
              ..where((t) => t.id.equals(existingOthers.id)))
            .getSingle();
      } else {
        final start = math.max(1801, maxBoundedEnd + 1);
        final id = await database.into(database.categories).insert(
              CategoriesCompanion.insert(
                name: 'Others',
                rangeStart: start,
                rangeEnd: LiveTvCategories.othersRangeEnd,
                sortOrder: LiveTvCategories.sortOrder('Others'),
              ),
            );
        final created = await (database.select(database.categories)
              ..where((t) => t.id.equals(id)))
            .getSingle();
        selected['Others'] = created;
        categories = [...categories, created];
      }

      // Merge duplicate spellings into their canonical row.
      for (final name in LiveTvCategories.names) {
        final target = selected[name]!;
        final duplicates = categories.where((c) =>
            c.id != target.id &&
            c.name.trim().toLowerCase() == name.toLowerCase());
        for (final duplicate in duplicates) {
          await (database.update(database.channels)
                ..where((t) => t.categoryId.equals(duplicate.id)))
              .write(ChannelsCompanion(categoryId: Value(target.id)));
          await (database.delete(database.categories)
                ..where((t) => t.id.equals(duplicate.id)))
              .go();
        }
      }

      final others = selected['Others']!;
      final canonicalIds = selected.values.map((c) => c.id).toSet();
      final obsolete = categories.where((c) => !canonicalIds.contains(c.id));
      for (final category in obsolete) {
        await (database.update(database.channels)
              ..where((t) => t.categoryId.equals(category.id)))
            .write(ChannelsCompanion(categoryId: Value(others.id)));
        await (database.delete(database.categories)
              ..where((t) => t.id.equals(category.id)))
            .go();
      }

      // Canonical spelling and stable order
      for (final name in LiveTvCategories.names) {
        final target = selected[name]!;
        await (database.update(database.categories)
              ..where((t) => t.id.equals(target.id)))
            .write(CategoriesCompanion(
          name: Value(name),
          sortOrder: Value(LiveTvCategories.sortOrder(name)),
          rangeEnd: name == 'Others'
              ? const Value(LiveTvCategories.othersRangeEnd)
              : const Value.absent(),
        ));
      }
    });
  }

  Future<Category> getOrCreateCategory(String name) async {
    if (name.trim().isEmpty) {
      throw ArgumentError('Category name cannot be empty.');
    }
    await ensureStandardCategories();
    final canonicalName = LiveTvCategories.resolve(name);
    return (database.select(database.categories)
          ..where((t) => t.name.equals(canonicalName)))
        .getSingle();
  }
}
