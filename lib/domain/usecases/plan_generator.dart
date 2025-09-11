import 'dart:math' as math;

import '../entities/ingredient.dart';
import '../entities/recipe.dart';
import '../entities/plan.dart';
import '../entities/user_targets.dart';
import '../entities/pantry_item.dart';
import 'macro_calculator.dart';

/// Configuration for plan generation algorithm
class PlanGenerationConfig {
  const PlanGenerationConfig({
    this.maxIterations = 100,
    this.maxGenerationTimeMs = 2000,
    this.maxIterationTimeMs = 300,
    this.candidatesPerSlot = 5,
    this.improvementThreshold = 0.01,
  });

  final int maxIterations;
  final int maxGenerationTimeMs;
  final int maxIterationTimeMs;
  final int candidatesPerSlot;
  final double improvementThreshold;
}

/// Weights for the multi-objective optimization function
class OptimizationWeights {
  const OptimizationWeights({
    required this.macroError,
    required this.budgetError,
    required this.varietyPenalty,
    required this.prepTimePenalty,
    required this.pantryBonus,
  });

  final double macroError;
  final double budgetError;
  final double varietyPenalty;
  final double prepTimePenalty;
  final double pantryBonus;

  /// Get mode-specific weights based on planning mode
  factory OptimizationWeights.forMode(PlanningMode mode) {
    switch (mode) {
      case PlanningMode.cutting:
        return const OptimizationWeights(
          macroError: 2.0,      // High macro precision
          budgetError: 1.0,     // Moderate budget concern
          varietyPenalty: 0.5,  // Allow some repetition
          prepTimePenalty: 0.3, // Low time penalty
          pantryBonus: 1.5,     // Encourage pantry use
        );
      case PlanningMode.bulkingBudget:
        return const OptimizationWeights(
          macroError: 1.5,      // Moderate macro precision
          budgetError: 2.0,     // High budget concern
          varietyPenalty: 0.3,  // Allow repetition for cost
          prepTimePenalty: 0.5, // Moderate time penalty
          pantryBonus: 2.0,     // High pantry use for cost
        );
      case PlanningMode.bulkingNoBudget:
        return const OptimizationWeights(
          macroError: 1.5,      // Moderate macro precision
          budgetError: 0.2,     // Very low budget concern
          varietyPenalty: 1.0,  // More variety desired
          prepTimePenalty: 2.0, // High time penalty (quick meals)
          pantryBonus: 0.5,     // Lower pantry priority
        );
      case PlanningMode.maintenance:
        return const OptimizationWeights(
          macroError: 1.0,      // Balanced macro precision
          budgetError: 1.0,     // Balanced budget concern
          varietyPenalty: 1.0,  // Balanced variety
          prepTimePenalty: 1.0, // Balanced time concern
          pantryBonus: 1.0,     // Balanced pantry use
        );
    }
  }
}

/// Result of a plan generation attempt
class PlanGenerationResult {
  const PlanGenerationResult({
    required this.plan,
    required this.score,
    required this.iterations,
    required this.generationTimeMs,
    required this.macroError,
    required this.budgetError,
  });

  final Plan plan;
  final double score;
  final int iterations;
  final int generationTimeMs;
  final double macroError;
  final double budgetError;
}

/// Service for generating optimized meal plans
class PlanGenerator {
  PlanGenerator({
    required this.macroCalculator,
    this.config = const PlanGenerationConfig(),
  });

  final MacroCalculator macroCalculator;
  final PlanGenerationConfig config;
  final math.Random _random = math.Random();

