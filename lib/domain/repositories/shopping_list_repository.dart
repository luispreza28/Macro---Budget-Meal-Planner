import '../value/shortfall_item.dart';

/// Repository interface for manipulating user-added Shopping List items
/// (e.g., Pantry Shortfalls). Persistence is per-plan when a plan id is
/// provided, else stored under a global key.
abstract class ShoppingListRepository {
  Future<void> addShortfalls(List<ShortfallItem> items, {String? planId});
}

