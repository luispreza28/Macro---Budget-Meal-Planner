import 'dart:math' as math;

import '../entities/ingredient.dart';
import '../entities/recipe.dart';
import '../entities/plan.dart';
import '../entities/user_targets.dart';
import '../entities/pantry_item.dart';
import 'plan_generator.dart';

/// Pantry usage result for tracking what was used
class PantryUsageResult {
  const PantryUsageResult({
    required this.usedItems,
    required this.totalSavings,
    required this.remainingPantry,
  });

  /// Map of ingredient ID to quantity used
  final Map<String, double> usedItems;
  
  /// Total cost savings from using pantry items
  final int totalSavings;
  
  /// Remaining pantry items after usage
  final List<PantryItem> remainingPantry;

  /// Get formatted savings string
  String get savingsString {
    if (totalSavings <= 0) return 'No savings';
    final dollars = totalSavings / 100;
    return 'Save \$${dollars.toStringAsFixed(2)}';
  }

  /// Get count of different items used
  int get itemsUsedCount => usedItems.length;
}

/// Configuration for pantry-first planning
class PantryFirstConfig {
  const PantryFirstConfig({
    this.prioritizePantryUsage = true,
    this.allowPartialPantryUse = true,
    this.pantryUsageWeight = 2.0,
    this.expirationPriorityDays = 3,
    this.minPantryValueThreshold = 50, // cents
  });

  /// Whether to prioritize using pantry items over other optimizations
  final bool prioritizePantryUsage;
  
  /// Whether to allow using partial quantities from pantry
  final bool allowPartialPantryUse;
  
  /// Weight multiplier for pantry usage in optimization
  final double pantryUsageWeight;
  
  /// Prioritize items expiring within this many days
  final int expirationPriorityDays;
  
  /// Minimum value threshold to consider pantry usage worthwhile
  final int minPantryValueThreshold;
}

/// Enhanced plan generator that prioritizes pantry item usage
class PantryFirstPlanner extends PlanGenerator {
  PantryFirstPlanner({
    required super.macroCalculator,
    super.config = const PlanGenerationConfig(),
    this.pantryConfig = const PantryFirstConfig(),
  });

  final PantryFirstConfig pantryConfig;

  /// Generate a plan that prioritizes using pantry items first
  Future<PlanGenerationResult> generatePantryFirstPlan({
    required UserTargets targets,
    required List<Recipe> availableRecipes,
    required List<Ingredient> ingredients,
    required List<PantryItem> pantryItems,
    String? planName,
  }) async {
    if (pantryItems.isEmpty) {
      // No pantry items, use regular planning
      return generatePlan(
        targets: targets,
        availableRecipes: availableRecipes,
        ingredients: ingredients,
        pantryItems: pantryItems,
        planName: planName,
      );
    }

    // Analyze pantry to identify high-priority items
    _analyzePantry(pantryItems, ingredients);
    
    // Filter recipes that can use pantry items
    final pantryFriendlyRecipes = _findPantryFriendlyRecipes(
      recipes: availableRecipes,
      pantryItems: pantryItems,
      targets: targets,
    );

    // Generate initial plan with pantry priority
    final initialPlan = await _generatePantryOptimizedPlan(
      targets: targets,
      recipes: pantryFriendlyRecipes,
      ingredients: ingredients,
      pantryItems: pantryItems,
      planName: planName ?? 'Pantry-First Plan',
    );

    return initialPlan;
  }

