import '../entities/recipe.dart';

/// Repository interface for recipe data operations
abstract class RecipeRepository {
  /// Get all recipes
  Future<List<Recipe>> getAllRecipes();

  /// Get recipe by ID
  Future<Recipe?> getRecipeById(String id);

  /// Search recipes by name
  Future<List<Recipe>> searchRecipes(String query);

  /// Get recipes by cuisine
  Future<List<Recipe>> getRecipesByCuisine(String cuisine);

  /// Get recipes compatible with diet flags
  Future<List<Recipe>> getRecipesForDiet(List<String> dietFlags);

  /// Get recipes within time constraint
  Future<List<Recipe>> getRecipesWithinTime(int maxTimeMins);

  /// Get recipes by cost range (per serving)
  Future<List<Recipe>> getRecipesByCostRange({
    int? minCostCents,
    int? maxCostCents,
  });

  /// Get recipes by calorie range (per serving)
  Future<List<Recipe>> getRecipesByCalorieRange({
    double? minKcal,
    double? maxKcal,
  });

  /// Get recipes suitable for cutting (high volume, high protein)
  Future<List<Recipe>> getCuttingRecipes();

  /// Get recipes suitable for bulking (calorie dense)
  Future<List<Recipe>> getBulkingRecipes();

  /// Get quick recipes (≤15 mins)
  Future<List<Recipe>> getQuickRecipes();

  /// Get recipes with highest protein density
  Future<List<Recipe>> getHighProteinRecipes({int limit = 50});

  /// Get most cost-effective recipes (lowest cost per 1000 kcal)
  Future<List<Recipe>> getCostEffectiveRecipes({int limit = 50});

  /// Add new recipe
  Future<void> addRecipe(Recipe recipe);

  /// Update existing recipe
  Future<void> updateRecipe(Recipe recipe);

  /// Delete recipe
  Future<void> deleteRecipe(String id);

  /// Bulk insert recipes (for seed data)
  Future<void> bulkInsertRecipes(List<Recipe> recipes);

  /// Check if recipe exists
  Future<bool> recipeExists(String id);

  /// Get recipes count
  Future<int> getRecipesCount();

  /// Get recipes by multiple IDs
  Future<List<Recipe>> getRecipesByIds(List<String> ids);

  /// Watch all recipes (reactive stream)
  Stream<List<Recipe>> watchAllRecipes();

  /// Watch recipe by ID (reactive stream)
  Stream<Recipe?> watchRecipeById(String id);

  /// Watch recipes for diet (reactive stream)
  Stream<List<Recipe>> watchRecipesForDiet(List<String> dietFlags);
}
