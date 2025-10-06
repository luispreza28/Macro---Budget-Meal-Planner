import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/plan.dart';
import '../../domain/repositories/plan_repository.dart';
import 'database_providers.dart';

/// Provider for all plans
final allPlansProvider = StreamProvider<List<Plan>>((ref) {
  final repository = ref.watch(planRepositoryProvider);
  return repository.watchAllPlans();
});

/// Provider for current active plan (explicitly user-selected)
final currentPlanProvider = StreamProvider<Plan?>((ref) {
  final repository = ref.watch(planRepositoryProvider);
  return repository.watchCurrentPlan();
});

/// Provider for recent plans
final recentPlansProvider = StreamProvider<List<Plan>>((ref) {
  final repository = ref.watch(planRepositoryProvider);
  return repository.watchRecentPlans(limit: 10);
});

/// Provider for plan by ID
final planByIdProvider = FutureProvider.family<Plan?, String>((ref, id) {
  final repository = ref.watch(planRepositoryProvider);
  return repository.getPlanById(id);
});

/// Provider for plans by user targets ID
final plansByUserTargetsIdProvider = FutureProvider.family<List<Plan>, String>((
  ref,
  userTargetsId,
) {
  final repository = ref.watch(planRepositoryProvider);
  return repository.getPlansByUserTargetsId(userTargetsId);
});

/// Provider for plans count
final plansCountProvider = StreamProvider<int>((ref) {
  final repository = ref.watch(planRepositoryProvider);
  return repository.watchPlansCount();
});

/// Provider for active plans count (for free tier limit)
final activePlansCountProvider = FutureProvider<int>((ref) {
  final repository = ref.watch(planRepositoryProvider);
  return repository.getActivePlansCount();
});

/// Provider for plan statistics
final planStatisticsProvider = FutureProvider<Map<String, dynamic>>((ref) {
  final repository = ref.watch(planRepositoryProvider);
  return repository.getPlanStatistics();
});

/// Provider for best scoring plans
final bestScoringPlansProvider =
    FutureProvider.family<List<Plan>, BestPlansParams>((ref, params) {
      final repository = ref.watch(planRepositoryProvider);
      return repository.getBestScoringPlans(
        targetKcal: params.targetKcal,
        targetProteinG: params.targetProteinG,
        targetCarbsG: params.targetCarbsG,
        targetFatG: params.targetFatG,
        budgetCents: params.budgetCents,
        weights: params.weights,
        limit: params.limit,
      );
    });

/// Parameters for best scoring plans provider
class BestPlansParams {
  const BestPlansParams({
    required this.targetKcal,
    required this.targetProteinG,
    required this.targetCarbsG,
    required this.targetFatG,
    this.budgetCents,
    required this.weights,
    this.limit = 10,
  });

  final double targetKcal;
  final double targetProteinG;
  final double targetCarbsG;
  final double targetFatG;
  final int? budgetCents;
  final Map<String, double> weights;
  final int limit;
}

/// Notifier for managing plan operations
class PlanNotifier extends StateNotifier<AsyncValue<void>> {
  PlanNotifier(this._repository) : super(const AsyncValue.data(null));

  final PlanRepository _repository;

  Future<void> savePlan(Plan plan) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.addPlan(plan));
  }

  Future<void> updatePlan(Plan plan) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.updatePlan(plan));
  }

  Future<void> deletePlan(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.deletePlan(id));
  }

  Future<void> setCurrentPlan(String planId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.setCurrentPlan(planId));
  }

  Future<void> clearCurrentPlan() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.clearCurrentPlan());
  }

  Future<void> cleanupOldPlans({int keepCount = 50}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.cleanupOldPlans(keepCount: keepCount),
    );
  }
}

/// Provider for plan operations
final planNotifierProvider =
    StateNotifierProvider<PlanNotifier, AsyncValue<void>>((ref) {
      final repository = ref.watch(planRepositoryProvider);
      return PlanNotifier(repository);
    });