  /// Calculate pantry usage for a given plan
  PantryUsageResult calculatePantryUsage({
    required Plan plan,
    required List<Recipe> recipes,
    required List<Ingredient> ingredients,
    required List<PantryItem> pantryItems,
  }  ) {
    final usedItems = <String, double>{};
    final remainingPantry = <PantryItem>[];
    int totalSavings = 0;

    // Create a copy of pantry items to track usage
    final pantryTracker = {
      for (var item in pantryItems) 
        item.ingredientId: PantryItem(
          id: item.id,
          ingredientId: item.ingredientId,
          qty: item.qty,
          unit: item.unit,
          addedAt: item.addedAt,
        )
    };

    // Calculate total ingredient requirements
    final totalRequirements = _calculateTotalIngredientRequirements(plan, recipes);

    // Process each required ingredient
    for (final entry in totalRequirements.entries) {
      final ingredientId = entry.key;
      final requiredQty = entry.value['qty'] as double;
      final unit = entry.value['unit'] as Unit;

      if (pantryTracker.containsKey(ingredientId)) {
        final pantryItem = pantryTracker[ingredientId]!;
        final ingredient = ingredients.firstWhere((ing) => ing.id == ingredientId);

        // Calculate how much we can use from pantry
        double usableQty = 0;
        if (pantryItem.unit == unit && pantryItem.qty > 0) {
          usableQty = math.min(requiredQty, pantryItem.qty);
          
          // Calculate savings
          final savings = ingredient.calculateCost(usableQty, unit);
          totalSavings += savings;
          
          // Track usage
          usedItems[ingredientId] = usableQty;
          
          // Update pantry tracker
          pantryTracker[ingredientId] = pantryItem.useQuantity(usableQty);
        }
      }
    }

    // Create remaining pantry list
    for (final item in pantryTracker.values) {
      if (!item.isEmpty) {
        remainingPantry.add(item);
      }
    }

    return PantryUsageResult(
      usedItems: usedItems,
      totalSavings: totalSavings,
      remainingPantry: remainingPantry,
    );
  }

  /// Get recipes that can effectively use pantry items
  List<Recipe> getRecipesUsingPantryItem({
    required String ingredientId,
    required List<Recipe> availableRecipes,
    required UserTargets targets,
  }) {
    return availableRecipes
        .where((recipe) => recipe.isCompatibleWithDiet(targets.dietFlags))
        .where((recipe) => recipe.fitsTimeConstraint(targets.timeCapMins))
        .where((recipe) => recipe.items.any((item) => item.ingredientId == ingredientId))
        .toList();
  }

  /// Suggest pantry items that are expiring soon and should be used
  List<PantryItem> getExpiringPantryItems({
    required List<PantryItem> pantryItems,
    int daysThreshold = 3,
  }) {
    // This is a simplified version - in a full implementation,
    // pantry items would have expiration dates
    return pantryItems.where((item) => item.qty > 0).toList();
  }

  /// Analyze pantry to identify high-priority items
  Map<String, dynamic> _analyzePantry(
    List<PantryItem> pantryItems,
    List<Ingredient> ingredients,
  ) {
    final analysis = <String, dynamic>{
      'highValueItems': <String>[],
      'expiringItems': <String>[],
      'abundantItems': <String>[],
      'totalValue': 0,
    };

    int totalValue = 0;
    final highValueItems = <String>[];
    final abundantItems = <String>[];

    for (final pantryItem in pantryItems) {
      final ingredient = ingredients.firstWhere(
        (ing) => ing.id == pantryItem.ingredientId,
        orElse: () => throw ArgumentError('Ingredient ${pantryItem.ingredientId} not found'),
      );

      final itemValue = ingredient.calculateCost(pantryItem.qty, pantryItem.unit);
      totalValue += itemValue;

      // High-value items (worth more than threshold)
      if (itemValue >= pantryConfig.minPantryValueThreshold) {
        highValueItems.add(pantryItem.ingredientId);
      }

      // Abundant items (more than typical serving sizes)
      if (pantryItem.qty > 200) { // Simplified threshold
        abundantItems.add(pantryItem.ingredientId);
      }
    }

    analysis['totalValue'] = totalValue;
    analysis['highValueItems'] = highValueItems;
    analysis['abundantItems'] = abundantItems;

    return analysis;
  }

