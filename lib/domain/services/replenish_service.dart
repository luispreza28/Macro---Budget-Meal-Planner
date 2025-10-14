import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../entities/ingredient.dart';
import '../repositories/pantry_repository.dart';
import '../repositories/shopping_list_repository.dart';
import '../../presentation/providers/database_providers.dart';
import '../../presentation/providers/ingredient_providers.dart';
import '../../presentation/providers/shortfall_providers.dart';
import '../../presentation/providers/shopping_list_providers.dart';
import '../../presentation/providers/pantry_providers.dart';

final replenishServiceProvider = Provider<ReplenishService>((ref) => ReplenishService(ref));

class ReplenishService {
  ReplenishService(this.ref);
  final Ref ref;

  /// Reads checked shopping items (optionally for a plan), aligns units, and merges into pantry.
  /// Returns a result summary for UX.
  Future<ReplenishResult> markPurchasedAndReplenish({String? planId, bool clearAfter = true}) async {
    // Load aggregated shopping items
    final grouped = await ref.read(shoppingListItemsProvider.future);
    // Load checked keys from prefs (persisted per-plan)
    final prefs = ref.read(sharedPreferencesProvider);
    if (kDebugMode) {
      debugPrint('[Replenish] checked=<${(prefs.getStringList('shopping_checked_${planId ?? ''}') ?? const <String>[]).length}> plan=<${planId ?? ''}>' );
    }
    final checkedKeys = (planId == null)
        ? <String>{}
        : (prefs.getStringList('shopping_checked_$planId')?.toSet() ?? <String>{});

    if (checkedKeys.isEmpty) {
      return const ReplenishResult(
        itemsProcessed: 0,
        itemsMerged: 0,
        mismatchesKept: 0,
        mismatchNotes: <String>[],
      );
    }

    // Build ingredient map for metadata (units/density)
    final ingredients = await ref.read(ingredientRepositoryProvider).getAllIngredients();
    final ingById = {for (final i in ingredients) i.id: i};

    // Flatten grouped items -> list and filter by checked keys
    final selected = <({String ingredientId, double qty, Unit unit})>[];
    for (final g in grouped) {
      for (final it in g.items) {
        final key = '${it.ingredient.id}|${it.unit.name}';
        if (checkedKeys.contains(key)) {
          selected.add((ingredientId: it.ingredient.id, qty: it.totalQty, unit: it.unit));
        }
      }
    }

    final mismatches = <String>[];
    final Map<String, double> deltaByIngredientBase = {};

    for (final s in selected) {
      final ing = ingById[s.ingredientId];
      if (ing == null) {
        mismatches.add('${s.ingredientId}: unknown ingredient');
        if (kDebugMode) {
          debugPrint('[Replenish] mismatch id=${s.ingredientId} reason=unknown ingredient');
        }
        continue;
      }

      final baseUnit = ing.unit;
      double? baseQty;
      if (s.unit == baseUnit) {
        baseQty = s.qty;
      } else if ((s.unit == Unit.grams && baseUnit == Unit.milliliters) ||
          (s.unit == Unit.milliliters && baseUnit == Unit.grams)) {
        final density = ing.densityGPerMl;
        if (density == null || density <= 0) {
          mismatches.add('${ing.name}: unit mismatch (needs density)');
          if (kDebugMode) {
            debugPrint('[Replenish] mismatch id=${ing.id} reason=unit mismatch (needs density)');
          }
          continue;
        }
        if (s.unit == Unit.grams && baseUnit == Unit.milliliters) {
          baseQty = s.qty / density; // g -> ml
        } else {
          baseQty = s.qty * density; // ml -> g
        }
        if (kDebugMode) {
          debugPrint('[Replenish] convert id=${ing.id} ${s.qty.toStringAsFixed(2)} ${s.unit.name} -> '
              '${baseQty.toStringAsFixed(2)} ${baseUnit.name} density=${density.toString()}');
        }
      } else if (s.unit == Unit.piece || baseUnit == Unit.piece) {
        // piece conversions via per-piece size
        final gpp = ing.gramsPerPiece;
        final mpp = ing.mlPerPiece;
        if (s.unit == Unit.piece && baseUnit == Unit.grams && gpp != null && gpp > 0) {
          baseQty = s.qty * gpp;
          if (kDebugMode) {
            debugPrint('[Replenish] piece conversion using gramsPerPiece: ${s.qty} pcs -> ${baseQty!.toStringAsFixed(2)} g');
          }
        } else if (s.unit == Unit.piece && baseUnit == Unit.milliliters && mpp != null && mpp > 0) {
          baseQty = s.qty * mpp;
          if (kDebugMode) {
            debugPrint('[Replenish] piece conversion using mlPerPiece: ${s.qty} pcs -> ${baseQty!.toStringAsFixed(2)} ml');
          }
        } else if (baseUnit == Unit.piece && s.unit == Unit.grams && gpp != null && gpp > 0) {
          baseQty = s.qty / gpp;
          if (kDebugMode) {
            debugPrint('[Replenish] piece conversion using gramsPerPiece: ${s.qty} g -> ${baseQty!.toStringAsFixed(2)} pcs');
          }
        } else if (baseUnit == Unit.piece && s.unit == Unit.milliliters && mpp != null && mpp > 0) {
          baseQty = s.qty / mpp;
          if (kDebugMode) {
            debugPrint('[Replenish] piece conversion using mlPerPiece: ${s.qty} ml -> ${baseQty!.toStringAsFixed(2)} pcs');
          }
        } else {
          mismatches.add('${ing.name}: unit mismatch (piece conversion needs size)');
          if (kDebugMode) {
            debugPrint('[Replenish] mismatch id=${ing.id} reason=piece conversion needs gramsPerPiece/mlPerPiece');
          }
          continue;
        }
      } else {
        // Other unknown mismatch
        mismatches.add('${ing.name}: unit mismatch');
        if (kDebugMode) {
          debugPrint('[Replenish] mismatch id=${ing.id} reason=unit mismatch');
        }
        continue;
      }

      final acc = (deltaByIngredientBase[ing.id] ?? 0) + (baseQty ?? 0);
      deltaByIngredientBase[ing.id] = acc;
    }

    final deltas = <({String ingredientId, double qty, Unit unit})>[];
    deltaByIngredientBase.forEach((id, qty) {
      final ing = ingById[id];
      if (ing != null && qty > 0) {
        deltas.add((ingredientId: id, qty: qty, unit: ing.unit));
      }
    });

    final pantryRepo = ref.read(pantryRepositoryProvider);
    final mergedCount = await pantryRepo.addOnHandDeltas(deltas);

    if (clearAfter && planId != null) {
      // Clear all checked items for the plan
      final shoppingRepo = ref.read(shoppingListRepositoryProvider);
      await shoppingRepo.clearCheckedItems(planId: planId);
    }

    // Invalidate dependent providers for UI refresh
    ref.invalidate(shortfallForCurrentPlanProvider);
    ref.invalidate(allPantryItemsProvider);
    ref.invalidate(pantryItemsCountProvider);
    ref.invalidate(shoppingListItemsProvider);

    if (kDebugMode) {
      debugPrint('[Replenish] merged=$mergedCount mismatches=${mismatches.length}');
    }

    return ReplenishResult(
      itemsProcessed: selected.length,
      itemsMerged: mergedCount,
      mismatchesKept: mismatches.length,
      mismatchNotes: mismatches,
    );
  }
}

class ReplenishResult {
  final int itemsProcessed;
  final int itemsMerged; // successfully merged into pantry
  final int mismatchesKept; // piece<->mass/vol, or g<->ml without density
  final List<String> mismatchNotes; // e.g., "olive_oil: unit mismatch (needs density)"
  const ReplenishResult({
    required this.itemsProcessed,
    required this.itemsMerged,
    required this.mismatchesKept,
    required this.mismatchNotes,
  });
}
