import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../entities/ingredient.dart' as domain;
import '../entities/recipe.dart';
import 'density_service.dart';
import 'micros_overlay_service.dart';

class RecipeMicros {
  final double fiberGPerServ;
  final int sodiumMgPerServ;
  final double satFatGPerServ;
  const RecipeMicros({required this.fiberGPerServ, required this.sodiumMgPerServ, required this.satFatGPerServ});
}

final microCalculatorProvider = Provider<MicroCalculator>((ref) => MicroCalculator(ref));

class MicroCalculator {
  MicroCalculator(this.ref);
  final Ref ref;

  Future<RecipeMicros> compute({
    required Recipe recipe,
    required Map<String, domain.Ingredient> ingById,
    bool debug = false,
  }) async {
    final overlay = await ref.read(microsOverlayServiceProvider).getAll();
    double fiber = 0, satFat = 0;
    int sodium = 0;

    for (final it in recipe.items) {
      final ing = ingById[it.ingredientId];
      if (ing == null) continue;
      final side = overlay[ing.id];
      if (side == null) continue;

      final qtyBase = _toBase(qty: it.qty, from: it.unit, to: ing.unit, ing: ing);
      if (qtyBase == null) continue;

      double factor;
      switch (ing.unit) {
        case domain.Unit.grams:
        case domain.Unit.milliliters:
          factor = qtyBase / 100.0;
          break;
        case domain.Unit.piece:
          // Treat per-100 as per piece (v0 parity with macros calc)
          factor = qtyBase;
          break;
      }

      fiber += side.fiberG * factor;
      satFat += side.satFatG * factor;
      sodium += (side.sodiumMg * factor).round();

      if (debug && kDebugMode) {
        debugPrint('[Micros] calc ${ing.name} factor=$factor fiber+=${side.fiberG * factor} sat+=${side.satFatG * factor} sod+=${(side.sodiumMg * factor).round()}');
      }
    }

    final s = recipe.servings > 0 ? recipe.servings.toDouble() : 1.0;
    return RecipeMicros(
      fiberGPerServ: fiber / s,
      satFatGPerServ: satFat / s,
      sodiumMgPerServ: (sodium / s).round(),
    );
  }

  double? _toBase({required double qty, required domain.Unit from, required domain.Unit to, required domain.Ingredient ing}) {
    if (from == to) return qty;
    if ((from == domain.Unit.grams && to == domain.Unit.milliliters) ||
        (from == domain.Unit.milliliters && to == domain.Unit.grams)) {
      final res = DensityCache.tryResolve(ing);
      final d = res?.gPerMl;
      if (d != null && d > 0) {
        final toQty = (from == domain.Unit.grams && to == domain.Unit.milliliters) ? (qty / d) : (qty * d);
        return toQty;
      }
      return qty; // keep as-is if no density (parity with macros)
    }
    if (from == domain.Unit.piece || to == domain.Unit.piece) {
      return qty; // v0: keep as-is
    }
    return qty;
  }
}

