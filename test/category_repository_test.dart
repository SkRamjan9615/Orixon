import 'package:orixon/core/database/app_database.dart';
import 'package:orixon/features/live_tv/data/repositories/category_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late CategoryRepository repository;

  const canonicalNames = [
    'Movies',
    'Sports',
    'News',
    'Kids',
    'Music',
    'Entertainment',
    'General',
    'Others',
  ];

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = CategoryRepository(database: database);
  });

  tearDown(() async {
    await database.close();
  });

  group('CategoryRepository', () {
    test('creates exactly eight canonical categories', () async {
      final category = await repository.getOrCreateCategory('Entertainment');
      final all = await repository.getAllCategories();

      expect(category.name, 'Entertainment');
      expect(all.map((c) => c.name).toList(), canonicalNames);
      expect(all.map((c) => c.rangeStart).toList(), [
        1, 101, 201, 301, 401, 501, 601, 1801,
      ]);
      expect(all.map((c) => c.rangeEnd).toList(), [
        100, 200, 300, 400, 500, 600, 700, 10000,
      ]);
      expect(all.map((c) => c.sortOrder).toList(), [0, 1, 2, 3, 4, 5, 6, 7]);
    });

    test('returns existing canonical category without duplicates', () async {
      final first = await repository.getOrCreateCategory('Sports');
      final second = await repository.getOrCreateCategory(' sports ');

      final all = await database.select(database.categories).get();

      expect(second.id, first.id);
      expect(all.length, 8);
      expect(all.where((c) => c.name == 'Sports').length, 1);
      expect(all.any((c) => c.name == 'Favourite'), isFalse);
    });

    test('maps canonical and unknown names correctly', () async {
      final entertainment = await repository.getOrCreateCategory('Entertainment');
      final general = await repository.getOrCreateCategory('General');
      final unknown = await repository.getOrCreateCategory('Uncategorized');

      expect(entertainment.name, 'Entertainment');
      expect(general.name, 'General');
      expect(general.id, isNot(entertainment.id));
      expect(unknown.name, 'Others');
    });

    test('trims and normalizes canonical category names', () async {
      final category = await repository.getOrCreateCategory('  sPoRtS  ');

      expect(category.name, 'Sports');
    });

    test('rejects empty category name without creating categories', () async {
      await expectLater(
        repository.getOrCreateCategory('   '),
        throwsArgumentError,
      );

      final all = await database.select(database.categories).get();
      expect(all, isEmpty);
    });

    test('rejects overlapping existing ranges', () async {
      await database
          .into(database.categories)
          .insert(
            CategoriesCompanion.insert(
              name: 'First',
              rangeStart: 1,
              rangeEnd: 150,
              sortOrder: 0,
            ),
          );
      await database
          .into(database.categories)
          .insert(
            CategoriesCompanion.insert(
              name: 'Second',
              rangeStart: 100,
              rangeEnd: 200,
              sortOrder: 1,
            ),
          );

      await expectLater(repository.getAllCategories(), throwsArgumentError);

      final all = await database.select(database.categories).get();
      expect(all.length, 2);
    });
  });
}
