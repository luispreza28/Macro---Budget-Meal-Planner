import '../entities/recipe.dart';
import '../entities/plan.dart';
import '../entities/user_targets.dart';
import '../entities/ingredient.dart';
import '../entities/pantry_item.dart';
import '../entities/price_override.dart';
import 'macro_calculator.dart';
import 'plan_generator.dart';
import 'pantry_first_planner.dart';
import 'swap_engine.dart';
import 'cost_calculator.dart';
import 'plan_validator.dart';

/// Comprehensive planning service that orchestrates all planning functionality
class PlanningService {
  PlanningService({
    MacroCalculator? macroCalculator,
    PlanGenerator? planGenerator,
    PantryFirstPlanner? pantryFirstPlanner,
    SwapEngine? swapEngine,
    CostCalculator? costCalculator,
    PlanValidator? planValidator,
  })  : macroCalculator = macroCalculator ?? MacroCalculator(),
        planGenerator = planGenerator ?? PlanGenerator(macroCalculator: macroCalculator ?? MacroCalculator()),
        swapEngine = swapEngine ?? SwapEngine(macroCalculator: macroCalculator ?? MacroCalculator()),
        costCalculator = costCalculator ?? CostCalculator(),
        planValidator = planValidator ?? PlanValidator(macroCalculator: macroCalculator ?? MacroCalculator()) {
    this.pantryFirstPlanner = pantryFirstPlanner ?? PantryFirstPlanner(macroCalculator: this.macroCalculator);
  }

  final MacroCalculator macroCalculator;
  final PlanGenerator planGenerator;
  late final PantryFirstPlanner pantryFirstPlanner;
  final SwapEngine swapEngine;
  final CostCalculator costCalculator;
  final PlanValidator planValidator;

  /// Generate a new meal plan with mode-specific optimization
  Future<PlanGenerationResult> generatePlan({
    required UserTargets targets,
    required List<Recipe> availableRecipes,
    required List<Ingredient> ingredients,
    List<PantryItem> pantryItems = const [],
    List<PriceOverride> priceOverrides = const [],
    String? planName,
    bool usePantryFirst = false,
  }) async {
    // Apply mode-specific recipe filtering and preparation
    final optimizedRecipes = _optimizeRecipesForMode(
      recipes: availableRecipes,
      mode: targets.planningMode,
      targets: targets,
    );

    if (optimizedRecipes.isEmpty) {
      throw ArgumentError('No suitable recipes found for ${targets.planningMode.displayName} mode');
    }

    // Choose planning strategy based on Pro features and pantry availability
    PlanGenerationResult result;
    
    if (usePantryFirst && pantryItems.isNotEmpty) {
      // Use pantry-first planning for Pro users
      result = await pantryFirstPlanner.generatePantryFirstPlan(
        targets: targets,
        availableRecipes: optimizedRecipes,
        ingredients: ingredients,
        pantryItems: pantryItems,
        planName: planName,
      );
    } else {
      // Use standard planning
      result = await planGenerator.generatePlan(
        targets: targets,
        availableRecipes: optimizedRecipes,
        ingredients: ingredients,
        pantryItems: pantryItems,
        planName: planName,
      );
    }

    // Validate the generated plan
    final validation = planValidator.validatePlan(
      plan: result.plan,
      targets: targets,
      availableRecipes: availableRecipes,
      availableIngredients: ingredients,
    );

    // If validation fails with errors, try to recover
    if (validation.hasErrors) {
      final recoveredPlan = await _attemptPlanRecovery(
        originalPlan: result.plan,
        targets: targets,
        availableRecipes: optimizedRecipes,
        ingredients: ingredients,
        pantryItems: pantryItems,
        validationResult: validation,
      );

      if (recoveredPlan != null) {
        return PlanGenerationResult(
          plan: recoveredPlan,
          score: result.score,
          iterations: result.iterations + 1,
          generationTimeMs: result.generationTimeMs,
          macroError: result.macroError,
          budgetError: result.budgetError,
        );
      }
    }

    return result;
  }

