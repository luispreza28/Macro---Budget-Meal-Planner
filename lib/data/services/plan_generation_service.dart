// lib/data/services/plan_generation_service.dart
import 'dart:math';
import 'package:flutter/foundation.dart';

import '../../domain/entities/ingredient.dart';
import '../../domain/entities/plan.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/entities/user_targets.dart';

/// Generator that prefers real recipe.items to compute macros & cost.
/// Falls back to Recipe.macrosPerServ and costPerServCents if items are missing.
class PlanGenerationService {
  PlanGenerationService({Random? rng}) : _rng = rng ?? Random();

  final Random _rng;

  /// Generates a weekly plan from inputs.
  /// NOTE: This method is pure and **does not persist** the plan. Callers are
  /// responsible for saving and setting the current plan.
  Future<Plan> generate({
    required UserTargets targets,
    required List<Recipe> recipes,
    required List<Ingredient> ingredients,
    double? costBias,
  }) async {
    if (recipes.isEmpty) {
      throw StateError('No recipes available to generate a plan.');
    }

    final ingById = {for (final i in ingredients) i.id: i};

    final int mealsPerDay = targets.mealsPerDay.clamp(1, 6) as int;
    final rng = _rng;
    final all = [...recipes];
    final itemized = all.where((r) => r.items.isNotEmpty).toList();
    final nonItemized = all.where((r) => r.items.isEmpty).toList();

    final int mealsNeeded = 7 * mealsPerDay;
    final int desiredPoolSize =
        (mealsNeeded * 2).clamp(mealsNeeded, 200) as int;

    const double itemizedWeight = 0.75;
    int targetItemized = (desiredPoolSize * itemizedWeight).round();
    int targetNonItemized = desiredPoolSize - targetItemized;

    final int availableItemized = itemized.length;
    final int availableNonItemized = nonItemized.length;

    if (availableItemized < targetItemized) {
      final int deficit = targetItemized - availableItemized;
      targetItemized = availableItemized;
      final int borrowed = targetNonItemized + deficit;
      targetNonItemized = borrowed > availableNonItemized
          ? availableNonItemized
          : borrowed;
    }

    if (availableNonItemized < targetNonItemized) {
      final int deficit = targetNonItemized - availableNonItemized;
      targetNonItemized = availableNonItemized;
      final int borrowed = targetItemized + deficit;
      targetItemized = borrowed > availableItemized
          ? availableItemized
          : borrowed;
    }

    if (availableItemized == 0 && availableNonItemized == 0) {
      throw StateError('No recipes available to build a plan.');
    }

    List<T> _sample<T>(List<T> list, int n) {
      if (list.isEmpty || n <= 0) return <T>[];
      final copy = [...list]..shuffle(rng);
      final int takeCount = n < 0 ? 0 : (n > list.length ? list.length : n);
      return copy.take(takeCount).toList();
    }

    final sampledItemized = _sample(itemized, targetItemized);
    final sampledNonItemized = _sample(nonItemized, targetNonItemized);

    final pool = <Recipe>[...sampledItemized, ...sampledNonItemized]
      ..shuffle(rng);

    // Optional: nudge selection toward cheaper recipes.
    if (costBias != null && costBias > 0) {
      assert(costBias >= 0 && costBias <= 1.0);
      if (kDebugMode) {
        debugPrint('[GenCostBias] applying cost bias: $costBias');
      }
      // Build a lightweight score that prefers cheaper items.
      final scores = <String, double>{};
      for (final r in pool) {
        final cents = r.costPerServCents.clamp(0, 2000);
        final normalized = cents / 2000.0; // 0..1
        final penalty = (costBias) * normalized; // 0..1
        final base = rng.nextDouble();
        final score = base - penalty; // lower => cheaper preferred
        scores[r.id] = score;
      }
      pool.sort((a, b) => (scores[a.id]!).compareTo(scores[b.id]!));
    }

    while (pool.length < mealsNeeded) {
      if (itemized.isNotEmpty) {
        pool.add(itemized[rng.nextInt(itemized.length)]);
      } else if (nonItemized.isNotEmpty) {
        pool.add(nonItemized[rng.nextInt(nonItemized.length)]);
      } else {
        break;
      }
    }

    if (pool.isEmpty) {
      throw StateError('Unable to build a recipe pool for planning.');
    }

    final List<PlanDay> days = [];

    double totalKcal = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    int totalCostCents = 0;

    Recipe? lastPicked;
    int poolCursor = 0;

    Recipe _pickWithNoImmediateRepeat(Set<String> usedThisDay) {
      for (int attempt = 0; attempt < pool.length; attempt++) {
        final int index = (poolCursor + attempt) % pool.length;
        final candidate = pool[index];
        final bool repeatsLast = candidate.id == lastPicked?.id;
        final bool usedInDay = usedThisDay.contains(candidate.id);
        if (!repeatsLast && !usedInDay) {
          poolCursor = (index + 1) % pool.length;
          return candidate;
        }
      }

      final fallback = pool[poolCursor % pool.length];
      poolCursor = (poolCursor + 1) % pool.length;
      return fallback;
    }

    for (int d = 0; d < 7; d++) {
      final List<PlanMeal> meals = [];
      final usedThisDay = <String>{};

      for (int m = 0; m < mealsPerDay; m++) {
        final recipe = _pickWithNoImmediateRepeat(usedThisDay);
        usedThisDay.add(recipe.id);
        lastPicked = recipe;

        const servings = 1.0;

        final _Totals t = _computeFromRecipe(
          recipe: recipe,
          servings: servings,
          ingById: ingById,
        );

        totalKcal += t.kcal;
        totalProtein += t.proteinG;
        totalCarbs += t.carbsG;
        totalFat += t.fatG;
        totalCostCents += t.costCents;

        meals.add(PlanMeal(recipeId: recipe.id, servings: servings));
      }

      final date = DateTime.now().add(Duration(days: d));
      days.add(PlanDay(date: date.toIso8601String(), meals: meals));
    }

    final planTotals = PlanTotals(
      kcal: totalKcal,
      proteinG: totalProtein,
      carbsG: totalCarbs,
      fatG: totalFat,
      costCents: totalCostCents,
    );

    final plan = Plan(
      id: 'plan_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Weekly Plan',
      userTargetsId: targets.id,
      days: days,
      totals: planTotals,
      createdAt: DateTime.now(),
    );

    return plan;
  }

