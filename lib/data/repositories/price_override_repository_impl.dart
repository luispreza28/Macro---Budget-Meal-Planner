import 'package:drift/drift.dart';

import '../../domain/entities/price_override.dart' as domain;
import '../../domain/repositories/price_override_repository.dart';
import '../datasources/database.dart';

/// Concrete implementation of PriceOverrideRepository using Drift
class PriceOverrideRepositoryImpl implements PriceOverrideRepository {
  const PriceOverrideRepositoryImpl(this._database);

  final AppDatabase _database;

  @override
  Future<List<domain.PriceOverride>> getAllPriceOverrides() async {
    final overrides = await _database.select(_database.priceOverrides).get();
    return overrides.map(_mapToEntity).toList();
  }

  @override
  Future<domain.PriceOverride?> getPriceOverrideById(String id) async {
    final override = await (_database.select(_database.priceOverrides)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
    
    return override != null ? _mapToEntity(override) : null;
  }

  @override
  Future<domain.PriceOverride?> getPriceOverrideByIngredient(String ingredientId) async {
    final override = await (_database.select(_database.priceOverrides)
          ..where((tbl) => tbl.ingredientId.equals(ingredientId)))
        .getSingleOrNull();
    
    return override != null ? _mapToEntity(override) : null;
  }

  @override
  Future<void> savePriceOverride(domain.PriceOverride override) async {
    await _database.into(_database.priceOverrides).insert(_mapFromEntity(override));
  }

  @override
  Future<void> updatePriceOverride(domain.PriceOverride override) async {
    await _database.update(_database.priceOverrides).replace(_mapFromEntity(override));
  }

  @override
  Future<void> deletePriceOverride(String id) async {
    await (_database.delete(_database.priceOverrides)
          ..where((tbl) => tbl.id.equals(id)))
        .go();
  }

  @override
  Future<void> deletePriceOverrideByIngredient(String ingredientId) async {
    await (_database.delete(_database.priceOverrides)
          ..where((tbl) => tbl.ingredientId.equals(ingredientId)))
        .go();
  }

  @override
  Future<void> clearAllPriceOverrides() async {
    await _database.delete(_database.priceOverrides).go();
  }

  @override
  Future<bool> hasPriceOverride(String ingredientId) async {
    final count = await (_database.selectOnly(_database.priceOverrides)
          ..addColumns([_database.priceOverrides.id.count()])
          ..where(_database.priceOverrides.ingredientId.equals(ingredientId)))
        .getSingle();
    
    return count.read(_database.priceOverrides.id.count())! > 0;
  }

  @override
  Future<int> getPriceOverridesCount() async {
    final count = await (_database.selectOnly(_database.priceOverrides)
          ..addColumns([_database.priceOverrides.id.count()]))
        .getSingle();
    
    return count.read(_database.priceOverrides.id.count()) ?? 0;
  }

  @override
  Stream<List<domain.PriceOverride>> watchAllPriceOverrides() {
    return _database.select(_database.priceOverrides).watch().map(
          (overrides) => overrides.map(_mapToEntity).toList(),
        );
  }

  @override
  Stream<domain.PriceOverride?> watchPriceOverrideByIngredient(String ingredientId) {
    return (_database.select(_database.priceOverrides)
          ..where((tbl) => tbl.ingredientId.equals(ingredientId)))
        .watchSingleOrNull()
        .map((override) => override != null ? _mapToEntity(override) : null);
  }

  /// Map from database model to domain entity
  domain.PriceOverride _mapToEntity(PriceOverrideData data) {
    return domain.PriceOverride(
      id: data.id,
      ingredientId: data.ingredientId,
      pricePerUnitCents: data.pricePerUnitCents,
      purchasePackQty: data.purchasePackQty,
      purchasePackUnit: domain.Unit.values.firstWhere((u) => u.name == data.purchasePackUnit),
      purchasePackPriceCents: data.purchasePackPriceCents,
      notes: data.notes,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
    );
  }

  /// Map from domain entity to database companion
  PriceOverridesCompanion _mapFromEntity(domain.PriceOverride override) {
    return PriceOverridesCompanion(
      id: Value(override.id),
      ingredientId: Value(override.ingredientId),
      pricePerUnitCents: Value(override.pricePerUnitCents),
      purchasePackQty: Value(override.purchasePackQty),
      purchasePackUnit: Value(override.purchasePackUnit.name),
      purchasePackPriceCents: Value(override.purchasePackPriceCents),
      notes: Value(override.notes),
      createdAt: Value(override.createdAt),
      updatedAt: Value(override.updatedAt),
    );
  }
}
