// lib/data/services/plan_generation_service.dart
import 'dart:math';

import '../../domain/entities/plan.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/entities/ingredient.dart';
import '../../domain/entities/user_targets.dart';

/// Generator that prefers real recipe.items to compute macros & cost.
/// Falls back to Recipe.macrosPerServ and costPerServCents if items are missing.
class PlanGenerationService {
  Plan generate({
    required UserTargets targets,
    required List<Recipe> recipes,
    required List<Ingredient> ingredients,
  }) {
    if (recipes.isEmpty) {
      throw StateError('No recipes available to generate a plan.');
    }

    final ingById = {for (final i in ingredients) i.id: i};

    final mealsPerDay = targets.mealsPerDay.clamp(2, 5);
    final rng = Random();
    final pool = [...recipes]..shuffle(rng);

    final List<PlanDay> days = [];
    int mealCursor = 0;

    double totalKcal = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    int totalCostCents = 0;

    for (int d = 0; d < 7; d++) {
      final List<PlanMeal> meals = [];
      for (int m = 0; m < mealsPerDay; m++) {
        final recipe = pool[mealCursor % pool.length];
        mealCursor++;

        final servings = 1.0;

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

        meals.add(PlanMeal(
          recipeId: recipe.id,
          servings: servings,
        ));
      }

      final date = DateTime.now().add(Duration(days: d));
      days.add(PlanDay(
        date: date.toIso8601String(),
        meals: meals,
      ));
    }

    final planTotals = PlanTotals(
      kcal: totalKcal,
      proteinG: totalProtein,
      carbsG: totalCarbs,
      fatG: totalFat,
      costCents: totalCostCents,
    );

    // Remove `updatedAt:` — the Plan constructor in your domain model
    // does not accept it.
    return Plan(
      id: 'plan_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Weekly Plan',
      userTargetsId: targets.id,
      days: days,
      totals: planTotals,
      createdAt: DateTime.now(),
    );
  }

  _Totals _computeFromRecipe({
    required Recipe recipe,
    required double servings,
    required Map<String, Ingredient> ingById,
  }) {
    if (recipe.items.isNotEmpty) {
      double kcal = 0, protein = 0, carbs = 0, fat = 0;
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
            baseQtyFor100 = qty; // assume 1 pc ~ 100g unless you add per-piece data
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
