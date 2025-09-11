import 'package:drift/drift.dart';

import '../../domain/entities/pantry_item.dart' as domain;
import '../../domain/repositories/pantry_repository.dart';
import '../datasources/database.dart';

/// Concrete implementation of PantryRepository using Drift
class PantryRepositoryImpl implements PantryRepository {
  const PantryRepositoryImpl(this._database);

  final AppDatabase _database;

  @override
  Future<List<domain.PantryItem>> getAllPantryItems() async {
    final items = await _database.select(_database.pantryItems).get();
    return items.map(_mapToEntity).toList();
  }

  @override
  Future<domain.PantryItem?> getPantryItemById(String id) async {
    final item = await (_database.select(_database.pantryItems)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
    
    return item != null ? _mapToEntity(item) : null;
  }

  @override
  Future<List<domain.PantryItem>> getPantryItemsByIngredient(String ingredientId) async {
    final items = await (_database.select(_database.pantryItems)
          ..where((tbl) => tbl.ingredientId.equals(ingredientId)))
        .get();
    
    return items.map(_mapToEntity).toList();
  }

  @override
  Future<void> addPantryItem(domain.PantryItem item) async {
    await _database.into(_database.pantryItems).insert(_mapFromEntity(item));
  }

  @override
  Future<void> updatePantryItem(domain.PantryItem item) async {
    await _database.update(_database.pantryItems).replace(_mapFromEntity(item));
  }

  @override
  Future<void> deletePantryItem(String id) async {
    await (_database.delete(_database.pantryItems)
          ..where((tbl) => tbl.id.equals(id)))
        .go();
  }

  @override
  Future<void> clearPantry() async {
    await _database.delete(_database.pantryItems).go();
  }

  @override
  Future<double> getAvailableQuantity(String ingredientId, domain.Unit unit) async {
    final items = await getPantryItemsByIngredient(ingredientId);
    
    double totalQuantity = 0.0;
    for (final item in items) {
      if (item.unit == unit) {
        totalQuantity += item.quantity;
      }
      // TODO: Add unit conversion logic here if needed
    }
    
    return totalQuantity;
  }

  @override
  Future<bool> hasIngredient(String ingredientId, {double? minimumQuantity}) async {
    final items = await getPantryItemsByIngredient(ingredientId);
    
    if (items.isEmpty) return false;
    
    if (minimumQuantity == null) return true;
    
    final totalQuantity = items.fold<double>(
      0.0,
      (sum, item) => sum + item.quantity,
    );
    
    return totalQuantity >= minimumQuantity;
  }

  @override
  Future<void> consumeIngredient(String ingredientId, double quantity, domain.Unit unit) async {
    final items = await getPantryItemsByIngredient(ingredientId);
    
    if (items.isEmpty) {
      throw Exception('Ingredient not found in pantry: $ingredientId');
    }
    
    double remainingToConsume = quantity;
    
    for (final item in items) {
      if (remainingToConsume <= 0) break;
      if (item.unit != unit) continue; // TODO: Add unit conversion
      
      if (item.quantity <= remainingToConsume) {
        // Consume entire item
        remainingToConsume -= item.quantity;
        await deletePantryItem(item.id);
      } else {
        // Partially consume item
        final updatedItem = item.copyWith(
          quantity: item.quantity - remainingToConsume,
          updatedAt: DateTime.now(),
        );
        await updatePantryItem(updatedItem);
        remainingToConsume = 0;
      }
    }
    
    if (remainingToConsume > 0) {
      throw Exception('Insufficient quantity in pantry for $ingredientId');
    }
  }

  @override
  Stream<List<domain.PantryItem>> watchAllPantryItems() {
    return _database.select(_database.pantryItems).watch().map(
          (items) => items.map(_mapToEntity).toList(),
        );
  }

  @override
  Stream<List<domain.PantryItem>> watchPantryItemsByIngredient(String ingredientId) {
    return (_database.select(_database.pantryItems)
          ..where((tbl) => tbl.ingredientId.equals(ingredientId)))
        .watch()
        .map((items) => items.map(_mapToEntity).toList());
  }

  /// Map from database model to domain entity
  domain.PantryItem _mapToEntity(PantryItemData data) {
    return domain.PantryItem(
      id: data.id,
      ingredientId: data.ingredientId,
      quantity: data.quantity,
      unit: domain.Unit.values.firstWhere((u) => u.name == data.unit),
      expirationDate: data.expirationDate,
      notes: data.notes,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
    );
  }

  /// Map from domain entity to database companion
  PantryItemsCompanion _mapFromEntity(domain.PantryItem item) {
    return PantryItemsCompanion(
      id: Value(item.id),
      ingredientId: Value(item.ingredientId),
      quantity: Value(item.quantity),
      unit: Value(item.unit.name),
      expirationDate: Value(item.expirationDate),
      notes: Value(item.notes),
      createdAt: Value(item.createdAt),
      updatedAt: Value(item.updatedAt),
    );
  }
}