  /// Find recipes that can effectively use pantry items
  List<Recipe> _findPantryFriendlyRecipes({
    required List<Recipe> recipes,
    required List<PantryItem> pantryItems,
    required UserTargets targets,
  }) {
    final pantryIngredientIds = pantryItems.map((item) => item.ingredientId).toSet();
    
    final pantryFriendlyRecipes = recipes
        .where((recipe) => recipe.isCompatibleWithDiet(targets.dietFlags))
        .where((recipe) => recipe.fitsTimeConstraint(targets.timeCapMins))
        .where((recipe) {
          // Recipe must use at least one pantry item
          return recipe.items.any((item) => pantryIngredientIds.contains(item.ingredientId));
        })
        .toList();

    // Sort by pantry usage potential
    pantryFriendlyRecipes.sort((a, b) {
      final aPantryItems = a.items.where((item) => pantryIngredientIds.contains(item.ingredientId)).length;
      final bPantryItems = b.items.where((item) => pantryIngredientIds.contains(item.ingredientId)).length;
      return bPantryItems.compareTo(aPantryItems); // More pantry items first
    });

    return pantryFriendlyRecipes;
  }

  /// Generate plan optimized for pantry usage
  Future<PlanGenerationResult> _generatePantryOptimizedPlan({
    required UserTargets targets,
    required List<Recipe> recipes,
    required List<Ingredient> ingredients,
    required List<PantryItem> pantryItems,
    required String planName,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    if (recipes.isEmpty) {
      throw ArgumentError('No pantry-friendly recipes available');
    }

    // Generate initial plan with pantry bias
    Plan currentPlan = _generatePantryBiasedInitialPlan(
      targets: targets,
      recipes: recipes,
      pantryItems: pantryItems,
      planName: planName,
    );

    // Calculate initial score with pantry bonus
    double currentScore = _calculatePantryOptimizedScore(
      plan: currentPlan,
      targets: targets,
      recipes: recipes,
      ingredients: ingredients,
      pantryItems: pantryItems,
    );

    int iterations = 0;

    // Local search optimization with pantry priority
    while (iterations < config.maxIterations && 
           stopwatch.elapsedMilliseconds < config.maxGenerationTimeMs) {
      
      // Try pantry-optimized improvement
      final improvedPlan = _tryPantryOptimizedImprovement(
        currentPlan: currentPlan,
        targets: targets,
        recipes: recipes,
        ingredients: ingredients,
        pantryItems: pantryItems,
      );

      final improvedScore = _calculatePantryOptimizedScore(
        plan: improvedPlan,
        targets: targets,
        recipes: recipes,
        ingredients: ingredients,
        pantryItems: pantryItems,
      );

      // Accept improvement
      if (improvedScore < currentScore - config.improvementThreshold) {
        currentPlan = improvedPlan;
        currentScore = improvedScore;
      }

      iterations++;
    }

    // Calculate final totals
    final totals = macroCalculator.calculatePlanTotals(
      plan: currentPlan,
      recipes: recipes,
    );

    final finalPlan = Plan(
      id: currentPlan.id,
      name: currentPlan.name,
      userTargetsId: currentPlan.userTargetsId,
      days: currentPlan.days,
      totals: totals,
      createdAt: currentPlan.createdAt,
    );
    
    final dailyAvg = macroCalculator.calculateDailyAverageMacros(
      plan: finalPlan,
      recipes: recipes,
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

  /// Generate initial plan with pantry bias
  Plan _generatePantryBiasedInitialPlan({
    required UserTargets targets,
    required List<Recipe> recipes,
    required List<PantryItem> pantryItems,
    required String planName,
  }) {
    final pantryIngredientIds = pantryItems.map((item) => item.ingredientId).toSet();
    final days = <PlanDay>[];
    final startDate = DateTime.now();

    for (int dayIndex = 0; dayIndex < 7; dayIndex++) {
      final date = startDate.add(Duration(days: dayIndex));
      final meals = <PlanMeal>[];

      for (int mealIndex = 0; mealIndex < targets.mealsPerDay; mealIndex++) {
        // Prefer recipes that use more pantry items
        final recipe = _selectPantryFriendlyRecipe(
          recipes: recipes,
          pantryIngredientIds: pantryIngredientIds,
          targets: targets,
          mealIndex: mealIndex,
        );

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
      totals: PlanTotals.empty(),
      createdAt: DateTime.now(),
    );
  }

  /// Select recipe that best utilizes pantry items
  Recipe _selectPantryFriendlyRecipe({
    required List<Recipe> recipes,
    required Set<String> pantryIngredientIds,
    required UserTargets targets,
    required int mealIndex,
  }) {
    // Score recipes by pantry usage
    final scoredRecipes = recipes.map((recipe) {
      int pantryItemsUsed = recipe.items
          .where((item) => pantryIngredientIds.contains(item.ingredientId))
          .length;
      
      // Bonus for mode-specific preferences
      double modeBonus = 0;
      switch (targets.planningMode) {
        case PlanningMode.cutting:
          if (recipe.isHighVolume()) modeBonus += 1;
          break;
        case PlanningMode.bulkingBudget:
          if (recipe.getCostEfficiency() < 500) modeBonus += 1;
          break;
        case PlanningMode.bulkingNoBudget:
          if (recipe.isQuick()) modeBonus += 1;
          break;
        case PlanningMode.maintenance:
          modeBonus += 0.5;
          break;
      }

      final score = pantryItemsUsed * 2 + modeBonus;
      return {'recipe': recipe, 'score': score};
    }).toList();

    // Sort by score (higher is better)
    scoredRecipes.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

    // Select from top candidates with some randomness
    final topCount = math.min(3, scoredRecipes.length);
    final selectedIndex = math.Random().nextInt(topCount);
    return scoredRecipes[selectedIndex]['recipe'] as Recipe;
  }

  /// Calculate optimization score with pantry bonus
  double _calculatePantryOptimizedScore({
    required Plan plan,
    required UserTargets targets,
    required List<Recipe> recipes,
    required List<Ingredient> ingredients,
    required List<PantryItem> pantryItems,
  }) {
    // Get base score using parent class method
    final baseScore = calculatePlanScore(
      plan: plan,
      targets: targets,
      recipes: recipes,
      ingredients: ingredients,
      pantryItems: pantryItems,
    );

    // Calculate additional pantry bonus
    final pantryUsage = calculatePantryUsage(
      plan: plan,
      recipes: recipes,
      ingredients: ingredients,
      pantryItems: pantryItems,
    );

    // Enhanced pantry bonus for pantry-first planning
    final pantryBonus = pantryUsage.totalSavings * pantryConfig.pantryUsageWeight;

    return baseScore - pantryBonus;
  }

  /// Try improvement with pantry optimization
  Plan _tryPantryOptimizedImprovement({
    required Plan currentPlan,
    required UserTargets targets,
    required List<Recipe> recipes,
    required List<Ingredient> ingredients,
    required List<PantryItem> pantryItems,
  }) {
    // Try regular improvement first using parent class method
    final regularImprovement = tryImprovement(
      currentPlan: currentPlan,
      targets: targets,
      recipes: recipes,
      ingredients: ingredients,
      pantryItems: pantryItems,
    );

    // Also try pantry-specific improvements
    final pantryImprovement = _tryPantrySpecificImprovement(
      currentPlan: currentPlan,
      targets: targets,
      recipes: recipes,
      ingredients: ingredients,
      pantryItems: pantryItems,
    );

    // Return the better improvement
    final regularScore = _calculatePantryOptimizedScore(
      plan: regularImprovement,
      targets: targets,
      recipes: recipes,
      ingredients: ingredients,
      pantryItems: pantryItems,
    );

    final pantryScore = _calculatePantryOptimizedScore(
      plan: pantryImprovement,
      targets: targets,
      recipes: recipes,
      ingredients: ingredients,
      pantryItems: pantryItems,
    );

    return pantryScore < regularScore ? pantryImprovement : regularImprovement;
  }

  /// Try improvement specifically focused on pantry usage
  Plan _tryPantrySpecificImprovement({
    required Plan currentPlan,
    required UserTargets targets,
    required List<Recipe> recipes,
    required List<Ingredient> ingredients,
    required List<PantryItem> pantryItems,
  }) {
    final pantryIngredientIds = pantryItems.map((item) => item.ingredientId).toSet();
    
    // Find meals that don't use pantry items and try to replace them
    for (int dayIndex = 0; dayIndex < currentPlan.days.length; dayIndex++) {
      final day = currentPlan.days[dayIndex];
      
      for (int mealIndex = 0; mealIndex < day.meals.length; mealIndex++) {
        final meal = day.meals[mealIndex];
        final recipe = recipes.firstWhere((r) => r.id == meal.recipeId);
        
        // Check if this recipe uses pantry items
        final usesPantry = recipe.items.any((item) => pantryIngredientIds.contains(item.ingredientId));
        
        if (!usesPantry) {
          // Try to find a pantry-friendly alternative
          final alternatives = recipes
              .where((r) => r.id != recipe.id)
              .where((r) => r.isCompatibleWithDiet(targets.dietFlags))
              .where((r) => r.fitsTimeConstraint(targets.timeCapMins))
              .where((r) => r.items.any((item) => pantryIngredientIds.contains(item.ingredientId)))
              .toList();

          if (alternatives.isNotEmpty) {
            final bestAlternative = alternatives.first;
            final newServings = _calculateOptimalServings(
              recipe: bestAlternative,
              targets: targets,
              mealIndex: mealIndex,
            );

            // Create improved plan
            final newMeal = PlanMeal(
              recipeId: bestAlternative.id,
              servings: newServings,
              notes: meal.notes,
            );

            final newMeals = List<PlanMeal>.from(day.meals);
            newMeals[mealIndex] = newMeal;
            final newDay = PlanDay(date: day.date, meals: newMeals);

            final newDays = List<PlanDay>.from(currentPlan.days);
            newDays[dayIndex] = newDay;

            return Plan(
              id: currentPlan.id,
              name: currentPlan.name,
              userTargetsId: currentPlan.userTargetsId,
              days: newDays,
              totals: currentPlan.totals,
              createdAt: currentPlan.createdAt,
            );
          }
        }
      }
    }

    return currentPlan; // No improvement found
  }

  /// Calculate total ingredient requirements for a plan
  Map<String, Map<String, dynamic>> _calculateTotalIngredientRequirements(
    Plan plan,
    List<Recipe> recipes,
  ) {
    final requirements = <String, Map<String, dynamic>>{};

    for (final day in plan.days) {
      for (final meal in day.meals) {
        final recipe = recipes.firstWhere((r) => r.id == meal.recipeId);
        
        for (final item in recipe.items) {
          final totalQty = item.qty * meal.servings;
          
          if (requirements.containsKey(item.ingredientId)) {
            final existing = requirements[item.ingredientId]!;
            if (existing['unit'] == item.unit) {
              existing['qty'] = existing['qty'] + totalQty;
            }
          } else {
            requirements[item.ingredientId] = {
              'qty': totalQty,
              'unit': item.unit,
            };
          }
        }
      }
    }

    return requirements;
  }

  /// Calculate optimal servings (override from base class for pantry context)
  double _calculateOptimalServings({
    required Recipe recipe,
    required UserTargets targets,
    required int mealIndex,
  }) {
    // Base serving size on daily calorie distribution
    final targetCaloriesPerMeal = targets.kcal / targets.mealsPerDay;
    
    // Adjust for meal type
    double mealMultiplier = 1.0;
    if (targets.mealsPerDay >= 3) {
      switch (mealIndex) {
        case 0: mealMultiplier = 0.8; break;
        case 1: mealMultiplier = 1.0; break;
        case 2: mealMultiplier = 1.2; break;
        default: mealMultiplier = 0.6; break;
      }
    }

    final targetMealCalories = targetCaloriesPerMeal * mealMultiplier;
    final servings = targetMealCalories / recipe.macrosPerServ.kcal;
    
    return (servings * 2).round() / 2.0;
  }
}
