import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/price_history_service.dart';
import '../../domain/entities/plan.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/entities/ingredient.dart';
import '../../presentation/providers/ingredient_providers.dart';
import '../../presentation/providers/recipe_providers.dart';

final planCostEstimatorProvider = Provider<PlanCostEstimator>((ref) => PlanCostEstimator(ref));

class PlanCostEstimator {
  PlanCostEstimator(this.ref);
  final Ref ref;

  /// Estimate weekly plan cost in cents (price-aware per store if provided).
  /// Strategy:
  /// - For each recipe in plan: try recompute costPerServ using latest PPU per ingredient for the given storeId.
  /// - If missing history for an ingredient, fall back to recipe.costPerServCents contribution.
  Future<int> estimatePlanCostCents({
    required Plan plan,
    String? storeId, // if null, use per-ingredient latest across any store
  }) async {
    final ings = { for (final i in await ref.read(allIngredientsProvider.future)) i.id : i };
    final historySvc = ref.read(priceHistoryServiceProvider);

    int total = 0;
    for (final day in plan.days) {
      for (final meal in day.meals) {
        final r = await ref.read(recipeByIdProvider(meal.recipeId).future);
        if (r == null) continue;

        final priceAware = await estimateRecipeServCostCents(r, ings, historySvc, storeId);
        final fallback = r.costPerServCents;
        final perServ = priceAware ?? fallback;

        total += (perServ * meal.servings).round();
      }
    }
    return max(0, total);
  }

  /// Public for reuse by optimizer and swap drawer scoring.
  Future<int?> estimateRecipeServCostCents(
    Recipe recipe,
    Map<String, Ingredient> ings,
    PriceHistoryService svc,
    String? storeId,
  ) async {
    double cents = 0;
    for (final it in recipe.items) {
      final ing = ings[it.ingredientId];
      if (ing == null) return null;
      final points = await svc.list(ing.id);
      if (points.isEmpty) return null;
      // choose latest for storeId if provided; else latest overall
      final p = points
          .where((p) => storeId == null || p.storeId == storeId)
          .fold<PricePoint?>(null, (a,b)=> a==null || b.at.isAfter(a.at) ? b : a) ??
          points.last;
      final qtyBase = _qtyToBase(it, ing);
      if (qtyBase == null) return null;
      cents += (qtyBase * p.ppuCents);
    }
    return cents.round();
  }

  /// Convert recipe item quantity to the ingredient's base unit (g/ml or piece count) for pricing.
  /// Rules: grams<->ml requires density; piece conversions require per-piece size.
  double? _qtyToBase(RecipeItem it, Ingredient ing) {
    if (it.unit == ing.unit) {
      return it.qty; // already in base unit
    }
    // grams <-> ml: require density
    if ((it.unit == Unit.grams && ing.unit == Unit.milliliters) ||
        (it.unit == Unit.milliliters && ing.unit == Unit.grams)) {
      final d = ing.densityGPerMl;
      if (d == null || d <= 0) return null;
      if (it.unit == Unit.grams) {
        // g -> ml base
        return it.qty / d; // ml
      } else {
        // ml -> g base
        return it.qty * d; // g
      }
    }
    // piece conversions need per-piece metadata
    if (it.unit == Unit.piece) {
      if (ing.unit == Unit.grams && ing.gramsPerPiece != null) return it.qty * ing.gramsPerPiece!;
      if (ing.unit == Unit.milliliters && ing.mlPerPiece != null) return it.qty * ing.mlPerPiece!;
      // piece->piece is handled in early return; otherwise unknown
      return null;
    }
    if (ing.unit == Unit.piece) {
      // converting g/ml to pieces requires known per-piece size
      if (it.unit == Unit.grams && ing.gramsPerPiece != null && ing.gramsPerPiece! > 0) {
        return it.qty / ing.gramsPerPiece!;
      }
      if (it.unit == Unit.milliliters && ing.mlPerPiece != null && ing.mlPerPiece! > 0) {
        return it.qty / ing.mlPerPiece!;
      }
      return null;
    }
    if (kDebugMode) {
      debugPrint('[Budget] qtyToBase unsupported: item=${it.unit} ing=${ing.unit}');
    }
    return null;
  }
}

