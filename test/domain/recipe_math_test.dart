import 'package:flutter_test/flutter_test.dart';

import 'package:macro_budget_meal_planner/domain/entities/ingredient.dart';
import 'package:macro_budget_meal_planner/domain/entities/recipe.dart';
import 'package:macro_budget_meal_planner/domain/services/recipe_math.dart';

void main() {
  group('RecipeMath.compute', () {
    test('computes per serving macros and cost for gram-based ingredients', () {
      const chicken = Ingredient(
        id: 'chicken',
        name: 'Chicken breast',
        unit: Unit.grams,
        macrosPer100g: MacrosPerHundred(
          kcal: 165,
          proteinG: 31,
          carbsG: 0,
          fatG: 3.6,
        ),
        pricePerUnitCents: 220,
        purchasePack: PurchasePack(qty: 454, unit: Unit.grams, priceCents: 999),
        aisle: Aisle.meat,
        tags: ['protein'],
        source: IngredientSource.manual,
      );
      const rice = Ingredient(
        id: 'rice',
        name: 'Brown rice',
        unit: Unit.grams,
        macrosPer100g: MacrosPerHundred(
          kcal: 360,
          proteinG: 7,
          carbsG: 79,
          fatG: 0.6,
        ),
        pricePerUnitCents: 130,
        purchasePack: PurchasePack(
          qty: 1000,
          unit: Unit.grams,
          priceCents: 1200,
        ),
        aisle: Aisle.pantry,
        tags: ['carb'],
        source: IngredientSource.manual,
      );

      final recipe = Recipe(
        id: 'r1',
        name: 'Chicken and Rice Bowl',
        servings: 2,
        timeMins: 30,
        cuisine: null,
        dietFlags: const [],
        items: const [
          RecipeItem(ingredientId: 'chicken', qty: 200, unit: Unit.grams),
          RecipeItem(ingredientId: 'rice', qty: 150, unit: Unit.grams),
        ],
        steps: const [],
        macrosPerServ: const MacrosPerServing(
          kcal: 0,
          proteinG: 0,
          carbsG: 0,
          fatG: 0,
        ),
        costPerServCents: 0,
        source: RecipeSource.manual,
      );

      final derived = RecipeMath.compute(
        recipe: recipe,
        ingredients: {'chicken': chicken, 'rice': rice},
      );

      expect(derived.costPerServCents, 318);
      expect(derived.kcalPerServ, closeTo(435, 0.1));
      expect(derived.proteinGPerServ, closeTo(36.25, 0.01));
      expect(derived.carbsGPerServ, closeTo(59.25, 0.01));
      expect(derived.fatGPerServ, closeTo(4.05, 0.01));
    });

    test('handles piece units and purchase pack fallback', () {
      const egg = Ingredient(
        id: 'egg',
        name: 'Large egg',
        unit: Unit.piece,
        macrosPer100g: MacrosPerHundred(
          kcal: 0,
          proteinG: 0,
          carbsG: 0,
          fatG: 0,
        ),
        pricePerUnitCents: 25,
        purchasePack: PurchasePack(qty: 12, unit: Unit.piece, priceCents: 300),
        aisle: Aisle.dairy,
        tags: ['protein'],
        source: IngredientSource.manual,
        nutritionPerPieceKcal: 70,
        nutritionPerPieceProteinG: 6,
        nutritionPerPieceCarbsG: 0.6,
        nutritionPerPieceFatG: 4.8,
      );
      const broth = Ingredient(
        id: 'broth',
        name: 'Vegetable broth',
        unit: Unit.milliliters,
        macrosPer100g: MacrosPerHundred(
          kcal: 0,
          proteinG: 0,
          carbsG: 0,
          fatG: 0,
        ),
        pricePerUnitCents: 0,
        purchasePack: PurchasePack(
          qty: 1000,
          unit: Unit.milliliters,
          priceCents: 400,
        ),
        aisle: Aisle.pantry,
        tags: ['broth'],
        source: IngredientSource.manual,
      );

      final recipe = Recipe(
        id: 'r2',
        name: 'Soft eggs in broth',
        servings: 1,
        timeMins: 10,
        cuisine: null,
        dietFlags: const [],
        items: const [
          RecipeItem(ingredientId: 'egg', qty: 2, unit: Unit.piece),
          RecipeItem(ingredientId: 'broth', qty: 250, unit: Unit.milliliters),
        ],
        steps: const [],
        macrosPerServ: const MacrosPerServing(
          kcal: 0,
          proteinG: 0,
          carbsG: 0,
          fatG: 0,
        ),
        costPerServCents: 0,
        source: RecipeSource.manual,
      );

      final derived = RecipeMath.compute(
        recipe: recipe,
        ingredients: {'egg': egg, 'broth': broth},
      );

      expect(derived.costPerServCents, 150);
      expect(derived.kcalPerServ, closeTo(140, 0.1));
      expect(derived.proteinGPerServ, closeTo(12, 0.01));
      expect(derived.carbsGPerServ, closeTo(1.2, 0.01));
      expect(derived.fatGPerServ, closeTo(9.6, 0.01));
    });
  });
}
