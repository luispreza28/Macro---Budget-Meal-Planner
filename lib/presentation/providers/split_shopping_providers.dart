import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/services/split_shopping_service.dart';
import '../../domain/services/split_shopping_prefs.dart';
import '../../domain/services/store_profile_service.dart';
import '../../domain/entities/ingredient.dart' as domain;
import '../../presentation/providers/ingredient_providers.dart';
import '../../presentation/providers/store_providers.dart';
import '../../presentation/providers/shopping_list_providers.dart';
import '../../presentation/providers/plan_providers.dart';
import '../../presentation/providers/database_providers.dart';

final splitModeProvider = FutureProvider.family<String, String>((ref, planId) async {
  return ref.read(splitPrefsServiceProvider).mode(planId);
});

final splitCapProvider = FutureProvider.family<int, String>((ref, planId) async {
  return ref.read(splitPrefsServiceProvider).cap(planId);
});

final splitLocksProvider = FutureProvider.family<Map<String, String>, String>((ref, planId) async {
  return ref.read(splitPrefsServiceProvider).locks(planId);
});

/// Computes assignments & totals for the current shopping list and store profiles.
final splitResultProvider = FutureProvider.family<SplitResult, String>((ref, planId) async {
  final mode = await ref.watch(splitModeProvider(planId).future);
  final cap = await ref.watch(splitCapProvider(planId).future);
  final locks = await ref.watch(splitLocksProvider(planId).future);
  final stores = await ref.watch(storeProfilesProvider.future);
  final selectedStore = await ref.watch(selectedStoreProvider.future);

  // Build ingredient map
  final ingsList = await ref.watch(allIngredientsProvider.future);
  final ings = {for (final i in ingsList) i.id: i};

  // Build ShoppingListLine[] from shoppingListItemsProvider, ignoring checked via prefs
  final groups = await ref.watch(shoppingListItemsProvider.future);

  // Checked set
  final prefs = ref.read(sharedPreferencesProvider);
  final checkedKey = 'shopping_checked_$planId';
  final checkedSet = (prefs.getStringList(checkedKey) ?? const <String>[]).toSet();

  final lines = <ShoppingListLine>[];
  for (final g in groups) {
    for (final it in g.items) {
      final id = '${it.ingredient.id}|${it.unit.name}';
      if (checkedSet.contains(id)) continue;
      lines.add(ShoppingListLine(
        id: id,
        ingredientId: it.ingredient.id,
        qty: it.totalQty,
        unit: it.unit,
      ));
    }
  }

  final svc = ref.read(splitShoppingServiceProvider);
  final capEff = (mode == 'single') ? 1 : (cap.clamp(1, 2));
  return svc.compute(
    planId: planId,
    lines: lines,
    ingredientsById: ings,
    stores: stores,
    selectedStoreId: selectedStore?.id,
    storeCap: capEff,
    locks: locks,
  );
});

