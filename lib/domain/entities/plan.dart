import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';


part 'plan.g.dart';

/// Meal entry in a daily plan
@JsonSerializable()
class PlanMeal extends Equatable {
  const PlanMeal({
    required this.recipeId,
    required this.servings,
    this.notes,
  });

  /// Reference to the recipe ID
  final String recipeId;

  /// Number of servings for this meal
  final double servings;

  /// Optional notes for the meal
  final String? notes;

  factory PlanMeal.fromJson(Map<String, dynamic> json) =>
      _$PlanMealFromJson(json);

  Map<String, dynamic> toJson() => _$PlanMealToJson(this);

  @override
  List<Object?> get props => [recipeId, servings, notes];
}

/// Daily plan with date and meals
@JsonSerializable()
class PlanDay extends Equatable {
  const PlanDay({
    required this.date,
    required this.meals,
  });

  /// Date for this day's plan (ISO format)
  final String date;

  /// List of meals for this day
  final List<PlanMeal> meals;

  factory PlanDay.fromJson(Map<String, dynamic> json) =>
      _$PlanDayFromJson(json);

  Map<String, dynamic> toJson() => _$PlanDayToJson(this);

  /// Get DateTime object from date string
  DateTime get dateTime => DateTime.parse(date);

  /// Get total servings for the day
  double get totalServings => meals.fold(0.0, (sum, meal) => sum + meal.servings);

  @override
  List<Object?> get props => [date, meals];
}

/// Plan totals for macros and cost
@JsonSerializable()
class PlanTotals extends Equatable {
  const PlanTotals({
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.costCents,
  });

  final double kcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final int costCents;

  factory PlanTotals.fromJson(Map<String, dynamic> json) =>
      _$PlanTotalsFromJson(json);

  Map<String, dynamic> toJson() => _$PlanTotalsToJson(this);

  /// Create empty totals
  factory PlanTotals.empty() {
    return const PlanTotals(
      kcal: 0,
      proteinG: 0,
      carbsG: 0,
      fatG: 0,
      costCents: 0,
    );
  }

  /// Add totals from another plan
  PlanTotals operator +(PlanTotals other) {
    return PlanTotals(
      kcal: kcal + other.kcal,
      proteinG: proteinG + other.proteinG,
      carbsG: carbsG + other.carbsG,
      fatG: fatG + other.fatG,
      costCents: costCents + other.costCents,
    );
  }

  /// Get daily averages
  PlanTotals getDailyAverage(int days) {
    if (days == 0) return PlanTotals.empty();
    return PlanTotals(
      kcal: kcal / days,
      proteinG: proteinG / days,
      carbsG: carbsG / days,
      fatG: fatG / days,
      costCents: (costCents / days).round(),
    );
  }

  /// Get macro distribution percentages
  Map<String, double> get macroPercentages {
    final totalCals = (proteinG * 4) + (carbsG * 4) + (fatG * 9);
    if (totalCals == 0) return {'protein': 0, 'carbs': 0, 'fat': 0};
    
    return {
      'protein': (proteinG * 4) / totalCals * 100,
      'carbs': (carbsG * 4) / totalCals * 100,
      'fat': (fatG * 9) / totalCals * 100,
    };
  }

  @override
  List<Object?> get props => [kcal, proteinG, carbsG, fatG, costCents];
}

/// Generated meal plan entity
@JsonSerializable()
class Plan extends Equatable {
  const Plan({
    required this.id,
    required this.name,
    required this.userTargetsId,
    required this.days,
    required this.totals,
    required this.createdAt,
  });

  /// Unique identifier for the plan
  final String id;

  /// Display name for the plan
  final String name;

  /// Reference to user targets used for this plan
  final String userTargetsId;

  /// List of daily plans (typically 7 days)
  final List<PlanDay> days;

  /// Total macros and cost for the entire plan
  final PlanTotals totals;

  /// Creation timestamp
  final DateTime createdAt;

