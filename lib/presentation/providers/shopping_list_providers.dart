// lib/presentation/providers/shopping_list_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/ingredient.dart' as ing;
import '../providers/database_providers.dart';
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
  ShoppingAisleGroup({required this.aisle, required this.items});

  final ing.Aisle aisle;
  final List<AggregatedShoppingItem> items;
}

/// Reactive builder: recomputes whenever plan/recipes/ingredients change.
/// Watches the upstream streams so any change triggers a recompute.
final shoppingListItemsProvider = FutureProvider<List<ShoppingAisleGroup>>((
  ref,
) async {
  // Watch the STREAM providers directly so changes invalidate/recompute this provider.
  final planAsync = ref.watch(currentPlanProvider);
  final recipesAsync = ref.watch(allRecipesProvider);
  final ingredientsAsync = ref.watch(allIngredientsProvider);

  final plan = planAsync.value;
  if (plan == null) return const [];

  // If streams haven’t emitted yet, fall back to repos (single shot).
  // If they have data, use that data.
  final recipeRepo = ref.read(recipeRepositoryProvider);
  final ingredientRepo = ref.read(ingredientRepositoryProvider);

  var recipes = recipesAsync.value;
  recipes ??= await recipeRepo.getAllRecipes();

  var ingredients = ingredientsAsync.value;
  ingredients ??= await ingredientRepo.getAllIngredients();

  if (recipes.isEmpty || ingredients.isEmpty) {
    return const [];
  }

  final recipeById = {for (final r in recipes) r.id: r};
  final ingredientById = {for (final i in ingredients) i.id: i};
  final Map<String, double> totalsByIngredientId = {};

  for (final day in plan.days) {
    for (final meal in day.meals) {
      final recipe = recipeById[meal.recipeId];
      if (recipe == null || recipe.items.isEmpty) continue;

      for (final item in recipe.items) {
        final ingMeta = ingredientById[item.ingredientId];
        if (ingMeta == null) continue;

        final double qtyInBase = _toIngredientUnit(
          qty: item.qty * meal.servings,
          from: item.unit,
          to: ingMeta.unit,
        );

        totalsByIngredientId.update(
          item.ingredientId,
          (v) => v + qtyInBase,
          ifAbsent: () => qtyInBase,
        );
      }
    }
  }

  if (totalsByIngredientId.isEmpty) {
    return const [];
  }

  final List<AggregatedShoppingItem> flat = [];
  totalsByIngredientId.forEach((id, totalQty) {
    final ingMeta = ingredientById[id];
    if (ingMeta == null) return;

    // FIX: keep cost in CENTS (don’t divide by 100 here)
    final estimatedCostCents = (totalQty * ingMeta.pricePerUnitCents).round();

    int? packs;
    if (ingMeta.purchasePack.priceCents != null &&
        ingMeta.purchasePack.qty > 0) {
      packs = (totalQty / ingMeta.purchasePack.qty).ceil();
    }

    flat.add(
      AggregatedShoppingItem(
        ingredient: ingMeta,
        totalQty: totalQty,
        unit: ingMeta.unit,
        estimatedCostCents: estimatedCostCents,
        packsNeeded: packs,
      ),
    );
  });

  if (flat.isEmpty) {
    return const [];
  }

  final Map<ing.Aisle, List<AggregatedShoppingItem>> byAisle = {};
  for (final it in flat) {
    byAisle.putIfAbsent(it.ingredient.aisle, () => []).add(it);
  }

  final groups = byAisle.entries.map((e) {
    e.value.sort((a, b) => a.ingredient.name.compareTo(b.ingredient.name));
    return ShoppingAisleGroup(aisle: e.key, items: e.value);
  }).toList();

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

final shoppingListDebugProvider = FutureProvider<String>((ref) async {
  final plan = ref.watch(currentPlanProvider).value;
  final recipes = ref.watch(allRecipesProvider).value;
  final ingredients = ref.watch(allIngredientsProvider).value;

  if (plan == null) return 'No current plan.';
  final rc = recipes?.length ?? 0;
  final ic = ingredients?.length ?? 0;

  int meals = 0, missingRecipe = 0, emptyItems = 0, missingIngredient = 0, ok = 0;
  final recipeById = {for (final r in (recipes ?? [])) r.id: r};
  final ingredientById = {for (final i in (ingredients ?? [])) i.id: i};

  for (final day in plan.days) {
    for (final meal in day.meals) {
      meals++;
      final r = recipeById[meal.recipeId];
      if (r == null) { missingRecipe++; continue; }
      if (r.items.isEmpty) { emptyItems++; continue; }
      bool anyMissing = false;
      for (final it in r.items) {
        if (!ingredientById.containsKey(it.ingredientId)) { anyMissing = true; missingIngredient++; }
      }
      if (!anyMissing) ok++;
    }
  }

  return 'Plan ok. Recipes: $rc, Ingredients: $ic, Meals: $meals, '
         'MissingRecipe: $missingRecipe, EmptyItems: $emptyItems, '
         'MissingIngredientRefs: $missingIngredient, MealsUsable: $ok';
});
