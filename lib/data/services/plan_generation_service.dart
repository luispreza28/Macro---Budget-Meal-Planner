import 'package:uuid/uuid.dart';

import '../../domain/entities/plan.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/entities/user_targets.dart';

/// Very simple plan generator:
/// - Creates a 7-day plan
/// - Uses `mealsPerDay` meals/day
/// - Cycles through available recipes (1 serving each)
/// - Computes totals from recipe macros & costs
class PlanGenerationService {
  Plan generate({
    required UserTargets targets,
    required List<Recipe> recipes,
  }) {
    if (recipes.isEmpty) {
      throw StateError('No recipes available to generate a plan.');
    }

    final mealsPerDay = targets.mealsPerDay;
    final start = DateTime.now();
    final days = <PlanDay>[];

    double totalKcal = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    int totalCostCents = 0;

    int recipeIndex = 0;

    for (int d = 0; d < 7; d++) {
      final dayDate = DateTime(start.year, start.month, start.day).add(Duration(days: d));
      final meals = <PlanMeal>[];

      for (int m = 0; m < mealsPerDay; m++) {
        final recipe = recipes[recipeIndex % recipes.length];
        recipeIndex++;

        // One serving per meal for now.
        meals.add(PlanMeal(recipeId: recipe.id, servings: 1));

        // Totals accumulate
        totalKcal += recipe.macrosPerServ.kcal;
        totalProtein += recipe.macrosPerServ.proteinG;
        totalCarbs += recipe.macrosPerServ.carbsG;
        totalFat += recipe.macrosPerServ.fatG;
        totalCostCents += recipe.costPerServCents;
      }

      days.add(PlanDay(date: dayDate.toIso8601String().split('T').first, meals: meals));
    }

    final totals = PlanTotals(
      kcal: totalKcal,
      proteinG: totalProtein,
      carbsG: totalCarbs,
      fatG: totalFat,
      costCents: totalCostCents,
    );

    final id = const Uuid().v4();
    final name =
        'Week of ${DateTime(start.year, start.month, start.day).toIso8601String().split('T').first}';

    return Plan(
      id: id,
      name: name,
      userTargetsId: targets.id,
      days: days,
      totals: totals,
      createdAt: DateTime.now(),
    );
    }
}
