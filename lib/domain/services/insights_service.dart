import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../entities/recipe.dart';
import '../entities/ingredient.dart';
import '../entities/plan.dart';
import '../entities/user_targets.dart';
import '../services/pantry_utilization_service.dart';
import '../services/trip_cost_service.dart';
import '../services/variety_prefs_service.dart';
import '../services/recipe_features.dart';
import '../services/prepared_inventory_service.dart';
import '../../presentation/providers/database_providers.dart';
import '../../presentation/providers/user_targets_providers.dart';
import '../../presentation/providers/store_providers.dart';

final insightsServiceProvider = Provider<InsightsService>((ref) => InsightsService(ref));

class InsightsService {
  InsightsService(this.ref);
  final Ref ref;

  // Macro adherence for current plan (avg per-day deltas vs targets)
  Future<MacroAdherence> macroAdherence(Plan plan, {Map<String, Ingredient>? ingredientsById}) async {
    final targets = await _targetsForPlan(plan);
    final recipeRepo = ref.read(recipeRepositoryProvider);
    final recipes = await recipeRepo.getRecipesByIds(plan.usedRecipeIds.toList());
    final recipeById = {for (final r in recipes) r.id: r};

    final days = plan.days.isEmpty ? 1 : plan.days.length;
    double sumDeltaKcal = 0;
    double sumDeltaP = 0;
    double sumDeltaC = 0;
    double sumDeltaF = 0;

    for (final day in plan.days) {
      double kcal = 0, p = 0, c = 0, f = 0;
      for (final meal in day.meals) {
        final r = recipeById[meal.recipeId];
        if (r == null) continue;
        final s = meal.servings;
        kcal += r.macrosPerServ.kcal * s;
        p += r.macrosPerServ.proteinG * s;
        c += r.macrosPerServ.carbsG * s;
        f += r.macrosPerServ.fatG * s;
      }
      sumDeltaKcal += (kcal - targets.kcal);
      sumDeltaP += (p - targets.proteinG);
      sumDeltaC += (c - targets.carbsG);
      sumDeltaF += (f - targets.fatG);
    }

    final avgDeltaKcal = sumDeltaKcal / days;
    final avgDeltaP = sumDeltaP / days;
    final avgDeltaC = sumDeltaC / days;
    final avgDeltaF = sumDeltaF / days;

    final absK = avgDeltaKcal.abs();
    final badge = absK <= 75
        ? AdherenceBadge.onTrack
        : (absK <= 150 ? AdherenceBadge.close : AdherenceBadge.off);

    if (kDebugMode) {
      debugPrint('[Insights] Macro avg deltas kcal=${avgDeltaKcal.toStringAsFixed(1)} P=${avgDeltaP.toStringAsFixed(1)} C=${avgDeltaC.toStringAsFixed(1)} F=${avgDeltaF.toStringAsFixed(1)} badge=$badge');
    }

    return MacroAdherence(
      avgDeltaKcal: avgDeltaKcal,
      avgDeltaP: avgDeltaP,
      avgDeltaC: avgDeltaC,
      avgDeltaF: avgDeltaF,
      badge: badge,
    );
  }

  // Budget: planned vs trip total (cents)
  Future<BudgetSummary> budgetSummary(Plan plan, {Map<String, Ingredient>? ingredientsById}) async {
    final recipeRepo = ref.read(recipeRepositoryProvider);
    final recipes = await recipeRepo.getRecipesByIds(plan.usedRecipeIds.toList());
    final recipeById = {for (final r in recipes) r.id: r};

    int plannedCents = 0;
    final items = <({String ingredientId, double qty, Unit unit})>[];
    for (final day in plan.days) {
      for (final meal in day.meals) {
        final r = recipeById[meal.recipeId];
        if (r == null) continue;
        plannedCents += (r.costPerServCents * meal.servings).round();
        for (final it in r.items) {
          final qty = it.qty * meal.servings;
          if (qty <= 0) continue;
          items.add((ingredientId: it.ingredientId, qty: qty, unit: it.unit));
        }
      }
    }

    final ingRepo = ref.read(ingredientRepositoryProvider);
    final ings = ingredientsById ?? {for (final i in await ingRepo.getAllIngredients()) i.id: i};
    final store = await ref.read(storeProfileServiceProvider).getSelected();
    int tripTotalCents = 0;
    if (items.isNotEmpty) {
      tripTotalCents = await ref.read(tripCostServiceProvider).computeTripTotalCents(
            items: items,
            store: store,
            ingredientsById: ings,
          );
    }
    if (tripTotalCents <= 0) tripTotalCents = plannedCents;

    if (kDebugMode) {
      debugPrint('[Insights] Budget planned=$plannedCents trip=$tripTotalCents items=${items.length}');
    }
    return BudgetSummary(plannedCents: plannedCents, tripTotalCents: tripTotalCents);
  }

