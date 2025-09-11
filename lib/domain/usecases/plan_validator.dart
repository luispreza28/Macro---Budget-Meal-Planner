import '../entities/recipe.dart';
import '../entities/plan.dart';
import '../entities/user_targets.dart';
import '../entities/ingredient.dart';
import 'macro_calculator.dart';

/// Types of plan validation issues
enum ValidationIssueType {
  missingRecipe,
  incompatibleDiet,
  timeConstraintViolation,
  macroDeficiency,
  budgetOverrun,
  missingIngredient,
  invalidServings,
  emptyPlan,
  duplicateDay,
}

/// Severity levels for validation issues
enum ValidationSeverity {
  error,    // Plan cannot be executed
  warning,  // Plan has issues but can be executed
  info,     // Informational notes about the plan
}

/// A validation issue found in a plan
class ValidationIssue {
  const ValidationIssue({
    required this.type,
    required this.severity,
    required this.message,
    required this.description,
    this.dayIndex,
    this.mealIndex,
    this.recipeId,
    this.ingredientId,
    this.suggestedFix,
  });

  /// Type of the validation issue
  final ValidationIssueType type;
  
  /// Severity of the issue
  final ValidationSeverity severity;
  
  /// Short message describing the issue
  final String message;
  
  /// Detailed description of the issue
  final String description;
  
  /// Day index if issue is specific to a day
  final int? dayIndex;
  
  /// Meal index if issue is specific to a meal
  final int? mealIndex;
  
  /// Recipe ID if issue is specific to a recipe
  final String? recipeId;
  
  /// Ingredient ID if issue is specific to an ingredient
  final String? ingredientId;
  
  /// Suggested fix for the issue
  final String? suggestedFix;

  /// Get location string for the issue
  String get locationString {
    if (dayIndex != null && mealIndex != null) {
      return 'Day ${dayIndex! + 1}, Meal ${mealIndex! + 1}';
    } else if (dayIndex != null) {
      return 'Day ${dayIndex! + 1}';
    }
    return 'Plan';
  }

  /// Check if this is a blocking error
  bool get isError => severity == ValidationSeverity.error;
  
  /// Check if this is a warning
  bool get isWarning => severity == ValidationSeverity.warning;
  
  /// Check if this is informational
  bool get isInfo => severity == ValidationSeverity.info;
}

/// Result of plan validation
class ValidationResult {
  const ValidationResult({
    required this.isValid,
    required this.issues,
    required this.summary,
  });

  /// Whether the plan is valid (no errors)
  final bool isValid;
  
  /// List of all validation issues found
  final List<ValidationIssue> issues;
  
  /// Summary of validation results
  final ValidationSummary summary;

  /// Get only error issues
  List<ValidationIssue> get errors => 
      issues.where((issue) => issue.severity == ValidationSeverity.error).toList();

  /// Get only warning issues
  List<ValidationIssue> get warnings => 
      issues.where((issue) => issue.severity == ValidationSeverity.warning).toList();

  /// Get only info issues
  List<ValidationIssue> get infos => 
      issues.where((issue) => issue.severity == ValidationSeverity.info).toList();

  /// Check if plan has any issues
  bool get hasIssues => issues.isNotEmpty;
  
  /// Check if plan has errors
  bool get hasErrors => errors.isNotEmpty;
  
  /// Check if plan has warnings
  bool get hasWarnings => warnings.isNotEmpty;
}

/// Summary of validation results
class ValidationSummary {
  const ValidationSummary({
    required this.totalIssues,
    required this.errorCount,
    required this.warningCount,
    required this.infoCount,
    required this.planQualityScore,
    required this.recommendations,
  });

  /// Total number of issues found
  final int totalIssues;
  
  /// Number of errors
  final int errorCount;
  
  /// Number of warnings
  final int warningCount;
  
  /// Number of info items
  final int infoCount;
  
  /// Overall plan quality score (0-100)
  final double planQualityScore;
  
  /// List of recommendations for improvement
  final List<String> recommendations;

  /// Get formatted summary string
  String get summaryString {
    if (totalIssues == 0) {
      return 'Plan is valid with no issues';
    }
    
    final parts = <String>[];
    if (errorCount > 0) parts.add('$errorCount error${errorCount > 1 ? 's' : ''}');
    if (warningCount > 0) parts.add('$warningCount warning${warningCount > 1 ? 's' : ''}');
    if (infoCount > 0) parts.add('$infoCount info');
    
    return parts.join(', ');
  }
}

