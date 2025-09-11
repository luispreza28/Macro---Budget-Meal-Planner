import 'package:flutter_test/flutter_test.dart';
import 'package:macro_budget_meal_planner/domain/entities/ingredient.dart';
import 'package:macro_budget_meal_planner/domain/entities/recipe.dart';
import 'package:macro_budget_meal_planner/domain/entities/plan.dart';
import 'package:macro_budget_meal_planner/domain/entities/user_targets.dart';
import 'package:macro_budget_meal_planner/domain/usecases/macro_calculator.dart';

void main() {
  group('MacroCalculator', () {
    late MacroCalculator macroCalculator;

    setUp(() {
      macroCalculator = MacroCalculator();
    });

    group('calculateIngredientMacros', () {
      test('should calculate macros correctly for 100g', () {
        // Arrange
        final ingredient = Ingredient(
          id: 'chicken_breast',
          name: 'Chicken Breast',
          unit: Unit.grams,
          macrosPer100g: const MacrosPerHundred(
            kcal: 165,
            proteinG: 31,
            carbsG: 0,
            fatG: 3.6,
          ),
          pricePerUnitCents: 150,
          purchasePack: const PurchasePack(qty: 1000, unit: Unit.grams),
          aisle: Aisle.meat,
          tags: const ['high_protein', 'lean'],
          source: IngredientSource.seed,
        );

        // Act
        final result = macroCalculator.calculateIngredientMacros(
          ingredient: ingredient,
          quantity: 100,
          unit: Unit.grams,
        );

        // Assert
        expect(result.kcal, equals(165));
        expect(result.proteinG, equals(31));
        expect(result.carbsG, equals(0));
        expect(result.fatG, equals(3.6));
      });

      test('should calculate macros correctly for 200g', () {
        // Arrange
        final ingredient = Ingredient(
          id: 'rice',
          name: 'White Rice',
          unit: Unit.grams,
          macrosPer100g: const MacrosPerHundred(
            kcal: 130,
            proteinG: 2.7,
            carbsG: 28,
            fatG: 0.3,
          ),
          pricePerUnitCents: 50,
          purchasePack: const PurchasePack(qty: 1000, unit: Unit.grams),
          aisle: Aisle.pantry,
          tags: const ['cheap', 'bulk'],
          source: IngredientSource.seed,
        );

        // Act
        final result = macroCalculator.calculateIngredientMacros(
          ingredient: ingredient,
          quantity: 200,
          unit: Unit.grams,
        );

        // Assert
        expect(result.kcal, equals(260));
        expect(result.proteinG, equals(5.4));
        expect(result.carbsG, equals(56));
        expect(result.fatG, equals(0.6));
      });
    });

    group('calculateRecipeMacros', () {
      test('should calculate recipe macros from ingredients', () {
        // Arrange
        final chickenIngredient = Ingredient(
          id: 'chicken',
          name: 'Chicken Breast',
          unit: Unit.grams,
          macrosPer100g: const MacrosPerHundred(
            kcal: 165,
            proteinG: 31,
            carbsG: 0,
            fatG: 3.6,
          ),
          pricePerUnitCents: 150,
          purchasePack: const PurchasePack(qty: 1000, unit: Unit.grams),
          aisle: Aisle.meat,
          tags: const ['high_protein'],
          source: IngredientSource.seed,
        );

        final riceIngredient = Ingredient(
          id: 'rice',
          name: 'White Rice',
          unit: Unit.grams,
          macrosPer100g: const MacrosPerHundred(
            kcal: 130,
            proteinG: 2.7,
            carbsG: 28,
            fatG: 0.3,
          ),
          pricePerUnitCents: 50,
          purchasePack: const PurchasePack(qty: 1000, unit: Unit.grams),
          aisle: Aisle.pantry,
          tags: const ['cheap'],
          source: IngredientSource.seed,
        );

        final recipe = Recipe(
          id: 'chicken_rice',
          name: 'Chicken and Rice',
          servings: 4,
          timeMins: 30,
          dietFlags: const [],
          items: const [
            RecipeItem(ingredientId: 'chicken', qty: 400, unit: Unit.grams),
            RecipeItem(ingredientId: 'rice', qty: 200, unit: Unit.grams),
          ],
          steps: const ['Cook chicken', 'Cook rice', 'Combine'],
          macrosPerServ: const MacrosPerServing(kcal: 0, proteinG: 0, carbsG: 0, fatG: 0),
          costPerServCents: 0,
          source: RecipeSource.seed,
        );

        final ingredients = [chickenIngredient, riceIngredient];

        // Act
        final result = macroCalculator.calculateRecipeMacros(
          recipe: recipe,
          ingredients: ingredients,
        );

        // Assert
        // Total: 400g chicken (660 kcal, 124g protein, 14.4g fat) + 200g rice (260 kcal, 5.4g protein, 56g carbs, 0.6g fat)
        // Per serving (4 servings): 230 kcal, 32.35g protein, 14g carbs, 3.75g fat
        expect(result.kcal, closeTo(230, 1));
        expect(result.proteinG, closeTo(32.35, 0.1));
        expect(result.carbsG, equals(14));
        expect(result.fatG, closeTo(3.75, 0.1));
      });
    });

    group('calculateMacroError', () {
      test('should calculate macro error correctly', () {
        // Arrange
        const actual = MacrosPerServing(
          kcal: 2100,
          proteinG: 140,
          carbsG: 250,
          fatG: 70,
        );

        final targets = UserTargets(
          id: 'test',
          kcal: 2000,
          proteinG: 150,
          carbsG: 250,
          fatG: 67,
          mealsPerDay: 3,
          dietFlags: const [],
          equipment: const [],
          planningMode: PlanningMode.cutting,
        );

        // Act
        final result = macroCalculator.calculateMacroError(
          actual: actual,
          targets: targets,
        );

        // Assert
        // Error = |2100-2000| + |140-150|*2 + |250-250| + |70-67| = 100 + 20 + 0 + 3 = 123
        expect(result, equals(123));
      });

      test('should apply 2x penalty for under-protein', () {
        // Arrange
        const actual = MacrosPerServing(
          kcal: 2000,
          proteinG: 120, // Under target
          carbsG: 250,
          fatG: 67,
        );

        final targets = UserTargets(
          id: 'test',
          kcal: 2000,
          proteinG: 150,
          carbsG: 250,
          fatG: 67,
          mealsPerDay: 3,
          dietFlags: const [],
          equipment: const [],
          planningMode: PlanningMode.cutting,
        );

        // Act
        final result = macroCalculator.calculateMacroError(
          actual: actual,
          targets: targets,
        );

        // Assert
        // Error = 0 + |120-150|*2 + 0 + 0 = 60
        expect(result, equals(60));
      });
    });

    group('isDayMacrosAcceptable', () {
      test('should return true for acceptable macros', () {
        // Arrange
        final targets = UserTargets(
          id: 'test',
          kcal: 2000,
          proteinG: 150,
          carbsG: 250,
          fatG: 67,
          mealsPerDay: 3,
          dietFlags: const [],
          equipment: const [],
          planningMode: PlanningMode.cutting,
        );

        final recipe = Recipe(
          id: 'test_recipe',
          name: 'Test Recipe',
          servings: 1,
          timeMins: 30,
          dietFlags: const [],
          items: const [],
          steps: const [],
          macrosPerServ: const MacrosPerServing(
            kcal: 667, // 2000/3 meals
            proteinG: 50, // 150/3 meals
            carbsG: 83,
            fatG: 22,
          ),
          costPerServCents: 500,
          source: RecipeSource.seed,
        );

        final day = PlanDay(
          date: '2024-01-01',
          meals: const [
            PlanMeal(recipeId: 'test_recipe', servings: 1),
            PlanMeal(recipeId: 'test_recipe', servings: 1),
            PlanMeal(recipeId: 'test_recipe', servings: 1),
          ],
        );

        // Act
        final result = macroCalculator.isDayMacrosAcceptable(
          day: day,
          targets: targets,
          recipes: [recipe],
        );

        // Assert
        expect(result, isTrue);
      });

      test('should return false for unacceptable macros', () {
        // Arrange
        final targets = UserTargets(
          id: 'test',
          kcal: 2000,
          proteinG: 150,
          carbsG: 250,
          fatG: 67,
          mealsPerDay: 3,
          dietFlags: const [],
          equipment: const [],
          planningMode: PlanningMode.cutting,
        );

        final recipe = Recipe(
          id: 'test_recipe',
          name: 'Test Recipe',
          servings: 1,
          timeMins: 30,
          dietFlags: const [],
          items: const [],
          steps: const [],
          macrosPerServ: const MacrosPerServing(
            kcal: 300, // Too low
            proteinG: 30, // Too low
            carbsG: 40,
            fatG: 10,
          ),
          costPerServCents: 500,
          source: RecipeSource.seed,
        );

        final day = PlanDay(
          date: '2024-01-01',
          meals: const [
            PlanMeal(recipeId: 'test_recipe', servings: 1),
            PlanMeal(recipeId: 'test_recipe', servings: 1),
            PlanMeal(recipeId: 'test_recipe', servings: 1),
          ],
        );

        // Act
        final result = macroCalculator.isDayMacrosAcceptable(
          day: day,
          targets: targets,
          recipes: [recipe],
        );

        // Assert
        expect(result, isFalse);
      });
    });
  });
}
