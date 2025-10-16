import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/services/batch_session_service.dart';
import '../../presentation/providers/recipe_providers.dart';
import '../../presentation/providers/ingredient_providers.dart';

final batchSessionsProvider = FutureProvider<List<BatchSession>>((ref) async {
  return ref.read(batchSessionServiceProvider).list();
});

final batchSessionByIdProvider = FutureProvider.family<BatchSession?, String>((ref, id) async {
  return ref.read(batchSessionServiceProvider).byId(id);
});

/// Cost estimate helper for a session using ingredient pricing (approx, ignoring store overrides for v1)
final batchSessionCostCentsProvider = FutureProvider.family<int, BatchSession>((ref, s) async {
  final recipes = await ref.watch(allRecipesProvider.future);
  final ings = {for (final i in await ref.watch(allIngredientsProvider.future)) i.id: i};
  // 'ings' currently unused in naive cost, but we keep it watched for future refinement.
  int total = 0;
  for (final item in s.items) {
    final r = recipes.firstWhereOrNull((x) => x.id == item.recipeId);
    if (r == null) continue;
    total += (r.costPerServCents * item.targetServings);
  }
  return total;
});

String newSessionId() => const Uuid().v4();