  /// Generate an optimized 7-day meal plan
  Future<PlanGenerationResult> generatePlan({
    required UserTargets targets,
    required List<Recipe> availableRecipes,
    required List<Ingredient> ingredients,
    List<PantryItem> pantryItems = const [],
    String? planName,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    // Filter recipes based on constraints
    final suitableRecipes = _filterRecipesByConstraints(
      recipes: availableRecipes,
      targets: targets,
    );

    if (suitableRecipes.isEmpty) {
      throw ArgumentError('No suitable recipes found for the given constraints');
    }

    // Generate initial plan
    Plan currentPlan = _generateInitialPlan(
      targets: targets,
      recipes: suitableRecipes,
      planName: planName ?? 'Generated Plan',
    );

    // Calculate initial score
    double currentScore = calculatePlanScore(
      plan: currentPlan,
      targets: targets,
      recipes: availableRecipes,
      ingredients: ingredients,
      pantryItems: pantryItems,
    );

    int iterations = 0;

    // Local search optimization
    while (iterations < config.maxIterations && 
           stopwatch.elapsedMilliseconds < config.maxGenerationTimeMs) {
      
      final iterationStopwatch = Stopwatch()..start();
      
      // Try to improve the plan
      final improvedPlan = tryImprovement(
        currentPlan: currentPlan,
        targets: targets,
        recipes: suitableRecipes,
        ingredients: ingredients,
        pantryItems: pantryItems,
      );

      final improvedScore = calculatePlanScore(
        plan: improvedPlan,
        targets: targets,
        recipes: availableRecipes,
        ingredients: ingredients,
        pantryItems: pantryItems,
      );

      // Accept improvement if score is better
      if (improvedScore < currentScore - config.improvementThreshold) {
        currentPlan = improvedPlan;
        currentScore = improvedScore;
      }

      iterations++;
      
      // Stop if iteration takes too long
      if (iterationStopwatch.elapsedMilliseconds > config.maxIterationTimeMs) {
        break;
      }
    }

    final totals = macroCalculator.calculatePlanTotals(
      plan: currentPlan,
      recipes: availableRecipes,
    );

    final finalPlan = currentPlan.copyWith(totals: totals);
    
    final dailyAvg = macroCalculator.calculateDailyAverageMacros(
      plan: finalPlan,
      recipes: availableRecipes,
    );
    
    final macroError = macroCalculator.calculateMacroError(
      actual: dailyAvg,
      targets: targets,
    );

    final budgetError = targets.budgetCents != null 
        ? math.max(0, totals.costCents - (targets.budgetCents! * 7))
        : 0;

    return PlanGenerationResult(
      plan: finalPlan,
      score: currentScore,
      iterations: iterations,
      generationTimeMs: stopwatch.elapsedMilliseconds,
      macroError: macroError,
      budgetError: budgetError.toDouble(),
    );
  }

  /// Filter recipes based on user constraints
  List<Recipe> _filterRecipesByConstraints({
    required List<Recipe> recipes,
    required UserTargets targets,
  }) {
    return recipes.where((recipe) {
      // Check diet compatibility
      if (!recipe.isCompatibleWithDiet(targets.dietFlags)) {
        return false;
      }

      // Check time constraint
      if (!recipe.fitsTimeConstraint(targets.timeCapMins)) {
        return false;
      }

      // Check equipment constraints (simplified for now)
      // In a full implementation, would check recipe.requiredEquipment against targets.equipment

      return true;
    }).toList();
  }

  /// Generate initial plan using mode-specific seeding
  Plan _generateInitialPlan({
    required UserTargets targets,
    required List<Recipe> recipes,
    required String planName,
  }) {
    final days = <PlanDay>[];
    final startDate = DateTime.now();

    for (int dayIndex = 0; dayIndex < 7; dayIndex++) {
      final date = startDate.add(Duration(days: dayIndex));
      final meals = <PlanMeal>[];

      // Generate meals for the day based on mealsPerDay
      for (int mealIndex = 0; mealIndex < targets.mealsPerDay; mealIndex++) {
        final recipe = _selectRecipeForMeal(
          recipes: recipes,
          targets: targets,
          mealIndex: mealIndex,
          dayIndex: dayIndex,
        );

        // Calculate appropriate serving size
        final servings = _calculateOptimalServings(
          recipe: recipe,
          targets: targets,
          mealIndex: mealIndex,
        );

        meals.add(PlanMeal(
          recipeId: recipe.id,
          servings: servings,
        ));
      }

      days.add(PlanDay(
        date: date.toIso8601String().split('T')[0],
        meals: meals,
      ));
    }

    return Plan(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: planName,
      userTargetsId: targets.id,
      days: days,
      totals: PlanTotals.empty(), // Will be calculated later
      createdAt: DateTime.now(),
    );
  }

  /// Select appropriate recipe for a meal slot
  Recipe _selectRecipeForMeal({
    required List<Recipe> recipes,
    required UserTargets targets,
    required int mealIndex,
    required int dayIndex,
  }) {
    List<Recipe> candidates;

    switch (targets.planningMode) {
      case PlanningMode.cutting:
        // Prefer high-volume, high-protein recipes
        candidates = recipes.where((r) => 
          r.isHighVolume() || r.getProteinDensity() > 15
        ).toList();
        break;
        
      case PlanningMode.bulkingBudget:
        // Prefer cost-efficient, calorie-dense recipes
        candidates = recipes.where((r) => 
          r.isCalorieDense() || r.getCostEfficiency() < 500
        ).toList();
        break;
        
      case PlanningMode.bulkingNoBudget:
        // Prefer quick, calorie-dense recipes
        candidates = recipes.where((r) => 
          r.isCalorieDense() && r.isQuick()
        ).toList();
        break;
        
      case PlanningMode.maintenance:
        // Balanced selection
        candidates = recipes;
        break;
    }

    if (candidates.isEmpty) {
      candidates = recipes;
    }

    // Sort by preference criteria
    candidates.sort((a, b) {
      switch (targets.planningMode) {
        case PlanningMode.cutting:
          return a.getProteinDensity().compareTo(b.getProteinDensity()) * -1;
        case PlanningMode.bulkingBudget:
          return a.getCostEfficiency().compareTo(b.getCostEfficiency());
        case PlanningMode.bulkingNoBudget:
          return a.timeMins.compareTo(b.timeMins);
        case PlanningMode.maintenance:
          return 0; // Keep original order
      }
    });

    // Select from top candidates with some randomness
    final topCount = math.min(5, candidates.length);
    final selectedIndex = _random.nextInt(topCount);
    return candidates[selectedIndex];
  }

  /// Calculate optimal serving size for a recipe in a meal
  double _calculateOptimalServings({
    required Recipe recipe,
    required UserTargets targets,
    required int mealIndex,
  }) {
    // Base serving size on daily calorie distribution
    final targetCaloriesPerMeal = targets.kcal / targets.mealsPerDay;
    
    // Adjust for meal type (breakfast smaller, dinner larger, etc.)
    double mealMultiplier = 1.0;
    if (targets.mealsPerDay >= 3) {
      switch (mealIndex) {
        case 0: // Breakfast
          mealMultiplier = 0.8;
          break;
        case 1: // Lunch
          mealMultiplier = 1.0;
          break;
        case 2: // Dinner
          mealMultiplier = 1.2;
          break;
        default: // Snacks
          mealMultiplier = 0.6;
          break;
      }
    }

    final targetMealCalories = targetCaloriesPerMeal * mealMultiplier;
    final servings = targetMealCalories / recipe.macrosPerServ.kcal;
    
    // Round to reasonable serving sizes (0.5, 1.0, 1.5, 2.0, etc.)
    return (servings * 2).round() / 2.0;
  }

  /// Try to improve the plan by making a random beneficial change
  Plan tryImprovement({
    required Plan currentPlan,
    required UserTargets targets,
    required List<Recipe> recipes,
    required List<Ingredient> ingredients,
    required List<PantryItem> pantryItems,
  }) {
    // Randomly select a meal slot to improve
    final dayIndex = _random.nextInt(currentPlan.days.length);
    final day = currentPlan.days[dayIndex];
    final mealIndex = _random.nextInt(day.meals.length);
    final currentMeal = day.meals[mealIndex];

    // Find alternative recipes
    final alternatives = _findAlternativeRecipes(
      currentRecipeId: currentMeal.recipeId,
      recipes: recipes,
      targets: targets,
      mealIndex: mealIndex,
    );

    if (alternatives.isEmpty) {
      return currentPlan; // No alternatives available
    }

    // Select best alternative
    final bestAlternative = alternatives.first;
    final newServings = _calculateOptimalServings(
      recipe: bestAlternative,
      targets: targets,
      mealIndex: mealIndex,
    );

    // Create new meal
    final newMeal = PlanMeal(
      recipeId: bestAlternative.id,
      servings: newServings,
      notes: currentMeal.notes,
    );

    // Create new day with replaced meal
    final newMeals = List<PlanMeal>.from(day.meals);
    newMeals[mealIndex] = newMeal;
    final newDay = PlanDay(date: day.date, meals: newMeals);

    // Create new plan with replaced day
    final newDays = List<PlanDay>.from(currentPlan.days);
    newDays[dayIndex] = newDay;

    return currentPlan.copyWith(days: newDays);
  }

  /// Find alternative recipes for a meal slot
  List<Recipe> _findAlternativeRecipes({
    required String currentRecipeId,
    required List<Recipe> recipes,
    required UserTargets targets,
    required int mealIndex,
  }) {
    final alternatives = recipes
        .where((r) => r.id != currentRecipeId)
        .where((r) => r.isCompatibleWithDiet(targets.dietFlags))
        .where((r) => r.fitsTimeConstraint(targets.timeCapMins))
        .toList();

    // Sort by suitability for the planning mode
    alternatives.sort((a, b) {
      switch (targets.planningMode) {
        case PlanningMode.cutting:
          return b.getProteinDensity().compareTo(a.getProteinDensity());
        case PlanningMode.bulkingBudget:
          return a.getCostEfficiency().compareTo(b.getCostEfficiency());
        case PlanningMode.bulkingNoBudget:
          return a.timeMins.compareTo(b.timeMins);
        case PlanningMode.maintenance:
          return 0;
      }
    });

    return alternatives.take(config.candidatesPerSlot).toList();
  }

  /// Calculate the optimization score for a plan
  double calculatePlanScore({
    required Plan plan,
    required UserTargets targets,
    required List<Recipe> recipes,
    required List<Ingredient> ingredients,
    required List<PantryItem> pantryItems,
  }) {
    final weights = OptimizationWeights.forMode(targets.planningMode);
    
    // Calculate daily average macros
    final dailyAvg = macroCalculator.calculateDailyAverageMacros(
      plan: plan,
      recipes: recipes,
    );

    // 1. Macro error (L1 norm with protein penalty)
    final macroError = macroCalculator.calculateMacroError(
      actual: dailyAvg,
      targets: targets,
    );

    // 2. Budget error
    final totals = macroCalculator.calculatePlanTotals(
      plan: plan,
      recipes: recipes,
    );
    final budgetError = targets.budgetCents != null 
        ? math.max(0, totals.costCents - (targets.budgetCents! * 7))
        : 0;

    // 3. Variety penalty (count recipe repetitions)
    final varietyPenalty = _calculateVarietyPenalty(plan);

    // 4. Prep time penalty
    final prepTimePenalty = _calculatePrepTimePenalty(plan, recipes, targets);

    // 5. Pantry bonus (negative term for using pantry items)
    final pantryBonus = _calculatePantryBonus(plan, recipes, ingredients, pantryItems);

    // Combine all factors
    final score = (weights.macroError * macroError) +
                  (weights.budgetError * budgetError) +
                  (weights.varietyPenalty * varietyPenalty) +
                  (weights.prepTimePenalty * prepTimePenalty) -
                  (weights.pantryBonus * pantryBonus);

    return score;
  }

  /// Calculate variety penalty for recipe repetition
  double _calculateVarietyPenalty(Plan plan) {
    final recipeCount = <String, int>{};
    
    for (final day in plan.days) {
      for (final meal in day.meals) {
        recipeCount[meal.recipeId] = (recipeCount[meal.recipeId] ?? 0) + 1;
      }
    }

    double penalty = 0;
    for (final count in recipeCount.values) {
      if (count > 2) {
        penalty += (count - 2) * 10; // Penalize repetition beyond 2 times
      }
    }

    return penalty;
  }

  /// Calculate prep time penalty
  double _calculatePrepTimePenalty(
    Plan plan,
    List<Recipe> recipes,
    UserTargets targets,
  ) {
    if (targets.timeCapMins == null) return 0;

    double totalTime = 0;
    for (final day in plan.days) {
      for (final meal in day.meals) {
        final recipe = recipes.firstWhere((r) => r.id == meal.recipeId);
        totalTime += recipe.timeMins;
      }
    }

    final dailyAvgTime = totalTime / plan.days.length;
    return math.max(0, dailyAvgTime - targets.timeCapMins!);
  }

  /// Calculate pantry bonus for using pantry items
  double _calculatePantryBonus(
    Plan plan,
    List<Recipe> recipes,
    List<Ingredient> ingredients,
    List<PantryItem> pantryItems,
  ) {
    if (pantryItems.isEmpty) return 0;

    final pantryMap = {for (var item in pantryItems) item.ingredientId: item};
    double bonus = 0;

    for (final day in plan.days) {
      for (final meal in day.meals) {
        final recipe = recipes.firstWhere((r) => r.id == meal.recipeId);
        
        for (final item in recipe.items) {
          if (pantryMap.containsKey(item.ingredientId)) {
            final pantryItem = pantryMap[item.ingredientId]!;
            final requiredQty = item.qty * meal.servings;
            
            if (pantryItem.hasEnoughFor(requiredQty, item.unit)) {
              // Calculate savings from using pantry item
              final ingredient = ingredients.firstWhere((ing) => ing.id == item.ingredientId);
              final savings = ingredient.calculateCost(requiredQty, item.unit);
              bonus += savings;
            }
          }
        }
      }
    }

    return bonus;
  }
}

/// Extension methods for Plan entity
extension PlanExtensions on Plan {
  Plan copyWith({
    String? id,
    String? name,
    String? userTargetsId,
    List<PlanDay>? days,
    PlanTotals? totals,
    DateTime? createdAt,
  }) {
    return Plan(
      id: id ?? this.id,
      name: name ?? this.name,
      userTargetsId: userTargetsId ?? this.userTargetsId,
      days: days ?? this.days,
      totals: totals ?? this.totals,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
