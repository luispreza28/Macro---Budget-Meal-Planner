import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_targets.g.dart';

/// Planning modes for different user goals
enum PlanningMode {
  @JsonValue('cutting')
  cutting('cutting'),
  @JsonValue('bulking_budget')
  bulkingBudget('bulking_budget'),
  @JsonValue('bulking_no_budget')
  bulkingNoBudget('bulking_no_budget'),
  @JsonValue('maintenance')
  maintenance('maintenance');

  const PlanningMode(this.value);
  final String value;

  /// Get display name for the mode
  String get displayName {
    switch (this) {
      case PlanningMode.cutting:
        return 'Cutting';
      case PlanningMode.bulkingBudget:
        return 'Bulking (Budget)';
      case PlanningMode.bulkingNoBudget:
        return 'Bulking (No Budget)';
      case PlanningMode.maintenance:
        return 'Maintenance';
    }
  }

  /// Get description for the mode
  String get description {
    switch (this) {
      case PlanningMode.cutting:
        return 'High protein, calorie deficit, high-volume foods';
      case PlanningMode.bulkingBudget:
        return 'Calorie surplus with cost optimization';
      case PlanningMode.bulkingNoBudget:
        return 'Calorie surplus with time optimization';
      case PlanningMode.maintenance:
        return 'Balanced nutrition at maintenance calories';
    }
  }
}

/// User targets and preferences for meal planning
@JsonSerializable()
class UserTargets extends Equatable {
  const UserTargets({
    required this.id,
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.budgetCents,
    required this.mealsPerDay,
    this.timeCapMins,
    required this.dietFlags,
    required this.equipment,
    required this.planningMode,
  });

  /// Unique identifier for the user targets
  final String id;

  /// Daily calorie target
  final double kcal;

  /// Daily protein target in grams
  final double proteinG;

  /// Daily carbohydrate target in grams
  final double carbsG;

  /// Daily fat target in grams
  final double fatG;

  /// Weekly budget in cents (null for no-budget mode)
  final int? budgetCents;

  /// Number of meals per day (2-5)
  final int mealsPerDay;

  /// Maximum preparation time per meal in minutes
  final int? timeCapMins;

  /// Diet compatibility flags (e.g., 'veg', 'gf', 'df')
  final List<String> dietFlags;

  /// Available cooking equipment
  final List<String> equipment;

  /// Planning mode for optimization strategy
  final PlanningMode planningMode;

  factory UserTargets.fromJson(Map<String, dynamic> json) =>
      _$UserTargetsFromJson(json);

  Map<String, dynamic> toJson() => _$UserTargetsToJson(this);

  /// Create default targets for onboarding
  factory UserTargets.defaultTargets() {
    return const UserTargets(
      id: 'default',
      kcal: 2000,
      proteinG: 150,
      carbsG: 200,
      fatG: 67,
      budgetCents: 5000, // $50/week
      mealsPerDay: 3,
      timeCapMins: 30,
      dietFlags: [],
      equipment: ['stove', 'oven', 'microwave'],
      planningMode: PlanningMode.maintenance,
    );
  }

  /// Create cutting preset
  factory UserTargets.cuttingPreset({
    required double bodyWeightLbs,
    int? budgetCents,
  }) {
    final kcal = bodyWeightLbs * 10; // Conservative cutting calories
    final proteinG = bodyWeightLbs * 1.0; // 1g per lb for cutting
    final fatG = bodyWeightLbs * 0.3; // 0.3g per lb
    final carbsG = (kcal - (proteinG * 4) - (fatG * 9)) / 4; // Remaining from carbs

    return UserTargets(
      id: 'cutting_preset',
      kcal: kcal,
      proteinG: proteinG,
      carbsG: carbsG,
      fatG: fatG,
      budgetCents: budgetCents ?? 4000, // $40/week default
      mealsPerDay: 3,
      timeCapMins: 30,
      dietFlags: [],
      equipment: ['stove', 'oven', 'microwave'],
      planningMode: PlanningMode.cutting,
    );
  }

