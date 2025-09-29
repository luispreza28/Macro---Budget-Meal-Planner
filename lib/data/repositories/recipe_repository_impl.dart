// lib/data/repositories/recipe_repository_impl.dart
import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/entities/recipe.dart' as domain;
import '../../domain/entities/ingredient.dart' as ing;
import '../../domain/repositories/recipe_repository.dart';
import '../datasources/database.dart';

class RecipeRepositoryImpl implements RecipeRepository {
  RecipeRepositoryImpl(this._db) {
    _seedIfEmpty();
    _backfillItemsIfMissing();
  }

  final AppDatabase _db;

  // ----------------- Mapping -----------------

  domain.Recipe _mapRow(Recipe row) {
    return domain.Recipe(
      id: row.id,
      name: row.name,
      servings: row.servings,
      timeMins: row.timeMins,
      cuisine: row.cuisine,
      dietFlags: _decodeStringList(row.dietFlags),
      items: _decodeRecipeItems(row.items),
      steps: _decodeStringList(row.steps),
      macrosPerServ: domain.MacrosPerServing(
        kcal: row.kcalPerServ,
        proteinG: row.proteinPerServ,
        carbsG: row.carbsPerServ,
        fatG: row.fatPerServ,
      ),
      costPerServCents: row.costPerServCents,
      source: row.source.toLowerCase() == 'manual'
          ? domain.RecipeSource.manual
          : domain.RecipeSource.seed,
    );
  }

  RecipesCompanion _mapCompanion(domain.Recipe r) {
    return RecipesCompanion(
      id: Value(r.id),
      name: Value(r.name),
      servings: Value(r.servings),
      timeMins: Value(r.timeMins),
      cuisine: Value(r.cuisine),
      dietFlags: Value(_encodeStringList(r.dietFlags)),
      items: Value(_encodeRecipeItems(r.items)),
      steps: Value(_encodeStringList(r.steps)),
      kcalPerServ: Value(r.macrosPerServ.kcal),
      proteinPerServ: Value(r.macrosPerServ.proteinG),
      carbsPerServ: Value(r.macrosPerServ.carbsG),
      fatPerServ: Value(r.macrosPerServ.fatG),
      costPerServCents: Value(r.costPerServCents),
      source: Value(r.source.value),
      updatedAt: Value(DateTime.now()),
    );
  }

  // ---------- JSON helpers ----------

