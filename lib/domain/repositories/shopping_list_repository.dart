import '../value/shortfall_item.dart';
import '../entities/ingredient.dart';

/// Repository interface for manipulating user-added Shopping List items
/// (e.g., Pantry Shortfalls). Persistence is per-plan when a plan id is
/// provided, else stored under a global key.
abstract class ShoppingListRepository {
  Future<void> addShortfalls(List<ShortfallItem> items, {String? planId});

  /// Returns checked items (ingredientId, qty, unit) for a plan, if any.
  Future<List<({String ingredientId, double qty, Unit unit})>> getCheckedItems({String? planId});

  /// Clears checked items for a plan (or globally if null planId).
  Future<void> clearCheckedItems({String? planId});
}
