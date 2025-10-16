import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/recipe.dart';
import '../../domain/entities/ingredient.dart';
import '../../domain/entities/user_targets.dart';
import '../../domain/value/substitution_score.dart';
import 'pantry_utilization_service.dart';
import 'plan_cost_service.dart';
import '../services/variety_prefs_service.dart';
import '../services/recipe_prefs_service.dart';
import '../../presentation/providers/ingredient_providers.dart';
import '../../presentation/providers/user_targets_providers.dart';
import '../../presentation/providers/taste_providers.dart';

final substitutionScoringServiceProvider =
    Provider<SubstitutionScoringService>(
  (ref) => SubstitutionScoringService(ref),
);

class SubstitutionScoringService {
  SubstitutionScoringService(this.ref);
  final Ref ref;

  // Tunable constants
  static const double _wPantry = 0.45;
  static const double _wBudget = 0.35;
  static const double _wMacro = 0.20;
  static const double _favoriteNudge = 0.05;
  static const double _varietyPenalty = 0.05; // optional, soft
  static const int _budgetScaleCents = 1500; // ~ $15 per week

  static const double _macroWK = 1 / 100.0;
  static const double _macroWP = 1.0;
  static const double _macroWC = 0.5;
  static const double _macroWF = 0.5;
  static const double _macroScale = 20.0; // heuristic

