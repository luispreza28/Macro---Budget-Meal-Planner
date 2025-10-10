import '../entities/ingredient.dart';
import '../entities/recipe.dart';

class RecipeDerived {
  const RecipeDerived({
    required this.kcalPerServ,
    required this.proteinGPerServ,
    required this.carbsGPerServ,
    required this.fatGPerServ,
    required this.costPerServCents,
  });

  final double kcalPerServ;
  final double proteinGPerServ;
  final double carbsGPerServ;
  final double fatGPerServ;
  final int costPerServCents;
}

class RecipeMath {
  static RecipeDerived compute({
    required Recipe recipe,
    required Map<String, Ingredient> ingredients,
  }) {
    final normalizedServings = recipe.servings <= 0 ? 1 : recipe.servings;
    final clampedServings = normalizedServings.clamp(1, 1000);
    final servingsDouble = clampedServings.toDouble();

    double totalCostCents = 0;
    double totalKcal = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    for (final item in recipe.items) {
      final ingredient = ingredients[item.ingredientId];
      if (ingredient == null) continue;

      final qtyInBase = _toIngredientUnit(
        qty: item.qty,
        from: item.unit,
        to: ingredient.unit,
      );

      totalCostCents += _computeCostCents(
        ingredient: ingredient,
        qtyInBaseUnit: qtyInBase,
      );

      final macros = _computeMacros(
        ingredient: ingredient,
        qtyInBaseUnit: qtyInBase,
      );
      totalKcal += macros.kcal;
      totalProtein += macros.proteinG;
      totalCarbs += macros.carbsG;
      totalFat += macros.fatG;
    }

    final perServKcal = totalKcal / servingsDouble;
    final perServProtein = totalProtein / servingsDouble;
    final perServCarbs = totalCarbs / servingsDouble;
    final perServFat = totalFat / servingsDouble;
    final perServCostCents = (totalCostCents / servingsDouble).round();

    return RecipeDerived(
      kcalPerServ: perServKcal.isFinite ? perServKcal : 0,
      proteinGPerServ: perServProtein.isFinite ? perServProtein : 0,
      carbsGPerServ: perServCarbs.isFinite ? perServCarbs : 0,
      fatGPerServ: perServFat.isFinite ? perServFat : 0,
      costPerServCents: perServCostCents,
    );
  }

  static double _toIngredientUnit({
    required double qty,
    required Unit from,
    required Unit to,
  }) {
    if (from == to) return qty;

    const densityGPerMl = 1.0;

    if (from == Unit.grams && to == Unit.milliliters) {
      return qty / densityGPerMl;
    }
    if (from == Unit.milliliters && to == Unit.grams) {
      return qty * densityGPerMl;
    }

    return qty;
  }

  static _MacroTotals _computeMacros({
    required Ingredient ingredient,
    required double qtyInBaseUnit,
  }) {
    if (qtyInBaseUnit <= 0) return const _MacroTotals.zero();

    if (ingredient.unit == Unit.grams || ingredient.unit == Unit.milliliters) {
      final per100Kcal =
          ingredient.nutritionPer100gKcal ?? ingredient.macrosPer100g.kcal;
      final per100Protein =
          ingredient.nutritionPer100gProteinG ??
          ingredient.macrosPer100g.proteinG;
      final per100Carbs =
          ingredient.nutritionPer100gCarbsG ?? ingredient.macrosPer100g.carbsG;
      final per100Fat =
          ingredient.nutritionPer100gFatG ?? ingredient.macrosPer100g.fatG;

      final hasAnyNutrition =
          per100Kcal > 0 ||
          per100Protein > 0 ||
          per100Carbs > 0 ||
          per100Fat > 0;
      if (!hasAnyNutrition) return const _MacroTotals.zero();

      final factor = qtyInBaseUnit / 100.0;
      return _MacroTotals(
        kcal: per100Kcal * factor,
        proteinG: per100Protein * factor,
        carbsG: per100Carbs * factor,
        fatG: per100Fat * factor,
      );
    }

    if (ingredient.unit == Unit.piece) {
      final perPieceKcal = ingredient.nutritionPerPieceKcal;
      final perPieceProtein = ingredient.nutritionPerPieceProteinG;
      final perPieceCarbs = ingredient.nutritionPerPieceCarbsG;
      final perPieceFat = ingredient.nutritionPerPieceFatG;

      final hasAnyNutrition =
          (perPieceKcal ?? 0) > 0 ||
          (perPieceProtein ?? 0) > 0 ||
          (perPieceCarbs ?? 0) > 0 ||
          (perPieceFat ?? 0) > 0;
      if (!hasAnyNutrition) return const _MacroTotals.zero();

      return _MacroTotals(
        kcal: (perPieceKcal ?? 0) * qtyInBaseUnit,
        proteinG: (perPieceProtein ?? 0) * qtyInBaseUnit,
        carbsG: (perPieceCarbs ?? 0) * qtyInBaseUnit,
        fatG: (perPieceFat ?? 0) * qtyInBaseUnit,
      );
    }

    return const _MacroTotals.zero();
  }

  static double _computeCostCents({
    required Ingredient ingredient,
    required double qtyInBaseUnit,
  }) {
    if (qtyInBaseUnit <= 0) return 0;

    if (ingredient.pricePerUnitCents > 0) {
      if (ingredient.unit == Unit.grams ||
          ingredient.unit == Unit.milliliters) {
        final unitsOfHundred = qtyInBaseUnit / 100.0;
        return unitsOfHundred * ingredient.pricePerUnitCents;
      }
      return qtyInBaseUnit * ingredient.pricePerUnitCents;
    }

    final packPrice = ingredient.purchasePack.priceCents;
    final packQty = ingredient.purchasePack.qty;
    if (packPrice != null && packPrice > 0 && packQty > 0) {
      final normalized = qtyInBaseUnit / packQty;
      return normalized * packPrice;
    }

    return 0;
  }
}

class _MacroTotals {
  const _MacroTotals({
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  const _MacroTotals.zero() : kcal = 0, proteinG = 0, carbsG = 0, fatG = 0;

  final double kcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
}
