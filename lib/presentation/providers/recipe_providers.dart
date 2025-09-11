import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/recipe.dart';
import '../../domain/repositories/recipe_repository.dart';
import 'database_providers.dart';

/// Provider for all recipes
final allRecipesProvider = StreamProvider<List<Recipe>>((ref) {
  final repository = ref.watch(recipeRepositoryProvider);
  return repository.watchAllRecipes();
});

/// Provider for recipe search
final recipeSearchProvider = 
    FutureProvider.family<List<Recipe>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final repository = ref.watch(recipeRepositoryProvider);
  return repository.searchRecipes(query);
});

/// Provider for recipes compatible with diet
final recipesForDietProvider = 
    StreamProvider.family<List<Recipe>, List<String>>((ref, dietFlags) {
  final repository = ref.watch(recipeRepositoryProvider);
  return repository.watchRecipesForDiet(dietFlags);
});

/// Provider for recipes within time constraint
final recipesWithinTimeProvider = 
    FutureProvider.family<List<Recipe>, int>((ref, maxTimeMins) {
  final repository = ref.watch(recipeRepositoryProvider);
  return repository.getRecipesWithinTime(maxTimeMins);
});

/// Provider for cutting recipes (high volume, high protein)
final cuttingRecipesProvider = FutureProvider<List<Recipe>>((ref) {
  final repository = ref.watch(recipeRepositoryProvider);
  return repository.getCuttingRecipes();
});

/// Provider for bulking recipes (calorie dense)
final bulkingRecipesProvider = FutureProvider<List<Recipe>>((ref) {
  final repository = ref.watch(recipeRepositoryProvider);
  return repository.getBulkingRecipes();
});

/// Provider for quick recipes (≤15 mins)
final quickRecipesProvider = FutureProvider<List<Recipe>>((ref) {
  final repository = ref.watch(recipeRepositoryProvider);
  return repository.getQuickRecipes();
});

/// Provider for high protein recipes
final highProteinRecipesProvider = FutureProvider<List<Recipe>>((ref) {
  final repository = ref.watch(recipeRepositoryProvider);
  return repository.getHighProteinRecipes();
});

/// Provider for cost-effective recipes
final costEffectiveRecipesProvider = FutureProvider<List<Recipe>>((ref) {
  final repository = ref.watch(recipeRepositoryProvider);
  return repository.getCostEffectiveRecipes();
});

/// Provider for single recipe by ID
final recipeByIdProvider = 
    StreamProvider.family<Recipe?, String>((ref, id) {
  final repository = ref.watch(recipeRepositoryProvider);
  return repository.watchRecipeById(id);
});

/// Provider for recipes by multiple IDs
final recipesByIdsProvider = 
    FutureProvider.family<List<Recipe>, List<String>>((ref, ids) {
  final repository = ref.watch(recipeRepositoryProvider);
  return repository.getRecipesByIds(ids);
});

/// Provider for recipes count
final recipesCountProvider = FutureProvider<int>((ref) {
  final repository = ref.watch(recipeRepositoryProvider);
  return repository.getRecipesCount();
});

/// Notifier for managing recipe operations
class RecipeNotifier extends StateNotifier<AsyncValue<void>> {
  RecipeNotifier(this._repository) : super(const AsyncValue.data(null));

  final RecipeRepository _repository;

  Future<void> addRecipe(Recipe recipe) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.addRecipe(recipe));
  }

  Future<void> updateRecipe(Recipe recipe) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.updateRecipe(recipe));
  }

  Future<void> deleteRecipe(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.deleteRecipe(id));
  }
}

/// Provider for recipe operations
final recipeNotifierProvider = 
    StateNotifierProvider<RecipeNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(recipeRepositoryProvider);
  return RecipeNotifier(repository);
});
