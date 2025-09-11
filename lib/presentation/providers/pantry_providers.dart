import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/pantry_item.dart';
import '../../domain/entities/ingredient.dart';
import '../../domain/repositories/pantry_repository.dart';
import 'database_providers.dart';

/// Provider for all pantry items
final allPantryItemsProvider = StreamProvider<List<PantryItem>>((ref) {
  final repository = ref.watch(pantryRepositoryProvider);
  return repository.watchAllPantryItems();
});

/// Provider for pantry item by ingredient ID
final pantryItemByIngredientIdProvider = 
    StreamProvider.family<PantryItem?, String>((ref, ingredientId) {
  final repository = ref.watch(pantryRepositoryProvider);
  return repository.watchPantryItemByIngredientId(ingredientId);
});

/// Provider for pantry items by ingredient IDs
final pantryItemsByIngredientIdsProvider = 
    FutureProvider.family<List<PantryItem>, List<String>>((ref, ingredientIds) {
  final repository = ref.watch(pantryRepositoryProvider);
  return repository.getPantryItemsByIngredientIds(ingredientIds);
});

/// Provider for pantry items count
final pantryItemsCountProvider = StreamProvider<int>((ref) {
  final repository = ref.watch(pantryRepositoryProvider);
  return repository.watchPantryItemsCount();
});

/// Provider for pantry items by aisle
final pantryItemsByAisleProvider = 
    FutureProvider.family<List<PantryItem>, Aisle>((ref, aisle) {
  final repository = ref.watch(pantryRepositoryProvider);
  return repository.getPantryItemsByAisle(aisle);
});

/// Provider for total pantry value
final totalPantryValueProvider = FutureProvider<int>((ref) {
  final repository = ref.watch(pantryRepositoryProvider);
  return repository.getTotalPantryValueCents();
});

/// Provider for checking if ingredient is in pantry
final isIngredientInPantryProvider = 
    FutureProvider.family<bool, String>((ref, ingredientId) {
  final repository = ref.watch(pantryRepositoryProvider);
  return repository.isIngredientInPantry(ingredientId);
});

/// Provider for pantry items with sufficient quantity
final pantryItemsWithSufficientQuantityProvider = 
    FutureProvider.family<List<PantryItem>, Map<String, double>>((ref, requiredQuantities) {
  final repository = ref.watch(pantryRepositoryProvider);
  return repository.getPantryItemsWithSufficientQuantity(requiredQuantities);
});

/// Notifier for managing pantry operations
class PantryNotifier extends StateNotifier<AsyncValue<void>> {
  PantryNotifier(this._repository) : super(const AsyncValue.data(null));

  final PantryRepository _repository;

  Future<void> addPantryItem(PantryItem item) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.addPantryItem(item));
  }

  Future<void> updatePantryItem(PantryItem item) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.updatePantryItem(item));
  }

  Future<void> removePantryItem(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.removePantryItem(id));
  }

  Future<void> removePantryItemByIngredientId(String ingredientId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.removePantryItemByIngredientId(ingredientId));
  }

  Future<void> clearPantry() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.clearPantry());
  }

  Future<void> useIngredientsFromPantry(Map<String, double> usedQuantities) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.useIngredientsFromPantry(usedQuantities));
  }

  Future<void> bulkInsertPantryItems(List<PantryItem> items) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.bulkInsertPantryItems(items));
  }
}

/// Provider for pantry operations
final pantryNotifierProvider = 
    StateNotifierProvider<PantryNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(pantryRepositoryProvider);
  return PantryNotifier(repository);
});
