import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/route_prefs_service.dart';
import '../../presentation/providers/ingredient_providers.dart';
import '../../presentation/providers/recipe_providers.dart';
import '../../domain/services/store_profile_service.dart';
import '../../presentation/providers/store_providers.dart';

final instoreModeProvider = FutureProvider.family<String, String>((ref, planId) async {
  return ref.read(routePrefsServiceProvider).mode(planId); // 'normal'|'instore'
});

final showUncheckedOnlyProvider = FutureProvider.family<bool, String>((ref, planId) async {
  return ref.read(routePrefsServiceProvider).uncheckedOnly(planId);
});

final collapsedSectionsProvider = FutureProvider.family<Set<String>, String>((ref, planId) async {
  return ref.read(routePrefsServiceProvider).collapsed(planId);
});

/// Computes aisle order for the selected store (fallback to default Aisle enum order).
final routeAisleOrderProvider = FutureProvider<List<String>>((ref) async {
  // Ensure store providers are kept warm/reactive
  await ref.watch(storeProfilesProvider.future);
  final selected = await ref.watch(selectedStoreProvider.future);
  final order = (selected?.aisleOrder.isNotEmpty == true) ? selected!.aisleOrder : _defaultAisleOrder();
  return order;
});

List<String> _defaultAisleOrder() => const [
      'produce',
      'bakery',
      'meat',
      'dairy',
      'frozen',
      'pantry',
      'condiments',
      'household'
    ];

