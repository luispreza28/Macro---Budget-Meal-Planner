import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/plan.dart';
import '../../domain/services/reminder_settings_service.dart';
import '../../domain/services/reminder_orchestrator.dart';
import '../../domain/widgets/home_widget_service.dart';
import '../providers/plan_providers.dart';
import '../providers/shopping_list_providers.dart';

final reminderSettingsProvider = FutureProvider<ReminderSettings>((ref) async {
  return ref.read(reminderSettingsServiceProvider).get();
});

final rescheduleRemindersProvider = FutureProvider.family<bool, Plan>((ref, plan) async {
  await ref.read(reminderOrchestratorProvider).rescheduleAll(plan: plan);
  await ref.read(homeWidgetServiceProvider).updateToday(plan: plan);
  return true;
});

/// Auto-rescheduler: listens for current plan changes and triggers reschedule.
/// Keep the side-effect setup small to avoid churn.
final reminderAutoReschedulerProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<Plan?>>(currentPlanProvider, (prev, next) async {
    final plan = next.valueOrNull;
    if (plan != null) {
      // fire-and-forget
      // ignore: unawaited_futures
      ref.read(rescheduleRemindersProvider(plan).future);
    }
  });
  // Also watch shopping list aggregation to refresh shop reminder/widget
  ref.listen<AsyncValue<List<dynamic>>>(
    shoppingListItemsProvider,
    (prev, next) async {
      final plan = ref.read(currentPlanProvider).asData?.value;
      if (plan != null) {
        // ignore: unawaited_futures
        ref.read(rescheduleRemindersProvider(plan).future);
      }
    },
  );
});