  /// Create bulking preset
  factory UserTargets.bulkingPreset({
    required double bodyWeightLbs,
    int? budgetCents,
  }) {
    final kcal = bodyWeightLbs * 16; // Bulking calories
    final proteinG = bodyWeightLbs * 0.8; // 0.8g per lb for bulking
    final fatG = bodyWeightLbs * 0.4; // 0.4g per lb
    final carbsG = (kcal - (proteinG * 4) - (fatG * 9)) / 4; // Remaining from carbs

    return UserTargets(
      id: 'bulking_preset',
      kcal: kcal,
      proteinG: proteinG,
      carbsG: carbsG,
      fatG: fatG,
      budgetCents: budgetCents,
      mealsPerDay: 4,
      timeCapMins: budgetCents != null ? 45 : 20, // More time if budget mode
      dietFlags: [],
      equipment: ['stove', 'oven', 'microwave'],
      planningMode: budgetCents != null 
          ? PlanningMode.bulkingBudget 
          : PlanningMode.bulkingNoBudget,
    );
  }

  /// Get total macro calories
  double get totalMacroCalories => (proteinG * 4) + (carbsG * 4) + (fatG * 9);

  /// Get macro distribution percentages
  Map<String, double> get macroPercentages {
    final totalCals = totalMacroCalories;
    if (totalCals == 0) return {'protein': 0, 'carbs': 0, 'fat': 0};
    
    return {
      'protein': (proteinG * 4) / totalCals * 100,
      'carbs': (carbsG * 4) / totalCals * 100,
      'fat': (fatG * 9) / totalCals * 100,
    };
  }

  /// Check if targets are valid
  bool get isValid {
    return kcal > 0 &&
           proteinG > 0 &&
           carbsG >= 0 &&
           fatG > 0 &&
           mealsPerDay >= 2 &&
           mealsPerDay <= 5 &&
           (budgetCents == null || budgetCents! > 0) &&
           (timeCapMins == null || timeCapMins! > 0);
  }

  /// Get daily budget in cents
  int? get dailyBudgetCents {
    if (budgetCents == null) return null;
    return (budgetCents! / 7).round();
  }

  /// Get budget per meal in cents
  int? get budgetPerMealCents {
    final daily = dailyBudgetCents;
    if (daily == null) return null;
    return (daily / mealsPerDay).round();
  }

  /// Check if equipment is available
  bool hasEquipment(String equipment) => this.equipment.contains(equipment);

  /// Check if diet flag is set
  bool hasDietFlag(String flag) => dietFlags.contains(flag);

  /// Get optimization weights for planning algorithm
  Map<String, double> get optimizationWeights {
    switch (planningMode) {
      case PlanningMode.cutting:
        return {
          'macro_error': 1.0,
          'budget_error': 0.8,
          'variety_penalty': 0.3,
          'prep_time_penalty': 0.2,
          'pantry_bonus': 0.5,
          'protein_penalty_multiplier': 2.0,
        };
      case PlanningMode.bulkingBudget:
        return {
          'macro_error': 0.8,
          'budget_error': 1.0,
          'variety_penalty': 0.3,
          'prep_time_penalty': 0.1,
          'pantry_bonus': 0.7,
          'cost_per_kcal_weight': 0.5,
        };
      case PlanningMode.bulkingNoBudget:
        return {
          'macro_error': 0.9,
          'budget_error': 0.1,
          'variety_penalty': 0.3,
          'prep_time_penalty': 0.8,
          'pantry_bonus': 0.3,
        };
      case PlanningMode.maintenance:
        return {
          'macro_error': 0.9,
          'budget_error': 0.6,
          'variety_penalty': 0.4,
          'prep_time_penalty': 0.4,
          'pantry_bonus': 0.5,
        };
    }
  }

  /// Copy with new values
  UserTargets copyWith({
    String? id,
    double? kcal,
    double? proteinG,
    double? carbsG,
    double? fatG,
    int? budgetCents,
    int? mealsPerDay,
    int? timeCapMins,
    List<String>? dietFlags,
    List<String>? equipment,
    PlanningMode? planningMode,
  }) {
    return UserTargets(
      id: id ?? this.id,
      kcal: kcal ?? this.kcal,
      proteinG: proteinG ?? this.proteinG,
      carbsG: carbsG ?? this.carbsG,
      fatG: fatG ?? this.fatG,
      budgetCents: budgetCents ?? this.budgetCents,
      mealsPerDay: mealsPerDay ?? this.mealsPerDay,
      timeCapMins: timeCapMins ?? this.timeCapMins,
      dietFlags: dietFlags ?? this.dietFlags,
      equipment: equipment ?? this.equipment,
      planningMode: planningMode ?? this.planningMode,
    );
  }

  @override
  List<Object?> get props => [
        id,
        kcal,
        proteinG,
        carbsG,
        fatG,
        budgetCents,
        mealsPerDay,
        timeCapMins,
        dietFlags,
        equipment,
        planningMode,
      ];
}
