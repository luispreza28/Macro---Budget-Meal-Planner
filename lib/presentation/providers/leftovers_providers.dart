import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/leftovers_overlay_service.dart';
import '../../domain/services/leftovers_scheduler_service.dart';
import '../../domain/services/leftovers_inventory_service.dart';
import 'plan_providers.dart';

final autoLeftoversEnabledProvider = FutureProvider.family<bool, String>((ref, planWeekKey) async {
  return ref.read(leftoversOverlayServiceProvider).autoEnabled(planWeekKey);
});

final overlaysForWeekProvider = FutureProvider.family<List<LeftoverPlacement>, String>((ref, planWeekKey) async {
  return ref.read(leftoversOverlayServiceProvider).listFor(planWeekKey);
});

/// Computes a suggested schedule (not persisted) given current inventory and base plan.
final leftoverSuggestionsProvider =
    FutureProvider.family<List<LeftoverPlacement>, LeftoverSuggestionArgs>((ref, args) async {
  final svc = ref.read(leftoversSchedulerServiceProvider);
  final plan = await ref.watch(currentPlanProvider.future);
  if (plan == null) return const [];
  // Build meal slots facade from the base plan (7 days * meals per day)
  final slots = List.generate(plan.days.length, (d) {
    final meals = plan.days[d].meals;
    return List.generate(meals.length, (m) => MealSlot(meals[m].recipeId));
  });
  return svc.plan(
    planId: args.planId,
    weekStart: args.weekStart,
    basePlanSlots: slots,
    allowCrossWeekGrace: args.allowCrossWeekGrace,
  );
});

class LeftoverSuggestionArgs {
  final String planId;
  final DateTime weekStart;
  final bool allowCrossWeekGrace;
  const LeftoverSuggestionArgs({required this.planId, required this.weekStart, this.allowCrossWeekGrace = false});
}