  /// Generate swap suggestions for a meal
  List<SwapSuggestion> generateSwapSuggestions({
    required Plan plan,
    required int dayIndex,
    required int mealIndex,
    required UserTargets targets,
    required List<Recipe> availableRecipes,
    required List<Ingredient> ingredients,
    List<PantryItem> pantryItems = const [],
    int maxSuggestions = 5,
  }) {
    // Apply mode-specific filtering to available recipes
    final optimizedRecipes = _optimizeRecipesForMode(
      recipes: availableRecipes,
      mode: targets.planningMode,
      targets: targets,
    );

    return swapEngine.generateSwapSuggestions(
      plan: plan,
      dayIndex: dayIndex,
      mealIndex: mealIndex,
      targets: targets,
      availableRecipes: optimizedRecipes,
      ingredients: ingredients,
      pantryItems: pantryItems,
      maxSuggestions: maxSuggestions,
    );
  }

  /// Apply a swap to a plan
  Plan applySwap({
    required Plan plan,
    required int dayIndex,
    required int mealIndex,
    required SwapSuggestion suggestion,
    required List<Recipe> recipes,
  }) {
    return swapEngine.applySwap(
      plan: plan,
      dayIndex: dayIndex,
      mealIndex: mealIndex,
      suggestion: suggestion,
      recipes: recipes,
    );
  }

  /// Calculate detailed cost analysis for a plan
  CostCalculationResult calculatePlanCost({
    required Plan plan,
    required List<Recipe> recipes,
    required List<Ingredient> ingredients,
    List<PantryItem> pantryItems = const [],
    List<PriceOverride> priceOverrides = const [],
  }) {
    return costCalculator.calculatePlanCost(
      plan: plan,
      recipes: recipes,
      ingredients: ingredients,
      pantryItems: pantryItems,
      priceOverrides: priceOverrides,
    );
  }

  /// Generate shopping list for a plan
  GroupedShoppingList generateShoppingList({
    required Plan plan,
    required List<Recipe> recipes,
    required List<Ingredient> ingredients,
    List<PantryItem> pantryItems = const [],
    List<PriceOverride> priceOverrides = const [],
  }) {
    return costCalculator.generateShoppingList(
      plan: plan,
      recipes: recipes,
      ingredients: ingredients,
      pantryItems: pantryItems,
      priceOverrides: priceOverrides,
    );
  }

  /// Validate a plan
  ValidationResult validatePlan({
    required Plan plan,
    required UserTargets targets,
    required List<Recipe> availableRecipes,
    required List<Ingredient> availableIngredients,
  }) {
    return planValidator.validatePlan(
      plan: plan,
      targets: targets,
      availableRecipes: availableRecipes,
      availableIngredients: availableIngredients,
    );
  }

  /// Get mode-specific recommendations for improving a plan
  List<String> getModeSpecificRecommendations({
    required Plan plan,
    required UserTargets targets,
    required List<Recipe> recipes,
    required List<Ingredient> ingredients,
  }) {
    final recommendations = <String>[];
    final dailyAvg = macroCalculator.calculateDailyAverageMacros(
      plan: plan,
      recipes: recipes,
    );

    switch (targets.planningMode) {
      case PlanningMode.cutting:
        recommendations.addAll(_getCuttingRecommendations(dailyAvg, targets, plan, recipes));
        break;
      case PlanningMode.bulkingBudget:
        recommendations.addAll(_getBulkingBudgetRecommendations(dailyAvg, targets, plan, recipes, ingredients));
        break;
      case PlanningMode.bulkingNoBudget:
        recommendations.addAll(_getBulkingNoBudgetRecommendations(dailyAvg, targets, plan, recipes));
        break;
      case PlanningMode.maintenance:
        recommendations.addAll(_getMaintenanceRecommendations(dailyAvg, targets, plan, recipes));
        break;
    }

    return recommendations;
  }

