import '../entities/recipe.dart';
import '../entities/plan.dart';
import '../entities/user_targets.dart';
import '../entities/ingredient.dart';
import '../entities/pantry_item.dart';
import 'macro_calculator.dart';

/// Reason for suggesting a recipe swap
enum SwapReason {
  costSavings,
  proteinIncrease,
  calorieAdjustment,
  pantryUse,
  timeReduction,
  varietyImprovement,
  macroBalance,
}

/// Impact of a recipe swap on plan metrics
class SwapImpact {
  const SwapImpact({
    required this.costDeltaCents,
    required this.kcalDelta,
    required this.proteinDelta,
    required this.carbsDelta,
    required this.fatDelta,
    required this.timeDelta,
    required this.pantryItemsUsed,
  });

  /// Cost change in cents (negative = savings)
  final int costDeltaCents;
  
  /// Calorie change
  final double kcalDelta;
  
  /// Protein change in grams
  final double proteinDelta;
  
  /// Carbs change in grams
  final double carbsDelta;
  
  /// Fat change in grams
  final double fatDelta;
  
  /// Time change in minutes
  final int timeDelta;
  
  /// List of pantry items that would be used
  final List<String> pantryItemsUsed;

  /// Get formatted cost impact string
  String get costImpactString {
    if (costDeltaCents == 0) return "No cost change";
    final dollars = (costDeltaCents.abs() / 100).toStringAsFixed(2);
    return costDeltaCents < 0 ? "-\$${dollars}/week" : "+\$${dollars}/week";
  }

  /// Get formatted protein impact string
  String get proteinImpactString {
    if (proteinDelta == 0) return "No protein change";
    final sign = proteinDelta > 0 ? "+" : "";
    return "${sign}${proteinDelta.toStringAsFixed(1)}g protein/day";
  }

  /// Get formatted calorie impact string
  String get calorieImpactString {
    if (kcalDelta == 0) return "No calorie change";
    final sign = kcalDelta > 0 ? "+" : "";
    return "${sign}${kcalDelta.toStringAsFixed(0)} kcal/day";
  }

  /// Get formatted time impact string
  String get timeImpactString {
    if (timeDelta == 0) return "No time change";
    final sign = timeDelta > 0 ? "+" : "";
    return "${sign}${timeDelta} min prep";
  }

  /// Get pantry usage string
  String get pantryUsageString {
    if (pantryItemsUsed.isEmpty) return "";
    if (pantryItemsUsed.length == 1) {
      return "Uses pantry ${pantryItemsUsed.first}";
    }
    return "Uses ${pantryItemsUsed.length} pantry items";
  }
}

/// A suggested recipe swap with reasoning and impact
class SwapSuggestion {
  const SwapSuggestion({
    required this.alternativeRecipe,
    required this.suggestedServings,
    required this.reasons,
    required this.impact,
    required this.score,
  });

  /// The alternative recipe to swap to
  final Recipe alternativeRecipe;
  
  /// Suggested serving size for the alternative
  final double suggestedServings;
  
  /// List of reasons for this swap
  final List<SwapReason> reasons;
  
  /// Impact metrics of making this swap
  final SwapImpact impact;
  
  /// Overall score for this swap (lower is better)
  final double score;

  /// Get primary reason badge text
  String get primaryReasonBadge {
    if (reasons.isEmpty) return "Alternative";
    
    switch (reasons.first) {
      case SwapReason.costSavings:
        return impact.costImpactString;
      case SwapReason.proteinIncrease:
        return impact.proteinImpactString;
      case SwapReason.calorieAdjustment:
        return impact.calorieImpactString;
      case SwapReason.pantryUse:
        return impact.pantryUsageString;
      case SwapReason.timeReduction:
        return impact.timeImpactString;
      case SwapReason.varietyImprovement:
        return "More variety";
      case SwapReason.macroBalance:
        return "Better macros";
    }
  }

  /// Get all reason badges
  List<String> get reasonBadges {
    final badges = <String>[];
    
    if (impact.costDeltaCents < 0) badges.add(impact.costImpactString);
    if (impact.proteinDelta > 0) badges.add(impact.proteinImpactString);
    if (impact.kcalDelta.abs() > 10) badges.add(impact.calorieImpactString);
    if (impact.timeDelta < 0) badges.add(impact.timeImpactString);
    if (impact.pantryItemsUsed.isNotEmpty) badges.add(impact.pantryUsageString);
    
    return badges;
  }
}

