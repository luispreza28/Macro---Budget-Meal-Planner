import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/entities/plan.dart' as domain;
import '../../domain/repositories/plan_repository.dart';
import '../datasources/database.dart';
import '../services/local_storage_service.dart';

class PlanRepositoryImpl implements PlanRepository {
  PlanRepositoryImpl(this._db, this._local);

  final AppDatabase _db;
  final LocalStorageService _local;
  final StreamController<String?> _currentPlanIdController =
      StreamController<String?>.broadcast();

  @override
  Future<void> addPlan(domain.Plan plan) async {
    final companion = _toCompanion(plan, updatedAt: plan.createdAt);
    await _db.into(_db.plans).insertOnConflictUpdate(companion);
  }

  @override
  Future<void> savePlan(domain.Plan plan) => addPlan(plan);

  @override
  Future<void> updatePlan(domain.Plan plan) async {
    final companion = _toCompanion(plan, updatedAt: DateTime.now());
    await _db.update(_db.plans).replace(companion);
  }

  @override
  Future<void> deletePlan(String id) async {
    await (_db.delete(_db.plans)..where((tbl) => tbl.id.equals(id))).go();
  }

  @override
  Future<List<domain.Plan>> getAllPlans() async {
    final rows = await (_db.select(
      _db.plans,
    )..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)])).get();
    return rows.map(_mapRow).toList(growable: false);
  }

  @override
  Future<domain.Plan?> getPlanById(String id) async {
    final row = await (_db.select(
      _db.plans,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    return row == null ? null : _mapRow(row);
  }

  @override
  Future<domain.Plan?> getCurrentPlan() async {
    final currentId = _local.getCurrentPlanId();
    if (currentId != null && currentId.isNotEmpty) {
      final plan = await getPlanById(currentId);
      if (plan != null) {
        return plan;
      }
    }
    return _latestPlan();
  }

  @override
  Future<List<domain.Plan>> getRecentPlans({int limit = 10}) async {
    final rows =
        await (_db.select(_db.plans)
              ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)])
              ..limit(limit))
            .get();
    return rows.map(_mapRow).toList(growable: false);
  }

  @override
  Future<List<domain.Plan>> getPlansByUserTargetsId(
    String userTargetsId,
  ) async {
    final rows =
        await (_db.select(_db.plans)
              ..where((tbl) => tbl.userTargetsId.equals(userTargetsId))
              ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
            .get();
    return rows.map(_mapRow).toList(growable: false);
  }

  @override
  Future<void> setCurrentPlan(String planId) async {
    await _local.setCurrentPlanId(planId);
    _notifyCurrentPlanId(planId);
  }

  @override
  Future<void> clearCurrentPlan() async {
    await _local.clearCurrentPlanId();
    _notifyCurrentPlanId(null);
  }

  @override
  Future<List<domain.Plan>> getPlansInDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final rows =
        await (_db.select(_db.plans)
              ..where(
                (tbl) => tbl.createdAt.isBetweenValues(startDate, endDate),
              )
              ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]))
            .get();
    return rows.map(_mapRow).toList(growable: false);
  }

  @override
  Future<List<domain.Plan>> getPlansInBudgetRange({
    int? minBudgetCents,
    int? maxBudgetCents,
  }) async {
    final query = _db.select(_db.plans);
    if (minBudgetCents != null) {
      query.where(
        (tbl) => tbl.totalCostCents.isBiggerOrEqualValue(minBudgetCents),
      );
    }
    if (maxBudgetCents != null) {
      query.where(
        (tbl) => tbl.totalCostCents.isSmallerOrEqualValue(maxBudgetCents),
      );
    }
    query.orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]);
    final rows = await query.get();
    return rows.map(_mapRow).toList(growable: false);
  }

  @override
  Future<List<domain.Plan>> getBestScoringPlans({
    required double targetKcal,
    required double targetProteinG,
    required double targetCarbsG,
    required double targetFatG,
    int? budgetCents,
    required Map<String, double> weights,
    int limit = 10,
  }) async {
    final plans = await getAllPlans();
    final scored = plans
        .map(
          (plan) => MapEntry(
            plan,
            plan.calculateScore(
              targetKcal: targetKcal,
              targetProteinG: targetProteinG,
              targetCarbsG: targetCarbsG,
              targetFatG: targetFatG,
              budgetCents: budgetCents,
              weights: weights,
            ),
          ),
        )
        .toList();
    scored.sort((a, b) => a.value.compareTo(b.value));
    return scored.take(limit).map((entry) => entry.key).toList();
  }

  @override
  Future<bool> planExists(String id) async {
    final row =
        await (_db.selectOnly(_db.plans)
              ..addColumns([_db.plans.id])
              ..where(_db.plans.id.equals(id)))
            .getSingleOrNull();
    return row != null;
  }

  @override
  Future<int> getPlansCount() async {
    final countExpr = _db.plans.id.count();
    final row = await (_db.selectOnly(
      _db.plans,
    )..addColumns([countExpr])).getSingle();
    return row.read(countExpr) ?? 0;
  }

  @override
  Future<int> getActivePlansCount() async {
    final count = await getPlansCount();
    return count > 0 ? 1 : 0;
  }

  @override
  Future<void> cleanupOldPlans({int keepCount = 50}) async {
    // Normalize keepCount
    final safeKeep = keepCount < 0 ? 0 : keepCount;

    await _db.transaction(() async {
      // 1) Count total plans
      final totalCount = await (_db.selectOnly(_db.plans)
            ..addColumns([_db.plans.id.count()]))
          .map((row) => row.read(_db.plans.id.count()) ?? 0)
          .getSingle();

      // Nothing to do if <= safeKeep
      if (totalCount <= safeKeep) return;

      // 2) Collect IDs to KEEP (the newest `safeKeep` by createdAt DESC)
      final keepRows = await (_db.select(_db.plans)
            ..orderBy([(p) => OrderingTerm.desc(p.createdAt)])
            ..limit(safeKeep))
          .get();
      final keepIds = keepRows.map((r) => r.id).toSet();

      // 3) Collect IDs to DELETE (everything NOT in keepIds)
      //    (We fetch in a second query to avoid large offsets and to be explicit.)
      final allRows = await (_db.select(_db.plans)
            ..orderBy([(p) => OrderingTerm.desc(p.createdAt)]))
          .get();

      final idsToDelete = <String>[];
      for (final r in allRows) {
        if (!keepIds.contains(r.id)) {
          idsToDelete.add(r.id);
        }
      }

      if (idsToDelete.isEmpty) return;

      // 4) Safety: don’t delete the explicitly active plan if set in prefs
      //    (This ensures we never orphan the “current plan” marker.)
      final currentId = _local.getCurrentPlanId(); // LocalStorageService
      if (currentId != null && currentId.isNotEmpty) {
        idsToDelete.remove(currentId);
      }
      if (idsToDelete.isEmpty) return;

      // 5) Delete
      await (_db.delete(_db.plans)..where((tbl) => tbl.id.isIn(idsToDelete))).go();
    });
  }

  @override
  Future<Map<String, dynamic>> getPlanStatistics() async {
    final plans = await getAllPlans();
    if (plans.isEmpty) {
      return {'count': 0, 'avg_weekly_cost': 0.0};
    }
    final totalCost = plans.fold<int>(
      0,
      (sum, plan) => sum + plan.totals.costCents,
    );
    final avgWeeklyCost = totalCost / plans.length / 100.0;
    return {'count': plans.length, 'avg_weekly_cost': avgWeeklyCost};
  }

  @override
  Stream<List<domain.Plan>> watchAllPlans() {
    final query = (_db.select(_db.plans)
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)]));
    return query.watch().map(
      (rows) => rows.map(_mapRow).toList(growable: false),
    );
  }

  @override
  Stream<domain.Plan?> watchCurrentPlan() {
    StreamSubscription<String?>? markerSub;
    StreamSubscription<domain.Plan?>? planSub;
    late final StreamController<domain.Plan?> controller;

    void switchTo(String? id) {
      final previousSub = planSub;
      planSub = null;
      if (previousSub != null) {
        unawaited(previousSub.cancel());
      }

      if (id == null || id.isEmpty) {
        controller.add(null);
        return;
      }

      planSub = _watchPlanById(
        id,
      ).listen(controller.add, onError: controller.addError);
    }

    controller = StreamController<domain.Plan?>(
      onListen: () {
        switchTo(_local.getCurrentPlanId());
        markerSub = _currentPlanIdController.stream.listen(
          switchTo,
          onError: controller.addError,
        );
      },
      onCancel: () async {
        final futures = <Future<void>>[];
        final currentPlanSub = planSub;
        final currentMarkerSub = markerSub;
        planSub = null;
        markerSub = null;
        if (currentPlanSub != null) {
          futures.add(currentPlanSub.cancel());
        }
        if (currentMarkerSub != null) {
          futures.add(currentMarkerSub.cancel());
        }
        if (futures.isNotEmpty) {
          await Future.wait(futures);
        }
      },
    );

    return controller.stream;
  }

  @override
  Stream<List<domain.Plan>> watchRecentPlans({int limit = 10}) {
    final query = (_db.select(_db.plans)
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)])
      ..limit(limit));
    return query.watch().map(
      (rows) => rows.map(_mapRow).toList(growable: false),
    );
  }

  @override
  Stream<int> watchPlansCount() {
    return watchAllPlans().map((plans) => plans.length);
  }

  @override
  Stream<domain.Plan?> watchLatestPlan() {
    final query = (_db.select(_db.plans)
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)])
      ..limit(1));

    return query.watch().map(
      (rows) => rows.isEmpty ? null : _mapRow(rows.first),
    );
  }

  void _notifyCurrentPlanId(String? planId) {
    if (!_currentPlanIdController.isClosed) {
      _currentPlanIdController.add(planId);
    }
  }

  Future<domain.Plan?> _latestPlan() async {
    final query = (_db.select(_db.plans)
      ..orderBy([(tbl) => OrderingTerm.desc(tbl.createdAt)])
      ..limit(1));
    final row = await query.getSingleOrNull();
    return row == null ? null : _mapRow(row);
  }

  Stream<domain.Plan?> _watchPlanById(String id) {
    final query = (_db.select(_db.plans)
      ..where((tbl) => tbl.id.equals(id))
      ..limit(1));

    return query.watch().map(
      (rows) => rows.isEmpty ? null : _mapRow(rows.first),
    );
  }

  PlansCompanion _toCompanion(domain.Plan plan, {required DateTime updatedAt}) {
    final totals = plan.totals;
    final daysJson = jsonEncode(plan.days.map((day) => day.toJson()).toList());
    return PlansCompanion(
      id: Value(plan.id),
      name: Value(plan.name),
      userTargetsId: Value(plan.userTargetsId),
      days: Value(daysJson),
      totalKcal: Value(totals.kcal),
      totalProteinG: Value(totals.proteinG),
      totalCarbsG: Value(totals.carbsG),
      totalFatG: Value(totals.fatG),
      totalCostCents: Value(totals.costCents),
      createdAt: Value(plan.createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  domain.Plan _mapRow(Plan row) {
    final daysList = (jsonDecode(row.days) as List<dynamic>)
        .map(
          (entry) =>
              domain.PlanDay.fromJson(Map<String, dynamic>.from(entry as Map)),
        )
        .toList(growable: false);
    final totals = domain.PlanTotals(
      kcal: row.totalKcal,
      proteinG: row.totalProteinG,
      carbsG: row.totalCarbsG,
      fatG: row.totalFatG,
      costCents: row.totalCostCents,
    );
    return domain.Plan(
      id: row.id,
      name: row.name,
      userTargetsId: row.userTargetsId,
      days: daysList,
      totals: totals,
      createdAt: row.createdAt,
    );
  }
}