  /// Optimize recipes for specific planning mode
  List<Recipe> _optimizeRecipesForMode({
    required List<Recipe> recipes,
    required PlanningMode mode,
    required UserTargets targets,
  }) {
    // Filter by diet compatibility and time constraints
    var filteredRecipes = recipes
        .where((recipe) => recipe.isCompatibleWithDiet(targets.dietFlags))
        .where((recipe) => recipe.fitsTimeConstraint(targets.timeCapMins))
        .toList();

    // Apply mode-specific optimization
    switch (mode) {
      case PlanningMode.cutting:
        // Prioritize high-protein, high-volume, lower-calorie recipes
        filteredRecipes.sort((a, b) {
          final aScore = _calculateCuttingScore(a);
          final bScore = _calculateCuttingScore(b);
          return bScore.compareTo(aScore); // Higher score first
        });
        break;

      case PlanningMode.bulkingBudget:
        // Prioritize cost-efficient, calorie-dense recipes
        filteredRecipes.sort((a, b) {
          final aScore = _calculateBulkingBudgetScore(a);
          final bScore = _calculateBulkingBudgetScore(b);
          return bScore.compareTo(aScore); // Higher score first
        });
        break;

      case PlanningMode.bulkingNoBudget:
        // Prioritize quick, calorie-dense recipes
        filteredRecipes.sort((a, b) {
          final aScore = _calculateBulkingNoBudgetScore(a);
          final bScore = _calculateBulkingNoBudgetScore(b);
          return bScore.compareTo(aScore); // Higher score first
        });
        break;

      case PlanningMode.maintenance:
        // Balanced approach - no specific sorting
        break;
    }

    return filteredRecipes;
  }

  /// Calculate cutting mode score for a recipe
  double _calculateCuttingScore(Recipe recipe) {
    double score = 0;
    
    // High protein density is good
    score += recipe.getProteinDensity() * 2;
    
    // High volume/low calorie density is good
    if (recipe.isHighVolume()) score += 20;
    
    // Lower calories per serving is better for cutting
    score += (500 - recipe.macrosPerServ.kcal).clamp(0, 200) / 10;
    
    // Reasonable prep time is preferred
    if (recipe.timeMins <= 30) score += 10;
    
    return score;
  }

  /// Calculate bulking budget score for a recipe
  double _calculateBulkingBudgetScore(Recipe recipe) {
    double score = 0;
    
    // Cost efficiency is key
    final costEfficiency = recipe.getCostEfficiency();
    if (costEfficiency < 300) score += 30;
    else if (costEfficiency < 500) score += 20;
    else if (costEfficiency < 700) score += 10;
    
    // Calorie density is important
    if (recipe.macrosPerServ.kcal > 400) score += 20;
    else if (recipe.macrosPerServ.kcal > 300) score += 10;
    
    // Protein content still matters
    score += recipe.macrosPerServ.proteinG / 5;
    
    return score;
  }

  /// Calculate bulking no-budget score for a recipe
  double _calculateBulkingNoBudgetScore(Recipe recipe) {
    double score = 0;
    
    // Quick prep time is highly valued
    if (recipe.timeMins <= 10) score += 30;
    else if (recipe.timeMins <= 20) score += 20;
    else if (recipe.timeMins <= 30) score += 10;
    
    // High calorie content
    if (recipe.macrosPerServ.kcal > 500) score += 25;
    else if (recipe.macrosPerServ.kcal > 400) score += 15;
    else if (recipe.macrosPerServ.kcal > 300) score += 5;
    
    // Protein content
    score += recipe.macrosPerServ.proteinG / 4;
    
    return score;
  }

  /// Get cutting-specific recommendations
  List<String> _getCuttingRecommendations(
    MacrosPerServing dailyAvg,
    UserTargets targets,
    Plan plan,
    List<Recipe> recipes,
  ) {
    final recommendations = <String>[];
    
    if (dailyAvg.proteinG < targets.proteinG * 0.9) {
      recommendations.add('Increase protein intake with lean meats, fish, or protein-rich recipes');
    }
    
    if (dailyAvg.kcal > targets.kcal * 1.05) {
      recommendations.add('Reduce portion sizes or choose lower-calorie alternatives');
    }
    
    // Check for high-volume recipes
    final highVolumeCount = _countHighVolumeRecipes(plan, recipes);
    if (highVolumeCount < plan.days.length) {
      recommendations.add('Add more high-volume foods like vegetables and salads for satiety');
    }
    
    return recommendations;
  }

