import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/prepared_inventory_service.dart';

final preparedServingsProvider = FutureProvider.family<int, String>((ref, recipeId) async {
  // prune expired opportunistically
  await ref.read(preparedInventoryServiceProvider).removeExpired();
  return ref.read(preparedInventoryServiceProvider).availableServings(recipeId);
});

final preparedEntriesProvider = FutureProvider.family<List<PreparedEntry>, String>((ref, recipeId) async {
  await ref.read(preparedInventoryServiceProvider).removeExpired();
  return ref.read(preparedInventoryServiceProvider).forRecipe(recipeId);
});

