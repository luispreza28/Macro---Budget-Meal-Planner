import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/ingredient.dart';
import '../../domain/repositories/ingredient_repository.dart';
import 'database_providers.dart';

/// Provider for all ingredients
final allIngredientsProvider = StreamProvider<List<Ingredient>>((ref) {
  final repository = ref.watch(ingredientRepositoryProvider);
  return repository.watchAllIngredients();
});

/// Provider for ingredients by aisle
final ingredientsByAisleProvider = 
    StreamProvider.family<List<Ingredient>, Aisle>((ref, aisle) {
  final repository = ref.watch(ingredientRepositoryProvider);
  return Stream.fromFuture(repository.getIngredientsByAisle(aisle));
});

/// Provider for ingredient search
final ingredientSearchProvider = 
    FutureProvider.family<List<Ingredient>, String>((ref, query) async {
  if (query.isEmpty) return [];
  final repository = ref.watch(ingredientRepositoryProvider);
  return repository.searchIngredients(query);
});

/// Provider for high protein ingredients
final highProteinIngredientsProvider = FutureProvider<List<Ingredient>>((ref) {
  final repository = ref.watch(ingredientRepositoryProvider);
  return repository.getHighProteinIngredients();
});

/// Provider for cheapest ingredients
final cheapestIngredientsProvider = FutureProvider<List<Ingredient>>((ref) {
  final repository = ref.watch(ingredientRepositoryProvider);
  return repository.getCheapestIngredients();
});

/// Provider for ingredients compatible with diet
final ingredientsForDietProvider = 
    FutureProvider.family<List<Ingredient>, List<String>>((ref, dietFlags) {
  final repository = ref.watch(ingredientRepositoryProvider);
  return repository.getIngredientsForDiet(dietFlags);
});

/// Provider for single ingredient by ID
final ingredientByIdProvider = 
    StreamProvider.family<Ingredient?, String>((ref, id) {
  final repository = ref.watch(ingredientRepositoryProvider);
  return repository.watchIngredientById(id);
});

/// Provider for ingredients count
final ingredientsCountProvider = FutureProvider<int>((ref) {
  final repository = ref.watch(ingredientRepositoryProvider);
  return repository.getIngredientsCount();
});

/// Notifier for managing ingredient operations
class IngredientNotifier extends StateNotifier<AsyncValue<void>> {
  IngredientNotifier(this._repository) : super(const AsyncValue.data(null));

  final IngredientRepository _repository;

  Future<void> addIngredient(Ingredient ingredient) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.addIngredient(ingredient));
  }

  Future<void> updateIngredient(Ingredient ingredient) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.updateIngredient(ingredient));
  }

  Future<void> deleteIngredient(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.deleteIngredient(id));
  }
}

/// Provider for ingredient operations
final ingredientNotifierProvider = 
    StateNotifierProvider<IngredientNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(ingredientRepositoryProvider);
  return IngredientNotifier(repository);
});
