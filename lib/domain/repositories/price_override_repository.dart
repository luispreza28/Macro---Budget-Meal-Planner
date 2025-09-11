import '../entities/price_override.dart';

/// Repository interface for price override data operations
abstract class PriceOverrideRepository {
  /// Get all price overrides
  Future<List<PriceOverride>> getAllPriceOverrides();

  /// Get price override by ingredient ID
  Future<PriceOverride?> getPriceOverrideByIngredientId(String ingredientId);

  /// Get price overrides by ingredient IDs
  Future<List<PriceOverride>> getPriceOverridesByIngredientIds(
    List<String> ingredientIds,
  );

  /// Add price override
  Future<void> addPriceOverride(PriceOverride override);

  /// Update price override
  Future<void> updatePriceOverride(PriceOverride override);

  /// Delete price override
  Future<void> deletePriceOverride(String id);

  /// Delete price override by ingredient ID
  Future<void> deletePriceOverrideByIngredientId(String ingredientId);

  /// Clear all price overrides
  Future<void> clearAllPriceOverrides();

  /// Check if price override exists for ingredient
  Future<bool> hasPriceOverrideForIngredient(String ingredientId);

  /// Get effective price for ingredient (with override if exists)
  Future<int> getEffectivePriceForIngredient(
    String ingredientId,
    int originalPriceCents,
  );

  /// Get price overrides count
  Future<int> getPriceOverridesCount();

  /// Bulk insert price overrides
  Future<void> bulkInsertPriceOverrides(List<PriceOverride> overrides);

  /// Watch all price overrides (reactive stream)
  Stream<List<PriceOverride>> watchAllPriceOverrides();

  /// Watch price override by ingredient ID (reactive stream)
  Stream<PriceOverride?> watchPriceOverrideByIngredientId(String ingredientId);

  /// Watch price overrides count (reactive stream)
  Stream<int> watchPriceOverridesCount();
}
