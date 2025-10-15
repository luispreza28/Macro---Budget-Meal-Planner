import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../entities/ingredient.dart' as domain;
import '../entities/recipe.dart';
import '../services/unit_align.dart';
import '../../presentation/providers/database_providers.dart';

final pantryDeductServiceProvider = Provider<PantryDeductService>((ref) => PantryDeductService(ref));

class PantryDeductService {
  PantryDeductService(this.ref);
  final Ref ref;

  /// Deducts pantry for a recipe scaled to servingsCooked. Returns map of ingredientId -> deducted base qty.
  Future<Map<String, double>> deductForCook({
    required Recipe recipe,
    required int servingsCooked,
    required Map<String, domain.Ingredient> ingredientsById,
  }) async {
    final deltas = <String, double>{};
    for (final it in recipe.items) {
      final ing = ingredientsById[it.ingredientId];
      if (ing == null) continue;
      final req = it.qty * (servingsCooked / recipe.servings);
      if (req <= 0) continue;
      // Convert required item qty to ingredient base for pantry ledger
      final toBase = alignQty(qty: req, from: it.unit, to: ing.unit, ing: ing);
      if (toBase == null) {
        if (kDebugMode) debugPrint('[CookDeduct] WARN unit mismatch for ${ing.id}');
        continue;
      }
      deltas[ing.id] = (deltas[ing.id] ?? 0) + toBase;
    }
    if (deltas.isEmpty) return deltas;
    // Apply to pantry repository as negative deltas
    final deltasList = deltas.entries
        .map((e) => (ingredientId: e.key, qty: -e.value, unit: ingredientsById[e.key]!.unit))
        .toList();
    await ref.read(pantryRepositoryProvider).addOnHandDeltas(deltasList);
    return deltas;
  }
}

