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
      debugPrint('[RecipeCalc] START recipe="${recipe.name}" servings=${recipe.servings} items=${recipe.items.length} ingCatalog=${ingredientsById.length}');
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
      debugPrint('[RecipeCalc] DONE perServ: kcal=${result.kcalPerServ} p=${result.proteinGPerServ} c=${result.carbsGPerServ} f=${result.fatGPerServ} costCents=${result.costCentsPerServ} missing=${acc.missing}');
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
      if (kDebugMode) debugPrint('[RecipeCalc]    ingredient not found for id=${it.ingredientId}');
      acc.missing = true;
      return;
    }
    final double qtyBase = _toBaseUnit(qty: it.qty, from: it.unit, to: ing.unit, ingredient: ing);
    if (kDebugMode) {
      debugPrint('[RecipeCalc]  ITEM id=${it.ingredientId} name="${ing.name}" qtyRaw=${it.qty} ${it.unit} -> qtyBase=$qtyBase ${ing.unit}');
    }

    // --- nutrition ---
    // Piece logic: use per-piece if present; else fallback via piece size to per-100; else mark missing.
    if (ing.unit == Unit.piece) {
      final perPiece = ing.perPieceAsNutrition;
      if (perPiece != null) {
        final factor = qtyBase; // pieces
        if (kDebugMode) {
          debugPrint('[RecipeCalc]    piece macros: using perPiece=${perPiece.kcal}/${perPiece.proteinG}/${perPiece.carbsG}/${perPiece.fatG} factor=$factor');
        }
        acc.kcal += perPiece.kcal * factor;
        acc.proteinG += perPiece.proteinG * factor;
        acc.carbsG += perPiece.carbsG * factor;
        acc.fatG += perPiece.fatG * factor;
      } else {
        final per100 = ing.per100; // per-100 g/ml
        if (per100 == null) {
          if (kDebugMode) debugPrint('[RecipeCalc]    piece macros: MISSING (no per-100 available)');
          acc.missing = true;
        } else {
          double? baseAmount; // grams or ml
          if ((ing.gramsPerPiece ?? 0) > 0) {
            baseAmount = qtyBase * (ing.gramsPerPiece ?? 0);
            if (kDebugMode) {
              debugPrint('[RecipeCalc]    piece macros: fallback via size=gramsPerPiece=${ing.gramsPerPiece} -> ${baseAmount.toStringAsFixed(2)}g');
              debugPrint('[RecipeCalc] piece macros: using perPiece=... | fallback via size=... | MISSING');
            }
          } else if ((ing.mlPerPiece ?? 0) > 0) {
            baseAmount = qtyBase * (ing.mlPerPiece ?? 0);
            if (kDebugMode) {
              debugPrint('[RecipeCalc]    piece macros: fallback via size=mlPerPiece=${ing.mlPerPiece} -> ${baseAmount.toStringAsFixed(2)}ml');
              debugPrint('[RecipeCalc] piece macros: using perPiece=... | fallback via size=... | MISSING');
            }
          }
          if (baseAmount == null) {
            if (kDebugMode) debugPrint('[RecipeCalc] piece macros: MISSING');
            acc.missing = true;
          } else {
            final factor = baseAmount / 100.0;
            acc.kcal += per100.kcal * factor;
            acc.proteinG += per100.proteinG * factor;
            acc.carbsG += per100.carbsG * factor;
            acc.fatG += per100.fatG * factor;
            if (kDebugMode) {
              debugPrint('[RecipeCalc]    macros: per100=${per100.kcal}/${per100.proteinG}/${per100.carbsG}/${per100.fatG} factor=$factor');
            }
          }
        }
      }
    } else {
      final per100 = ing.per100;
      if (per100 == null) {
        if (kDebugMode) debugPrint('[RecipeCalc]    macros: MISSING for "${ing.name}"');
        acc.missing = true;
      } else if (per100.kcal == 0 && per100.proteinG == 0 && per100.carbsG == 0 && per100.fatG == 0) {
        if (kDebugMode) debugPrint('[RecipeCalc]    macros: ZERO_VALUES for "${ing.name}"');
        acc.missing = true;
      } else {
        final factor = qtyBase / 100.0;
        acc.kcal += per100.kcal * factor;
        acc.proteinG += per100.proteinG * factor;
        acc.carbsG += per100.carbsG * factor;
        acc.fatG += per100.fatG * factor;
        if (kDebugMode) {
          debugPrint('[RecipeCalc]    macros: per100=${per100.kcal}/${per100.proteinG}/${per100.carbsG}/${per100.fatG} factor=$factor');
        }
      }
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

    if (kDebugMode) debugPrint('[RecipeCalc]    cost: UNIT ppu=$ppuCents add=$addCents qtyBase=$qtyBase');
  }

  static double _toBaseUnit({
    required double qty,
    required Unit from,
    required Unit to,
    required Ingredient ingredient,
  }) {
    if (from == to) return qty;

    // grams <-> ml: don't convert without density; return as-is (log it)
    if ((from == Unit.grams && to == Unit.milliliters) ||
        (from == Unit.milliliters && to == Unit.grams)) {
      final d = ingredient.densityGPerMl;
      if (d != null && d > 0) {
        final toQty = (from == Unit.grams && to == Unit.milliliters) ? (qty / d) : (qty * d);
        if (kDebugMode) {
          debugPrint('[RecipeCalc]    CONVERT g<->ml using density=${d.toStringAsFixed(3)} : ${qty.toStringAsFixed(2)}${from.name} -> ${toQty.toStringAsFixed(2)}${to.name}');
        }
        return toQty;
      } else {
        if (kDebugMode) debugPrint('[RecipeCalc]    WARN: grams<->ml conversion skipped (no density). qty kept=$qty');
        return qty;
      }
    }

    // piece <-> grams via gramsPerPiece
    if ((from == Unit.piece && to == Unit.grams) || (from == Unit.grams && to == Unit.piece)) {
      final gpp = ingredient.gramsPerPiece;
      if (gpp != null && gpp > 0) {
        final toQty = (from == Unit.piece && to == Unit.grams) ? (qty * gpp) : (qty / gpp);
        if (kDebugMode) {
          debugPrint('[RecipeCalc] CONVERT piece<->g using gramsPerPiece=$gpp : ${qty.toStringAsFixed(2)}${from.name} -> ${toQty.toStringAsFixed(2)}${to.name}');
        }
        return toQty;
      } else {
        if (kDebugMode) debugPrint('[RecipeCalc] WARN: piece<->g conversion skipped (no gramsPerPiece). qty kept=$qty');
        return qty;
      }
    }

    // piece <-> milliliters via mlPerPiece
    if ((from == Unit.piece && to == Unit.milliliters) || (from == Unit.milliliters && to == Unit.piece)) {
      final mpp = ingredient.mlPerPiece;
      if (mpp != null && mpp > 0) {
        final toQty = (from == Unit.piece && to == Unit.milliliters) ? (qty * mpp) : (qty / mpp);
        if (kDebugMode) {
          debugPrint('[RecipeCalc] CONVERT piece<->ml using mlPerPiece=$mpp : ${qty.toStringAsFixed(2)}${from.name} -> ${toQty.toStringAsFixed(2)}${to.name}');
        }
        return toQty;
      } else {
        if (kDebugMode) debugPrint('[RecipeCalc] WARN: piece<->ml conversion skipped (no mlPerPiece). qty kept=$qty');
        return qty;
      }
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

