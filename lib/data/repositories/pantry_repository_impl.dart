import 'package:drift/drift.dart';

import '../../domain/entities/ingredient.dart';
import '../../domain/entities/pantry_item.dart' as domain;
import '../../domain/repositories/pantry_repository.dart';
import '../datasources/database.dart' as db;

class PantryRepositoryImpl implements PantryRepository {
  PantryRepositoryImpl(this._database);

  final db.AppDatabase _database;

  @override
  Future<List<domain.PantryItem>> getAllPantryItems() async {
    final rows = await _database.select(_database.pantryItems).get();
    return rows.map(_mapToEntity).toList();
  }

  @override
  Future<domain.PantryItem?> getPantryItemByIngredientId(String ingredientId) async {
    final row = await (_database.select(_database.pantryItems)
          ..where((tbl) => tbl.ingredientId.equals(ingredientId)))
        .getSingleOrNull();
    return row != null ? _mapToEntity(row) : null;
  }

  @override
  Future<List<domain.PantryItem>> getPantryItemsByIngredientIds(
    List<String> ingredientIds,
  ) async {
    if (ingredientIds.isEmpty) return const [];
    final rows = await (_database.select(_database.pantryItems)
          ..where((tbl) => tbl.ingredientId.isIn(ingredientIds)))
        .get();
    return rows.map(_mapToEntity).toList();
  }

  @override
  Future<void> addPantryItem(domain.PantryItem item) async {
    await _database.into(_database.pantryItems).insert(
          _mapToCompanion(
            item,
            updatedAt: item.addedAt,
          ),
        );
  }

  @override
  Future<void> updatePantryItem(domain.PantryItem item) async {
    await _database.update(_database.pantryItems).replace(_mapToCompanion(item));
  }

  @override
  Future<void> removePantryItem(String id) async {
    await (_database.delete(_database.pantryItems)..where((tbl) => tbl.id.equals(id))).go();
  }

  @override
  Future<void> removePantryItemByIngredientId(String ingredientId) async {
    await (_database.delete(_database.pantryItems)
          ..where((tbl) => tbl.ingredientId.equals(ingredientId)))
        .go();
  }

  @override
  Future<void> clearPantry() async {
    await _database.delete(_database.pantryItems).go();
  }

  @override
  Future<bool> isIngredientInPantry(String ingredientId) async {
    final result = await (_database.selectOnly(_database.pantryItems)
          ..addColumns([_database.pantryItems.id.count()])
          ..where(_database.pantryItems.ingredientId.equals(ingredientId)))
        .getSingle();
    return (result.read(_database.pantryItems.id.count()) ?? 0) > 0;
  }

  @override
  Future<List<domain.PantryItem>> getPantryItemsWithSufficientQuantity(
    Map<String, double> requiredQuantities,
  ) async {
    if (requiredQuantities.isEmpty) return const [];
    final items = await getPantryItemsByIngredientIds(requiredQuantities.keys.toList());
    return items.where((item) {
      final required = requiredQuantities[item.ingredientId];
      return required != null && item.qty >= required;
    }).toList();
  }

  @override
  Future<void> useIngredientsFromPantry(
    Map<String, double> usedQuantities,
  ) async {
    if (usedQuantities.isEmpty) return;
    await _database.transaction(() async {
      for (final entry in usedQuantities.entries) {
        final ingredientId = entry.key;
        var remaining = entry.value;
        final rows = await (_database.select(_database.pantryItems)
              ..where((tbl) => tbl.ingredientId.equals(ingredientId))
              ..orderBy([(tbl) => OrderingTerm(expression: tbl.createdAt)]))
            .get();
        if (rows.isEmpty) {
          throw StateError('Ingredient not found in pantry: $ingredientId');
        }
        for (final row in rows) {
          if (remaining <= 0) break;
          final item = _mapToEntity(row);
          if (item.qty <= remaining) {
            remaining -= item.qty;
            await removePantryItem(item.id);
          } else {
            final updated = item.copyWith(qty: item.qty - remaining);
            remaining = 0;
            await updatePantryItem(updated);
          }
        }
        if (remaining > 0) {
          throw StateError('Insufficient quantity in pantry for $ingredientId');
        }
      }
    });
  }

