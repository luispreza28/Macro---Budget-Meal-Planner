import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/pantry_repository.dart';
import '../../presentation/providers/database_providers.dart';
import '../entities/ingredient.dart';
import '../entities/recipe.dart';

final pantryUtilizationServiceProvider = Provider<PantryUtilizationService>(
  (ref) => PantryUtilizationService(ref),
);

class PantryUtilizationService {
  PantryUtilizationService(this.ref);
  final Ref ref;

  /// Computes how much of a recipe's required items can be covered by on-hand pantry.
  /// Returns a score in 0..1 and a cost-savings estimate in cents (best-effort).
  Future<PantryUtilization> scoreRecipePantryUse(
    Recipe recipe, {
    Map<String, Ingredient>? ingredientsById, // optional fast-path
  }) async {
    final pantryRepo = ref.read(pantryRepositoryProvider);
    final onHand = await pantryRepo.getOnHand(); // ingredientId -> (qty, unit)

    if (recipe.items.isEmpty || onHand.isEmpty) {
      return const PantryUtilization(coverageRatio: 0, estimatedSavingsCents: 0);
    }

    double requiredTotal = 0.0;
    double coveredTotal = 0.0;
    double savingsCentsAcc = 0.0;

    for (final it in recipe.items) {
      final on = onHand[it.ingredientId];
      final ing = ingredientsById != null
          ? ingredientsById[it.ingredientId]
          : null; // best-effort when not provided

      final requiredQty = it.qty;
      requiredTotal += requiredQty;

      if (on == null) {
        if (kDebugMode) {
          debugPrint('[PantryUse] item=${it.ingredientId} need=${_fmt(requiredQty, it.unit)} onHand=0 ${it.unit.name} covered=0');
        }
        continue; // nothing on hand
      }

      // Try convert pantry qty into the item's unit
      final onHandInItemUnit = ing != null
          ? convertQty(on.qty, on.unit, it.unit, ing)
          : (on.unit == it.unit ? on.qty : null);

      if (onHandInItemUnit == null || onHandInItemUnit <= 0) {
        if (kDebugMode) {
          debugPrint('[PantryUse] item=${it.ingredientId} need=${_fmt(requiredQty, it.unit)} onHand=${_fmt(on.qty, on.unit)} covered=0');
        }
        continue;
      }

      final covered = onHandInItemUnit < requiredQty ? onHandInItemUnit : requiredQty;
      coveredTotal += covered;

      // Savings: covered qty converted to ingredient base unit * PPU cents
      if (ing != null) {
        final baseUnit = ing.unit;
        final coveredInBase = convertQty(covered, it.unit, baseUnit, ing);
        if (coveredInBase != null && coveredInBase > 0) {
          final ppu = _pricePerUnitCents(ing);
          // Align to pricing semantics: grams/ml are priced per 100 units; piece per piece
          final unitsForPricing = (baseUnit == Unit.piece)
              ? coveredInBase
              : (coveredInBase / 100.0);
          final add = unitsForPricing * ppu;
          if (add.isFinite) savingsCentsAcc += add;
        }
      }

      if (kDebugMode) {
        debugPrint('[PantryUse] item=${it.ingredientId} need=${_fmt(requiredQty, it.unit)} onHand=${_fmt(onHandInItemUnit, it.unit)} covered=${covered.toStringAsFixed(2)}');
      }
    }

    final coverage = requiredTotal > 0 ? (coveredTotal / requiredTotal).clamp(0.0, 1.0) : 0.0;
    final savings = savingsCentsAcc.isFinite ? savingsCentsAcc.round() : 0;

    if (kDebugMode) {
      debugPrint('[PantryUse] coverage=${coverage.toStringAsFixed(3)} savingsCents=$savings');
    }

    return PantryUtilization(
      coverageRatio: coverage,
      estimatedSavingsCents: savings,
    );
  }

  /// Utility to align units using density rules (g<->ml only if density present).
  /// Returns qty in `to` units or null if mismatch.
  double? convertQty(double qty, Unit from, Unit to, Ingredient ing) {
    if (from == to) return qty;
    // Never convert piece <-> mass/volume for now
    if (from == Unit.piece || to == Unit.piece) return null;

    // grams <-> milliliters via density
    final density = ing.densityGPerMl;
    if (density == null || density <= 0) return null;

    if (from == Unit.grams && to == Unit.milliliters) {
      return qty / density; // g -> ml
    }
    if (from == Unit.milliliters && to == Unit.grams) {
      return qty * density; // ml -> g
    }
    return null;
  }

  // Determine price per pricing unit cents for ingredient.
  // For grams/ml: return cents per 100 units. For piece: cents per piece.
  int _pricePerUnitCents(Ingredient ing) {
    // Prefer purchase pack if present and usable
    final pack = ing.purchasePack;
    final packPrice = pack.priceCents;
    if (packPrice != null && packPrice > 0) {
      // Convert pack qty to base unit if needed (respect unit rules)
      double? baseQty;
      if (pack.unit == ing.unit) {
        baseQty = pack.qty;
      } else {
        baseQty = convertQty(pack.qty, pack.unit, ing.unit, ing);
      }
      if (baseQty != null && baseQty > 0) {
        final unitsForPricing = (ing.unit == Unit.piece) ? baseQty : (baseQty / 100.0);
        if (unitsForPricing > 0) {
          return (packPrice / unitsForPricing).round();
        }
      }
    }
    // Fallback to ingredient's price per unit cents
    return ing.pricePerUnitCents;
  }

  String _fmt(double q, Unit u) => '${q.toStringAsFixed(2)} ${u.name}';
}

class PantryUtilization {
  final double coverageRatio; // fraction of total required qty covered by pantry (0..1)
  final int estimatedSavingsCents; // rough savings (cost not needing to be purchased)
  const PantryUtilization({required this.coverageRatio, required this.estimatedSavingsCents});
}