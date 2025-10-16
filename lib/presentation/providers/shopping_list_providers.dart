// lib/presentation/providers/shopping_list_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/ingredient.dart' as ing;
import '../providers/database_providers.dart';
import '../providers/plan_providers.dart';
import '../providers/recipe_providers.dart';
import '../providers/ingredient_providers.dart';
import '../providers/sub_rules_providers.dart';
import 'dart:convert';

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
  // Aggregate by ingredient + unit to support separate lines for different units.
  final Map<String, Map<ing.Unit, double>> totals = {};

  for (final day in plan.days) {
    for (final meal in day.meals) {
      final recipe = recipeById[meal.recipeId];
      if (recipe == null || recipe.items.isEmpty) continue;

      for (final item in recipe.items) {
        final srcIng = ingredientById[item.ingredientId];
        if (srcIng == null) continue;

        // Convert plan-derived items into source ingredient base unit for consistency.
        final qtyInBase = _toIngredientUnit(
          qty: item.qty * meal.servings,
          from: item.unit,
          to: srcIng.unit,
        );

        // Apply global (scope-less) ALWAYS remap: map A -> B when applicable.
        // For shopping we conservatively apply only rules without scope tags.
        String targetId = item.ingredientId;
        try {
          // use empty tag scope => only rules with empty scopeTags apply.
          final mappedId = await mapAlwaysIngredient(
            ref: ref,
            ing: srcIng,
            recipeTags: <String>{},
          );
          targetId = mappedId;
        } catch (_) {
          targetId = item.ingredientId;
        }

        // If remapped, ensure base units are compatible; otherwise skip remap.
        final targetIng = ingredientById[targetId] ?? srcIng;
        if (targetId != item.ingredientId && targetIng.unit != srcIng.unit) {
          // Units differ (e.g., g vs ml). To avoid invalid merges without density, skip remap.
          // Keep under original ingredient id.
          final byUnit = totals.putIfAbsent(item.ingredientId, () => {});
          byUnit.update(srcIng.unit, (v) => v + qtyInBase, ifAbsent: () => qtyInBase);
          continue;
        }

        final byUnit = totals.putIfAbsent(targetId, () => {});
        byUnit.update(targetIng.unit, (v) => v + qtyInBase, ifAbsent: () => qtyInBase);
      }
    }
  }

  // Merge in user-added extras (e.g., shortfalls) persisted per-plan.
  final extras = await _loadExtrasForPlan(ref, plan.id);
  for (final e in extras) {
    final byUnit = totals.putIfAbsent(e.ingredientId, () => {});
    byUnit.update(e.unit, (v) => v + e.qty, ifAbsent: () => e.qty);
  }

  if (totals.isEmpty) {
    return const [];
  }

  final List<AggregatedShoppingItem> flat = [];
  totals.forEach((id, byUnit) {
    final ingMeta = ingredientById[id];
    if (byUnit.isEmpty || ingMeta == null) return;

    byUnit.forEach((unit, totalQty) {
      int estimatedCostCents = 0;
      int? packs;

      // Only compute pack/cost if the unit matches the ingredient base unit.
      if (unit == ingMeta.unit) {
        final packPrice = ingMeta.purchasePack.priceCents;
        final packQty = ingMeta.purchasePack.qty;
        if (packPrice != null && packQty > 0) {
          packs = (totalQty / packQty).ceil();
          estimatedCostCents = packs * packPrice;
        } else {
          estimatedCostCents = (totalQty * ingMeta.pricePerUnitCents).round();
        }
      }

      flat.add(
        AggregatedShoppingItem(
          ingredient: ingMeta,
          totalQty: totalQty,
          unit: unit,
          estimatedCostCents: estimatedCostCents,
          packsNeeded: packs,
        ),
      );
    });
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

  const double densityGPerMl = 1.0;

  if (from == ing.Unit.grams && to == ing.Unit.milliliters) {
    return qty / densityGPerMl;
  }
  if (from == ing.Unit.milliliters && to == ing.Unit.grams) {
    return qty * densityGPerMl;
  }

  return qty;
}

// ---------- Extras (persisted Shortfalls) ----------

class _Extra {
  _Extra({required this.ingredientId, required this.unit, required this.qty});
  final String ingredientId;
  final ing.Unit unit;
  final double qty;
}

Future<List<_Extra>> _loadExtrasForPlan(Ref ref, String planId) async {
  final prefs = ref.read(sharedPreferencesProvider);
  final key = 'shopping_extras_${planId}';
  final raw = prefs.getString(key);
  if (raw == null || raw.isEmpty) return const [];
  try {
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      return _Extra(
        ingredientId: m['ingredientId'] as String,
        unit: ing.Unit.values.firstWhere(
          (u) => u.name == (m['unit'] as String),
          orElse: () => ing.Unit.grams,
        ),
        qty: (m['qty'] as num).toDouble(),
      );
    }).toList();
  } catch (_) {
    return const [];
  }
}

final shoppingListDebugProvider = FutureProvider<String>((ref) async {
  final plan = ref.watch(currentPlanProvider).value;
  final recipes = ref.watch(allRecipesProvider).value;
  final ingredients = ref.watch(allIngredientsProvider).value;

  if (plan == null) return 'No current plan.';
  final rc = recipes?.length ?? 0;
  final ic = ingredients?.length ?? 0;

  int meals = 0,
      missingRecipe = 0,
      emptyItems = 0,
      missingIngredient = 0,
      ok = 0;
  final recipeById = {for (final r in (recipes ?? [])) r.id: r};
  final ingredientById = {for (final i in (ingredients ?? [])) i.id: i};

  for (final day in plan.days) {
    for (final meal in day.meals) {
      meals++;
      final r = recipeById[meal.recipeId];
      if (r == null) {
        missingRecipe++;
        continue;
      }
      if (r.items.isEmpty) {
        emptyItems++;
        continue;
      }
      bool anyMissing = false;
      for (final it in r.items) {
        if (!ingredientById.containsKey(it.ingredientId)) {
          anyMissing = true;
          missingIngredient++;
        }
      }
      if (!anyMissing) ok++;
    }
  }

  return 'Plan ok. Recipes: $rc, Ingredients: $ic, Meals: $meals, '
      'MissingRecipe: $missingRecipe, EmptyItems: $emptyItems, '
      'MissingIngredientRefs: $missingIngredient, MealsUsable: $ok';
});
