import '../entities/plan.dart';

/// Repository interface for meal plan data operations
abstract class PlanRepository {
  /// Get all plans
  Future<List<Plan>> getAllPlans();

  /// Get plan by ID
  Future<Plan?> getPlanById(String id);

  /// Get current active plan
  Future<Plan?> getCurrentPlan();

  /// Get recent plans (most recently created first)
  Future<List<Plan>> getRecentPlans({int limit = 10});

  /// Get plans by user targets ID
  Future<List<Plan>> getPlansByUserTargetsId(String userTargetsId);

  /// Save new plan
  Future<void> savePlan(Plan plan);

  /// Update existing plan
  Future<void> updatePlan(Plan plan);

  /// Delete plan
  Future<void> deletePlan(String id);

  /// Set current active plan
  Future<void> setCurrentPlan(String planId);

  /// Clear current active plan
  Future<void> clearCurrentPlan();

  /// Get plans within date range
  Future<List<Plan>> getPlansInDateRange({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Get plans within budget range
  Future<List<Plan>> getPlansInBudgetRange({
    int? minBudgetCents,
    int? maxBudgetCents,
  });

  /// Get best scoring plans (lowest optimization score)
  Future<List<Plan>> getBestScoringPlans({
    required double targetKcal,
    required double targetProteinG,
    required double targetCarbsG,
    required double targetFatG,
    int? budgetCents,
    required Map<String, double> weights,
    int limit = 10,
  });

  /// Check if plan exists
  Future<bool> planExists(String id);

  /// Get plans count
  Future<int> getPlansCount();

  /// Get plans count for free tier (limit 1)
  Future<int> getActivePlansCount();

  /// Delete old plans (keep only recent N plans)
  Future<void> cleanupOldPlans({int keepCount = 50});

  /// Get plan statistics
  Future<Map<String, dynamic>> getPlanStatistics();

  /// Watch all plans (reactive stream)
  Stream<List<Plan>> watchAllPlans();

  /// Watch current plan (reactive stream)
  Stream<Plan?> watchCurrentPlan();

  /// Watch recent plans (reactive stream)
  Stream<List<Plan>> watchRecentPlans({int limit = 10});

  /// Watch plans count (reactive stream)
  Stream<int> watchPlansCount();
}
