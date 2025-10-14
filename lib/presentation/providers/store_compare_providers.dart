import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/services/trip_cost_service.dart';
import '../../domain/entities/ingredient.dart' as ing;
import '../providers/store_providers.dart';
import '../providers/shopping_list_providers.dart';
import '../providers/plan_providers.dart';
import '../providers/database_providers.dart';

final storeQuotesProvider = FutureProvider<List<StoreQuote>>((ref) async {
  final stores = await ref.watch(storeProfilesProvider.future);
  // selected may be null (baseline)
  await ref.watch(selectedStoreProvider.future);
  final groups = await ref.watch(shoppingListItemsProvider.future);

  // Build ingredient map and flat items list, filtering out checked for current plan
  final ingById = <String, ing.Ingredient>{};
  for (final g in groups) {
    for (final it in g.items) {
      ingById[it.ingredient.id] = it.ingredient;
    }
  }

  final plan = await ref.watch(currentPlanProvider.future);
  final prefs = ref.read(sharedPreferencesProvider);
  final checkedKey = plan?.id != null ? 'shopping_checked_${plan!.id}' : null;
  final checkedSet = checkedKey != null
      ? (prefs.getStringList(checkedKey) ?? const <String>[]).toSet()
      : const <String>{};

  final items = <({String ingredientId, double qty, ing.Unit unit})>[];
  for (final g in groups) {
    for (final it in g.items) {
      final key = '${it.ingredient.id}|${it.unit.name}';
      if (checkedSet.contains(key)) continue; // only items to buy
      items.add((ingredientId: it.ingredient.id, qty: it.totalQty, unit: it.unit));
    }
  }

  final svc = ref.read(tripCostServiceProvider);
  // Baseline (no store overrides)
  final baselineTotal = await svc.computeTripTotalCents(
    items: items,
    store: null,
    ingredientsById: ingById,
  );
  if (kDebugMode) {
    debugPrint('[TripCost] quote store=<baseline> total=$baselineTotal');
  }
  final baseline = StoreQuote(storeId: null, displayName: 'Baseline', totalCents: baselineTotal);

  final quotes = await svc.quoteAllStores(
    items: items,
    stores: stores,
    ingredientsById: ingById,
  );
  return [baseline, ...quotes];
});

final cheapestStoreQuoteProvider = FutureProvider<StoreQuote?>((ref) async {
  final quotes = await ref.watch(storeQuotesProvider.future);
  if (quotes.isEmpty) return null;
  final sorted = [...quotes]..sort((a, b) => a.totalCents.compareTo(b.totalCents));
  return sorted.first;
});