  factory Plan.fromJson(Map<String, dynamic> json) =>
      _$PlanFromJson(json);

  Map<String, dynamic> toJson() => _$PlanToJson(this);

  /// Get plan duration in days
  int get durationDays => days.length;

  /// Get daily average totals
  PlanTotals get dailyAverageTotals => totals.getDailyAverage(durationDays);

  /// Get weekly cost
  int get weeklyCostCents => totals.costCents;

  /// Get daily average cost
  int get dailyAverageCostCents => (totals.costCents / durationDays).round();

  /// Get all unique recipe IDs used in the plan
  Set<String> get usedRecipeIds {
    return days
        .expand((day) => day.meals)
        .map((meal) => meal.recipeId)
        .toSet();
  }

  /// Get total servings for a specific recipe across all days
  double getTotalServingsForRecipe(String recipeId) {
    return days
        .expand((day) => day.meals)
        .where((meal) => meal.recipeId == recipeId)
        .fold(0.0, (sum, meal) => sum + meal.servings);
  }

  /// Check if plan meets macro targets within tolerance
  bool meetsMacroTargets({
    required double targetKcal,
    required double targetProteinG,
    required double targetCarbsG,
    required double targetFatG,
    double kcalTolerance = 0.05, // 5% tolerance
    double proteinTolerance = 0.95, // Must be at least 95% of protein target
  }) {
    final daily = dailyAverageTotals;
    
    // Check calorie tolerance (±5%)
    final kcalError = (daily.kcal - targetKcal).abs() / targetKcal;
    if (kcalError > kcalTolerance) return false;
    
    // Check protein minimum (95% of target)
    if (daily.proteinG < targetProteinG * proteinTolerance) return false;
    
    return true;
  }

  /// Check if plan meets budget constraint
  bool meetsBudget(int? budgetCents) {
    if (budgetCents == null) return true;
    return totals.costCents <= budgetCents;
  }

  /// Get plan score for optimization (lower is better)
  double calculateScore({
    required double targetKcal,
    required double targetProteinG,
    required double targetCarbsG,
    required double targetFatG,
    int? budgetCents,
    required Map<String, double> weights,
  }) {
    final daily = dailyAverageTotals;
    double score = 0.0;
    
    // Macro error (L1 norm)
    final kcalError = (daily.kcal - targetKcal).abs() / targetKcal;
    final proteinError = (daily.proteinG - targetProteinG).abs() / targetProteinG;
    final carbsError = (daily.carbsG - targetCarbsG).abs() / targetCarbsG;
    final fatError = (daily.fatG - targetFatG).abs() / targetFatG;
    final macroError = kcalError + proteinError + carbsError + fatError;
    
    score += (weights['macro_error'] ?? 1.0) * macroError;
    
    // Under-protein penalty (2x penalty)
    if (daily.proteinG < targetProteinG) {
      final proteinPenalty = (targetProteinG - daily.proteinG) / targetProteinG;
      score += (weights['protein_penalty_multiplier'] ?? 2.0) * proteinPenalty;
    }
    
    // Budget error
    if (budgetCents != null) {
      final budgetError = (totals.costCents - budgetCents).clamp(0, double.infinity) / budgetCents;
      score += (weights['budget_error'] ?? 1.0) * budgetError;
    }
    
    // Variety penalty (count repeated recipes)
    final recipeUsage = <String, int>{};
    for (final day in days) {
      for (final meal in day.meals) {
        recipeUsage[meal.recipeId] = (recipeUsage[meal.recipeId] ?? 0) + 1;
      }
    }
    final varietyPenalty = recipeUsage.values
        .where((count) => count > 2)
        .fold(0.0, (sum, count) => sum + (count - 2));
    score += (weights['variety_penalty'] ?? 0.3) * varietyPenalty;
    
    return score;
  }

  /// Copy with new values
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

  @override
  List<Object?> get props => [id, name, userTargetsId, days, totals, createdAt];
}
