import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/services/plan_cost_service.dart';
import '../../domain/entities/plan.dart';
import '../providers/plan_providers.dart';
import '../providers/user_targets_providers.dart';

// Existing cost+targets view-model (kept for backward-compat in UI)
enum BudgetStatus { under, near, over }

class BudgetViewModel {
  final int weeklyTotalCents;
  final int? weeklyBudgetCents; // null => no budget set
  final BudgetStatus? status;   // null when budget is null
  final int? overageCents;      // only when status == over
  final double? utilization;    // 0..>1, only when budget present
  final List<int> perDayCents;  // length=7
  const BudgetViewModel({
    required this.weeklyTotalCents,
    required this.weeklyBudgetCents,
    required this.status,
    required this.overageCents,
    required this.utilization,
    required this.perDayCents,
  });
}

/// Summarize plan cost
final weeklyCostSummaryProvider = FutureProvider<PlanCostSummary>((ref) async {
  final plan = await ref.watch(currentPlanProvider.future);
  if (plan == null) {
    return const PlanCostSummary(weeklyTotalCents: 0, perDayCents: [0, 0, 0, 0, 0, 0, 0]);
  }
  final svc = ref.read(planCostServiceProvider);
  return svc.summarizePlanCost(plan);
});

const double _kNearBand = 0.10;

/// Combine cost + user budget to compute status
final budgetStatusProvider = FutureProvider<BudgetViewModel>((ref) async {
  final summary = await ref.watch(weeklyCostSummaryProvider.future);
  final targets = await ref.watch(currentUserTargetsProvider.future);
  final budgetCents = targets?.budgetCents; // weekly budget

  if (budgetCents == null || budgetCents <= 0) {
    return BudgetViewModel(
      weeklyTotalCents: summary.weeklyTotalCents,
      weeklyBudgetCents: null,
      status: null,
      overageCents: null,
      utilization: null,
      perDayCents: summary.perDayCents,
    );
  }

  final util = summary.weeklyTotalCents / budgetCents;
  final BudgetStatus status = util < (1 - _kNearBand)
      ? BudgetStatus.under
      : (util <= (1 + _kNearBand) ? BudgetStatus.near : BudgetStatus.over);
  final overage = status == BudgetStatus.over
      ? (summary.weeklyTotalCents - budgetCents)
      : 0;

  return BudgetViewModel(
    weeklyTotalCents: summary.weeklyTotalCents,
    weeklyBudgetCents: budgetCents,
    status: status,
    overageCents: status == BudgetStatus.over ? overage : null,
    utilization: util,
    perDayCents: summary.perDayCents,
  );
});

// New: SP-based Budget Guardrails v2
import '../../domain/services/budget_settings_service.dart';
import '../../domain/services/plan_cost_estimator.dart';

final budgetSettingsProvider = FutureProvider<BudgetSettings>((ref) async {
  return ref.read(budgetSettingsServiceProvider).get();
});

class BudgetStatusV2 {
  final int estimateCents;
  final int budgetCents;
  int get deltaCents => estimateCents - budgetCents;
  double get pct => budgetCents == 0 ? 0 : estimateCents / budgetCents;
  final String label;
  const BudgetStatusV2({required this.estimateCents, required this.budgetCents, required this.label});
}

final weeklyBudgetStatusProvider = FutureProvider.family<BudgetStatusV2, Plan>((ref, plan) async {
  final settings = await ref.watch(budgetSettingsProvider.future);
  final est = await ref.read(planCostEstimatorProvider).estimatePlanCostCents(
    plan: plan,
    storeId: settings.preferredStoreId,
  );
  final f = NumberFormat.simpleCurrency();
  return BudgetStatusV2(
    estimateCents: est,
    budgetCents: settings.weeklyBudgetCents,
    label: 'Est ${f.format(est/100)} / ${f.format(settings.weeklyBudgetCents/100)}',
  );
});

