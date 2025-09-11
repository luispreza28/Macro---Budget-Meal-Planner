import '../entities/ingredient.dart';
import '../entities/recipe.dart';
import '../entities/plan.dart';
import '../entities/user_targets.dart';

/// Service for calculating macronutrients and nutritional information
class MacroCalculator {
  /// Calculate macros for a specific ingredient quantity
  MacrosPerHundred calculateIngredientMacros({
    required Ingredient ingredient,
    required double quantity,
    required Unit unit,
  }) {
    return ingredient.calculateMacros(quantity, unit);
  }

  /// Calculate total macros for a recipe with all its ingredients
  MacrosPerServing calculateRecipeMacros({
    required Recipe recipe,
    required List<Ingredient> ingredients,
  }) {
    double totalKcal = 0;
    double totalProteinG = 0;
    double totalCarbsG = 0;
    double totalFatG = 0;

    for (final item in recipe.items) {
      final ingredient = ingredients.firstWhere(
        (ing) => ing.id == item.ingredientId,
        orElse: () => throw ArgumentError(
          'Ingredient ${item.ingredientId} not found for recipe ${recipe.id}',
        ),
      );

      final itemMacros = ingredient.calculateMacros(item.qty, item.unit);
      totalKcal += itemMacros.kcal;
      totalProteinG += itemMacros.proteinG;
      totalCarbsG += itemMacros.carbsG;
      totalFatG += itemMacros.fatG;
    }

    // Divide by servings to get per-serving macros
    return MacrosPerServing(
      kcal: totalKcal / recipe.servings,
      proteinG: totalProteinG / recipe.servings,
      carbsG: totalCarbsG / recipe.servings,
      fatG: totalFatG / recipe.servings,
    );
  }

  /// Calculate total macros for a plan day
  MacrosPerServing calculateDayMacros({
    required PlanDay day,
    required List<Recipe> recipes,
  }) {
    double totalKcal = 0;
    double totalProteinG = 0;
    double totalCarbsG = 0;
    double totalFatG = 0;

    for (final meal in day.meals) {
      final recipe = recipes.firstWhere(
        (r) => r.id == meal.recipeId,
        orElse: () => throw ArgumentError(
          'Recipe ${meal.recipeId} not found for plan day ${day.date}',
        ),
      );

      final mealMacros = recipe.calculateTotalMacros(meal.servings);
      totalKcal += mealMacros.kcal;
      totalProteinG += mealMacros.proteinG;
      totalCarbsG += mealMacros.carbsG;
      totalFatG += mealMacros.fatG;
    }

    return MacrosPerServing(
      kcal: totalKcal,
      proteinG: totalProteinG,
      carbsG: totalCarbsG,
      fatG: totalFatG,
    );
  }

  /// Calculate total macros for an entire plan
  PlanTotals calculatePlanTotals({
    required Plan plan,
    required List<Recipe> recipes,
  }) {
    double totalKcal = 0;
    double totalProteinG = 0;
    double totalCarbsG = 0;
    double totalFatG = 0;
    int totalCostCents = 0;

    for (final day in plan.days) {
      final dayMacros = calculateDayMacros(day: day, recipes: recipes);
      totalKcal += dayMacros.kcal;
      totalProteinG += dayMacros.proteinG;
      totalCarbsG += dayMacros.carbsG;
      totalFatG += dayMacros.fatG;

      // Calculate day cost
      for (final meal in day.meals) {
        final recipe = recipes.firstWhere((r) => r.id == meal.recipeId);
        totalCostCents += recipe.calculateTotalCost(meal.servings);
      }
    }

    return PlanTotals(
      kcal: totalKcal,
      proteinG: totalProteinG,
      carbsG: totalCarbsG,
      fatG: totalFatG,
      costCents: totalCostCents,
    );
  }

  /// Calculate macro error against targets
  double calculateMacroError({
    required MacrosPerServing actual,
    required UserTargets targets,
  }) {
    final kcalError = (actual.kcal - targets.kcal).abs();
    final proteinError = (actual.proteinG - targets.proteinG).abs();
    final carbsError = (actual.carbsG - targets.carbsG).abs();
    final fatError = (actual.fatG - targets.fatG).abs();

    // Under-protein is penalized 2x as per PRD
    final proteinPenalty = actual.proteinG < targets.proteinG ? 2.0 : 1.0;

    return kcalError + (proteinError * proteinPenalty) + carbsError + fatError;
  }

  /// Calculate daily macro error for a plan day
  double calculateDayMacroError({
    required PlanDay day,
    required UserTargets targets,
    required List<Recipe> recipes,
  }) {
    final dayMacros = calculateDayMacros(day: day, recipes: recipes);
    return calculateMacroError(actual: dayMacros, targets: targets);
  }

  /// Calculate average daily macros for a plan
  MacrosPerServing calculateDailyAverageMacros({
    required Plan plan,
    required List<Recipe> recipes,
  }) {
    if (plan.days.isEmpty) {
      return const MacrosPerServing(
        kcal: 0,
        proteinG: 0,
        carbsG: 0,
        fatG: 0,
      );
    }

    final totals = calculatePlanTotals(plan: plan, recipes: recipes);
    final days = plan.days.length;

    return MacrosPerServing(
      kcal: totals.kcal / days,
      proteinG: totals.proteinG / days,
      carbsG: totals.carbsG / days,
      fatG: totals.fatG / days,
    );
  }

  /// Check if daily macros are within acceptable range (±5% for kcal, ≥100% for protein)
  bool isDayMacrosAcceptable({
    required PlanDay day,
    required UserTargets targets,
    required List<Recipe> recipes,
  }) {
    final dayMacros = calculateDayMacros(day: day, recipes: recipes);
    
    // Check calorie tolerance (±5%)
    final kcalTolerance = targets.kcal * 0.05;
    final kcalWithinRange = (dayMacros.kcal - targets.kcal).abs() <= kcalTolerance;
    
    // Check protein minimum (≥100%)
    final proteinMet = dayMacros.proteinG >= targets.proteinG;
    
    return kcalWithinRange && proteinMet;
  }

  /// Get macro distribution percentages
  Map<String, double> getMacroDistribution(MacrosPerServing macros) {
    final totalCals = (macros.proteinG * 4) + (macros.carbsG * 4) + (macros.fatG * 9);
    if (totalCals == 0) return {'protein': 0, 'carbs': 0, 'fat': 0};
    
    return {
      'protein': (macros.proteinG * 4) / totalCals * 100,
      'carbs': (macros.carbsG * 4) / totalCals * 100,
      'fat': (macros.fatG * 9) / totalCals * 100,
    };
  }

  /// Calculate protein per calorie ratio
  double getProteinPerCalorie(MacrosPerServing macros) {
    if (macros.kcal == 0) return 0;
    return macros.proteinG / macros.kcal;
  }

  /// Calculate cost per 1000 kcal for efficiency analysis
  double getCostPer1000Kcal({
    required int costCents,
    required double kcal,
  }) {
    if (kcal <= 0) return double.infinity;
    return (costCents * 1000) / kcal;
  }
}