  /// Get bulking budget recommendations
  List<String> _getBulkingBudgetRecommendations(
    MacrosPerServing dailyAvg,
    UserTargets targets,
    Plan plan,
    List<Recipe> recipes,
    List<Ingredient> ingredients,
  ) {
    final recommendations = <String>[];
    
    if (dailyAvg.kcal < targets.kcal * 0.95) {
      recommendations.add('Add calorie-dense, cost-effective foods like oats, rice, and pasta');
    }
    
    final totals = macroCalculator.calculatePlanTotals(plan: plan, recipes: recipes);
    final avgCostEfficiency = costCalculator.calculateCostEfficiency(
      costCents: totals.costCents,
      kcal: totals.kcal,
    );
    
    if (avgCostEfficiency > 500) {
      recommendations.add('Choose more cost-effective recipes to maximize calories per dollar');
    }
    
    return recommendations;
  }

  /// Get bulking no-budget recommendations
  List<String> _getBulkingNoBudgetRecommendations(
    MacrosPerServing dailyAvg,
    UserTargets targets,
    Plan plan,
    List<Recipe> recipes,
  ) {
    final recommendations = <String>[];
    
    if (dailyAvg.kcal < targets.kcal * 0.95) {
      recommendations.add('Add quick, calorie-dense meals like smoothies and protein shakes');
    }
    
    final avgPrepTime = _calculateAveragePrepTime(plan, recipes);
    if (avgPrepTime > 30) {
      recommendations.add('Consider meal prep or quicker recipes to reduce daily cooking time');
    }
    
    return recommendations;
  }

  /// Get maintenance recommendations
  List<String> _getMaintenanceRecommendations(
    MacrosPerServing dailyAvg,
    UserTargets targets,
    Plan plan,
    List<Recipe> recipes,
  ) {
    final recommendations = <String>[];
    
    final kcalError = (dailyAvg.kcal - targets.kcal).abs() / targets.kcal;
    if (kcalError > 0.1) {
      recommendations.add('Adjust portion sizes to better match calorie targets');
    }
    
    final variety = _calculateRecipeVariety(plan);
    if (variety < 0.7) {
      recommendations.add('Add more variety to prevent meal fatigue');
    }
    
    return recommendations;
  }

  /// Attempt to recover from plan validation errors
  Future<Plan?> _attemptPlanRecovery({
    required Plan originalPlan,
    required UserTargets targets,
    required List<Recipe> availableRecipes,
    required List<Ingredient> ingredients,
    required List<PantryItem> pantryItems,
    required ValidationResult validationResult,
  }) async {
    // For now, return null - in a full implementation, this would:
    // 1. Identify specific errors
    // 2. Try to fix them (replace missing recipes, adjust servings, etc.)
    // 3. Re-validate the fixed plan
    // 4. Return the recovered plan or null if recovery failed
    return null;
  }

  /// Count high-volume recipes in a plan
  int _countHighVolumeRecipes(Plan plan, List<Recipe> recipes) {
    final recipeMap = {for (var r in recipes) r.id: r};
    int count = 0;
    
    for (final day in plan.days) {
      for (final meal in day.meals) {
        final recipe = recipeMap[meal.recipeId];
        if (recipe?.isHighVolume() == true) {
          count++;
        }
      }
    }
    
    return count;
  }

  /// Calculate average prep time for a plan
  double _calculateAveragePrepTime(Plan plan, List<Recipe> recipes) {
    final recipeMap = {for (var r in recipes) r.id: r};
    int totalTime = 0;
    int totalMeals = 0;
    
    for (final day in plan.days) {
      for (final meal in day.meals) {
        final recipe = recipeMap[meal.recipeId];
        if (recipe != null) {
          totalTime += recipe.timeMins;
          totalMeals++;
        }
      }
    }
    
    return totalMeals > 0 ? totalTime / totalMeals : 0;
  }

  /// Calculate recipe variety score (0-1, higher is more variety)
  double _calculateRecipeVariety(Plan plan) {
    final recipeCount = <String, int>{};
    int totalMeals = 0;
    
    for (final day in plan.days) {
      for (final meal in day.meals) {
        recipeCount[meal.recipeId] = (recipeCount[meal.recipeId] ?? 0) + 1;
        totalMeals++;
      }
    }
    
    if (totalMeals == 0) return 0;
    
    final uniqueRecipes = recipeCount.length;
    return uniqueRecipes / totalMeals;
  }
}