  // Pantry usage: percentage coverage across the plan
  Future<PantryUsageSummary> pantryUsage(Plan plan, {Map<String, Ingredient>? ingredientsById}) async {
    final recipeRepo = ref.read(recipeRepositoryProvider);
    final recipes = await recipeRepo.getRecipesByIds(plan.usedRecipeIds.toList());
    final recipeById = {for (final r in recipes) r.id: r};
    final pantrySvc = ref.read(pantryUtilizationServiceProvider);

    double weighted = 0.0;
    double totalServings = 0.0;
    for (final day in plan.days) {
      for (final meal in day.meals) {
        final r = recipeById[meal.recipeId];
        if (r == null) continue;
        final util = await pantrySvc.scoreRecipePantryUse(r, ingredientsById: ingredientsById);
        weighted += util.coverageRatio * meal.servings;
        totalServings += meal.servings;
      }
    }
    final cov = totalServings > 0 ? (weighted / totalServings).clamp(0.0, 1.0) : 0.0;
    if (kDebugMode) debugPrint('[Insights] Pantry coverageRatio=${cov.toStringAsFixed(3)}');
    return PantryUsageSummary(coverageRatio: cov);
  }

  // Variety score (0..100) derived from variety penalties/cooldowns
  Future<VarietySummary> varietyScore(Plan plan, {List<Plan> history = const []}) async {
    final prefs = ref.read(varietyPrefsServiceProvider);
    final maxRepeats = await prefs.maxRepeatsPerWeek();
    final proteinSpread = await prefs.enableProteinSpread();
    final cuisineRotation = await prefs.enableCuisineRotation();
    final prepMix = await prefs.enablePrepMix();

    final recipeRepo = ref.read(recipeRepositoryProvider);
    final recipes = await recipeRepo.getRecipesByIds(plan.usedRecipeIds.toList());
    final byId = {for (final r in recipes) r.id: r};

    final totalMeals = plan.days.fold<double>(0, (a, d) => a + d.meals.length);
    if (totalMeals <= 0) {
      return const VarietySummary(score0to100: 0, components: {});
    }

    // repeats component
    final counts = <String, int>{};
    for (final d in plan.days) {
      for (final m in d.meals) {
        counts[m.recipeId] = (counts[m.recipeId] ?? 0) + 1;
      }
    }
    double overage = 0;
    counts.forEach((_, c) {
      final over = c - maxRepeats;
      if (over > 0) overage += over;
    });
    final repeatsComp = (1.0 - (overage / totalMeals)).clamp(0.0, 1.0);

    // protein component
    double proteinComp = 1.0;
    if (proteinSpread) {
      final prots = <String>{};
      for (final d in plan.days) {
        for (final m in d.meals) {
          final r = byId[m.recipeId];
          if (r == null) continue;
          prots.add(RecipeFeatures.proteinTag(r));
        }
      }
      proteinComp = (prots.length / (totalMeals.clamp(1, 6))).clamp(0.0, 1.0);
    }

    // cuisine component
    double cuisineComp = 1.0;
    if (cuisineRotation) {
      final cuisines = <String>{};
      for (final d in plan.days) {
        for (final m in d.meals) {
          final r = byId[m.recipeId];
          if (r == null) continue;
          cuisines.add(RecipeFeatures.cuisineTag(r));
        }
      }
      cuisineComp = (cuisines.length / (totalMeals.clamp(1, 6))).clamp(0.0, 1.0);
    }

    // prep mix component
    double prepComp = 1.0;
    if (prepMix) {
      final buckets = <String>{};
      for (final d in plan.days) {
        for (final m in d.meals) {
          final r = byId[m.recipeId];
          if (r == null) continue;
          buckets.add(RecipeFeatures.prepBucket(r));
        }
      }
      // Encourage having 2 or 3 buckets present
      prepComp = (buckets.length / 3.0).clamp(0.0, 1.0);
    }

    // history/novelty component
    final historySet = <String>{}..addAll(history.expand((p) => p.usedRecipeIds));
    int novel = 0;
    for (final d in plan.days) {
      for (final m in d.meals) {
        if (!historySet.contains(m.recipeId)) novel++;
      }
    }
    final historyComp = (novel / totalMeals).clamp(0.0, 1.0);

    final components = <String, double>{
      'repeats': repeatsComp,
      'protein': proteinComp,
      'cuisine': cuisineComp,
      'prep': prepComp,
      'history': historyComp,
    };
    // Aggregate simple mean
    final score = (components.values.fold<double>(0, (a, v) => a + v) / components.length) * 100.0;
    if (kDebugMode) debugPrint('[Insights] Variety score=${score.toStringAsFixed(1)} comps=$components');
    return VarietySummary(score0to100: score, components: components);
  }

