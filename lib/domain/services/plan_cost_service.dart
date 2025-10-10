import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/plan.dart';
import '../../domain/entities/recipe.dart';
import '../../presentation/providers/recipe_providers.dart';

/// Provides utilities to estimate plan costs based on the recipe catalog.
final planCostServiceProvider = Provider<PlanCostService>((ref) => PlanCostService(ref));

class PlanCostService {
  PlanCostService(this.ref);
  final Ref ref;

  /// Returns total weekly cost in cents and per-day breakdown (Sun..Sat).
  /// Does not alter any stored data.
  Future<PlanCostSummary> summarizePlanCost(Plan plan) async {
    final recipes = await ref.watch(allRecipesProvider.future);
    final byId = {for (final r in recipes) r.id: r};

    int weekly = 0;
    final perDay = <int>[];

    for (var i = 0; i < plan.days.length; i++) {
      final day = plan.days[i];
      int dayTotal = 0;
      for (final meal in day.meals) {
        final recipe = byId[meal.recipeId];
        if (recipe == null) {
          if (kDebugMode) {
            debugPrint('[Cost] missing recipeId=${meal.recipeId}');
          }
          continue;
        }
        final add = (recipe.costPerServCents * meal.servings).round().clamp(0, 1 << 31);
        if (kDebugMode) {
          debugPrint('[Cost] meal recipe=${recipe.name} servings=${meal.servings} costPerServ=${recipe.costPerServCents} -> add=$add');
        }
        dayTotal += add;
      }
      weekly += dayTotal;
      perDay.add(dayTotal);
      if (kDebugMode) {
        debugPrint('[Cost] day#$i total=$dayTotal, weekly so far=$weekly');
      }
    }

    if (kDebugMode) {
      debugPrint('[Cost] weekly total=$weekly');
    }

    // Ensure exactly 7 entries; pad with zeros if needed.
    while (perDay.length < 7) {
      perDay.add(0);
    }

    return PlanCostSummary(weeklyTotalCents: weekly, perDayCents: perDay.take(7).toList());
  }

  /// Utility: cost in cents for a given meal (recipeId + servings).
  int mealCostCents({required Recipe recipe, required int servings}) {
    final add = (recipe.costPerServCents * servings).clamp(0, 1 << 31);
    return add.toInt();
  }
}

class PlanCostSummary {
  final int weeklyTotalCents;
  /// length=7, index aligned with plan days
  final List<int> perDayCents;
  const PlanCostSummary({required this.weeklyTotalCents, required this.perDayCents});
}

