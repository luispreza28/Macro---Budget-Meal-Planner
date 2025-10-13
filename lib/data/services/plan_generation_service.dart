// lib/data/services/plan_generation_service.dart
import 'dart:math';
import 'package:flutter/foundation.dart';

import '../../domain/entities/ingredient.dart';
import '../../domain/entities/plan.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/entities/user_targets.dart';
import '../../domain/services/recipe_features.dart';
import '../../domain/services/variety_options.dart';

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
    double? favoriteBias, // 0..1; nudge toward favorites
    Map<String, String>? pinnedSlots, // slotKey -> recipeId
    Set<String>? excludedRecipeIds, // avoid these recipes entirely
    Set<String>? favoriteRecipeIds, // optional, used with favoriteBias
    VarietyOptions? varietyOptions,
  }) async {
    if (recipes.isEmpty) {
      throw StateError('No recipes available to generate a plan.');
    }

    final ingById = {for (final i in ingredients) i.id: i};

    final int mealsPerDay = targets.mealsPerDay.clamp(1, 6) as int;
    final rng = _rng;
    // Exclude recipes if requested
    final excluded = excludedRecipeIds ?? const <String>{};
    final all = [...recipes.where((r) => !excluded.contains(r.id))];
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

    // Build a base score map to sort candidates with optional biases
    final baseScores = <String, double>{};
    final doCost = costBias != null && costBias > 0;
    final favs = favoriteRecipeIds ?? const <String>{};
    final fb = (favoriteBias ?? 0).clamp(0.0, 1.0);
    if (doCost && kDebugMode) {
      debugPrint('[GenCostBias] applying cost bias: $costBias');
    }
    if (fb > 0 && kDebugMode) {
      debugPrint('[GenBias] applying favorite bias: $fb (favs=${favs.length})');
    }
    if (doCost || fb > 0) {
      for (final r in pool) {
        final base = rng.nextDouble();
        double score = base;
        if (doCost) {
          final cents = r.costPerServCents.clamp(0, 2000);
          final normalized = cents / 2000.0; // 0..1
          final penalty = (costBias!) * normalized; // 0..1
          score -= penalty; // lower => cheaper preferred
        }
        if (fb > 0) {
          final isFav = favs.contains(r.id) ? 1.0 : 0.0;
          score += fb * isFav;
        }
        baseScores[r.id] = score;
      }
      pool.sort((a, b) => (baseScores[b.id] ?? 0).compareTo(baseScores[a.id] ?? 0)); // higher score first
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
    final selectedCounts = <String, int>{}; // recipeId -> times selected in current week
    final proteinCache = <String, String>{};
    final cuisineCache = <String, String>{};
    final bucketCache = <String, String>{};
    final bucketCounts = <String, int>{'quick': 0, 'medium': 0, 'long': 0};
    final lastForMealIndex = <int, Recipe?>{}; // mealIndex -> last recipe (prev day)

    // History cooldown map from recent plans
    final cooldownUsage = <String, int>{};
    if (varietyOptions != null && varietyOptions.historyPlans.isNotEmpty) {
      for (final p in varietyOptions.historyPlans) {
        for (final d in p.days) {
          for (final m in d.meals) {
            cooldownUsage[m.recipeId] = (cooldownUsage[m.recipeId] ?? 0) + 1;
          }
        }
      }
    }

    // Variety penalty constants
    const double P_REPEAT_HARD = 1.5;
    const double P_REPEAT_SOFT = 0.4;
    const double P_STREAK_PROTEIN = 0.35;
    const double P_STREAK_CUISINE = 0.25;
    const double P_PREP_IMBALANCE = 0.2;
    const double P_COOLDOWN = 0.2;
    const int COOLDOWN_CAP = 3;

    String _proteinOf(Recipe r) =>
        proteinCache[r.id] ??= RecipeFeatures.proteinTag(r);
    String _cuisineOf(Recipe r) =>
        cuisineCache[r.id] ??= RecipeFeatures.cuisineTag(r);
    String _bucketOf(Recipe r) => bucketCache[r.id] ??= RecipeFeatures.prepBucket(r);

    double _scoreWithVariety(Recipe candidate, {
      required Set<String> usedThisDay,
      required int dayIndex,
      required int mealIndex,
    }) {
      // Start from base score (cost/fav) with slight randomness
      double score = (baseScores[candidate.id] ?? 0) + rng.nextDouble() * 0.01;

      // Repeat penalty this week (soft when approaching limit, hard when exceeding)
      final maxRepeats = varietyOptions?.maxRepeatsPerWeek ?? 1;
      final usedCount = selectedCounts[candidate.id] ?? 0;
      if (usedCount >= maxRepeats) {
        score -= P_REPEAT_HARD;
        if (kDebugMode) {
          debugPrint('[Variety] repeatPenalty=HARD id=${candidate.id} count=$usedCount');
        }
      } else if (usedCount == maxRepeats - 1 && maxRepeats > 0) {
        score -= P_REPEAT_SOFT;
        if (kDebugMode) {
          debugPrint('[Variety] repeatPenalty=SOFT id=${candidate.id} count=$usedCount');
        }
      }

      // Protein/cuisine streak penalties (compare with previous picks)
      if (varietyOptions?.enableProteinSpread ?? true) {
        final prev = lastPicked;
        final prevSameMeal = lastForMealIndex[mealIndex];
        final candProt = _proteinOf(candidate);
        if (prev != null && _proteinOf(prev) == candProt) {
          score -= P_STREAK_PROTEIN;
          if (kDebugMode) {
            debugPrint('[Variety] proteinStreak=prevSlot');
          }
        }
        if (prevSameMeal != null && _proteinOf(prevSameMeal) == candProt) {
          score -= P_STREAK_PROTEIN * 0.8; // smaller penalty for day-to-day streak
        }
      }

      if (varietyOptions?.enableCuisineRotation ?? true) {
        final prev = lastPicked;
        final prevSameMeal = lastForMealIndex[mealIndex];
        final candCui = _cuisineOf(candidate);
        if (prev != null && _cuisineOf(prev) == candCui) {
          score -= P_STREAK_CUISINE;
          if (kDebugMode) {
            debugPrint('[Variety] cuisineStreak=prevSlot');
          }
        }
        if (prevSameMeal != null && _cuisineOf(prevSameMeal) == candCui) {
          score -= P_STREAK_CUISINE * 0.8;
        }
      }

      // Prep bucket mix: encourage at least one quick and avoid all-long
      if (varietyOptions?.enablePrepMix ?? true) {
        final candB = _bucketOf(candidate);
        final hasQuick = (bucketCounts['quick'] ?? 0) > 0;
        final totalSoFar = bucketCounts.values.fold<int>(0, (a, b) => a + b);
        final allLongSoFar = totalSoFar > 0 && (bucketCounts['long'] ?? 0) == totalSoFar;
        if (!hasQuick && candB != 'quick') {
          score -= P_PREP_IMBALANCE;
          if (kDebugMode) debugPrint('[Variety] prepImbalance=noQuickYet');
        }
        if (allLongSoFar && candB == 'long') {
          score -= P_PREP_IMBALANCE;
        }
      }

      // History cooldown
      if ((varietyOptions?.historyPlans.isNotEmpty ?? false)) {
        final usage = cooldownUsage[candidate.id] ?? 0;
        if (usage > 0) {
          final penalty = P_COOLDOWN * (usage > COOLDOWN_CAP ? COOLDOWN_CAP : usage);
          score -= penalty;
          if (kDebugMode) {
            debugPrint('[Variety] cooldown usage=$usage penalty=$penalty');
          }
        }
      }

      // Clamp lower bound to avoid runaway negatives
      if (score < -10) score = -10;
      return score;
    }

    Recipe _pickWithScoring(Set<String> usedThisDay, int dayIndex, int mealIndex) {
      // Evaluate a limited window of candidates to keep runtime small
      final window = min(pool.length, 24);
      Recipe? best;
      double bestScore = double.negativeInfinity;
      for (int attempt = 0; attempt < window; attempt++) {
        final int index = (poolCursor + attempt) % pool.length;
        final candidate = pool[index];
        if (usedThisDay.contains(candidate.id)) {
          continue; // avoid duplicate within day (hard)
        }
        final s = _scoreWithVariety(candidate, usedThisDay: usedThisDay, dayIndex: dayIndex, mealIndex: mealIndex);
        if (s > bestScore) {
          bestScore = s;
          best = candidate;
        }
      }
      if (best == null) {
        // fallback sequential
        best = pool[poolCursor % pool.length];
      }
      // advance cursor past chosen
      final chosenIndex = pool.indexOf(best!);
      poolCursor = (chosenIndex + 1) % pool.length;
      return best;
    }

    final pins = pinnedSlots ?? const <String, String>{};
    for (int d = 0; d < 7; d++) {
      final List<PlanMeal> meals = [];
      final usedThisDay = <String>{};

      for (int m = 0; m < mealsPerDay; m++) {
        final slotKey = 'd${d}-m${m}';
        Recipe recipe;
        final pinnedId = pins[slotKey];
        if (pinnedId != null) {
          // Use pinned recipe if available in our candidate set
          final pinned = recipes.firstWhere(
            (r) => r.id == pinnedId,
            orElse: () => pool.first,
          );
          recipe = pinned;
          if (kDebugMode) {
            debugPrint('[GenBias] pinned slot $slotKey -> ${pinned.id}');
          }
        } else {
          recipe = _pickWithScoring(usedThisDay, d, m);
        }
        usedThisDay.add(recipe.id);
        lastPicked = recipe;
        lastForMealIndex[m] = recipe;
        selectedCounts[recipe.id] = (selectedCounts[recipe.id] ?? 0) + 1;
        final b = _bucketOf(recipe);
        bucketCounts[b] = (bucketCounts[b] ?? 0) + 1;

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
