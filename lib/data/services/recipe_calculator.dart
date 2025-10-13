import 'package:flutter/foundation.dart';
import '../../domain/entities/ingredient.dart';
import '../../domain/entities/recipe.dart';

class RecipeDerivedTotals {
  const RecipeDerivedTotals({
    required this.kcalPerServ,
    required this.proteinGPerServ,
    required this.carbsGPerServ,
    required this.fatGPerServ,
    required this.costCentsPerServ,
    required this.missingNutrition,
  });

  final double kcalPerServ;
  final double proteinGPerServ;
  final double carbsGPerServ;
  final double fatGPerServ;
  final int costCentsPerServ;
  final bool missingNutrition;
}

class RecipeCalculator {
  /// Computes per-serving totals from a recipe draft and ingredient catalog.
  static RecipeDerivedTotals compute({
    required Recipe recipe,
    required Map<String, Ingredient> ingredientsById,
    bool debug = false,
    List<String>? outMissingLines,
  }) {
    if (debug && kDebugMode) {
      debugPrint('[RecipeCalc] START recipe="${recipe.name}" '
          'servings=${recipe.servings} items=${recipe.items.length} '
          'ingCatalog=${ingredientsById.length}');
    }

    final _Acc acc = _Acc();

    for (final it in recipe.items) {
      _applyItem(it: it, ingCatalog: ingredientsById, acc: acc);
    }

    final servings = recipe.servings > 0 ? recipe.servings.toDouble() : 1.0;
    final result = RecipeDerivedTotals(
      kcalPerServ: acc.kcal / servings,
      proteinGPerServ: acc.proteinG / servings,
      carbsGPerServ: acc.carbsG / servings,
      fatGPerServ: acc.fatG / servings,
      costCentsPerServ: (acc.costCents / servings).round(),
      missingNutrition: acc.missing,
    );

    if (debug && kDebugMode) {
      debugPrint('[RecipeCalc] DONE perServ: '
          'kcal=${result.kcalPerServ} p=${result.proteinGPerServ} '
          'c=${result.carbsGPerServ} f=${result.fatGPerServ} '
          'costCents=${result.costCentsPerServ} missing=${acc.missing}');
    }
    return result;
  }

  static void _applyItem({
    required RecipeItem it,
    required Map<String, Ingredient> ingCatalog,
    required _Acc acc,
  }) {
    final ing = ingCatalog[it.ingredientId];
    if (ing == null) {
      debugPrint('[RecipeCalc]    ingredient not found for id=${it.ingredientId}');
      acc.missing = true;
      return;
    }

    final double qtyBase = _toBaseUnit(qty: it.qty, from: it.unit, to: ing.unit);
    if (kDebugMode) {
      debugPrint('[RecipeCalc]  ITEM id=${it.ingredientId} name="${ing.name}" '
          'qtyRaw=${it.qty} ${it.unit} -> qtyBase=$qtyBase ${ing.unit}');
    }

    // --- nutrition ---
    // Prefer per-piece overrides for piece-based ingredients when present
    final per100 = (ing.unit == Unit.piece && ing.perPieceAsNutrition != null)
        ? ing.perPieceAsNutrition
        : ing.per100;
    if (per100 == null) {
      debugPrint('[RecipeCalc]    macros: MISSING for "${ing.name}"');
      acc.missing = true;
    } else if (per100.kcal == 0 && per100.proteinG == 0 && per100.carbsG == 0 && per100.fatG == 0) {
      // Present structurally but all zeros — treat as missing
      debugPrint('[RecipeCalc]    macros: ZERO_VALUES for "${ing.name}"');
      acc.missing = true;
      // Do not add macros; still compute cost below.
    } else {
      double factor;
      switch (ing.unit) {
        case Unit.grams:
        case Unit.milliliters:
          factor = qtyBase / 100.0;
          break;
        case Unit.piece:
          // Treat per100 as "per piece" (see note).
          debugPrint('[RecipeCalc]    NOTE: unit=piece -> treat per100 as per piece');
          factor = qtyBase;
          break;
      }
      acc.kcal += per100.kcal * factor;
      acc.proteinG += per100.proteinG * factor;
      acc.carbsG += per100.carbsG * factor;
      acc.fatG += per100.fatG * factor;

      debugPrint('[RecipeCalc]    macros: per100=${per100.kcal}/${per100.proteinG}/${per100.carbsG}/${per100.fatG} '
          'factor=$factor add=(${per100.kcal * factor} kcal)');
    }

    // --- cost ---
    int ppuCents;
    if (ing.purchasePack.priceCents != null && ing.purchasePack.qty > 0) {
      ppuCents = (ing.purchasePack.priceCents! / ing.purchasePack.qty).round();
    } else {
      ppuCents = ing.pricePerUnitCents;
    }
    final addCents = (qtyBase * ppuCents).round();
    acc.costCents += addCents;

    debugPrint('[RecipeCalc]    cost: UNIT ppu=$ppuCents add=$addCents qtyBase=$qtyBase');
  }

  static double _toBaseUnit({
    required double qty,
    required Unit from,
    required Unit to,
  }) {
    if (from == to) return qty;

    // grams <-> ml: don’t convert without density; return as-is (log it)
    if ((from == Unit.grams && to == Unit.milliliters) ||
        (from == Unit.milliliters && to == Unit.grams)) {
      debugPrint('[RecipeCalc]    WARN: grams<->ml conversion skipped (no density). qty kept=$qty');
      return qty;
    }

    // piece <-> weight/volume: no mapping; return as-is (log it)
    if (from == Unit.piece || to == Unit.piece) {
      debugPrint('[RecipeCalc]    WARN: piece<->mass/vol conversion skipped. qty kept=$qty');
      return qty;
    }

    return qty;
  }
}

class _Acc {
  double kcal = 0;
  double proteinG = 0;
  double carbsG = 0;
  double fatG = 0;
  int costCents = 0;
  bool missing = false;
}
