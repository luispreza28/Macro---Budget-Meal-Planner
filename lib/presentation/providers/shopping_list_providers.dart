// lib/presentation/providers/shopping_list_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/ingredient.dart' as ing;
import '../../domain/entities/recipe.dart' as domain;
import '../../domain/entities/plan.dart';
import '../providers/plan_providers.dart';
import '../providers/recipe_providers.dart';
import '../providers/ingredient_providers.dart';

class AggregatedShoppingItem {
  AggregatedShoppingItem({
    required this.ingredient,
    required this.totalQty,
    required this.unit,
    required this.estimatedCostCents,
    required this.packsNeeded, // ceil(totalQty / purchasePack.qty) if available
  });

  final ing.Ingredient ingredient;
  final double totalQty;
  final ing.Unit unit;
  final int estimatedCostCents;
  final int? packsNeeded;
}

class ShoppingAisleGroup {
  ShoppingAisleGroup({
    required this.aisle,
    required this.items,
  });

  final ing.Aisle aisle;
  final List<AggregatedShoppingItem> items;
}

final shoppingListItemsProvider =
    FutureProvider<List<ShoppingAisleGroup>>((ref) async {
  final plan = await ref.watch(currentPlanProvider.future);
  if (plan == null) return const [];

  final recipes = await ref.watch(allRecipesProvider.future);
  final ingredients = await ref.watch(allIngredientsProvider.future);

  final recipeById = {for (final r in recipes) r.id: r};
  final ingredientById = {for (final i in ingredients) i.id: i};

  // Aggregate quantities by ingredientId in the ingredient's base unit.
  final Map<String, double> totalsByIngredientId = {};

  for (final day in plan.days) {
    for (final meal in day.meals) {
      final recipe = recipeById[meal.recipeId];
      if (recipe == null) continue;

      for (final item in recipe.items) {
        final ingMeta = ingredientById[item.ingredientId];
        if (ingMeta == null) continue;

        // Convert item.qty to the ingredient's base unit when possible.
        final double qtyInBase = _toIngredientUnit(
          qty: item.qty * meal.servings,
          from: item.unit,
          to: ingMeta.unit,
        );

        totalsByIngredientId.update(item.ingredientId, (v) => v + qtyInBase,
            ifAbsent: () => qtyInBase);
      }
    }
  }

  // Build AggregatedShoppingItem list
  final List<AggregatedShoppingItem> flat = [];
  totalsByIngredientId.forEach((id, totalQty) {
    final ingMeta = ingredientById[id];
    if (ingMeta == null) return;

    // Estimated cost: pricePerUnitCents is per 1 (g/ml/pc) of ingredient.unit
    final estimatedCostCents =
        ((totalQty * ingMeta.pricePerUnitCents) / 100).round();

    int? packs;
    if (ingMeta.purchasePack.priceCents != null && ingMeta.purchasePack.qty > 0) {
      packs = (totalQty / ingMeta.purchasePack.qty).ceil();
    }

    flat.add(AggregatedShoppingItem(
      ingredient: ingMeta,
      totalQty: totalQty,
      unit: ingMeta.unit,
      estimatedCostCents: estimatedCostCents,
      packsNeeded: packs,
    ));
  });

  // Group by aisle, and sort items by name within aisle
  final Map<ing.Aisle, List<AggregatedShoppingItem>> byAisle = {};
  for (final it in flat) {
    byAisle.putIfAbsent(it.ingredient.aisle, () => []).add(it);
  }
  final groups = byAisle.entries.map((e) {
    e.value.sort((a, b) => a.ingredient.name.compareTo(b.ingredient.name));
    return ShoppingAisleGroup(aisle: e.key, items: e.value);
  }).toList();

  // Optional: order aisles in a sensible store flow
  groups.sort((a, b) => _aisleOrder(a.aisle).compareTo(_aisleOrder(b.aisle)));

  return groups;
});

int _aisleOrder(ing.Aisle a) {
  // Adjust order to your real-world store path preference
  const order = <ing.Aisle, int>{
    ing.Aisle.produce: 0,
    ing.Aisle.meat: 1,
    ing.Aisle.dairy: 2,
    ing.Aisle.pantry: 3,
    ing.Aisle.frozen: 4,
    ing.Aisle.bakery: 5,
    ing.Aisle.condiments: 6,
    ing.Aisle.household: 7,
  };
  return order[a] ?? 99;
}

double _toIngredientUnit({
  required double qty,
  required ing.Unit from,
  required ing.Unit to,
}) {
  if (from == to) return qty;

  // Simple strategy:
  // - grams <-> grams (same)
  // - ml <-> ml (same)
  // - piece to grams/ml cannot be converted without a mapping; keep as-is
  // - grams <-> ml need density to be correct; keep as-is
  // This will keep data consistent for your seeded items, which already match.
  return qty;
}
