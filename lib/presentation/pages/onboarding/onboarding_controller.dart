import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/entities/user_targets.dart';

/// Onboarding state for managing the multi-step flow
class OnboardingState {
  const OnboardingState({
    this.currentStep = 0,
    this.selectedGoal,
    this.bodyWeightLbs,
    this.kcal = 2000,
    this.proteinG = 150,
    this.carbsG = 200,
    this.fatG = 67,
    this.budgetCents,
    this.mealsPerDay = 3,
    this.timeCapMins = 30,
    this.dietFlags = const <String>{},
    this.equipment = const <String>{'stove', 'oven', 'microwave'},
    this.planningMode = PlanningMode.maintenance,
    this.isCustomMacros = false,
  });

  final int currentStep;
  final String? selectedGoal;
  final double? bodyWeightLbs;
  final double kcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final int? budgetCents;
  final int mealsPerDay;
  final int? timeCapMins;
  final Set<String> dietFlags;
  final Set<String> equipment;
  final PlanningMode planningMode;
  final bool isCustomMacros;

  OnboardingState copyWith({
    int? currentStep,
    String? selectedGoal,
    double? bodyWeightLbs,
    double? kcal,
    double? proteinG,
    double? carbsG,
    double? fatG,
    int? budgetCents,
    int? mealsPerDay,
    int? timeCapMins,
    Set<String>? dietFlags,
    Set<String>? equipment,
    PlanningMode? planningMode,
    bool? isCustomMacros,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      selectedGoal: selectedGoal ?? this.selectedGoal,
      bodyWeightLbs: bodyWeightLbs ?? this.bodyWeightLbs,
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
      isCustomMacros: isCustomMacros ?? this.isCustomMacros,
    );
  }

  UserTargets toUserTargets() {
    return UserTargets(
      id: const Uuid().v4(),
      kcal: kcal,
      proteinG: proteinG,
      carbsG: carbsG,
      fatG: fatG,
      budgetCents: budgetCents,
      mealsPerDay: mealsPerDay,
      timeCapMins: timeCapMins,
      dietFlags: dietFlags.toList(),
      equipment: equipment.toList(),
      planningMode: planningMode,
    );
  }

  bool get canProceed {
    switch (currentStep) {
      case 0: // Goals
        return selectedGoal != null;
      case 1: // Body weight (if needed)
        return selectedGoal == 'custom' || bodyWeightLbs != null;
      case 2: // Macros
        return kcal > 0 && proteinG > 0 && fatG > 0;
      case 3: // Budget
        return true; // Budget is optional
      case 4: // Meals and time
        return mealsPerDay >= 2 && mealsPerDay <= 5;
      case 5: // Diet and equipment
        return true; // Both are optional
      default:
        return false;
    }
  }
}

/// Controller for onboarding flow
class OnboardingController extends StateNotifier<OnboardingState> {
  OnboardingController() : super(const OnboardingState());

  static const int totalSteps = 6;

  void nextStep() {
    if (state.currentStep < totalSteps - 1 && state.canProceed) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void setGoal(String goal) {
    state = state.copyWith(selectedGoal: goal);
    
    // Set default planning mode based on goal
    PlanningMode mode;
    switch (goal) {
      case 'cutting':
        mode = PlanningMode.cutting;
        break;
      case 'bulking_budget':
        mode = PlanningMode.bulkingBudget;
        break;
      case 'bulking_no_budget':
        mode = PlanningMode.bulkingNoBudget;
        break;
      default:
        mode = PlanningMode.maintenance;
    }
    state = state.copyWith(planningMode: mode);
  }

  void setBodyWeight(double weight) {
    state = state.copyWith(bodyWeightLbs: weight);
    
    // Auto-calculate macros based on goal and body weight
    if (state.selectedGoal != null && state.selectedGoal != 'custom') {
      _calculateMacrosFromGoal(weight);
    }
  }

  void _calculateMacrosFromGoal(double bodyWeightLbs) {
    switch (state.selectedGoal) {
      case 'cutting':
        final targets = UserTargets.cuttingPreset(bodyWeightLbs: bodyWeightLbs);
        state = state.copyWith(
          kcal: targets.kcal,
          proteinG: targets.proteinG,
          carbsG: targets.carbsG,
          fatG: targets.fatG,
          budgetCents: targets.budgetCents,
          mealsPerDay: targets.mealsPerDay,
          timeCapMins: targets.timeCapMins,
        );
        break;
      case 'bulking_budget':
      case 'bulking_no_budget':
        final targets = UserTargets.bulkingPreset(
          bodyWeightLbs: bodyWeightLbs,
          budgetCents: state.selectedGoal == 'bulking_budget' ? 8500 : null, // $85/week
        );
        state = state.copyWith(
          kcal: targets.kcal,
          proteinG: targets.proteinG,
          carbsG: targets.carbsG,
          fatG: targets.fatG,
          budgetCents: targets.budgetCents,
          mealsPerDay: targets.mealsPerDay,
          timeCapMins: targets.timeCapMins,
        );
        break;
    }
  }

  void setMacros({
    double? kcal,
    double? proteinG,
    double? carbsG,
    double? fatG,
  }) {
    state = state.copyWith(
      kcal: kcal,
      proteinG: proteinG,
      carbsG: carbsG,
      fatG: fatG,
      isCustomMacros: true,
    );
  }

  void setBudget(int? budgetCents) {
    state = state.copyWith(budgetCents: budgetCents);
  }

  void setMealsPerDay(int meals) {
    state = state.copyWith(mealsPerDay: meals);
  }

  void setTimeCapMins(int? timeCap) {
    state = state.copyWith(timeCapMins: timeCap);
  }

  void setDietFlags(Set<String> flags) {
    state = state.copyWith(dietFlags: flags);
  }

  void setEquipment(Set<String> equipment) {
    state = state.copyWith(equipment: equipment);
  }

  void reset() {
    state = const OnboardingState();
  }
}

/// Provider for onboarding controller
final onboardingControllerProvider = 
    StateNotifierProvider<OnboardingController, OnboardingState>((ref) {
  return OnboardingController();
});
