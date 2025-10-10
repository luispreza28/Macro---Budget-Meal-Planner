import 'package:drift/drift.dart';

import '../../domain/entities/ingredient.dart' as domain;
import '../../domain/repositories/ingredient_repository.dart';
import '../datasources/database.dart';

/// Concrete implementation of IngredientRepository using Drift
class IngredientRepositoryImpl implements IngredientRepository {
  const IngredientRepositoryImpl(this._database);

  final AppDatabase _database;

  @override
  Future<List<domain.Ingredient>> getAllIngredients() async {
    final ingredients = await _database.select(_database.ingredients).get();
    return ingredients.map(_mapToEntity).toList();
  }

  @override
  Future<domain.Ingredient?> getIngredientById(String id) async {
    final ingredient = await (_database.select(_database.ingredients)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
    
    return ingredient != null ? _mapToEntity(ingredient) : null;
  }

  @override
  Future<List<domain.Ingredient>> getIngredientsByAisle(domain.Aisle aisle) async {
    final ingredients = await (_database.select(_database.ingredients)
          ..where((tbl) => tbl.aisle.equals(aisle.value)))
        .get();
    
    return ingredients.map(_mapToEntity).toList();
  }

  @override
  Future<List<domain.Ingredient>> searchIngredients(String query) async {
    final ingredients = await (_database.select(_database.ingredients)
          ..where((tbl) => tbl.name.like('%$query%')))
        .get();
    
    return ingredients.map(_mapToEntity).toList();
  }

  @override
  Future<List<domain.Ingredient>> getIngredientsByTags(List<String> tags) async {
    if (tags.isEmpty) return getAllIngredients();
    
    // For simplicity, we'll search for ingredients that contain any of the tags
    // In production, this would use proper JSON querying
    final ingredients = await _database.select(_database.ingredients).get();
    
    return ingredients
        .map(_mapToEntity)
        .where((ingredient) => tags.any((tag) => ingredient.hasTag(tag)))
        .toList();
  }

  @override
  Future<List<domain.Ingredient>> getIngredientsForDiet(List<String> dietFlags) async {
    final ingredients = await _database.select(_database.ingredients).get();
    
    return ingredients
        .map(_mapToEntity)
        .where((ingredient) => ingredient.isCompatibleWithDiet(dietFlags))
        .toList();
  }

  @override
  Future<void> addIngredient(domain.Ingredient ingredient) async {
    await _database.into(_database.ingredients).insert(_mapToCompanion(ingredient));
  }

  @override
  Future<void> updateIngredient(domain.Ingredient ingredient) async {
    await _database.update(_database.ingredients).replace(_mapToCompanion(ingredient));
  }

  @override
  Future<void> deleteIngredient(String id) async {
    await (_database.delete(_database.ingredients)..where((tbl) => tbl.id.equals(id))).go();
  }

  @override
  Future<List<domain.Ingredient>> getCheapestIngredients({int limit = 50}) async {
    final ingredients = await (_database.select(_database.ingredients)
          ..orderBy([(tbl) => OrderingTerm.asc(tbl.pricePerUnitCents)])
          ..limit(limit))
        .get();
    
    return ingredients.map(_mapToEntity).toList();
  }

  @override
  Future<List<domain.Ingredient>> getHighProteinIngredients({
    double minProteinPer100g = 15.0,
    int limit = 50,
  }) async {
    final ingredients = await (_database.select(_database.ingredients)
          ..where((tbl) => tbl.proteinPer100g.isBiggerOrEqualValue(minProteinPer100g))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.proteinPer100g)])
          ..limit(limit))
        .get();
    
    return ingredients.map(_mapToEntity).toList();
  }

  @override
  Future<void> bulkInsertIngredients(List<domain.Ingredient> ingredients) async {
    await _database.batch((batch) {
      for (final ingredient in ingredients) {
        batch.insert(_database.ingredients, _mapToCompanion(ingredient));
      }
    });
  }

  @override
  Future<bool> ingredientExists(String id) async {
    final count = await (_database.selectOnly(_database.ingredients)
          ..addColumns([_database.ingredients.id.count()])
          ..where(_database.ingredients.id.equals(id)))
        .getSingle();
    
    return count.read(_database.ingredients.id.count())! > 0;
  }

  @override
  Future<int> getIngredientsCount() async {
    final count = await (_database.selectOnly(_database.ingredients)
          ..addColumns([_database.ingredients.id.count()]))
        .getSingle();
    
    return count.read(_database.ingredients.id.count()) ?? 0;
  }

  @override
  Stream<List<domain.Ingredient>> watchAllIngredients() {
    return _database.select(_database.ingredients).watch().map(
          (ingredients) => ingredients.map(_mapToEntity).toList(),
        );
  }

  @override
  Stream<domain.Ingredient?> watchIngredientById(String id) {
    return (_database.select(_database.ingredients)
          ..where((tbl) => tbl.id.equals(id)))
        .watchSingleOrNull()
        .map((ingredient) => ingredient != null ? _mapToEntity(ingredient) : null);
  }

  @override
  Future<void> upsertNutritionAndPrice({
    required String id,
    required domain.NutritionPer100 per100,
    required domain.Unit unit,
    int? pricePerUnitCents,
    double packQty = 0,
    int? packPriceCents,
  }) async {
    final existing = await (_database.select(_database.ingredients)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();

    final name = existing?.name ?? _humanizeId(id);
    final aisle = existing?.aisle ?? domain.Aisle.pantry.value;
    final tags = existing?.tags ?? '[]';
    final source = existing?.source ?? domain.IngredientSource.manual.value;
    final now = DateTime.now();

    final unitStr = unit.value;
    final int pricePerUnit = pricePerUnitCents ?? existing?.pricePerUnitCents ?? 0;
    final double packQtyUse = (packQty > 0)
        ? packQty
        : (existing != null ? existing.purchasePackQty : 0);
    final String packUnitUse = unitStr; // align purchase pack unit with base unit
    final int? packPriceUse = packPriceCents ?? existing?.purchasePackPriceCents;

    final companion = IngredientsCompanion(
      id: Value(id),
      name: Value(name),
      unit: Value(unitStr),
      kcalPer100g: Value(per100.kcal),
      proteinPer100g: Value(per100.proteinG),
      carbsPer100g: Value(per100.carbsG),
      fatPer100g: Value(per100.fatG),
      pricePerUnitCents: Value(pricePerUnit),
      purchasePackQty: Value(packQtyUse),
      purchasePackUnit: Value(packUnitUse),
      purchasePackPriceCents: Value(packPriceUse),
      aisle: Value(aisle),
      tags: Value(tags),
      source: Value(source),
      lastVerifiedAt: Value(now),
      updatedAt: Value(now),
    );

    if (existing == null) {
      await _database.into(_database.ingredients).insert(companion);
    } else {
      await (_database.update(_database.ingredients)
            ..where((t) => t.id.equals(id)))
          .write(companion);
    }
  }

  /// Maps database row to domain entity
  domain.Ingredient _mapToEntity(Ingredient data) {
    return domain.Ingredient(
      id: data.id,
      name: data.name,
        unit: domain.Unit.values.firstWhere((u) => u.value == data.unit),
        macrosPer100g: domain.MacrosPerHundred(
        kcal: data.kcalPer100g,
        proteinG: data.proteinPer100g,
        carbsG: data.carbsPer100g,
        fatG: data.fatPer100g,
      ),
      pricePerUnitCents: data.pricePerUnitCents,
        purchasePack: domain.PurchasePack(
          qty: data.purchasePackQty,
          unit: domain.Unit.values.firstWhere((u) => u.value == data.purchasePackUnit),
        priceCents: data.purchasePackPriceCents,
      ),
        aisle: domain.Aisle.values.firstWhere((a) => a.value == data.aisle),
        tags: _parseJsonStringList(data.tags),
        source: domain.IngredientSource.values.firstWhere((s) => s.value == data.source),
      lastVerifiedAt: data.lastVerifiedAt,
    );
  }

  /// Maps domain entity to database companion
  IngredientsCompanion _mapToCompanion(domain.Ingredient ingredient) {
    return IngredientsCompanion(
      id: Value(ingredient.id),
      name: Value(ingredient.name),
      unit: Value(ingredient.unit.value),
      kcalPer100g: Value(ingredient.macrosPer100g.kcal),
      proteinPer100g: Value(ingredient.macrosPer100g.proteinG),
      carbsPer100g: Value(ingredient.macrosPer100g.carbsG),
      fatPer100g: Value(ingredient.macrosPer100g.fatG),
      pricePerUnitCents: Value(ingredient.pricePerUnitCents),
      purchasePackQty: Value(ingredient.purchasePack.qty),
      purchasePackUnit: Value(ingredient.purchasePack.unit.value),
      purchasePackPriceCents: Value(ingredient.purchasePack.priceCents),
      aisle: Value(ingredient.aisle.value),
      tags: Value(_encodeJsonStringList(ingredient.tags)),
      source: Value(ingredient.source.value),
      lastVerifiedAt: Value(ingredient.lastVerifiedAt),
      updatedAt: Value(DateTime.now()),
    );
  }

  /// Parse JSON string list (simple implementation)
  List<String> _parseJsonStringList(String jsonString) {
    try {
      // Simple implementation - in production would use proper JSON parsing
      if (jsonString.isEmpty || jsonString == '[]') return [];
      return jsonString
          .replaceAll('[', '')
          .replaceAll(']', '')
          .replaceAll('"', '')
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Encode string list to JSON (simple implementation)
  String _encodeJsonStringList(List<String> list) {
    if (list.isEmpty) return '[]';
    return '[${list.map((s) => '"$s"').join(',')}]';
  }

  String _humanizeId(String id) {
    final base = id.replaceAll(RegExp(r'^[^a-zA-Z0-9]+'), '');
    return base
        .replaceAll('_', ' ')
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }
}
