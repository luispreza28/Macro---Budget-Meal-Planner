import 'package:drift/drift.dart';

import '../../domain/entities/ingredient.dart';
import '../../domain/entities/price_override.dart' as domain;
import '../../domain/repositories/price_override_repository.dart';
import '../datasources/database.dart' as db;

class PriceOverrideRepositoryImpl implements PriceOverrideRepository {
  PriceOverrideRepositoryImpl(this._database);

  final db.AppDatabase _database;

  @override
  Future<List<domain.PriceOverride>> getAllPriceOverrides() async {
    final rows = await _database.select(_database.priceOverrides).get();
    return rows.map(_mapToEntity).toList();
  }

  @override
  Future<domain.PriceOverride?> getPriceOverrideByIngredientId(String ingredientId) async {
    final row = await (_database.select(_database.priceOverrides)
          ..where((tbl) => tbl.ingredientId.equals(ingredientId)))
        .getSingleOrNull();
    return row != null ? _mapToEntity(row) : null;
  }

  @override
  Future<List<domain.PriceOverride>> getPriceOverridesByIngredientIds(
    List<String> ingredientIds,
  ) async {
    if (ingredientIds.isEmpty) return const [];
    final rows = await (_database.select(_database.priceOverrides)
          ..where((tbl) => tbl.ingredientId.isIn(ingredientIds)))
        .get();
    return rows.map(_mapToEntity).toList();
  }

  @override
  Future<void> addPriceOverride(domain.PriceOverride override) async {
    final now = DateTime.now();
    await _database.into(_database.priceOverrides).insert(
          _mapToCompanion(
            override,
            updatedAt: now,
            includeCreatedAt: true,
          ),
        );
  }

  @override
  Future<void> updatePriceOverride(domain.PriceOverride override) async {
    await _database.update(_database.priceOverrides).replace(
          _mapToCompanion(
            override,
            includeCreatedAt: false,
          ),
        );
  }

  @override
  Future<void> deletePriceOverride(String id) async {
    await (_database.delete(_database.priceOverrides)..where((tbl) => tbl.id.equals(id))).go();
  }

  @override
  Future<void> deletePriceOverrideByIngredientId(String ingredientId) async {
    await (_database.delete(_database.priceOverrides)
          ..where((tbl) => tbl.ingredientId.equals(ingredientId)))
        .go();
  }

  @override
  Future<void> clearAllPriceOverrides() async {
    await _database.delete(_database.priceOverrides).go();
  }

  @override
  Future<bool> hasPriceOverrideForIngredient(String ingredientId) async {
    final result = await (_database.selectOnly(_database.priceOverrides)
          ..addColumns([_database.priceOverrides.id.count()])
          ..where(_database.priceOverrides.ingredientId.equals(ingredientId)))
        .getSingle();
    return (result.read(_database.priceOverrides.id.count()) ?? 0) > 0;
  }

  @override
  Future<int> getEffectivePriceForIngredient(
    String ingredientId,
    int originalPriceCents,
  ) async {
    final override = await getPriceOverrideByIngredientId(ingredientId);
    return override?.pricePerUnitCents ?? originalPriceCents;
  }

  @override
  Future<int> getPriceOverridesCount() async {
    final result = await (_database.selectOnly(_database.priceOverrides)
          ..addColumns([_database.priceOverrides.id.count()]))
        .getSingle();
    return result.read(_database.priceOverrides.id.count()) ?? 0;
  }

  @override
  Future<void> bulkInsertPriceOverrides(List<domain.PriceOverride> overrides) async {
    if (overrides.isEmpty) return;
    final now = DateTime.now();
    await _database.batch((batch) {
      batch.insertAll(
        _database.priceOverrides,
        overrides
            .map((override) => _mapToCompanion(
                  override,
                  updatedAt: now,
                  includeCreatedAt: true,
                ))
            .toList(),
      );
    });
  }

  @override
  Stream<List<domain.PriceOverride>> watchAllPriceOverrides() {
    return _database.select(_database.priceOverrides).watch().map(
          (rows) => rows.map(_mapToEntity).toList(),
        );
  }

  @override
  Stream<domain.PriceOverride?> watchPriceOverrideByIngredientId(String ingredientId) {
    return (_database.select(_database.priceOverrides)
          ..where((tbl) => tbl.ingredientId.equals(ingredientId)))
        .watchSingleOrNull()
        .map((row) => row != null ? _mapToEntity(row) : null);
  }

  @override
  Stream<int> watchPriceOverridesCount() {
    return (_database.selectOnly(_database.priceOverrides)
          ..addColumns([_database.priceOverrides.id.count()]))
        .watchSingle()
        .map((row) => row.read(_database.priceOverrides.id.count()) ?? 0);
  }

  domain.PriceOverride _mapToEntity(db.PriceOverride data) {
    PurchasePack? pack;
    if (data.purchasePackQty != null && data.purchasePackUnit != null) {
      pack = PurchasePack(
        qty: data.purchasePackQty!,
        unit: _unitFromString(data.purchasePackUnit!),
        priceCents: data.purchasePackPriceCents,
      );
    }
    return domain.PriceOverride(
      id: data.id,
      ingredientId: data.ingredientId,
      pricePerUnitCents: data.pricePerUnitCents,
      purchasePack: pack,
    );
  }

  db.PriceOverridesCompanion _mapToCompanion(
    domain.PriceOverride override, {
    DateTime? updatedAt,
    required bool includeCreatedAt,
  }) {
    final timestamp = updatedAt ?? DateTime.now();
    return db.PriceOverridesCompanion(
      id: Value(override.id),
      ingredientId: Value(override.ingredientId),
      pricePerUnitCents: Value(override.pricePerUnitCents),
      purchasePackQty: Value(override.purchasePack?.qty),
      purchasePackUnit: Value(override.purchasePack?.unit.value),
      purchasePackPriceCents: Value(override.purchasePack?.priceCents),
      createdAt: includeCreatedAt ? Value(timestamp) : const Value.absent(),
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
