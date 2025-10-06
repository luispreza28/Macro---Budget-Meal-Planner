import 'package:flutter_test/flutter_test.dart';
import 'package:macro_budget_meal_planner/core/utils/validators.dart';
import 'package:macro_budget_meal_planner/core/errors/validation_exceptions.dart';
import 'package:macro_budget_meal_planner/domain/entities/ingredient.dart';
import 'package:macro_budget_meal_planner/domain/entities/recipe.dart';
import 'package:macro_budget_meal_planner/domain/entities/user_targets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Validators Tests', () {
    group('Ingredient Validation', () {
      test('should validate correct ingredient', () {
        const validIngredient = Ingredient(
          id: 'test_ingredient',
          name: 'Test Ingredient',
          unit: Unit.grams,
          macrosPer100g: MacrosPerHundred(kcal: 100, proteinG: 20, carbsG: 10, fatG: 5),
          pricePerUnitCents: 200,
          purchasePack: PurchasePack(qty: 500, unit: Unit.grams),
          aisle: Aisle.meat,
          tags: ['test'],
          source: IngredientSource.seed,
        );

        expect(() => Validators.validateIngredient(validIngredient), returnsNormally);
      });

      test('should throw exception for empty ingredient ID', () {
        const invalidIngredient = Ingredient(
          id: '',
          name: 'Test Ingredient',
          unit: Unit.grams,
          macrosPer100g: MacrosPerHundred(kcal: 100, proteinG: 20, carbsG: 10, fatG: 5),
          pricePerUnitCents: 200,
          purchasePack: PurchasePack(qty: 500, unit: Unit.grams),
          aisle: Aisle.meat,
          tags: ['test'],
          source: IngredientSource.seed,
        );

        expect(
          () => Validators.validateIngredient(invalidIngredient),
          throwsA(isA<IngredientValidationException>()),
        );
      });

      test('should throw exception for negative calories', () {
        const invalidIngredient = Ingredient(
          id: 'test',
          name: 'Test Ingredient',
          unit: Unit.grams,
          macrosPer100g: MacrosPerHundred(kcal: -100, proteinG: 20, carbsG: 10, fatG: 5),
          pricePerUnitCents: 200,
          purchasePack: PurchasePack(qty: 500, unit: Unit.grams),
          aisle: Aisle.meat,
          tags: ['test'],
          source: IngredientSource.seed,
        );

        expect(
          () => Validators.validateIngredient(invalidIngredient),
          throwsA(isA<IngredientValidationException>()),
        );
      });
    });

    group('Recipe Validation', () {
      test('should validate correct recipe', () {
        const validRecipe = Recipe(
          id: 'test_recipe',
          name: 'Test Recipe',
          servings: 4,
          timeMins: 30,
          dietFlags: ['test'],
          items: [
            RecipeItem(ingredientId: 'ingredient1', qty: 100, unit: Unit.grams),
          ],
          steps: ['Step 1'],
          macrosPerServ: MacrosPerServing(kcal: 300, proteinG: 25, carbsG: 20, fatG: 10),
          costPerServCents: 250,
          source: RecipeSource.seed,
        );

        expect(() => Validators.validateRecipe(validRecipe), returnsNormally);
      });

      test('should throw exception for empty recipe items', () {
        const invalidRecipe = Recipe(
          id: 'test_recipe',
          name: 'Test Recipe',
          servings: 4,
          timeMins: 30,
          dietFlags: ['test'],
          items: [], // Empty items
          steps: ['Step 1'],
          macrosPerServ: MacrosPerServing(kcal: 300, proteinG: 25, carbsG: 20, fatG: 10),
          costPerServCents: 250,
          source: RecipeSource.seed,
        );

        expect(
          () => Validators.validateRecipe(invalidRecipe),
          throwsA(isA<RecipeValidationException>()),
        );
      });
    });

    group('UserTargets Validation', () {
      test('should validate correct user targets', () {
        const validTargets = UserTargets(
          id: 'test_targets',
          kcal: 2000,
          proteinG: 150,
          carbsG: 200,
          fatG: 67,
          budgetCents: 5000,
          mealsPerDay: 3,
          timeCapMins: 30,
          dietFlags: [],
          equipment: ['stove'],
          planningMode: PlanningMode.maintenance,
        );

        expect(() => Validators.validateUserTargets(validTargets), returnsNormally);
      });

      test('should throw exception for invalid meals per day', () {
        const invalidTargets = UserTargets(
          id: 'test_targets',
          kcal: 2000,
          proteinG: 150,
          carbsG: 200,
          fatG: 67,
          mealsPerDay: 1, // Invalid - should be 2-5
          dietFlags: [],
          equipment: ['stove'],
          planningMode: PlanningMode.maintenance,
        );

        expect(
          () => Validators.validateUserTargets(invalidTargets),
          throwsA(isA<UserTargetsValidationException>()),
        );
      });
    });

    group('Utility Validators', () {
      test('should validate email format', () {
        expect(Validators.isValidEmail('test@example.com'), true);
        expect(Validators.isValidEmail('invalid-email'), false);
        expect(Validators.isValidEmail(''), false);
      });

      test('should validate password strength', () {
        expect(Validators.isValidPassword('password123'), true);
        expect(Validators.isValidPassword('password'), false); // No number
        expect(Validators.isValidPassword('123'), false); // Too short
        expect(Validators.isValidPassword(''), false);
      });

      test('should validate positive numbers', () {
        expect(Validators.isPositiveNumber(5.0), true);
        expect(Validators.isPositiveNumber(0.1), true);
        expect(Validators.isPositiveNumber(0.0), false);
        expect(Validators.isPositiveNumber(-1.0), false);
      });

      test('should validate non-negative numbers', () {
        expect(Validators.isNonNegativeNumber(5.0), true);
        expect(Validators.isNonNegativeNumber(0.0), true);
        expect(Validators.isNonNegativeNumber(-1.0), false);
      });

      test('should validate string length', () {
        expect(Validators.isValidLength('test', minLength: 3, maxLength: 10), true);
        expect(Validators.isValidLength('te', minLength: 3), false);
        expect(Validators.isValidLength('verylongstring', maxLength: 10), false);
      });

      test('should validate number ranges', () {
        expect(Validators.isInRange(5.0, min: 0, max: 10), true);
        expect(Validators.isInRange(-1.0, min: 0), false);
        expect(Validators.isInRange(15.0, max: 10), false);
      });
    });
  });
}
