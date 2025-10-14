import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/value/substitution_score.dart';
import '../../domain/services/substitution_scoring_service.dart';
import 'recipe_providers.dart';
import 'recipe_pref_providers.dart';

/// Compute ranked substitution scores for a given current recipe and servings.
final substitutionScoresProvider = FutureProvider.family<
    List<SubstitutionScore>, ({String currentRecipeId, int servingsForMeal})>(
  (ref, args) async {
    final allRecipes = await ref.watch(allRecipesProvider.future);
    final current =
        allRecipes.firstWhere((r) => r.id == args.currentRecipeId, orElse: () => allRecipes.first);

    // Filter candidates: exclude current, excluded recipes
    final excluded = await ref.watch(excludedRecipesProvider.future);
    final candidates = allRecipes
        .where((r) => r.id != current.id && !excluded.contains(r.id))
        .toList(growable: false);

    final svc = ref.read(substitutionScoringServiceProvider);
    return svc.rankAlternatives(
      current: current,
      candidates: candidates,
      servingsForMeal: args.servingsForMeal,
    );
  },
);