/// Configuration for plan validation
class ValidationConfig {
  const ValidationConfig({
    this.strictMacroTolerance = false,
    this.macroTolerancePercent = 10.0,
    this.budgetTolerancePercent = 5.0,
    this.checkIngredientAvailability = true,
    this.validateDietCompatibility = true,
    this.validateTimeConstraints = true,
  });

  /// Whether to use strict macro tolerance
  final bool strictMacroTolerance;
  
  /// Tolerance percentage for macro targets
  final double macroTolerancePercent;
  
  /// Tolerance percentage for budget overruns
  final double budgetTolerancePercent;
  
  /// Whether to check ingredient availability
  final bool checkIngredientAvailability;
  
  /// Whether to validate diet compatibility
  final bool validateDietCompatibility;
  
  /// Whether to validate time constraints
  final bool validateTimeConstraints;
}

/// Service for validating meal plans
class PlanValidator {
  PlanValidator({
    required this.macroCalculator,
    this.config = const ValidationConfig(),
  });

  final MacroCalculator macroCalculator;
  final ValidationConfig config;

  /// Validate a complete meal plan
  ValidationResult validatePlan({
    required Plan plan,
    required UserTargets targets,
    required List<Recipe> availableRecipes,
    required List<Ingredient> availableIngredients,
  }) {
    final issues = <ValidationIssue>[];
    
    // Basic plan structure validation
    issues.addAll(_validatePlanStructure(plan));
    
    // Recipe availability validation
    issues.addAll(_validateRecipeAvailability(plan, availableRecipes));
    
    // Ingredient availability validation
    if (config.checkIngredientAvailability) {
      issues.addAll(_validateIngredientAvailability(
        plan,
        availableRecipes,
        availableIngredients,
      ));
    }
    
    // Diet compatibility validation
    if (config.validateDietCompatibility) {
      issues.addAll(_validateDietCompatibility(plan, targets, availableRecipes));
    }
    
    // Time constraints validation
    if (config.validateTimeConstraints) {
      issues.addAll(_validateTimeConstraints(plan, targets, availableRecipes));
    }
    
    // Macro targets validation
    issues.addAll(_validateMacroTargets(plan, targets, availableRecipes));
    
    // Budget validation
    if (targets.budgetCents != null) {
      issues.addAll(_validateBudget(plan, targets, availableRecipes));
    }
    
    // Plan quality assessment
    issues.addAll(_assessPlanQuality(plan, targets, availableRecipes));

    final summary = _createValidationSummary(issues);
    final isValid = issues.where((i) => i.severity == ValidationSeverity.error).isEmpty;

    return ValidationResult(
      isValid: isValid,
      issues: issues,
      summary: summary,
    );
  }

  /// Validate a single day of a plan
  ValidationResult validateDay({
    required PlanDay day,
    required UserTargets targets,
    required List<Recipe> availableRecipes,
    required List<Ingredient> availableIngredients,
    int? dayIndex,
  }) {
    final issues = <ValidationIssue>[];
    
    // Day structure validation
    if (day.meals.isEmpty) {
      issues.add(ValidationIssue(
        type: ValidationIssueType.emptyPlan,
        severity: ValidationSeverity.error,
        message: 'Empty day',
        description: 'Day has no meals planned',
        dayIndex: dayIndex,
        suggestedFix: 'Add meals to this day',
      ));
    }
    
    // Individual meal validation
    for (int mealIndex = 0; mealIndex < day.meals.length; mealIndex++) {
      final meal = day.meals[mealIndex];
      issues.addAll(_validateMeal(
        meal,
        availableRecipes,
        availableIngredients,
        targets,
        dayIndex,
        mealIndex,
      ));
    }
    
    // Daily macro validation
    if (issues.where((i) => i.isError).isEmpty) {
      final dayMacros = macroCalculator.calculateDayMacros(
        day: day,
        recipes: availableRecipes,
      );
      issues.addAll(_validateDailyMacros(dayMacros, targets, dayIndex));
    }

    final summary = _createValidationSummary(issues);
    final isValid = issues.where((i) => i.severity == ValidationSeverity.error).isEmpty;

    return ValidationResult(
      isValid: isValid,
      issues: issues,
      summary: summary,
    );
  }