  /// Rank alternatives for replacing `current` within a specific slot context.
  /// `servingsForMeal` affects weekly cost delta (assume once in the week).
  Future<List<SubstitutionScore>> rankAlternatives({
    required Recipe current,
    required List<Recipe> candidates,
    required int servingsForMeal,
    Map<String, Ingredient>? ingredientsById,
  }) async {
    final pantrySvc = ref.read(pantryUtilizationServiceProvider);
    final costSvc = ref.read(planCostServiceProvider);
    final prefsSvc = ref.read(recipePrefsServiceProvider);
    final varietySvc = ref.read(varietyPrefsServiceProvider);

    // Targets: if unavailable, macroGain will be 0 (no macro preference)
    final UserTargets? targets = await ref
        .watch(currentUserTargetsProvider.future)
        .catchError((_) => null);
    final perMealTargets = _derivePerMealTargets(targets);

    // Ingredients cache (fast-path)
    Map<String, Ingredient>? ingMap = ingredientsById;
    ingMap ??= {
      for (final ing in (await ref.watch(allIngredientsProvider.future)))
        ing.id: ing
    };

    // Taste rules (optional)
    final rules = await ref.watch(tasteRulesProvider.future).catchError((_) => null);

    // Apply taste-based filtering (respect explicit allows)
    final filteredCandidates = (rules == null)
        ? candidates
        : candidates.where((r) {
            if (rules.allowRecipes.contains(r.id)) return true;
            final banned = recipeHardBanned(recipe: r, rules: rules, ingById: ingMap!);
            return !banned;
          }).toList(growable: false);

    // Pantry coverage for current
    final currentUtil = await pantrySvc.scoreRecipePantryUse(
      current,
      ingredientsById: ingMap,
    );

    final isFavoriteSet = await prefsSvc.getFavorites();
    final enableCuisineRotation = await varietySvc.enableCuisineRotation();

    final results = <SubstitutionScore>[];
    for (final cand in filteredCandidates) {
      // Pantry delta
      final candUtil = await pantrySvc.scoreRecipePantryUse(
        cand,
        ingredientsById: ingMap,
      );
      final coverageDelta = (candUtil.coverageRatio - currentUtil.coverageRatio)
          .clamp(-1.0, 1.0);
      final pantryGain = math.max(coverageDelta, 0.0);

      // Budget delta (weekly cost, single occurrence)
      final costCurrent = costSvc.mealCostCents(
          recipe: current, servings: servingsForMeal);
      final costCand = costSvc.mealCostCents(
          recipe: cand, servings: servingsForMeal);
      final weeklyCostDeltaCents = costCand - costCurrent; // negative is better
      final budgetGain = _clamp(
        (-weeklyCostDeltaCents) / _budgetScaleCents,
        0,
        1,
      );

      // Macro delta per serving
      final macroDelta = (
        kcal: cand.macrosPerServ.kcal - current.macrosPerServ.kcal,
        proteinG:
            cand.macrosPerServ.proteinG - current.macrosPerServ.proteinG,
        carbsG: cand.macrosPerServ.carbsG - current.macrosPerServ.carbsG,
        fatG: cand.macrosPerServ.fatG - current.macrosPerServ.fatG,
      );

      // Macro improvement toward targets per serving
      double macroGain = 0.0;
      if (perMealTargets != null) {
        final distCurrent = _macroDistance(current.macrosPerServ, perMealTargets);
        final distCand = _macroDistance(cand.macrosPerServ, perMealTargets);
        macroGain = _clamp((distCurrent - distCand) / _macroScale, 0, 1);
      }

      // Composite
      double composite =
          _wPantry * pantryGain + _wBudget * budgetGain + _wMacro * macroGain;

      // Taste boost (normalized, small weight)
      if (rules != null) {
        final t = tasteScore(recipe: cand, rules: rules, ingById: ingMap!);
        final tNorm = ((t + 10.0) / 20.0).clamp(0.0, 1.0);
        composite += 0.15 * tNorm;
      }

      // Nudges
      if (isFavoriteSet.contains(cand.id)) {
        composite += _favoriteNudge;
      }
      // Optional small variety penalty: if cuisine is same as current and rotation is enabled
      if (enableCuisineRotation) {
        if ((cand.cuisine?.isNotEmpty ?? false) &&
            cand.cuisine == current.cuisine) {
          composite -= _varietyPenalty;
        }
      }
      composite = composite.clamp(0.0, 1.2);

      if (kDebugMode) {
        debugPrint(
            '[Subs] cand="${cand.name}" pantryGain=${_fmt(pantryGain)} budgetGain=${_fmt(budgetGain)} macroGain=${_fmt(macroGain)} composite=${_fmt(composite)}');
        debugPrint(
            '[Subs]   Δcoverage=${_fmt(coverageDelta)} ΔcostCents=$weeklyCostDeltaCents Δkcal=${_fmt(macroDelta.kcal)} ΔP=${_fmt(macroDelta.proteinG)} ΔC=${_fmt(macroDelta.carbsG)} ΔF=${_fmt(macroDelta.fatG)}');
      }

      results.add(
        SubstitutionScore(
          candidateRecipeId: cand.id,
          pantryGain: pantryGain,
          budgetGain: budgetGain,
          macroGain: macroGain,
          coverageDelta: coverageDelta,
          weeklyCostDeltaCents: weeklyCostDeltaCents,
          macroDeltaPerServ: macroDelta,
          composite: composite,
        ),
      );
    }

    results.sort((b, a) => a.composite.compareTo(b.composite));
    return results;
  }

  // Helpers
  double _macroDistance(MacrosPerServing r, (
    double kcal,
    double proteinG,
    double carbsG,
    double fatG,
  ) T) {
    final d = _macroWK * (r.kcal - T.kcal).abs() +
        _macroWP * (r.proteinG - T.proteinG).abs() +
        _macroWC * (r.carbsG - T.carbsG).abs() +
        _macroWF * (r.fatG - T.fatG).abs();
    return d;
  }

  (
    double kcal,
    double proteinG,
    double carbsG,
    double fatG,
  )? _derivePerMealTargets(UserTargets? targets) {
    if (targets == null) return null;
    final meals = targets.mealsPerDay <= 0 ? 3 : targets.mealsPerDay;
    return (
      kcal: targets.kcal / meals,
      proteinG: targets.proteinG / meals,
      carbsG: targets.carbsG / meals,
      fatG: targets.fatG / meals,
    );
  }

  double _clamp(num v, num lo, num hi) => v.clamp(lo, hi).toDouble();
  String _fmt(num v) => v.toStringAsFixed(3);
}