  // Trends for last N plans
  Future<TrendsSummary> trends(List<Plan> plans) async {
    // plans expected sorted desc by createdAt
    final userRepo = ref.read(userTargetsRepositoryProvider);
    final recipeRepo = ref.read(recipeRepositoryProvider);

    final kcalDeltaSeries = <double>[];
    final costSeries = <int>[];

    for (final p in plans) {
      final targets = await userRepo.getUserTargetsById(p.userTargetsId);
      if (targets == null) continue;
      final recipes = await recipeRepo.getRecipesByIds(p.usedRecipeIds.toList());
      final byId = {for (final r in recipes) r.id: r};

      // avg kcal delta
      double sumDeltaKcal = 0;
      final days = p.days.isEmpty ? 1 : p.days.length;
      for (final d in p.days) {
        double kcal = 0;
        for (final m in d.meals) {
          final r = byId[m.recipeId];
          if (r == null) continue;
          kcal += r.macrosPerServ.kcal * m.servings;
        }
        sumDeltaKcal += (kcal - targets.kcal);
      }
      kcalDeltaSeries.add(sumDeltaKcal / days);

      // planned weekly cost
      int plannedCents = 0;
      for (final d in p.days) {
        for (final m in d.meals) {
          final r = byId[m.recipeId];
          if (r == null) continue;
          plannedCents += (r.costPerServCents * m.servings).round();
        }
      }
      costSeries.add(plannedCents);
    }

    return TrendsSummary(kcalDeltaSeries: kcalDeltaSeries, costSeriesCents: costSeries);
  }

  // Top movers: most and least used (by frequency across history)
  Future<TopMovers> topMovers(List<Plan> plans) async {
    final freq = <String, int>{};
    for (final p in plans) {
      for (final d in p.days) {
        for (final m in d.meals) {
          freq[m.recipeId] = (freq[m.recipeId] ?? 0) + 1;
        }
      }
    }
    if (freq.isEmpty) return const TopMovers(mostUsedRecipeIds: [], leastUsedRecipeIds: []);

    final entries = freq.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    final most = entries.take(3).map((e) => e.key).toList();

    // among used, bottom 3
    entries.sort((a, b) => a.value.compareTo(b.value));
    final least = entries.take(3).map((e) => e.key).toList();

    if (kDebugMode) debugPrint('[Insights] Top movers most=$most least=$least');
    return TopMovers(mostUsedRecipeIds: most, leastUsedRecipeIds: least);
  }

  // Leftovers: servings rescued this week (from PreparedInventoryService counter)
  Future<int> leftoversUsedThisWeek() async {
    return ref.read(preparedInventoryServiceProvider).rescuedThisWeek();
  }

  Future<UserTargets> _targetsForPlan(Plan plan) async {
    final repo = ref.read(userTargetsRepositoryProvider);
    final t = await repo.getUserTargetsById(plan.userTargetsId);
    if (t != null) return t;
    final cur = await ref.read(currentUserTargetsProvider.future);
    if (cur != null) return cur;
    // Last resort
    return UserTargets.defaultTargets();
  }
}

class MacroAdherence {
  final double avgDeltaKcal; // candidate - target (avg/day)
  final double avgDeltaP;
  final double avgDeltaC;
  final double avgDeltaF;
  final AdherenceBadge badge; // onTrack / close / off
  const MacroAdherence({required this.avgDeltaKcal, required this.avgDeltaP, required this.avgDeltaC, required this.avgDeltaF, required this.badge});
}
enum AdherenceBadge { onTrack, close, off }

class BudgetSummary {
  final int plannedCents;   // sum recipe.costPerServCents * servings
  final int tripTotalCents; // from TripCostService using selected store
  const BudgetSummary({required this.plannedCents, required this.tripTotalCents});
}

class PantryUsageSummary {
  final double coverageRatio; // 0..1 for the plan
  const PantryUsageSummary({required this.coverageRatio});
}

class VarietySummary {
  final double score0to100; // 0..100 higher is better variety
  final Map<String,double> components; // repeats/protein/cuisine/prep/history 0..1
  const VarietySummary({required this.score0to100, required this.components});
}

class TrendsSummary {
  final List<double> kcalDeltaSeries; // last 4 plans avg kcal delta vs targets
  final List<int> costSeriesCents;    // last 4 plans planned cost or trip total
  const TrendsSummary({required this.kcalDeltaSeries, required this.costSeriesCents});
}

class TopMovers {
  final List<String> mostUsedRecipeIds;  // top 3
  final List<String> leastUsedRecipeIds; // bottom 3 among used
  const TopMovers({required this.mostUsedRecipeIds, required this.leastUsedRecipeIds});
}