  /// Validate plan structure
  List<ValidationIssue> _validatePlanStructure(Plan plan) {
    final issues = <ValidationIssue>[];
    
    if (plan.days.isEmpty) {
      issues.add(ValidationIssue(
        type: ValidationIssueType.emptyPlan,
        severity: ValidationSeverity.error,
        message: 'Empty plan',
        description: 'Plan has no days',
        suggestedFix: 'Generate a new plan with meals',
      ));
    }
    
    // Check for duplicate days
    final dates = plan.days.map((day) => day.date).toList();
    final uniqueDates = dates.toSet();
    if (dates.length != uniqueDates.length) {
      issues.add(ValidationIssue(
        type: ValidationIssueType.duplicateDay,
        severity: ValidationSeverity.error,
        message: 'Duplicate days',
        description: 'Plan contains duplicate dates',
        suggestedFix: 'Remove duplicate days',
      ));
    }
    
    return issues;
  }

  /// Validate recipe availability
  List<ValidationIssue> _validateRecipeAvailability(
    Plan plan,
    List<Recipe> availableRecipes,
  ) {
    final issues = <ValidationIssue>[];
    final recipeIds = availableRecipes.map((r) => r.id).toSet();
    
    for (int dayIndex = 0; dayIndex < plan.days.length; dayIndex++) {
      final day = plan.days[dayIndex];
      
      for (int mealIndex = 0; mealIndex < day.meals.length; mealIndex++) {
        final meal = day.meals[mealIndex];
        
        if (!recipeIds.contains(meal.recipeId)) {
          issues.add(ValidationIssue(
            type: ValidationIssueType.missingRecipe,
            severity: ValidationSeverity.error,
            message: 'Missing recipe',
            description: 'Recipe ${meal.recipeId} not found',
            dayIndex: dayIndex,
            mealIndex: mealIndex,
            recipeId: meal.recipeId,
            suggestedFix: 'Replace with an available recipe',
          ));
        }
      }
    }
    
    return issues;
  }

  /// Validate ingredient availability
  List<ValidationIssue> _validateIngredientAvailability(
    Plan plan,
    List<Recipe> availableRecipes,
    List<Ingredient> availableIngredients,
  ) {
    final issues = <ValidationIssue>[];
    final ingredientIds = availableIngredients.map((i) => i.id).toSet();
    
    for (final recipe in availableRecipes) {
      if (plan.days.any((day) => day.meals.any((meal) => meal.recipeId == recipe.id))) {
        for (final item in recipe.items) {
          if (!ingredientIds.contains(item.ingredientId)) {
            issues.add(ValidationIssue(
              type: ValidationIssueType.missingIngredient,
              severity: ValidationSeverity.error,
              message: 'Missing ingredient',
              description: 'Ingredient ${item.ingredientId} not available for recipe ${recipe.name}',
              recipeId: recipe.id,
              ingredientId: item.ingredientId,
              suggestedFix: 'Add ingredient to database or replace recipe',
            ));
          }
        }
      }
    }
    
    return issues;
  }

  /// Validate diet compatibility
  List<ValidationIssue> _validateDietCompatibility(
    Plan plan,
    UserTargets targets,
    List<Recipe> availableRecipes,
  ) {
    final issues = <ValidationIssue>[];
    final recipeMap = {for (var r in availableRecipes) r.id: r};
    
    for (int dayIndex = 0; dayIndex < plan.days.length; dayIndex++) {
      final day = plan.days[dayIndex];
      
      for (int mealIndex = 0; mealIndex < day.meals.length; mealIndex++) {
        final meal = day.meals[mealIndex];
        final recipe = recipeMap[meal.recipeId];
        
        if (recipe != null && !recipe.isCompatibleWithDiet(targets.dietFlags)) {
          issues.add(ValidationIssue(
            type: ValidationIssueType.incompatibleDiet,
            severity: ValidationSeverity.error,
            message: 'Diet incompatible',
            description: 'Recipe ${recipe.name} is not compatible with diet restrictions',
            dayIndex: dayIndex,
            mealIndex: mealIndex,
            recipeId: recipe.id,
            suggestedFix: 'Replace with diet-compatible recipe',
          ));
        }
      }
    }
    
    return issues;
  }

