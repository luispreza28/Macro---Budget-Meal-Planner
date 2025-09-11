import 'package:drift/drift.dart';
import 'dart:convert';

import '../../domain/entities/recipe.dart' as domain;
import '../../domain/repositories/recipe_repository.dart';
import '../datasources/database.dart';

/// Concrete implementation of RecipeRepository using Drift
class RecipeRepositoryImpl implements RecipeRepository {
  const RecipeRepositoryImpl(this._database);

  final AppDatabase _database;

  @override
  Future<List<domain.Recipe>> getAllRecipes() async {
    final recipes = await _database.select(_database.recipes).get();
    return recipes.map(_mapToEntity).toList();
  }

  @override
  Future<domain.Recipe?> getRecipeById(String id) async {
    final recipe = await (_database.select(_database.recipes)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
    
    return recipe != null ? _mapToEntity(recipe) : null;
  }

  @override
  Future<List<domain.Recipe>> searchRecipes(String query) async {
    final recipes = await (_database.select(_database.recipes)
          ..where((tbl) => tbl.name.like('%$query%')))
        .get();
    
    return recipes.map(_mapToEntity).toList();
  }

  @override
  Future<List<domain.Recipe>> getRecipesByCuisine(String cuisine) async {
    final recipes = await (_database.select(_database.recipes)
          ..where((tbl) => tbl.cuisine.equals(cuisine)))
        .get();
    
    return recipes.map(_mapToEntity).toList();
  }

  @override
  Future<List<domain.Recipe>> getRecipesForDiet(List<String> dietFlags) async {
    final recipes = await _database.select(_database.recipes).get();
    
    return recipes
        .map(_mapToEntity)
        .where((recipe) => recipe.isCompatibleWithDiet(dietFlags))
        .toList();
  }

  @override
  Future<List<domain.Recipe>> getRecipesWithinTime(int maxTimeMins) async {
    final recipes = await (_database.select(_database.recipes)
          ..where((tbl) => tbl.timeMins.isSmallerOrEqualValue(maxTimeMins)))
        .get();
    
    return recipes.map(_mapToEntity).toList();
  }

  @override
  Future<List<domain.Recipe>> getRecipesByCostRange({
    int? minCostCents,
    int? maxCostCents,
  }) async {
    var query = _database.select(_database.recipes);
    
    if (minCostCents != null) {
      query = query..where((tbl) => tbl.costPerServCents.isBiggerOrEqualValue(minCostCents));
    }
    
    if (maxCostCents != null) {
      query = query..where((tbl) => tbl.costPerServCents.isSmallerOrEqualValue(maxCostCents));
    }
    
    final recipes = await query.get();
    return recipes.map(_mapToEntity).toList();
  }

  @override
  Future<List<domain.Recipe>> getRecipesByCalorieRange({
    double? minKcal,
    double? maxKcal,
  }) async {
    var query = _database.select(_database.recipes);
    
    if (minKcal != null) {
      query = query..where((tbl) => tbl.kcalPerServ.isBiggerOrEqualValue(minKcal));
    }
    
    if (maxKcal != null) {
      query = query..where((tbl) => tbl.kcalPerServ.isSmallerOrEqualValue(maxKcal));
    }
    
    final recipes = await query.get();
    return recipes.map(_mapToEntity).toList();
  }

  @override
  Future<List<domain.Recipe>> getCuttingRecipes() async {
    final recipes = await _database.select(_database.recipes).get();
    
    return recipes
        .map(_mapToEntity)
        .where((recipe) => 
            recipe.isHighVolume() || 
            recipe.getProteinDensity() > 20 || // High protein density
            recipe.macrosPerServ.kcal < 400) // Lower calorie meals
        .toList();
  }

  @override
  Future<List<domain.Recipe>> getBulkingRecipes() async {
    final recipes = await _database.select(_database.recipes).get();
    
    return recipes
        .map(_mapToEntity)
        .where((recipe) => 
            recipe.isCalorieDense() || 
            recipe.macrosPerServ.kcal > 400) // Higher calorie meals
        .toList();
  }

  @override
  Future<List<domain.Recipe>> getQuickRecipes() async {
    final recipes = await (_database.select(_database.recipes)
          ..where((tbl) => tbl.timeMins.isSmallerOrEqualValue(15)))
        .get();
    
    return recipes.map(_mapToEntity).toList();
  }

  @override
  Future<List<domain.Recipe>> getHighProteinRecipes({int limit = 50}) async {
    final recipes = await (_database.select(_database.recipes)
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.proteinPerServ)])
          ..limit(limit))
        .get();
    
    return recipes.map(_mapToEntity).toList();
  }

  @override
  Future<List<domain.Recipe>> getCostEffectiveRecipes({int limit = 50}) async {
    final recipes = await _database.select(_database.recipes).get();
    
    // Calculate cost efficiency and sort
    final recipesWithEfficiency = recipes
        .map(_mapToEntity)
        .map((recipe) => {
              'recipe': recipe,
              'efficiency': recipe.getCostEfficiency(),
            })
        .toList();
    
    recipesWithEfficiency.sort((a, b) => 
        (a['efficiency'] as double).compareTo(b['efficiency'] as double));
    
    return recipesWithEfficiency
        .take(limit)
        .map((item) => item['recipe'] as domain.Recipe)
        .toList();
  }

  @override
  Future<void> addRecipe(domain.Recipe recipe) async {
    await _database.into(_database.recipes).insert(_mapToCompanion(recipe));
  }

  @override
  Future<void> updateRecipe(domain.Recipe recipe) async {
    await _database.update(_database.recipes).replace(_mapToCompanion(recipe));
  }

  @override
  Future<void> deleteRecipe(String id) async {
    await (_database.delete(_database.recipes)..where((tbl) => tbl.id.equals(id))).go();
  }

  @override
  Future<void> bulkInsertRecipes(List<domain.Recipe> recipes) async {
    await _database.batch((batch) {
      for (final recipe in recipes) {
        batch.insert(_database.recipes, _mapToCompanion(recipe));
      }
    });
  }

  @override
  Future<bool> recipeExists(String id) async {
    final count = await (_database.selectOnly(_database.recipes)
          ..addColumns([_database.recipes.id.count()])
          ..where(_database.recipes.id.equals(id)))
        .getSingle();
    
    return count.read(_database.recipes.id.count())! > 0;
  }

  @override
  Future<int> getRecipesCount() async {
    final count = await (_database.selectOnly(_database.recipes)
          ..addColumns([_database.recipes.id.count()]))
        .getSingle();
    
    return count.read(_database.recipes.id.count()) ?? 0;
  }

  @override
  Future<List<domain.Recipe>> getRecipesByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    
    final recipes = await (_database.select(_database.recipes)
          ..where((tbl) => tbl.id.isIn(ids)))
        .get();
    
    return recipes.map(_mapToEntity).toList();
  }

  @override
  Stream<List<domain.Recipe>> watchAllRecipes() {
    return _database.select(_database.recipes).watch().map(
          (recipes) => recipes.map(_mapToEntity).toList(),
        );
  }

  @override
  Stream<domain.Recipe?> watchRecipeById(String id) {
    return (_database.select(_database.recipes)
          ..where((tbl) => tbl.id.equals(id)))
        .watchSingleOrNull()
        .map((recipe) => recipe != null ? _mapToEntity(recipe) : null);
  }

  @override
  Stream<List<domain.Recipe>> watchRecipesForDiet(List<String> dietFlags) {
    return _database.select(_database.recipes).watch().map(
          (recipes) => recipes
              .map(_mapToEntity)
              .where((recipe) => recipe.isCompatibleWithDiet(dietFlags))
              .toList(),
        );
  }

  /// Maps database row to domain entity
  domain.Recipe _mapToEntity(Recipe data) {
    return domain.Recipe(
      id: data.id,
      name: data.name,
      servings: data.servings,
      timeMins: data.timeMins,
      cuisine: data.cuisine,
      dietFlags: _parseJsonStringList(data.dietFlags),
      items: _parseRecipeItems(data.items),
      steps: _parseJsonStringList(data.steps),
      macrosPerServ: domain.MacrosPerServing(
        kcal: data.kcalPerServ,
        proteinG: data.proteinPerServ,
        carbsG: data.carbsPerServ,
        fatG: data.fatPerServ,
      ),
      costPerServCents: data.costPerServCents,
      source: domain.RecipeSource.values.firstWhere((s) => s.value == data.source),
    );
  }

  /// Maps domain entity to database companion
  RecipesCompanion _mapToCompanion(domain.Recipe recipe) {
    return RecipesCompanion(
      id: Value(recipe.id),
      name: Value(recipe.name),
      servings: Value(recipe.servings),
      timeMins: Value(recipe.timeMins),
      cuisine: Value(recipe.cuisine),
      dietFlags: Value(_encodeJsonStringList(recipe.dietFlags)),
      items: Value(_encodeRecipeItems(recipe.items)),
      steps: Value(_encodeJsonStringList(recipe.steps)),
      kcalPerServ: Value(recipe.macrosPerServ.kcal),
      proteinPerServ: Value(recipe.macrosPerServ.proteinG),
      carbsPerServ: Value(recipe.macrosPerServ.carbsG),
      fatPerServ: Value(recipe.macrosPerServ.fatG),
      costPerServCents: Value(recipe.costPerServCents),
      source: Value(recipe.source.value),
      updatedAt: Value(DateTime.now()),
    );
  }

  /// Parse JSON string list
  List<String> _parseJsonStringList(String jsonString) {
    try {
      if (jsonString.isEmpty || jsonString == '[]') return [];
      final decoded = jsonDecode(jsonString);
      return List<String>.from(decoded);
    } catch (e) {
      return [];
    }
  }

  /// Encode string list to JSON
  String _encodeJsonStringList(List<String> list) {
    return jsonEncode(list);
  }

  /// Parse recipe items from JSON
  List<domain.RecipeItem> _parseRecipeItems(String jsonString) {
    try {
      if (jsonString.isEmpty || jsonString == '[]') return [];
      final decoded = jsonDecode(jsonString) as List;
      return decoded.map((item) => domain.RecipeItem.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Encode recipe items to JSON
  String _encodeRecipeItems(List<domain.RecipeItem> items) {
    return jsonEncode(items.map((item) => item.toJson()).toList());
  }
}
