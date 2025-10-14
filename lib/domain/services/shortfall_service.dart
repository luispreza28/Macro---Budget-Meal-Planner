import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../entities/ingredient.dart';
import '../entities/recipe.dart';
import '../repositories/ingredient_repository.dart';
import '../repositories/pantry_repository.dart';
import 'unit_align.dart';

final shortfallServiceProvider = Provider<ShortfallService>((ref) => ShortfallService(ref));

class ShortfallService {
  ShortfallService(this.ref);
  final Ref ref;

  /// Computes per-item shortfalls for a given recipe & servings in the current plan context.
  /// Aligns units using density and per-piece size as available.
  Future<MealShortfall> compute({
    required Recipe recipe,
    required int servingsForMeal,
    Map<String, Ingredient>? ingredientsById, // optional fast-path
  }) async {
    // Fast paths for repos we need
    final ingRepo = ref.read(ingredientRepositoryProvider);
    final pantryRepo = ref.read(pantryRepositoryProvider);

    // Build ingredient map (use provided or fetch minimal set)
    Map<String, Ingredient> ingById = ingredientsById ?? {};
    if (ingById.isEmpty) {
      final ids = recipe.items.map((e) => e.ingredientId).toSet().toList();
      final all = await ingRepo.getIngredientsByIds(ids);
      ingById = {for (final i in all) i.id: i};
    }

    // Pantry on-hand aggregated in ingredient base unit (impl guarantees base-unit only)
    final onHandMap = await pantryRepo.getOnHand(); // id -> (qty, unit)

    final lines = <ShortfallLine>[];
    double sumRequired = 0;
    double sumCovered = 0;

    for (final it in recipe.items) {
      final ing = ingById[it.ingredientId];
      if (ing == null) {
        // Unknown ingredient: treat as full remaining in its own unit; on-hand 0
        final reqQty = it.qty * servingsForMeal / recipe.servings;
        sumRequired += reqQty;
        lines.add(
          ShortfallLine(
            ingredientId: it.ingredientId,
            ingredientName: it.ingredientId,
            requiredQty: _round1(reqQty),
            onHandQty: 0,
            remainingQty: _round1(reqQty),
            displayUnit: it.unit,
            unitMismatch: true,
          ),
        );
        continue;
      }

      // Required qty for this meal
      final requiredQty = it.qty * (servingsForMeal / recipe.servings);

      // Convert pantry base unit -> required unit if possible
      final on = onHandMap[ing.id];
      double onAligned = 0;
      bool mismatch = false;
      if (on != null && on.qty > 0) {
        if (on.unit == it.unit) {
          onAligned = on.qty;
        } else {
          final aligned = alignQty(qty: on.qty, from: on.unit, to: it.unit, ing: ing);
          if (aligned == null) {
            mismatch = true;
            onAligned = 0;
          } else {
            onAligned = aligned;
          }
        }
      }

      final covered = requiredQty <= 0 ? 0 : (onAligned >= requiredQty ? requiredQty : (onAligned < 0 ? 0 : onAligned));
      sumRequired += requiredQty;
      sumCovered += covered;

      final remaining = (requiredQty - onAligned);
      final rem = remaining > 0 ? remaining : 0;

      if (kDebugMode) {
        debugPrint('[ShortfallV2] ${ing.name} req=${requiredQty.toStringAsFixed(2)} ${it.unit.name} onHand=${onAligned.toStringAsFixed(2)} rem=${rem.toStringAsFixed(2)} mismatch=$mismatch');
      }

      if (rem > 1e-6) {
        lines.add(
          ShortfallLine(
            ingredientId: ing.id,
            ingredientName: ing.name,
            requiredQty: _round1(requiredQty),
            onHandQty: _round1(onAligned),
            remainingQty: _round1(rem),
            displayUnit: it.unit,
            unitMismatch: mismatch,
          ),
        );
      }
    }

    final coverage = (sumRequired <= 0) ? 1.0 : (sumCovered / sumRequired).clamp(0.0, 1.0);
    return MealShortfall(
      coverageRatio: coverage,
      lines: lines,
      notes: const [],
    );
  }

  double _round1(double v) => ((v * 10).round() / 10.0);
}

/// Per-meal shortfall model
class MealShortfall {
  final double coverageRatio; // 0..1 across all items
  final List<ShortfallLine> lines; // only lines with remaining > 0
  final List<String> notes; // unit mismatch, missing nutrition, etc.
  const MealShortfall({required this.coverageRatio, required this.lines, required this.notes});
}

/// One line: delta needed to make this meal at the given servings.
class ShortfallLine {
  final String ingredientId;
  final String ingredientName;
  final double requiredQty; // in displayUnit (aligned)
  final double onHandQty; // in displayUnit
  final double remainingQty; // required - onHand (>=0)
  final Unit displayUnit; // best aligned unit for UX
  final bool unitMismatch; // true if could not convert on-hand to required
  const ShortfallLine({
    required this.ingredientId,
    required this.ingredientName,
    required this.requiredQty,
    required this.onHandQty,
    required this.remainingQty,
    required this.displayUnit,
    required this.unitMismatch,
  });
}