  /// Validate time constraints
  List<ValidationIssue> _validateTimeConstraints(
    Plan plan,
    UserTargets targets,
    List<Recipe> availableRecipes,
  ) {
    final issues = <ValidationIssue>[];
    if (targets.timeCapMins == null) return issues;
    
    final recipeMap = {for (var r in availableRecipes) r.id: r};
    
    for (int dayIndex = 0; dayIndex < plan.days.length; dayIndex++) {
      final day = plan.days[dayIndex];
      int dailyPrepTime = 0;
      
      for (int mealIndex = 0; mealIndex < day.meals.length; mealIndex++) {
        final meal = day.meals[mealIndex];
        final recipe = recipeMap[meal.recipeId];
        
        if (recipe != null) {
          dailyPrepTime += recipe.timeMins;
          
          if (!recipe.fitsTimeConstraint(targets.timeCapMins)) {
            issues.add(ValidationIssue(
              type: ValidationIssueType.timeConstraintViolation,
              severity: ValidationSeverity.warning,
              message: 'Time constraint exceeded',
              description: 'Recipe ${recipe.name} takes ${recipe.timeMins} minutes, exceeding ${targets.timeCapMins} minute limit',
              dayIndex: dayIndex,
              mealIndex: mealIndex,
              recipeId: recipe.id,
              suggestedFix: 'Replace with quicker recipe',
            ));
          }
        }
      }
      
      if (dailyPrepTime > targets.timeCapMins! * 2) {
        issues.add(ValidationIssue(
          type: ValidationIssueType.timeConstraintViolation,
          severity: ValidationSeverity.warning,
          message: 'Daily prep time high',
          description: 'Day ${dayIndex + 1} requires ${dailyPrepTime} minutes of prep time',
          dayIndex: dayIndex,
          suggestedFix: 'Consider meal prep or quicker recipes',
        ));
      }
    }
    
    return issues;
  }

  /// Validate macro targets
  List<ValidationIssue> _validateMacroTargets(
    Plan plan,
    UserTargets targets,
    List<Recipe> availableRecipes,
  ) {
    final issues = <ValidationIssue>[];
    
    final dailyAvg = macroCalculator.calculateDailyAverageMacros(
      plan: plan,
      recipes: availableRecipes,
    );
    
    final tolerance = config.macroTolerancePercent / 100;
    
    // Calorie validation
    final kcalError = (dailyAvg.kcal - targets.kcal).abs() / targets.kcal;
    if (kcalError > tolerance) {
      final severity = kcalError > 0.2 ? ValidationSeverity.error : ValidationSeverity.warning;
      issues.add(ValidationIssue(
        type: ValidationIssueType.macroDeficiency,
        severity: severity,
        message: 'Calorie target missed',
        description: 'Daily average ${dailyAvg.kcal.toStringAsFixed(0)} kcal vs target ${targets.kcal.toStringAsFixed(0)} kcal',
        suggestedFix: 'Adjust serving sizes or swap recipes',
      ));
    }
    
    // Protein validation (critical for most goals)
    if (dailyAvg.proteinG < targets.proteinG * 0.9) {
      issues.add(ValidationIssue(
        type: ValidationIssueType.macroDeficiency,
        severity: ValidationSeverity.error,
        message: 'Protein target missed',
        description: 'Daily average ${dailyAvg.proteinG.toStringAsFixed(1)}g vs target ${targets.proteinG.toStringAsFixed(1)}g protein',
        suggestedFix: 'Add high-protein recipes or increase serving sizes',
      ));
    }
    
    return issues;
  }

  /// Validate budget constraints
  List<ValidationIssue> _validateBudget(
    Plan plan,
    UserTargets targets,
    List<Recipe> availableRecipes,
  ) {
    final issues = <ValidationIssue>[];
    
    final totals = macroCalculator.calculatePlanTotals(
      plan: plan,
      recipes: availableRecipes,
    );
    
    final weeklyBudget = targets.budgetCents! * 7;
    final overrun = totals.costCents - weeklyBudget;
    
    if (overrun > 0) {
      final overrunPercent = (overrun / weeklyBudget) * 100;
      final severity = overrunPercent > config.budgetTolerancePercent 
          ? ValidationSeverity.error 
          : ValidationSeverity.warning;
      
      issues.add(ValidationIssue(
        type: ValidationIssueType.budgetOverrun,
        severity: severity,
        message: 'Budget exceeded',
        description: 'Plan costs \$${(totals.costCents / 100).toStringAsFixed(2)} vs budget \$${(weeklyBudget / 100).toStringAsFixed(2)}',
        suggestedFix: 'Choose cheaper recipes or reduce serving sizes',
      ));
    }
    
    return issues;
  }

