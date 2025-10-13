import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/plan_pin_service.dart';
import 'plan_providers.dart';

final pinsForCurrentPlanProvider = FutureProvider<Map<String, String>>((ref) async {
  final plan = await ref.watch(currentPlanProvider.future);
  if (plan == null) return {};
  final svc = ref.read(planPinServiceProvider);
  return svc.getPins(plan.id);
});

