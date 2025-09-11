import '../entities/pantry_item.dart';
import '../entities/ingredient.dart';

/// Repository interface for pantry data operations
abstract class PantryRepository {
  /// Get all pantry items
  Future<List<PantryItem>> getAllPantryItems();

  /// Get pantry item by ingredient ID
  Future<PantryItem?> getPantryItemByIngredientId(String ingredientId);

  /// Get pantry items by ingredient IDs
  Future<List<PantryItem>> getPantryItemsByIngredientIds(List<String> ingredientIds);

  /// Add item to pantry
  Future<void> addPantryItem(PantryItem item);

  /// Update pantry item quantity
  Future<void> updatePantryItem(PantryItem item);

  /// Remove item from pantry
  Future<void> removePantryItem(String id);

  /// Remove pantry item by ingredient ID
  Future<void> removePantryItemByIngredientId(String ingredientId);

  /// Clear all pantry items
  Future<void> clearPantry();

  /// Check if ingredient is in pantry
  Future<bool> isIngredientInPantry(String ingredientId);

  /// Get pantry items with sufficient quantity for recipe
  Future<List<PantryItem>> getPantryItemsWithSufficientQuantity(
    Map<String, double> requiredQuantities,
  );

  /// Use ingredients from pantry (reduce quantities)
  Future<void> useIngredientsFromPantry(
    Map<String, double> usedQuantities,
  );

  /// Get total pantry value in cents
  Future<int> getTotalPantryValueCents();

  /// Get pantry items count
  Future<int> getPantryItemsCount();

  /// Get pantry items by aisle
  Future<List<PantryItem>> getPantryItemsByAisle(Aisle aisle);

  /// Bulk insert pantry items
  Future<void> bulkInsertPantryItems(List<PantryItem> items);

  /// Watch all pantry items (reactive stream)
  Stream<List<PantryItem>> watchAllPantryItems();

  /// Watch pantry item by ingredient ID (reactive stream)
  Stream<PantryItem?> watchPantryItemByIngredientId(String ingredientId);

  /// Watch pantry items count (reactive stream)
  Stream<int> watchPantryItemsCount();
}
