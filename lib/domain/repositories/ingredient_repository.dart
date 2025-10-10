import '../entities/ingredient.dart';

/// Repository interface for ingredient data operations
abstract class IngredientRepository {
  /// Get all ingredients
  Future<List<Ingredient>> getAllIngredients();

  /// Get ingredient by ID
  Future<Ingredient?> getIngredientById(String id);

  /// Get ingredients by aisle
  Future<List<Ingredient>> getIngredientsByAisle(Aisle aisle);

  /// Search ingredients by name
  Future<List<Ingredient>> searchIngredients(String query);

  /// Get ingredients by tags
  Future<List<Ingredient>> getIngredientsByTags(List<String> tags);

  /// Get ingredients compatible with diet flags
  Future<List<Ingredient>> getIngredientsForDiet(List<String> dietFlags);

  /// Add new ingredient
  Future<void> addIngredient(Ingredient ingredient);

  /// Update existing ingredient
  Future<void> updateIngredient(Ingredient ingredient);

  /// Delete ingredient
  Future<void> deleteIngredient(String id);

  /// Get ingredients with lowest cost per 100g
  Future<List<Ingredient>> getCheapestIngredients({int limit = 50});

  /// Get high protein ingredients
  Future<List<Ingredient>> getHighProteinIngredients({
    double minProteinPer100g = 15.0,
    int limit = 50,
  });

  /// Bulk insert ingredients (for seed data)
  Future<void> bulkInsertIngredients(List<Ingredient> ingredients);

  /// Check if ingredient exists
  Future<bool> ingredientExists(String id);

  /// Get ingredients count
  Future<int> getIngredientsCount();

  /// Watch all ingredients (reactive stream)
  Stream<List<Ingredient>> watchAllIngredients();

  /// Watch ingredient by ID (reactive stream)
  Stream<Ingredient?> watchIngredientById(String id);

  /// Upsert minimal nutrition/pricing fields for a given ingredient id
  Future<void> upsertNutritionAndPrice({
    required String id,
    required NutritionPer100 per100,
    required Unit unit,
    int? pricePerUnitCents,
    double packQty = 0,
    int? packPriceCents,
  });
}
