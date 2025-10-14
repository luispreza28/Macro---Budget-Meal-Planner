import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/plan.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/services/pantry_shortfall_service.dart';
import '../../domain/value/shortfall_item.dart';
import 'plan_providers.dart';
import 'recipe_providers.dart';
import '../../domain/services/shortfall_service.dart';
import '../../domain/services/shortfall_service.dart' as v2;

final shortfallForRecipeProvider =
    FutureProvider.family<List<ShortfallItem>, String>((ref, recipeId) async {
  final recipe = await ref.watch(recipeByIdProvider(recipeId).future);
  if (recipe == null) return const [];
  final svc = ref.read(pantryShortfallServiceProvider);
  return svc.shortfallForRecipe(recipe);
});

final shortfallForCurrentPlanProvider =
    FutureProvider<List<ShortfallItem>>((ref) async {
  final plan = await ref.watch(currentPlanProvider.future);
  if (plan == null) return const [];
  final svc = ref.read(pantryShortfallServiceProvider);
  return svc.shortfallForPlan(plan);
});

/// Per-meal shortfall with unit-aligned deltas and coverage ratio.
final mealShortfallProvider = FutureProvider.family<MealShortfall, ({String recipeId, int servingsForMeal})>((ref, args) async {
  final recipes = await ref.watch(allRecipesProvider.future);
  final r = recipes.firstWhere((e) => e.id == args.recipeId);
  final svc = ref.read(shortfallServiceProvider);
  return svc.compute(recipe: r, servingsForMeal: args.servingsForMeal);
});
