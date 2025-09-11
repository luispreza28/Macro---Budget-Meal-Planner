import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/price_override.dart';
import '../../domain/repositories/price_override_repository.dart';
import 'database_providers.dart';

/// Provider for all price overrides
final allPriceOverridesProvider = StreamProvider<List<PriceOverride>>((ref) {
  final repository = ref.watch(priceOverrideRepositoryProvider);
  return repository.watchAllPriceOverrides();
});

/// Provider for price override by ingredient ID
final priceOverrideByIngredientIdProvider = 
    StreamProvider.family<PriceOverride?, String>((ref, ingredientId) {
  final repository = ref.watch(priceOverrideRepositoryProvider);
  return repository.watchPriceOverrideByIngredientId(ingredientId);
});

/// Provider for price overrides by ingredient IDs
final priceOverridesByIngredientIdsProvider = 
    FutureProvider.family<List<PriceOverride>, List<String>>((ref, ingredientIds) {
  final repository = ref.watch(priceOverrideRepositoryProvider);
  return repository.getPriceOverridesByIngredientIds(ingredientIds);
});

/// Provider for price overrides count
final priceOverridesCountProvider = StreamProvider<int>((ref) {
  final repository = ref.watch(priceOverrideRepositoryProvider);
  return repository.watchPriceOverridesCount();
});

/// Provider for checking if ingredient has price override
final hasPriceOverrideForIngredientProvider = 
    FutureProvider.family<bool, String>((ref, ingredientId) {
  final repository = ref.watch(priceOverrideRepositoryProvider);
  return repository.hasPriceOverrideForIngredient(ingredientId);
});

/// Provider for effective price for ingredient
final effectivePriceForIngredientProvider = 
    FutureProvider.family<int, EffectivePriceParams>((ref, params) {
  final repository = ref.watch(priceOverrideRepositoryProvider);
  return repository.getEffectivePriceForIngredient(
    params.ingredientId,
    params.originalPriceCents,
  );
});

/// Parameters for effective price provider
class EffectivePriceParams {
  const EffectivePriceParams({
    required this.ingredientId,
    required this.originalPriceCents,
  });

  final String ingredientId;
  final int originalPriceCents;
}

/// Notifier for managing price override operations
class PriceOverrideNotifier extends StateNotifier<AsyncValue<void>> {
  PriceOverrideNotifier(this._repository) : super(const AsyncValue.data(null));

  final PriceOverrideRepository _repository;

  Future<void> addPriceOverride(PriceOverride override) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.addPriceOverride(override));
  }

  Future<void> updatePriceOverride(PriceOverride override) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.updatePriceOverride(override));
  }

  Future<void> deletePriceOverride(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.deletePriceOverride(id));
  }

  Future<void> deletePriceOverrideByIngredientId(String ingredientId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.deletePriceOverrideByIngredientId(ingredientId));
  }

  Future<void> clearAllPriceOverrides() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.clearAllPriceOverrides());
  }

  Future<void> bulkInsertPriceOverrides(List<PriceOverride> overrides) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.bulkInsertPriceOverrides(overrides));
  }
}

/// Provider for price override operations
final priceOverrideNotifierProvider = 
    StateNotifierProvider<PriceOverrideNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(priceOverrideRepositoryProvider);
  return PriceOverrideNotifier(repository);
});
