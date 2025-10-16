import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/plan.dart';
import '../../domain/entities/recipe.dart';
import '../../presentation/providers/recipe_providers.dart';
import '../../presentation/providers/ingredient_providers.dart';
import '../../presentation/providers/taste_providers.dart';
import '../services/plan_cost_estimator.dart';
import '../services/budget_settings_service.dart';
import '../services/price_history_service.dart';

final budgetOptimizerServiceProvider = Provider<BudgetOptimizerService>((ref)=>BudgetOptimizerService(ref));

class BudgetOptimizerService {
  BudgetOptimizerService(this.ref);
  final Ref ref;

  /// Returns a list of suggested swaps (mealIndex -> newRecipeId) to reduce cost by ~targetSaveCents
  /// subject to kcal/protein tolerance and honoring taste/allergen rules.
  Future<List<SwapSuggestion>> suggestCheaperSwaps({
    required Plan plan,
    required int targetSaveCents,
  }) async {
    final settings = await ref.read(budgetSettingsServiceProvider).get();
    final recipes = await ref.read(allRecipesProvider.future);
    final ings = { for (final i in await ref.read(allIngredientsProvider.future)) i.id : i };
    final rules = await ref.read(tasteRulesProvider.future);
    final est = ref.read(planCostEstimatorProvider);
    final priceSvc = ref.read(priceHistoryServiceProvider);

    // Precompute candidate costs per serving (price-aware if possible)
    final costPerServ = <String,int>{};
    for (final r in recipes) {
      final c = await est.estimateRecipeServCostCents(r, ings, priceSvc, settings.preferredStoreId);
      costPerServ[r.id] = c ?? r.costPerServCents;
    }

    // For each meal in the plan, find cheaper alternatives with similar macros
    final suggestions = <SwapSuggestion>[];
    int saved = 0;
    outer:
    for (int d=0; d<plan.days.length; d++) {
      for (int m=0; m<plan.days[d].meals.length; m++) {
        final meal = plan.days[d].meals[m];
        final matches = recipes.where((x)=>x.id==meal.recipeId).toList(growable: false);
        if (matches.isEmpty) continue;
        final r = matches.first;
        final baseCost = costPerServ[r.id] ?? r.costPerServCents;

        // Build candidate pool: not hard-banned, not hidden; similar kcal/protein (within tolerance)
        final kTol = settings.kcalTolerancePct / 100.0;
        final pTol = settings.proteinTolerancePct / 100.0;

        Recipe? best;
        int bestDelta = 0;

        for (final cand in recipes) {
          if (cand.id == r.id) continue;
          // Taste rules: drop hard-banned unless explicitly allowed
          final hardBan = recipeHardBanned(recipe: cand, rules: rules, ingById: ings);
          if (hardBan && !rules.allowRecipes.contains(cand.id)) continue;

          final kcalClose = (cand.macrosPerServ.kcal - r.macrosPerServ.kcal).abs() <= (max(50.0, r.macrosPerServ.kcal * kTol));
          final pClose = (cand.macrosPerServ.proteinG - r.macrosPerServ.proteinG).abs() <= (max(5.0, r.macrosPerServ.proteinG * pTol));
          if (!kcalClose || !pClose) continue;

          final cCost = costPerServ[cand.id] ?? cand.costPerServCents;
          final delta = baseCost - cCost; // positive means savings per serving
          if (delta > bestDelta) {
            bestDelta = delta;
            best = cand;
          }
        }

        if (best != null && bestDelta > 0) {
          final save = bestDelta * meal.servings;
          suggestions.add(SwapSuggestion(
            dayIndex: d, mealIndex: m, fromRecipeId: r.id, toRecipeId: best.id, saveCents: save.round(),
          ));
          saved += save.round();
          if (saved >= targetSaveCents || suggestions.length >= settings.maxAutoSwaps) break outer;
        }
      }
    }
    return suggestions;
  }
}

class SwapSuggestion {
  final int dayIndex;
  final int mealIndex;
  final String fromRecipeId;
  final String toRecipeId;
  final int saveCents;
  const SwapSuggestion({
    required this.dayIndex,
    required this.mealIndex,
    required this.fromRecipeId,
    required this.toRecipeId,
    required this.saveCents,
  });
}
