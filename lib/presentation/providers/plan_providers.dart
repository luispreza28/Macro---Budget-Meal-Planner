import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/plan.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/repositories/plan_repository.dart';
import 'database_providers.dart';
import 'recipe_providers.dart';
import '../widgets/plan_widgets/swap_drawer.dart';

/// Provider for all plans
final allPlansProvider = StreamProvider<List<Plan>>((ref) {
  final repository = ref.watch(planRepositoryProvider);
  return repository.watchAllPlans();
});

/// Provider for current active plan (explicitly user-selected)
final currentPlanProvider = StreamProvider<Plan?>((ref) {
  final repository = ref.watch(planRepositoryProvider);
  return repository.watchCurrentPlan();
});

/// Provider for recent plans
final recentPlansProvider = StreamProvider<List<Plan>>((ref) {
  final repository = ref.watch(planRepositoryProvider);
  return repository.watchRecentPlans(limit: 10);
});

/// Provider for plan by ID
final planByIdProvider = FutureProvider.family<Plan?, String>((ref, id) {
  final repository = ref.watch(planRepositoryProvider);
  return repository.getPlanById(id);
});

/// Provider for plans by user targets ID
final plansByUserTargetsIdProvider = FutureProvider.family<List<Plan>, String>((
  ref,
  userTargetsId,
) {
  final repository = ref.watch(planRepositoryProvider);
  return repository.getPlansByUserTargetsId(userTargetsId);
});

/// Provider for plans count
final plansCountProvider = StreamProvider<int>((ref) {
  final repository = ref.watch(planRepositoryProvider);
  return repository.watchPlansCount();
});

/// Provider for active plans count (for free tier limit)
final activePlansCountProvider = FutureProvider<int>((ref) {
  final repository = ref.watch(planRepositoryProvider);
  return repository.getActivePlansCount();
});

/// Provider for plan statistics
final planStatisticsProvider = FutureProvider<Map<String, dynamic>>((ref) {
  final repository = ref.watch(planRepositoryProvider);
  return repository.getPlanStatistics();
});

/// Provider for best scoring plans
final bestScoringPlansProvider =
    FutureProvider.family<List<Plan>, BestPlansParams>((ref, params) {
      final repository = ref.watch(planRepositoryProvider);
      return repository.getBestScoringPlans(
        targetKcal: params.targetKcal,
        targetProteinG: params.targetProteinG,
        targetCarbsG: params.targetCarbsG,
        targetFatG: params.targetFatG,
        budgetCents: params.budgetCents,
        weights: params.weights,
        limit: params.limit,
      );
    });

/// Parameters for best scoring plans provider
class BestPlansParams {
  const BestPlansParams({
    required this.targetKcal,
    required this.targetProteinG,
    required this.targetCarbsG,
    required this.targetFatG,
    this.budgetCents,
    required this.weights,
    this.limit = 10,
  });

  final double targetKcal;
  final double targetProteinG;
  final double targetCarbsG;
  final double targetFatG;
  final int? budgetCents;
  final Map<String, double> weights;
  final int limit;
}

/// Notifier for managing plan operations
class PlanNotifier extends StateNotifier<AsyncValue<void>> {
  PlanNotifier(this._repository) : super(const AsyncValue.data(null));

  final PlanRepository _repository;

  Future<void> savePlan(Plan plan) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.addPlan(plan));
  }

  Future<void> updatePlan(Plan plan) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.updatePlan(plan));
  }

  Future<void> deletePlan(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.deletePlan(id));
  }

  Future<void> setCurrentPlan(String planId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.setCurrentPlan(planId));
  }

  Future<void> clearCurrentPlan() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.clearCurrentPlan());
  }

  Future<void> cleanupOldPlans({int keepCount = 50}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.cleanupOldPlans(keepCount: keepCount),
    );
  }
}

/// Provider for plan operations
final planNotifierProvider =
    StateNotifierProvider<PlanNotifier, AsyncValue<void>>((ref) {
      final repository = ref.watch(planRepositoryProvider);
      return PlanNotifier(repository);
    });

/// Parameters describing the current meal context for swap suggestions.
class SwapContext {
  const SwapContext({
    required this.currentRecipeId,
    required this.targetKcal,
    required this.targetProteinG,
    required this.targetCarbsG,
    required this.targetFatG,
    required this.mealIndex,
    this.targetsId,
    this.budgetCents,
    this.limit = 12,
  });

  final String currentRecipeId;
  final double targetKcal;
  final double targetProteinG;
  final double targetCarbsG;
  final double targetFatG;
  final int mealIndex;
  final String? targetsId;
  final int? budgetCents;
  final int limit;

  @override
  bool operator ==(Object other) {
    return other is SwapContext &&
        other.currentRecipeId == currentRecipeId &&
        other.targetKcal == targetKcal &&
        other.targetProteinG == targetProteinG &&
        other.targetCarbsG == targetCarbsG &&
        other.targetFatG == targetFatG &&
        other.mealIndex == mealIndex &&
        other.targetsId == targetsId &&
        other.budgetCents == budgetCents &&
        other.limit == limit;
  }

