import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/plan.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/services/pantry_shortfall_service.dart';
import '../../domain/value/shortfall_item.dart';
import 'plan_providers.dart';
import 'recipe_providers.dart';

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

