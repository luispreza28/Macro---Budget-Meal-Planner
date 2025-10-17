import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/services/replenishment_engine.dart';
import '../../domain/services/shopping_extras_service.dart';
import '../../presentation/providers/recipe_providers.dart';
import '../../presentation/providers/shopping_list_providers.dart';
import '../../domain/services/split_shopping_prefs.dart';

// Bump to trigger recompute when Par prefs change
final replenishmentPrefsVersionProvider = StateProvider<int>((_) => 0);

final replenishmentSuggestionsProvider =
    FutureProvider.family<List<RestockSuggestion>, Plan>((ref, plan) async {
  // ensure invalidation when prefs change
  ref.watch(replenishmentPrefsVersionProvider);
  return ref
      .read(replenishmentEngineProvider)
      .computeSuggestions(plan: plan, horizonDays: 10);
});

final addSuggestionToShoppingProvider =
    FutureProvider.family<bool, (String planId, RestockSuggestion s)>((ref, arg) async {
  final (planId, s) = arg;
  final extras = ref.read(shoppingExtrasServiceProvider);
  await extras.add(
    planId,
    ExtraLine(
      id: const Uuid().v4(),
      ingredientId: s.ingredientId,
      qty: s.qty,
      unit: s.unit,
      storeId: s.storeId,
      reason: 'Restock: ${s.reason}',
    ),
  );
  // Respect Split Shopping: lock line to suggested store if present
  final storeId = s.storeId;
  if (storeId != null && storeId.isNotEmpty) {
    final lineId = '${s.ingredientId}|${s.unit.name}';
    await ref.read(splitPrefsServiceProvider).setLock(planId, lineId, storeId);
  }
  // Invalidate shopping list so new extras appear
  ref.invalidate(shoppingListItemsProvider);
  return true;
});