  /// Assess overall plan quality
  List<ValidationIssue> _assessPlanQuality(
    Plan plan,
    UserTargets targets,
    List<Recipe> availableRecipes,
  ) {
    final issues = <ValidationIssue>[];
    
    // Check recipe variety
    final recipeCount = <String, int>{};
    for (final day in plan.days) {
      for (final meal in day.meals) {
        recipeCount[meal.recipeId] = (recipeCount[meal.recipeId] ?? 0) + 1;
      }
    }
    
    final highRepeatCount = recipeCount.values.where((count) => count > 3).length;
    if (highRepeatCount > 0) {
      issues.add(ValidationIssue(
        type: ValidationIssueType.duplicateDay,
        severity: ValidationSeverity.info,
        message: 'Limited variety',
        description: '$highRepeatCount recipe${highRepeatCount > 1 ? 's' : ''} repeated more than 3 times',
        suggestedFix: 'Add more recipe variety',
      ));
    }
    
    return issues;
  }

  /// Validate a single meal
  List<ValidationIssue> _validateMeal(
    PlanMeal meal,
    List<Recipe> availableRecipes,
    List<Ingredient> availableIngredients,
    UserTargets targets,
    int? dayIndex,
    int mealIndex,
  ) {
    final issues = <ValidationIssue>[];
    
    // Validate serving size
    if (meal.servings <= 0 || meal.servings > 10) {
      issues.add(ValidationIssue(
        type: ValidationIssueType.invalidServings,
        severity: ValidationSeverity.error,
        message: 'Invalid servings',
        description: 'Serving size ${meal.servings} is invalid',
        dayIndex: dayIndex,
        mealIndex: mealIndex,
        recipeId: meal.recipeId,
        suggestedFix: 'Adjust serving size to reasonable amount',
      ));
    }
    
    return issues;
  }

  /// Validate daily macros
  List<ValidationIssue> _validateDailyMacros(
    MacrosPerServing dayMacros,
    UserTargets targets,
    int? dayIndex,
  ) {
    final issues = <ValidationIssue>[];
    
    // Check if day is severely under calories
    if (dayMacros.kcal < targets.kcal * 0.7) {
      issues.add(ValidationIssue(
        type: ValidationIssueType.macroDeficiency,
        severity: ValidationSeverity.warning,
        message: 'Low calorie day',
        description: 'Day ${dayIndex != null ? dayIndex + 1 : ''} has only ${dayMacros.kcal.toStringAsFixed(0)} kcal',
        dayIndex: dayIndex,
        suggestedFix: 'Add more food to this day',
      ));
    }
    
    return issues;
  }

  /// Create validation summary
  ValidationSummary _createValidationSummary(List<ValidationIssue> issues) {
    final errorCount = issues.where((i) => i.severity == ValidationSeverity.error).length;
    final warningCount = issues.where((i) => i.severity == ValidationSeverity.warning).length;
    final infoCount = issues.where((i) => i.severity == ValidationSeverity.info).length;
    
    // Calculate quality score (0-100)
    double qualityScore = 100.0;
    qualityScore -= errorCount * 25.0;    // Errors are serious
    qualityScore -= warningCount * 10.0;  // Warnings are moderate
    qualityScore -= infoCount * 2.0;      // Info items are minor
    qualityScore = qualityScore.clamp(0.0, 100.0);
    
    // Generate recommendations
    final recommendations = <String>[];
    if (errorCount > 0) {
      recommendations.add('Fix critical errors before using this plan');
    }
    if (warningCount > 0) {
      recommendations.add('Consider addressing warnings for better results');
    }
    if (qualityScore < 80) {
      recommendations.add('Plan quality could be improved');
    }
    
    return ValidationSummary(
      totalIssues: issues.length,
      errorCount: errorCount,
      warningCount: warningCount,
      infoCount: infoCount,
      planQualityScore: qualityScore,
      recommendations: recommendations,
    );
  }
}
