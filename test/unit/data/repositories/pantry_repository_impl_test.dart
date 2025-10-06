import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:macro_budget_meal_planner/data/repositories/pantry_repository_impl.dart';
import 'package:macro_budget_meal_planner/domain/entities/ingredient.dart'
    as domain;
import 'package:macro_budget_meal_planner/domain/entities/pantry_item.dart'
    as domain;
import 'package:macro_budget_meal_planner/data/datasources/database.dart' as db;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

class _FakePathProviderPlatform extends PathProviderPlatform {
  _FakePathProviderPlatform(this.directory);

  final Directory directory;

  @override
  Future<String?> getApplicationDocumentsPath() async => directory.path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late PathProviderPlatform originalPlatform;
  late db.AppDatabase database;
  late PantryRepositoryImpl repository;

  setUp(() async {
    originalPlatform = PathProviderPlatform.instance;
    tempDir = await Directory.systemTemp.createTemp('pantry_repo_test');
    PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir);
    database = db.AppDatabase();
    repository = PantryRepositoryImpl(database);
  });

  tearDown(() async {
    await database.close();
    PathProviderPlatform.instance = originalPlatform;
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<void> _insertPantryItem({
    required String id,
    required String ingredientId,
    required double qty,
    required domain.Unit unit,
    DateTime? addedAt,
  }) async {
    final item = domain.PantryItem(
      id: id,
      ingredientId: ingredientId,
      qty: qty,
      unit: unit,
      addedAt: addedAt ?? DateTime.now(),
    );
    await repository.addPantryItem(item);
  }

  group('useIngredientsFromPantry validation', () {
    test('throws PantryValidationException when ingredient missing', () async {
      await expectLater(
        repository.useIngredientsFromPantry({'missing': 2}),
        throwsA(
          isA<PantryValidationException>()
              .having((e) => e.issues.length, 'issue count', 1)
              .having((e) => e.issues.first.reason, 'reason', 'missing')
              .having((e) => e.issues.first.availableQty, 'available', 0.0),
        ),
      );
    });

    test('throws PantryValidationException when stock insufficient', () async {
      await _insertPantryItem(
        id: 'pi1',
        ingredientId: 'ing1',
        qty: 1.0,
        unit: domain.Unit.grams,
      );

      await expectLater(
        repository.useIngredientsFromPantry({'ing1': 2.0}),
        throwsA(
          isA<PantryValidationException>()
              .having((e) => e.issues.first.reason, 'reason', 'insufficient')
              .having((e) => e.issues.first.availableQty, 'available', 1.0)
              .having((e) => e.issues.first.requiredQty, 'required', 2.0),
        ),
      );
    });

    test('throws PantryValidationException on unit mismatch', () async {
      final now = DateTime.now();
      await _insertPantryItem(
        id: 'pi1',
        ingredientId: 'ing1',
        qty: 1.0,
        unit: domain.Unit.grams,
        addedAt: now,
      );
      await _insertPantryItem(
        id: 'pi2',
        ingredientId: 'ing1',
        qty: 1.0,
        unit: domain.Unit.milliliters,
        addedAt: now.add(const Duration(seconds: 1)),
      );

      await expectLater(
        repository.useIngredientsFromPantry({'ing1': 1.0}),
        throwsA(
          isA<PantryValidationException>()
              .having((e) => e.issues.first.reason, 'reason', 'unit_mismatch')
              .having((e) => e.issues.first.unitName, 'unitName', 'mixed'),
        ),
      );
    });
  });

  group('useIngredientsFromPantry success and rollback', () {
    test('deducts quantities atomically when validation passes', () async {
      final now = DateTime.now();
      await _insertPantryItem(
        id: 'pi1',
        ingredientId: 'ing1',
        qty: 2.0,
        unit: domain.Unit.grams,
        addedAt: now,
      );
      await _insertPantryItem(
        id: 'pi2',
        ingredientId: 'ing1',
        qty: 3.0,
        unit: domain.Unit.grams,
        addedAt: now.add(const Duration(minutes: 1)),
      );

      await repository.useIngredientsFromPantry({'ing1': 4.0});

      final remaining = await repository.getPantryItemsByIngredientIds([
        'ing1',
      ]);
      final totalQty = remaining.fold<double>(0, (sum, item) => sum + item.qty);
      expect(totalQty, closeTo(1.0, 1e-6));
      expect(remaining.length, 1);
    });

    test(
      'rolls back transaction when stock disappears mid-operation',
      () async {
        await _insertPantryItem(
          id: 'pi1',
          ingredientId: 'ing1',
          qty: 3.0,
          unit: domain.Unit.grams,
        );
        await _insertPantryItem(
          id: 'pi2',
          ingredientId: 'ing2',
          qty: 2.0,
          unit: domain.Unit.grams,
        );

        repository.beforeTransactionCallback = () async {
          await (database.delete(
            database.pantryItems,
          )..where((tbl) => tbl.ingredientId.equals('ing1'))).go();
        };

        await expectLater(
          repository.useIngredientsFromPantry({'ing1': 2.0, 'ing2': 1.0}),
          throwsA(
            isA<PantryValidationException>()
                .having(
                  (e) => e.issues.first.ingredientId,
                  'ingredientId',
                  'ing1',
                )
                .having((e) => e.issues.first.reason, 'reason', 'insufficient'),
          ),
        );

        repository.beforeTransactionCallback = null;

        final rows = await database.select(database.pantryItems).get();
        final byIngredient = {
          for (final row in rows) row.ingredientId: row.qty,
        };
        expect(byIngredient['ing1'], closeTo(3.0, 1e-6));
        expect(byIngredient['ing2'], closeTo(2.0, 1e-6));
      },
    );
  });
}