  List<String> _decodeStringList(String raw) {
    if (raw.isEmpty) return const [];
    try {
      final list = (json.decode(raw) as List).cast<String>();
      return list;
    } catch (_) {
      return raw
          .replaceAll('[', '')
          .replaceAll(']', '')
          .replaceAll('"', '')
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
  }

  String _encodeStringList(List<String> v) => json.encode(v);

  List<domain.RecipeItem> _decodeRecipeItems(String raw) {
    if (raw.isEmpty) return const [];
    try {
      final list = (json.decode(raw) as List).cast<Map<String, dynamic>>();
      return list.map<domain.RecipeItem>((m) {
        final unitStr = (m['unit'] as String).toLowerCase();
        final unit = ing.Unit.values
            .firstWhere((u) => u.value == unitStr, orElse: () => ing.Unit.grams);
        return domain.RecipeItem(
          ingredientId: m['ingredientId'] as String,
          qty: (m['qty'] as num).toDouble(),
          unit: unit,
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  String _encodeRecipeItems(List<domain.RecipeItem> items) {
    final list = items
        .map((i) => {
              'ingredientId': i.ingredientId,
              'qty': i.qty,
              'unit': i.unit.value,
            })
        .toList();
    return json.encode(list);
  }

  // ----------------- CRUD -----------------

  @override
  Future<List<domain.Recipe>> getAllRecipes() async {
    final rows = await _db.select(_db.recipes).get();
    return rows.map(_mapRow).toList();
  }

  @override
  Future<domain.Recipe?> getRecipeById(String id) async {
    final row = await (_db.select(_db.recipes)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _mapRow(row);
  }

  @override
  Future<List<domain.Recipe>> searchRecipes(String query) async {
    final rows = await (_db.select(_db.recipes)
          ..where((t) => t.name.like('%$query%')))
        .get();
    return rows.map(_mapRow).toList();
  }

  @override
  Future<List<domain.Recipe>> getRecipesByCuisine(String cuisine) async {
    final rows = await (_db.select(_db.recipes)
          ..where((t) => t.cuisine.equals(cuisine)))
        .get();
    return rows.map(_mapRow).toList();
  }

  @override
  Future<List<domain.Recipe>> getRecipesForDiet(List<String> dietFlags) async {
    if (dietFlags.isEmpty) return getAllRecipes();
    final rows = await _db.select(_db.recipes).get();
    return rows
        .map(_mapRow)
        .where((r) => dietFlags.every((f) => r.dietFlags.contains(f)))
        .toList();
  }

  @override
  Future<List<domain.Recipe>> getRecipesWithinTime(int maxTimeMins) async {
    final rows = await (_db.select(_db.recipes)
          ..where((t) => t.timeMins.isSmallerOrEqualValue(maxTimeMins)))
        .get();
    return rows.map(_mapRow).toList();
  }

  @override
  Future<List<domain.Recipe>> getRecipesByCostRange({int? minCostCents, int? maxCostCents}) async {
    final q = _db.select(_db.recipes);
    if (minCostCents != null) {
      q.where((t) => t.costPerServCents.isBiggerOrEqualValue(minCostCents));
    }
    if (maxCostCents != null) {
      q.where((t) => t.costPerServCents.isSmallerOrEqualValue(maxCostCents));
    }
    final rows = await q.get();
    return rows.map(_mapRow).toList();
  }

  @override
  Future<List<domain.Recipe>> getRecipesByCalorieRange({double? minKcal, double? maxKcal}) async {
    final q = _db.select(_db.recipes);
    if (minKcal != null) q.where((t) => t.kcalPerServ.isBiggerOrEqualValue(minKcal));
    if (maxKcal != null) q.where((t) => t.kcalPerServ.isSmallerOrEqualValue(maxKcal));
    final rows = await q.get();
    return rows.map(_mapRow).toList();
  }

  @override
  Future<List<domain.Recipe>> getCuttingRecipes() async {
    final rows = await (_db.select(_db.recipes)
          ..orderBy([(t) => OrderingTerm.desc(t.proteinPerServ)]))
        .get();
    return rows.map(_mapRow).toList();
  }

  @override
  Future<List<domain.Recipe>> getBulkingRecipes() async {
    final rows = await (_db.select(_db.recipes)
          ..orderBy([(t) => OrderingTerm.desc(t.kcalPerServ)]))
        .get();
    return rows.map(_mapRow).toList();
  }

  @override
  Future<List<domain.Recipe>> getQuickRecipes() async {
    final rows = await (_db.select(_db.recipes)
          ..where((t) => t.timeMins.isSmallerOrEqualValue(15)))
        .get();
    return rows.map(_mapRow).toList();
  }

  @override
  Future<List<domain.Recipe>> getHighProteinRecipes({int limit = 50}) async {
    final rows = await (_db.select(_db.recipes)
          ..orderBy([(t) => OrderingTerm.desc(t.proteinPerServ)])
          ..limit(limit))
        .get();
    return rows.map(_mapRow).toList();
  }

  @override
  Future<List<domain.Recipe>> getCostEffectiveRecipes({int limit = 50}) async {
    final rows = await (_db.select(_db.recipes)
          ..orderBy([(t) => OrderingTerm.asc(t.costPerServCents)])
          ..limit(limit))
        .get();
    return rows.map(_mapRow).toList();
  }

  @override
  Future<void> addRecipe(domain.Recipe recipe) async {
    await _db.into(_db.recipes).insert(_mapCompanion(recipe));
  }

  @override
  Future<void> updateRecipe(domain.Recipe recipe) async {
    await _db.update(_db.recipes).replace(_mapCompanion(recipe));
  }

  @override
  Future<void> deleteRecipe(String id) async {
    await (_db.delete(_db.recipes)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<void> bulkInsertRecipes(List<domain.Recipe> recipes) async {
    await _db.batch((b) {
      for (final r in recipes) {
        b.insert(_db.recipes, _mapCompanion(r));
      }
    });
  }

  @override
  Future<bool> recipeExists(String id) async {
    final res = await (_db.selectOnly(_db.recipes)
          ..addColumns([_db.recipes.id.count()])
          ..where(_db.recipes.id.equals(id)))
        .getSingle();
    return (res.read(_db.recipes.id.count()) ?? 0) > 0;
  }

  @override
  Future<int> getRecipesCount() async {
    final res = await (_db.selectOnly(_db.recipes)
          ..addColumns([_db.recipes.id.count()]))
        .getSingle();
    return res.read(_db.recipes.id.count()) ?? 0;
  }

  @override
  Future<List<domain.Recipe>> getRecipesByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final rows = await (_db.select(_db.recipes)
          ..where((t) => t.id.isIn(ids)))
        .get();
    return rows.map(_mapRow).toList();
  }

  @override
  Stream<List<domain.Recipe>> watchAllRecipes() {
    return _db
        .select(_db.recipes)
        .watch()
        .map((rows) => rows.map(_mapRow).toList());
  }

  @override
  Stream<domain.Recipe?> watchRecipeById(String id) {
    return (_db.select(_db.recipes)..where((t) => t.id.equals(id)))
        .watchSingleOrNull()
        .map((row) => row == null ? null : _mapRow(row));
  }

  @override
  Stream<List<domain.Recipe>> watchRecipesForDiet(List<String> dietFlags) {
    return _db.select(_db.recipes).watch().map((rows) {
      final mapped = rows.map(_mapRow).toList();
      if (dietFlags.isEmpty) return mapped;
      return mapped
          .where((r) => dietFlags.every((f) => r.dietFlags.contains(f)))
          .toList();
    });
  }

  // ----------------- Backfill for existing installs -----------------

  // Known default items per recipe (per *serving*).
  static final Map<String, List<domain.RecipeItem>> _defaultItemsByRecipeId = {
    'rec_oat_pb': const [
      domain.RecipeItem(ingredientId: 'ing_oats_rolled', qty: 50, unit: ing.Unit.grams),
      domain.RecipeItem(ingredientId: 'ing_milk', qty: 200, unit: ing.Unit.milliliters),
      domain.RecipeItem(ingredientId: 'ing_peanut_butter', qty: 32, unit: ing.Unit.grams),
      domain.RecipeItem(ingredientId: 'ing_salt_pepper', qty: 1, unit: ing.Unit.grams),
    ],
    'rec_chicken_rice': const [
      domain.RecipeItem(ingredientId: 'ing_chicken_breast_raw', qty: 150, unit: ing.Unit.grams),
      domain.RecipeItem(ingredientId: 'ing_rice_cooked', qty: 150, unit: ing.Unit.grams),
      domain.RecipeItem(ingredientId: 'ing_olive_oil', qty: 5, unit: ing.Unit.grams),
      domain.RecipeItem(ingredientId: 'ing_salt_pepper', qty: 1, unit: ing.Unit.grams),
    ],
    'rec_yogurt_bowl': const [
      domain.RecipeItem(ingredientId: 'ing_greek_yogurt', qty: 200, unit: ing.Unit.grams),
      domain.RecipeItem(ingredientId: 'ing_olive_oil', qty: 0, unit: ing.Unit.grams),
    ],
    'rec_veggie_omelette': const [
      domain.RecipeItem(ingredientId: 'ing_egg', qty: 120, unit: ing.Unit.grams),
      domain.RecipeItem(ingredientId: 'ing_bell_pepper', qty: 50, unit: ing.Unit.grams),
      domain.RecipeItem(ingredientId: 'ing_onion', qty: 30, unit: ing.Unit.grams),
      domain.RecipeItem(ingredientId: 'ing_cheese', qty: 30, unit: ing.Unit.grams),
      domain.RecipeItem(ingredientId: 'ing_olive_oil', qty: 5, unit: ing.Unit.grams),
      domain.RecipeItem(ingredientId: 'ing_salt_pepper', qty: 1, unit: ing.Unit.grams),
    ],
  };

  // Also allow mapping by normalized name (covers older ids).
  static final Map<String, List<domain.RecipeItem>> _defaultItemsByName = {
    'peanut butter oatmeal': _defaultItemsByRecipeId['rec_oat_pb']!,
    'chicken & rice': _defaultItemsByRecipeId['rec_chicken_rice']!,
    'chicken and rice': _defaultItemsByRecipeId['rec_chicken_rice']!,
    'greek yogurt bowl': _defaultItemsByRecipeId['rec_yogurt_bowl']!,
    'veggie omelette': _defaultItemsByRecipeId['rec_veggie_omelette']!,
  };

  String _norm(String s) =>
      s.toLowerCase().replaceAll('&', 'and').replaceAll(RegExp(r'\s+'), ' ').trim();

  Future<void> _backfillItemsIfMissing() async {
    final rows = await _db.select(_db.recipes).get();
    if (rows.isEmpty) return;

    for (final row in rows) {
      final hasItems = row.items.isNotEmpty && row.items.trim() != '[]';
      if (hasItems) continue;

      List<domain.RecipeItem>? defaults = _defaultItemsByRecipeId[row.id];
      if (defaults == null || defaults.isEmpty) {
        defaults = _defaultItemsByName[_norm(row.name)];
      }
      if (defaults == null || defaults.isEmpty) continue;

      final itemsJson = _encodeRecipeItems(defaults);
      await (_db.update(_db.recipes)..where((t) => t.id.equals(row.id))).write(
        RecipesCompanion(
          items: Value(itemsJson),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  // ----------------- Minimal Seed (for fresh DBs) -----------------

  Future<void> _seedIfEmpty() async {
    final count = await getRecipesCount();
    if (count > 0) return;

    await _ensureIngredients();

    List<domain.Recipe> demo = [
      domain.Recipe(
        id: 'rec_oat_pb',
        name: 'Peanut Butter Oatmeal',
        servings: 1,
        timeMins: 8,
        cuisine: 'american',
        dietFlags: const ['qui', 'hig'],
        items: _defaultItemsByRecipeId['rec_oat_pb'] ?? const [],
        steps: const ['Cook oats with milk', 'Stir in peanut butter', 'Season to taste'],
        macrosPerServ: const domain.MacrosPerServing(kcal: 400, proteinG: 18, carbsG: 45, fatG: 16),
        costPerServCents: 120,
        source: domain.RecipeSource.seed,
      ),
      domain.Recipe(
        id: 'rec_chicken_rice',
        name: 'Chicken & Rice',
        servings: 1,
        timeMins: 25,
        cuisine: 'american',
        dietFlags: const ['hig'],
        items: _defaultItemsByRecipeId['rec_chicken_rice'] ?? const [],
        steps: const ['Pan sear chicken', 'Serve over rice', 'Season'],
        macrosPerServ: const domain.MacrosPerServing(kcal: 550, proteinG: 45, carbsG: 55, fatG: 15),
        costPerServCents: 250,
        source: domain.RecipeSource.seed,
      ),
      domain.Recipe(
        id: 'rec_yogurt_bowl',
        name: 'Greek Yogurt Bowl',
        servings: 1,
        timeMins: 5,
        cuisine: 'mediterranean',
        dietFlags: const ['qui', 'hig'],
        items: _defaultItemsByRecipeId['rec_yogurt_bowl'] ?? const [],
        steps: const ['Spoon into bowl'],
        macrosPerServ: const domain.MacrosPerServing(kcal: 300, proteinG: 22, carbsG: 12, fatG: 9),
        costPerServCents: 180,
        source: domain.RecipeSource.seed,
      ),
      domain.Recipe(
        id: 'rec_veggie_omelette',
        name: 'Veggie Omelette',
        servings: 1,
        timeMins: 10,
        cuisine: 'french',
        dietFlags: const ['qui'],
        items: _defaultItemsByRecipeId['rec_veggie_omelette'] ?? const [],
        steps: const ['Saute veg', 'Add eggs', 'Fold with cheese'],
        macrosPerServ: const domain.MacrosPerServing(kcal: 450, proteinG: 28, carbsG: 8, fatG: 34),
        costPerServCents: 210,
        source: domain.RecipeSource.seed,
      ),
    ];

    await bulkInsertRecipes(demo);
  }

  Future<void> _ensureIngredients() async {
    final res = await _db.customSelect('SELECT COUNT(*) AS c FROM ingredients').getSingle();
    final count = (res.data['c'] as int?) ?? 0;
    if (count > 0) return;

    String tags(List<String> v) => json.encode(v);

    await _db.batch((b) {
      b.insert(_db.ingredients, IngredientsCompanion.insert(
        id: 'ing_oats_rolled',
        name: 'Rolled oats',
        unit: ing.Unit.grams.value,
        kcalPer100g: 389,
        proteinPer100g: 17,
        carbsPer100g: 66,
        fatPer100g: 7,
        pricePerUnitCents: 20,
        purchasePackQty: 1000,
        purchasePackUnit: ing.Unit.grams.value,
        purchasePackPriceCents: const Value(200),
        aisle: ing.Aisle.pantry.value,
        tags: tags(['qui']),
        source: ing.IngredientSource.seed.value,
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));
      b.insert(_db.ingredients, IngredientsCompanion.insert(
        id: 'ing_peanut_butter',
        name: 'Peanut butter',
        unit: ing.Unit.grams.value,
        kcalPer100g: 588,
        proteinPer100g: 25,
        carbsPer100g: 20,
        fatPer100g: 50,
        pricePerUnitCents: 25,
        purchasePackQty: 454,
        purchasePackUnit: ing.Unit.grams.value,
        purchasePackPriceCents: const Value(350),
        aisle: ing.Aisle.pantry.value,
        tags: tags(['hig']),
        source: ing.IngredientSource.seed.value,
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));
      b.insert(_db.ingredients, IngredientsCompanion.insert(
        id: 'ing_milk',
        name: 'Milk',
        unit: ing.Unit.milliliters.value,
        kcalPer100g: 64,
        proteinPer100g: 3.4,
        carbsPer100g: 5,
        fatPer100g: 3.6,
        pricePerUnitCents: 10,
        purchasePackQty: 1000,
        purchasePackUnit: ing.Unit.milliliters.value,
        purchasePackPriceCents: const Value(100),
        aisle: ing.Aisle.dairy.value,
        tags: tags([]),
        source: ing.IngredientSource.seed.value,
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));
      b.insert(_db.ingredients, IngredientsCompanion.insert(
        id: 'ing_greek_yogurt',
        name: 'Greek yogurt',
        unit: ing.Unit.grams.value,
        kcalPer100g: 59,
        proteinPer100g: 10,
        carbsPer100g: 3.6,
        fatPer100g: 0.4,
        pricePerUnitCents: 18,
        purchasePackQty: 500,
        purchasePackUnit: ing.Unit.grams.value,
        purchasePackPriceCents: const Value(250),
        aisle: ing.Aisle.dairy.value,
        tags: tags(['hig']),
        source: ing.IngredientSource.seed.value,
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));
      b.insert(_db.ingredients, IngredientsCompanion.insert(
        id: 'ing_rice_cooked',
        name: 'Cooked white rice',
        unit: ing.Unit.grams.value,
        kcalPer100g: 130,
        proteinPer100g: 2.4,
        carbsPer100g: 28,
        fatPer100g: 0.3,
        pricePerUnitCents: 5,
        purchasePackQty: 1000,
        purchasePackUnit: ing.Unit.grams.value,
        purchasePackPriceCents: const Value(50),
        aisle: ing.Aisle.pantry.value,
        tags: tags([]),
        source: ing.IngredientSource.seed.value,
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));
      b.insert(_db.ingredients, IngredientsCompanion.insert(
        id: 'ing_chicken_breast_raw',
        name: 'Chicken breast (raw)',
        unit: ing.Unit.grams.value,
        kcalPer100g: 120,
        proteinPer100g: 23,
        carbsPer100g: 0,
        fatPer100g: 2.6,
        pricePerUnitCents: 35,
        purchasePackQty: 1000,
        purchasePackUnit: ing.Unit.grams.value,
        purchasePackPriceCents: const Value(350),
        aisle: ing.Aisle.meat.value,
        tags: tags(['hig']),
        source: ing.IngredientSource.seed.value,
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));
      b.insert(_db.ingredients, IngredientsCompanion.insert(
        id: 'ing_olive_oil',
        name: 'Olive oil',
        unit: ing.Unit.grams.value,
        kcalPer100g: 884,
        proteinPer100g: 0,
        carbsPer100g: 0,
        fatPer100g: 100,
        pricePerUnitCents: 120,
        purchasePackQty: 500,
        purchasePackUnit: ing.Unit.milliliters.value,
        purchasePackPriceCents: const Value(600),
        aisle: ing.Aisle.pantry.value,
        tags: tags([]),
        source: ing.IngredientSource.seed.value,
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));
      b.insert(_db.ingredients, IngredientsCompanion.insert(
        id: 'ing_egg',
        name: 'Egg',
        unit: ing.Unit.grams.value,
        kcalPer100g: 155,
        proteinPer100g: 13,
        carbsPer100g: 1.1,
        fatPer100g: 11,
        pricePerUnitCents: 25,
        purchasePackQty: 600,
        purchasePackUnit: ing.Unit.grams.value,
        purchasePackPriceCents: const Value(150),
        aisle: ing.Aisle.dairy.value,
        tags: tags([]),
        source: ing.IngredientSource.seed.value,
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));
      b.insert(_db.ingredients, IngredientsCompanion.insert(
        id: 'ing_bell_pepper',
        name: 'Bell pepper',
        unit: ing.Unit.grams.value,
        kcalPer100g: 31,
        proteinPer100g: 1,
        carbsPer100g: 6,
        fatPer100g: 0.3,
        pricePerUnitCents: 30,
        purchasePackQty: 500,
        purchasePackUnit: ing.Unit.grams.value,
        purchasePackPriceCents: const Value(150),
        aisle: ing.Aisle.produce.value,
        tags: tags([]),
        source: ing.IngredientSource.seed.value,
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));
      b.insert(_db.ingredients, IngredientsCompanion.insert(
        id: 'ing_onion',
        name: 'Onion',
        unit: ing.Unit.grams.value,
        kcalPer100g: 40,
        proteinPer100g: 1.1,
        carbsPer100g: 9.3,
        fatPer100g: 0.1,
        pricePerUnitCents: 15,
        purchasePackQty: 1000,
        purchasePackUnit: ing.Unit.grams.value,
        purchasePackPriceCents: const Value(150),
        aisle: ing.Aisle.produce.value,
        tags: tags([]),
        source: ing.IngredientSource.seed.value,
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));
      b.insert(_db.ingredients, IngredientsCompanion.insert(
        id: 'ing_cheese',
        name: 'Cheddar cheese',
        unit: ing.Unit.grams.value,
        kcalPer100g: 403,
        proteinPer100g: 25,
        carbsPer100g: 1.3,
        fatPer100g: 33,
        pricePerUnitCents: 90,
        purchasePackQty: 200,
        purchasePackUnit: ing.Unit.grams.value,
        purchasePackPriceCents: const Value(180),
        aisle: ing.Aisle.dairy.value,
        tags: tags([]),
        source: ing.IngredientSource.seed.value,
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));
      b.insert(_db.ingredients, IngredientsCompanion.insert(
        id: 'ing_salt_pepper',
        name: 'Salt & pepper',
        unit: ing.Unit.grams.value,
        kcalPer100g: 0,
        proteinPer100g: 0,
        carbsPer100g: 0,
        fatPer100g: 0,
        pricePerUnitCents: 1,
        purchasePackQty: 100,
        purchasePackUnit: ing.Unit.grams.value,
        purchasePackPriceCents: const Value(100),
        aisle: ing.Aisle.pantry.value,
        tags: tags([]),
        source: ing.IngredientSource.seed.value,
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ));
    });
  }
}