  _Totals _computeFromRecipe({
    required Recipe recipe,
    required double servings,
    required Map<String, Ingredient> ingById,
  }) {
    if (recipe.items.isNotEmpty) {
      double kcal = 0;
      double protein = 0;
      double carbs = 0;
      double fat = 0;
      double costCentsDouble = 0;

      for (final it in recipe.items) {
        final ing = ingById[it.ingredientId];
        if (ing == null) continue;

        final qty = it.qty * servings;

        double baseQtyFor100;
        switch (it.unit) {
          case Unit.grams:
          case Unit.milliliters:
            baseQtyFor100 = qty / 100.0;
            break;
          case Unit.piece:
            baseQtyFor100 = qty;
            break;
        }

        kcal += ing.macrosPer100g.kcal * baseQtyFor100;
        protein += ing.macrosPer100g.proteinG * baseQtyFor100;
        carbs += ing.macrosPer100g.carbsG * baseQtyFor100;
        fat += ing.macrosPer100g.fatG * baseQtyFor100;

        final unitsOf100 = (it.unit == Unit.piece) ? qty : qty / 100.0;
        costCentsDouble += unitsOf100 * ing.pricePerUnitCents;
      }

      return _Totals(
        kcal: kcal,
        proteinG: protein,
        carbsG: carbs,
        fatG: fat,
        costCents: costCentsDouble.round(),
      );
    } else {
      return _Totals(
        kcal: recipe.macrosPerServ.kcal * servings,
        proteinG: recipe.macrosPerServ.proteinG * servings,
        carbsG: recipe.macrosPerServ.carbsG * servings,
        fatG: recipe.macrosPerServ.fatG * servings,
        costCents: (recipe.costPerServCents * servings).round(),
      );
    }
  }
}

class _Totals {
  final double kcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final int costCents;
  _Totals({
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.costCents,
  });
}
