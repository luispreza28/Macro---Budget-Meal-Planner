import 'dart:async';

import '../../domain/entities/plan.dart';
import '../../domain/repositories/plan_repository.dart';

/// Simple in-memory PlanRepository for development/testing.
class MockPlanRepository implements PlanRepository {
  final List<Plan> _plans = <Plan>[];
  String? _currentPlanId;

  final _plansCtrl = StreamController<List<Plan>>.broadcast();
  final _currentPlanCtrl = StreamController<Plan?>.broadcast();
  final _plansCountCtrl = StreamController<int>.broadcast();

  MockPlanRepository() {
    _emit();
  }

  void dispose() {
    _plansCtrl.close();
    _currentPlanCtrl.close();
    _plansCountCtrl.close();
  }

  // Helpers
  Plan? _findById(String id) {
    for (final p in _plans) {
      if (p.id == id) return p;
    }
    return null;
  }

  Plan? _currentPlan() {
    if (_currentPlanId == null) return null;
    return _findById(_currentPlanId!);
  }

  void _emit() {
    _plansCtrl.add(List.unmodifiable(_plans));
    _currentPlanCtrl.add(_currentPlan());
    _plansCountCtrl.add(_plans.length);
  }

  @override
  Future<void> cleanupOldPlans({int keepCount = 50}) async {
    _plans.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (_plans.length > keepCount) {
      _plans.removeRange(keepCount, _plans.length);
      if (_currentPlanId != null && _findById(_currentPlanId!) == null) {
        _currentPlanId = _plans.isEmpty ? null : _plans.first.id;
      }
      _emit();
    }
  }

  @override
  Future<void> clearCurrentPlan() async {
    _currentPlanId = null;
    _emit();
  }

  @override
  Future<void> deletePlan(String id) async {
    _plans.removeWhere((p) => p.id == id);
    if (_currentPlanId == id) {
      _currentPlanId = _plans.isEmpty ? null : _plans.first.id;
    }
    _emit();
  }

  @override
  Future<List<Plan>> getAllPlans() async {
    return List.unmodifiable(_plans);
  }

  @override
  Future<int> getActivePlansCount() async {
    // Only the "current" plan counts as active for free tier logic.
    return _currentPlanId == null ? 0 : 1;
  }

  @override
  Future<List<Plan>> getBestScoringPlans({
    required double targetKcal,
    required double targetProteinG,
    required double targetCarbsG,
    required double targetFatG,
    int? budgetCents,
    required Map<String, double> weights,
    int limit = 10,
  }) async {
    final scored = _plans
        .map(
          (p) => MapEntry(
            p,
            p.calculateScore(
              targetKcal: targetKcal,
              targetProteinG: targetProteinG,
              targetCarbsG: targetCarbsG,
              targetFatG: targetFatG,
              budgetCents: budgetCents,
              weights: {
                'macro_error': weights['macro_error'] ?? 1.0,
                'protein_penalty_multiplier':
                    weights['protein_penalty_multiplier'] ?? 2.0,
                'budget_error': weights['budget_error'] ?? 1.0,
                'variety_penalty': weights['variety_penalty'] ?? 0.3,
              },
            ),
          ),
        )
        .toList();

    scored.sort((a, b) => a.value.compareTo(b.value));
    return scored.take(limit).map((e) => e.key).toList();
  }

  @override
  Future<Plan?> getCurrentPlan() async => _currentPlan();

  @override
  Future<Plan?> getPlanById(String id) async => _findById(id);

  @override
  Future<List<Plan>> getPlansByUserTargetsId(String userTargetsId) async {
    return _plans.where((p) => p.userTargetsId == userTargetsId).toList();
  }

  @override
  Future<List<Plan>> getPlansInBudgetRange({
    int? minBudgetCents,
    int? maxBudgetCents,
  }) async {
    return _plans.where((p) {
      final cost = p.totals.costCents;
      final minOk = minBudgetCents == null || cost >= minBudgetCents;
      final maxOk = maxBudgetCents == null || cost <= maxBudgetCents;
      return minOk && maxOk;
    }).toList();
  }

  @override
  Future<List<Plan>> getPlansInDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return _plans
        .where(
          (p) =>
              p.createdAt.isAfter(startDate) && p.createdAt.isBefore(endDate),
        )
        .toList();
  }

  @override
  Future<int> getPlansCount() async => _plans.length;

  @override
  Future<List<Plan>> getRecentPlans({int limit = 10}) async {
    final copy = [..._plans];
    copy.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return copy.take(limit).toList();
  }

  @override
  Future<bool> planExists(String id) async => _findById(id) != null;

  @override
  Future<void> addPlan(Plan plan) async => savePlan(plan);

  @override
  Future<void> savePlan(Plan plan) async {
    if (await planExists(plan.id)) {
      final idx = _plans.indexWhere((p) => p.id == plan.id);
      _plans[idx] = plan;
    } else {
      _plans.add(plan);
    }
    _emit();
  }

  @override
  Future<void> setCurrentPlan(String planId) async {
    _currentPlanId = planId;
    _emit();
  }

  @override
  Future<void> updatePlan(Plan plan) async {
    final idx = _plans.indexWhere((p) => p.id == plan.id);
    if (idx >= 0) {
      _plans[idx] = plan;
      _emit();
    }
  }

  @override
  Future<Map<String, dynamic>> getPlanStatistics() async {
    final total = _plans.length;
    final avgCost = total == 0
        ? 0.0
        : _plans.map((p) => p.totals.costCents).reduce((a, b) => a + b) /
              total /
              100.0;

    return {'count': total, 'avg_weekly_cost': avgCost};
  }

  // -------- FIX: yield initial snapshot before controller stream --------
  @override
  Stream<List<Plan>> watchAllPlans() async* {
    yield List.unmodifiable(_plans); // immediate snapshot
    yield* _plansCtrl.stream; // then live updates
  }

  @override
  Stream<Plan?> watchCurrentPlan() async* {
    yield _currentPlan(); // immediate snapshot (possibly null)
    yield* _currentPlanCtrl.stream; // then live updates
  }

  @override
  Stream<Plan?> watchLatestPlan() async* {
    Plan? selectLatest(List<Plan> snapshot) {
      if (snapshot.isEmpty) return null;
      return snapshot.reduce(
        (a, b) => a.createdAt.isAfter(b.createdAt) ? a : b,
      );
    }

    yield selectLatest(_plans);
    yield* _plansCtrl.stream.map(selectLatest);
  }

  @override
  Stream<List<Plan>> watchRecentPlans({int limit = 10}) async* {
    final copy = [..._plans];
    copy.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    yield copy.take(limit).toList(); // immediate snapshot
    yield* _plansCtrl.stream.map((plans) {
      final c = [...plans];
      c.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return c.take(limit).toList();
    });
  }

  @override
  Stream<int> watchPlansCount() async* {
    yield _plans.length; // immediate snapshot
    yield* _plansCountCtrl.stream; // then live updates
  }
}
