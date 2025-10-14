import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/plan.dart';
import '../../domain/services/insights_service.dart';
import '../../domain/services/pantry_utilization_service.dart';
import '../providers/plan_providers.dart';
import '../providers/database_providers.dart';
import '../providers/recipe_providers.dart';

// Recent plans for insights (limit 6)
final insightsRecentPlansProvider = FutureProvider<List<Plan>>((ref) async {
  return ref.read(planRepositoryProvider).getRecentPlans(limit: 6);
});

final currentPlanNonNullProvider = FutureProvider<Plan>((ref) async {
  final p = await ref.watch(currentPlanProvider.future);
  if (p == null) throw StateError('No current plan');
  return p;
});

final insightsMacroProvider = FutureProvider<MacroAdherence>((ref) async {
  final plan = await ref.watch(currentPlanNonNullProvider.future);
  return ref.read(insightsServiceProvider).macroAdherence(plan);
});

final insightsBudgetProvider = FutureProvider<BudgetSummary>((ref) async {
  final plan = await ref.watch(currentPlanNonNullProvider.future);
  return ref.read(insightsServiceProvider).budgetSummary(plan);
});

final insightsPantryProvider = FutureProvider<PantryUsageSummary>((ref) async {
  final plan = await ref.watch(currentPlanNonNullProvider.future);
  return ref.read(insightsServiceProvider).pantryUsage(plan);
});

final insightsVarietyProvider = FutureProvider<VarietySummary>((ref) async {
  final plan = await ref.watch(currentPlanNonNullProvider.future);
  final history = await ref.watch(insightsRecentPlansProvider.future);
  return ref
      .read(insightsServiceProvider)
      .varietyScore(plan, history: history.where((p) => p.id != plan.id).toList());
});

final insightsTrendsProvider = FutureProvider<TrendsSummary>((ref) async {
  final plans = await ref.watch(insightsRecentPlansProvider.future);
  return ref.read(insightsServiceProvider).trends(plans.take(4).toList());
});

final insightsTopMoversProvider = FutureProvider<TopMovers>((ref) async {
  final plans = await ref.watch(insightsRecentPlansProvider.future);
  return ref.read(insightsServiceProvider).topMovers(plans);
});

// Quick Actions:
final anyShortfallsThisWeekProvider = FutureProvider<bool>((ref) async {
  final plan = await ref.watch(currentPlanNonNullProvider.future);
  for (final day in plan.days) {
    for (final meal in day.meals) {
      final r = await ref.read(recipeByIdProvider(meal.recipeId).future);
      if (r == null) continue;
      final util = await ref.read(pantryUtilizationServiceProvider).scoreRecipePantryUse(r);
      if (util.coverageRatio < 1.0) return true;
    }
  }
  return false;
});