/// Service for generating recipe swap suggestions
class SwapEngine {
  SwapEngine({
    required this.macroCalculator,
  });

  final MacroCalculator macroCalculator;

  /// Generate swap suggestions for a specific meal in a plan
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
    final day = plan.days[dayIndex];
    final currentMeal = day.meals[mealIndex];
    final currentRecipe = availableRecipes.firstWhere(
      (r) => r.id == currentMeal.recipeId,
    );

    // Find alternative recipes
    final alternatives = _findAlternativeRecipes(
      currentRecipe: currentRecipe,
      availableRecipes: availableRecipes,
      targets: targets,
    );

    // Generate suggestions for each alternative
    final suggestions = <SwapSuggestion>[];
    
    for (final alternative in alternatives) {
      final suggestion = _createSwapSuggestion(
        currentRecipe: currentRecipe,
        currentServings: currentMeal.servings,
        alternativeRecipe: alternative,
        targets: targets,
        ingredients: ingredients,
        pantryItems: pantryItems,
        plan: plan,
        dayIndex: dayIndex,
        mealIndex: mealIndex,
      );
      
      if (suggestion != null) {
        suggestions.add(suggestion);
      }
    }

    // Sort by score (lower is better) and return top suggestions
    suggestions.sort((a, b) => a.score.compareTo(b.score));
    return suggestions.take(maxSuggestions).toList();
  }

  /// Apply a swap to a plan and return the updated plan
  Plan applySwap({
    required Plan plan,
    required int dayIndex,
    required int mealIndex,
    required SwapSuggestion suggestion,
    required List<Recipe> recipes,
  }) {
    final day = plan.days[dayIndex];
    final currentMeal = day.meals[mealIndex];
    
    // Create new meal with swapped recipe
    final newMeal = PlanMeal(
      recipeId: suggestion.alternativeRecipe.id,
      servings: suggestion.suggestedServings,
      notes: currentMeal.notes,
    );

    // Create new day with swapped meal
    final newMeals = List<PlanMeal>.from(day.meals);
    newMeals[mealIndex] = newMeal;
    final newDay = PlanDay(date: day.date, meals: newMeals);

    // Create new plan with swapped day
    final newDays = List<PlanDay>.from(plan.days);
    newDays[dayIndex] = newDay;

    // Recalculate totals
    final updatedPlan = Plan(
      id: plan.id,
      name: plan.name,
      userTargetsId: plan.userTargetsId,
      days: newDays,
      totals: plan.totals, // Will be recalculated
      createdAt: plan.createdAt,
    );

    final newTotals = macroCalculator.calculatePlanTotals(
      plan: updatedPlan,
      recipes: recipes,
    );

    return Plan(
      id: updatedPlan.id,
      name: updatedPlan.name,
      userTargetsId: updatedPlan.userTargetsId,
      days: updatedPlan.days,
      totals: newTotals,
      createdAt: updatedPlan.createdAt,
    );
  }

  /// Find suitable alternative recipes
  List<Recipe> _findAlternativeRecipes({
    required Recipe currentRecipe,
    required List<Recipe> availableRecipes,
    required UserTargets targets,
  }) {
    return availableRecipes
        .where((recipe) => recipe.id != currentRecipe.id)
        .where((recipe) => recipe.isCompatibleWithDiet(targets.dietFlags))
        .where((recipe) => recipe.fitsTimeConstraint(targets.timeCapMins))
        .toList();
  }

  /// Create a swap suggestion for an alternative recipe
  SwapSuggestion? _createSwapSuggestion({
    required Recipe currentRecipe,
    required double currentServings,
    required Recipe alternativeRecipe,
    required UserTargets targets,
    required List<Ingredient> ingredients,
    required List<PantryItem> pantryItems,
    required Plan plan,
    required int dayIndex,
    required int mealIndex,
  }) {
    // Calculate optimal serving size for alternative
    final suggestedServings = _calculateOptimalServings(
      alternativeRecipe: alternativeRecipe,
      currentRecipe: currentRecipe,
      currentServings: currentServings,
      targets: targets,
    );

    // Calculate impact
    final impact = _calculateSwapImpact(
      currentRecipe: currentRecipe,
      currentServings: currentServings,
      alternativeRecipe: alternativeRecipe,
      alternativeServings: suggestedServings,
      ingredients: ingredients,
      pantryItems: pantryItems,
    );

    // Determine reasons for this swap
    final reasons = _determineSwapReasons(
      currentRecipe: currentRecipe,
      alternativeRecipe: alternativeRecipe,
      impact: impact,
      targets: targets,
      plan: plan,
    );

    // Calculate score (lower is better)
    final score = _calculateSwapScore(
      impact: impact,
      reasons: reasons,
      targets: targets,
    );

    return SwapSuggestion(
      alternativeRecipe: alternativeRecipe,
      suggestedServings: suggestedServings,
      reasons: reasons,
      impact: impact,
      score: score,
    );
  }

  /// Calculate optimal serving size for alternative recipe
  double _calculateOptimalServings({
    required Recipe alternativeRecipe,
    required Recipe currentRecipe,
    required double currentServings,
    required UserTargets targets,
  }) {
    // Try to match current calorie contribution
    final currentCalories = currentRecipe.macrosPerServ.kcal * currentServings;
    final alternativeServings = currentCalories / alternativeRecipe.macrosPerServ.kcal;
    
    // Round to reasonable serving sizes
    return (alternativeServings * 2).round() / 2.0;
  }

  /// Calculate the impact of swapping recipes
  SwapImpact _calculateSwapImpact({
    required Recipe currentRecipe,
    required double currentServings,
    required Recipe alternativeRecipe,
    required double alternativeServings,
    required List<Ingredient> ingredients,
    required List<PantryItem> pantryItems,
  }) {
    // Calculate macro deltas
    final currentMacros = currentRecipe.calculateTotalMacros(currentServings);
    final alternativeMacros = alternativeRecipe.calculateTotalMacros(alternativeServings);
    
    final kcalDelta = alternativeMacros.kcal - currentMacros.kcal;
    final proteinDelta = alternativeMacros.proteinG - currentMacros.proteinG;
    final carbsDelta = alternativeMacros.carbsG - currentMacros.carbsG;
    final fatDelta = alternativeMacros.fatG - currentMacros.fatG;

    // Calculate cost delta
    final currentCost = currentRecipe.calculateTotalCost(currentServings);
    final alternativeCost = alternativeRecipe.calculateTotalCost(alternativeServings);
    final costDeltaCents = alternativeCost - currentCost;

    // Calculate time delta
    final timeDelta = alternativeRecipe.timeMins - currentRecipe.timeMins;

    // Check pantry usage
    final pantryItemsUsed = _getPantryItemsUsed(
      recipe: alternativeRecipe,
      servings: alternativeServings,
      pantryItems: pantryItems,
    );

    return SwapImpact(
      costDeltaCents: costDeltaCents,
      kcalDelta: kcalDelta,
      proteinDelta: proteinDelta,
      carbsDelta: carbsDelta,
      fatDelta: fatDelta,
      timeDelta: timeDelta,
      pantryItemsUsed: pantryItemsUsed,
    );
  }

  /// Determine reasons for suggesting this swap
  List<SwapReason> _determineSwapReasons({
    required Recipe currentRecipe,
    required Recipe alternativeRecipe,
    required SwapImpact impact,
    required UserTargets targets,
    required Plan plan,
  }) {
    final reasons = <SwapReason>[];

    // Cost savings
    if (impact.costDeltaCents < -50) { // Significant savings
      reasons.add(SwapReason.costSavings);
    }

    // Protein increase
    if (impact.proteinDelta > 5) {
      reasons.add(SwapReason.proteinIncrease);
    }

    // Calorie adjustment
    if (impact.kcalDelta.abs() > 50) {
      reasons.add(SwapReason.calorieAdjustment);
    }

    // Pantry usage
    if (impact.pantryItemsUsed.isNotEmpty) {
      reasons.add(SwapReason.pantryUse);
    }

    // Time reduction
    if (impact.timeDelta < -10) {
      reasons.add(SwapReason.timeReduction);
    }

    // Variety improvement
    final currentRecipeCount = _countRecipeUsage(plan, currentRecipe.id);
    if (currentRecipeCount > 2) {
      reasons.add(SwapReason.varietyImprovement);
    }

    // Macro balance (mode-specific)
    if (_improvesMacroBalance(currentRecipe, alternativeRecipe, targets)) {
      reasons.add(SwapReason.macroBalance);
    }

    return reasons;
  }

  /// Calculate score for a swap suggestion (lower is better)
  double _calculateSwapScore({
    required SwapImpact impact,
    required List<SwapReason> reasons,
    required UserTargets targets,
  }) {
    double score = 0;

    // Base score starts neutral
    score += 100;

    // Cost savings are good (reduce score)
    if (impact.costDeltaCents < 0) {
      score -= impact.costDeltaCents.abs() / 10;
    } else {
      score += impact.costDeltaCents / 10;
    }

    // Protein improvements are good for most modes
    if (impact.proteinDelta > 0) {
      score -= impact.proteinDelta * 2;
    }

    // Time savings are good for no-budget mode
    if (targets.planningMode == PlanningMode.bulkingNoBudget && impact.timeDelta < 0) {
      score -= impact.timeDelta.abs() * 2;
    }

    // Pantry usage is always good
    score -= impact.pantryItemsUsed.length * 10;

    // Variety improvements are good
    if (reasons.contains(SwapReason.varietyImprovement)) {
      score -= 20;
    }

    // Mode-specific scoring
    switch (targets.planningMode) {
      case PlanningMode.cutting:
        // Prefer high-protein, low-calorie swaps
        if (impact.proteinDelta > 0 && impact.kcalDelta <= 0) {
          score -= 30;
        }
        break;
      case PlanningMode.bulkingBudget:
        // Prefer cost-effective swaps
        if (impact.costDeltaCents < 0) {
          score -= 40;
        }
        break;
      case PlanningMode.bulkingNoBudget:
        // Prefer time-saving swaps
        if (impact.timeDelta < 0) {
          score -= 30;
        }
        break;
      case PlanningMode.maintenance:
        // Balanced scoring
        break;
    }

    return score;
  }

  /// Get pantry items that would be used by a recipe
  List<String> _getPantryItemsUsed({
    required Recipe recipe,
    required double servings,
    required List<PantryItem> pantryItems,
  }) {
    final pantryMap = {for (var item in pantryItems) item.ingredientId: item};
    final usedItems = <String>[];

    for (final item in recipe.items) {
      if (pantryMap.containsKey(item.ingredientId)) {
        final pantryItem = pantryMap[item.ingredientId]!;
        final requiredQty = item.qty * servings;
        
        if (pantryItem.hasEnoughFor(requiredQty, item.unit)) {
          usedItems.add(item.ingredientId);
        }
      }
    }

    return usedItems;
  }

  /// Count how many times a recipe is used in a plan
  int _countRecipeUsage(Plan plan, String recipeId) {
    int count = 0;
    for (final day in plan.days) {
      for (final meal in day.meals) {
        if (meal.recipeId == recipeId) {
          count++;
        }
      }
    }
    return count;
  }

  /// Check if alternative recipe improves macro balance for the target mode
  bool _improvesMacroBalance(
    Recipe currentRecipe,
    Recipe alternativeRecipe,
    UserTargets targets,
  ) {
    switch (targets.planningMode) {
      case PlanningMode.cutting:
        // Better if higher protein density
        return alternativeRecipe.getProteinDensity() > currentRecipe.getProteinDensity();
      case PlanningMode.bulkingBudget:
        // Better if more cost-efficient
        return alternativeRecipe.getCostEfficiency() < currentRecipe.getCostEfficiency();
      case PlanningMode.bulkingNoBudget:
        // Better if higher calorie density
        return alternativeRecipe.macrosPerServ.kcal > currentRecipe.macrosPerServ.kcal;
      case PlanningMode.maintenance:
        // Balanced - no specific preference
        return false;
    }
  }
}