  @override
  int get hashCode => Object.hash(
    currentRecipeId,
    targetKcal,
    targetProteinG,
    targetCarbsG,
    targetFatG,
    mealIndex,
    targetsId,
    budgetCents,
    limit,
  );
}

/// Provider that returns ranked swap options for a particular meal context.
final swapSuggestionsProvider =
    FutureProvider.family<List<SwapOption>, SwapContext>((ref, ctx) async {
      final repository = ref.watch(planRepositoryProvider);
      final recommender = ref.watch(recommendationServiceProvider);
      final recipes = await ref.watch(allRecipesProvider.future);

      if (recipes.isEmpty) return const [];

      final recipeMap = {for (final recipe in recipes) recipe.id: recipe};
      final current = recipeMap[ctx.currentRecipeId];
      if (current == null) return const [];

      final weights = <String, double>{
        'macro_error': 1.0,
        'protein_penalty_multiplier': 2.0,
        'budget_error': 0.8,
        'variety_penalty': 0.2,
      };

      final plans = await repository.getBestScoringPlans(
        targetKcal: ctx.targetKcal,
        targetProteinG: ctx.targetProteinG,
        targetCarbsG: ctx.targetCarbsG,
        targetFatG: ctx.targetFatG,
        budgetCents: ctx.budgetCents,
        weights: weights,
        limit: math.max(8, ctx.limit),
      );

      final candidateIds = <String>{};
      for (final plan in plans) {
        for (final day in plan.days) {
          for (final meal in day.meals) {
            candidateIds.add(meal.recipeId);
          }
        }
      }
      candidateIds.remove(current.id);

      final candidateRecipes = candidateIds
          .map((id) => recipeMap[id])
          .whereType<Recipe>()
          .toList(growable: false);

      final ranked = _rankRecipes(
        primaryCandidates: candidateRecipes,
        allRecipes: recipes,
        current: current,
        ctx: ctx,
      );

      return recommender.toSwapOptions(current: current, candidates: ranked);
    });

List<Recipe> _rankRecipes({
  required List<Recipe> primaryCandidates,
  required List<Recipe> allRecipes,
  required Recipe current,
  required SwapContext ctx,
}) {
  final scored = primaryCandidates
      .map(
        (recipe) => MapEntry(
          recipe,
          _scoreRecipe(recipe: recipe, current: current, ctx: ctx),
        ),
      )
      .toList(growable: false);

  scored.sort((a, b) => a.value.compareTo(b.value));

  final ranked = <Recipe>[];
  for (final entry in scored) {
    ranked.add(entry.key);
    if (ranked.length >= ctx.limit) {
      break;
    }
  }

  if (ranked.length >= ctx.limit) {
    return ranked;
  }

  final fallback = allRecipes
      .where((recipe) {
        return recipe.id != current.id && !ranked.any((r) => r.id == recipe.id);
      })
      .map(
        (recipe) =>
            MapEntry(recipe, _targetCloseness(recipe.macrosPerServ, ctx)),
      )
      .toList(growable: false);

  fallback.sort((a, b) => a.value.compareTo(b.value));

  for (final entry in fallback) {
    ranked.add(entry.key);
    if (ranked.length >= ctx.limit) break;
  }

  return ranked;
}

double _scoreRecipe({
  required Recipe recipe,
  required Recipe current,
  required SwapContext ctx,
}) {
  final targetFitness = _targetCloseness(recipe.macrosPerServ, ctx);
  final currentSimilarity = _macroDistance(
    recipe.macrosPerServ,
    current.macrosPerServ,
  );

  double costScore = 0;
  final referenceCost = (ctx.budgetCents ?? current.costPerServCents).clamp(
    1,
    1000000,
  );
  costScore =
      (recipe.costPerServCents - referenceCost).abs() /
      referenceCost.toDouble();

  if (ctx.budgetCents != null && recipe.costPerServCents > ctx.budgetCents!) {
    final over = recipe.costPerServCents - ctx.budgetCents!;
    costScore += over / ctx.budgetCents!.toDouble();
  }

  return (targetFitness * 0.6) +
      (currentSimilarity * 0.25) +
      (costScore * 0.15);
}

double _targetCloseness(MacrosPerServing macros, SwapContext ctx) {
  final kcal = _relativeDelta(macros.kcal, ctx.targetKcal);
  final protein = _relativeDelta(macros.proteinG, ctx.targetProteinG);
  final carbs = _relativeDelta(macros.carbsG, ctx.targetCarbsG);
  final fat = _relativeDelta(macros.fatG, ctx.targetFatG);

  return (0.35 * kcal) + (0.35 * protein) + (0.15 * carbs) + (0.15 * fat);
}

double _macroDistance(MacrosPerServing a, MacrosPerServing b) {
  final kcal = _relativeDelta(a.kcal, b.kcal);
  final protein = _relativeDelta(a.proteinG, b.proteinG);
  final carbs = _relativeDelta(a.carbsG, b.carbsG);
  final fat = _relativeDelta(a.fatG, b.fatG);

  return (0.35 * kcal) + (0.35 * protein) + (0.15 * carbs) + (0.15 * fat);
}

double _relativeDelta(double actual, double target) {
  final denom = target.abs() < 1 ? 1.0 : target.abs();
  return (actual - target).abs() / denom;
}