  @override
  Future<int> getTotalPantryValueCents() async {
    final rows = await _database.select(_database.pantryItems).get();
    if (rows.isEmpty) return 0;
    final ingredientIds = {
      for (final row in rows) row.ingredientId,
    }.toList();
    final ingredients = await (_database.select(_database.ingredients)
          ..where((tbl) => tbl.id.isIn(ingredientIds)))
        .get();
    final priceByIngredient = {
      for (final ingredient in ingredients) ingredient.id: ingredient.pricePerUnitCents,
    };
    var total = 0;
    for (final row in rows) {
      final pricePerUnit = priceByIngredient[row.ingredientId];
      if (pricePerUnit == null) continue;
      total += (row.qty * pricePerUnit).round();
    }
    return total;
  }

  @override
  Future<int> getPantryItemsCount() async {
    final result = await (_database.selectOnly(_database.pantryItems)
          ..addColumns([_database.pantryItems.id.count()]))
        .getSingle();
    return result.read(_database.pantryItems.id.count()) ?? 0;
  }

  @override
  Future<List<domain.PantryItem>> getPantryItemsByAisle(Aisle aisle) async {
    final query = _database.select(_database.pantryItems).join([
      innerJoin(
        _database.ingredients,
        _database.ingredients.id.equalsExp(_database.pantryItems.ingredientId),
      ),
    ])
      ..where(_database.ingredients.aisle.equals(aisle.value));
    final rows = await query.get();
    return rows.map((row) => _mapToEntity(row.readTable(_database.pantryItems))).toList();
  }

  @override
  Future<void> bulkInsertPantryItems(List<domain.PantryItem> items) async {
    if (items.isEmpty) return;
    await _database.batch((batch) {
      batch.insertAll(
        _database.pantryItems,
        items.map((item) => _mapToCompanion(item, updatedAt: item.addedAt)).toList(),
      );
    });
  }

  @override
  Stream<List<domain.PantryItem>> watchAllPantryItems() {
    return _database.select(_database.pantryItems).watch().map(
          (rows) => rows.map(_mapToEntity).toList(),
        );
  }

  @override
  Stream<domain.PantryItem?> watchPantryItemByIngredientId(String ingredientId) {
    return (_database.select(_database.pantryItems)
          ..where((tbl) => tbl.ingredientId.equals(ingredientId)))
        .watchSingleOrNull()
        .map((row) => row != null ? _mapToEntity(row) : null);
  }

  @override
  Stream<int> watchPantryItemsCount() {
    return (_database.selectOnly(_database.pantryItems)
          ..addColumns([_database.pantryItems.id.count()]))
        .watchSingle()
        .map((row) => row.read(_database.pantryItems.id.count()) ?? 0);
  }

  domain.PantryItem _mapToEntity(db.PantryItem data) {
    return domain.PantryItem(
      id: data.id,
      ingredientId: data.ingredientId,
      qty: data.qty,
      unit: _unitFromString(data.unit),
      addedAt: data.createdAt,
    );
  }

  db.PantryItemsCompanion _mapToCompanion(
    domain.PantryItem item, {
    DateTime? updatedAt,
  }) {
    final timestamp = updatedAt ?? DateTime.now();
    return db.PantryItemsCompanion(
      id: Value(item.id),
      ingredientId: Value(item.ingredientId),
      qty: Value(item.qty),
      unit: Value(item.unit.value),
      createdAt: Value(item.addedAt),
      updatedAt: Value(timestamp),
    );
  }

  Unit _unitFromString(String value) {
    return Unit.values.firstWhere(
      (unit) => unit.value == value,
      orElse: () => Unit.grams,
    );
  }
}
