import 'package:flutter_test/flutter_test.dart';
import 'package:macro_budget_meal_planner/domain/entities/recipe.dart';
import 'package:macro_budget_meal_planner/domain/entities/ingredient.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Recipe Entity Tests', () {
    late Recipe testRecipe;

    setUp(() {
      testRecipe = const Recipe(
        id: 'test_recipe',
        name: 'Test Recipe',
        servings: 4,
        timeMins: 30,
        cuisine: 'American',
        dietFlags: ['high_protein'],
        items: [
          RecipeItem(ingredientId: 'chicken_breast', qty: 400, unit: Unit.grams),
          RecipeItem(ingredientId: 'rice_brown', qty: 200, unit: Unit.grams),
        ],
        steps: [
          'Cook rice according to package directions',
          'Season and cook chicken breast',
          'Serve together',
        ],
        macrosPerServ: MacrosPerServing(
          kcal: 350,
          proteinG: 35,
          carbsG: 25,
          fatG: 8,
        ),
        costPerServCents: 250,
        source: RecipeSource.seed,
      );
    });

    test('should create recipe with correct properties', () {
      expect(testRecipe.id, 'test_recipe');
      expect(testRecipe.name, 'Test Recipe');
      expect(testRecipe.servings, 4);
      expect(testRecipe.timeMins, 30);
      expect(testRecipe.cuisine, 'American');
      expect(testRecipe.dietFlags, ['high_protein']);
      expect(testRecipe.items.length, 2);
      expect(testRecipe.steps.length, 3);
      expect(testRecipe.macrosPerServ.kcal, 350);
      expect(testRecipe.costPerServCents, 250);
      expect(testRecipe.source, RecipeSource.seed);
    });

    test('should calculate total macros for servings correctly', () {
      final totalMacros = testRecipe.calculateTotalMacros(2.0);
      
      expect(totalMacros.kcal, 700); // 350 * 2
      expect(totalMacros.proteinG, 70); // 35 * 2
      expect(totalMacros.carbsG, 50); // 25 * 2
      expect(totalMacros.fatG, 16); // 8 * 2
    });

    test('should calculate total cost for servings correctly', () {
      final totalCost = testRecipe.calculateTotalCost(2.0);
      
      expect(totalCost, 500); // 250 * 2
    });

    test('should check diet compatibility correctly', () {
      expect(testRecipe.isCompatibleWithDiet(['high_protein']), true);
      expect(testRecipe.isCompatibleWithDiet(['vegetarian']), false);
      expect(testRecipe.isCompatibleWithDiet(['high_protein', 'quick']), false);
    });

    test('should check time constraint compatibility', () {
      expect(testRecipe.fitsTimeConstraint(45), true);
      expect(testRecipe.fitsTimeConstraint(30), true);
      expect(testRecipe.fitsTimeConstraint(20), false);
      expect(testRecipe.fitsTimeConstraint(null), true);
    });

    test('should calculate cost efficiency correctly', () {
      final efficiency = testRecipe.getCostEfficiency();
      
      // (250 cents * 1000) / 350 kcal = ~714.3 cents per 1000 kcal
      expect(efficiency, closeTo(714.3, 0.1));
    });

    test('should calculate protein density correctly', () {
      final density = testRecipe.getProteinDensity();
      
      // (35g protein * 100) / 350 kcal = 10g per 100 kcal
      expect(density, 10.0);
    });

    test('should identify high volume recipes', () {
      final highVolumeRecipe = testRecipe.copyWith(
        dietFlags: ['high_volume', 'salad'],
      );
      
      expect(highVolumeRecipe.isHighVolume(), true);
      expect(testRecipe.isHighVolume(), false);
    });

    test('should identify calorie dense recipes', () {
      final calorieDenseRecipe = testRecipe.copyWith(
        macrosPerServ: const MacrosPerServing(kcal: 500, proteinG: 35, carbsG: 25, fatG: 8),
      );
      
      expect(calorieDenseRecipe.isCalorieDense(), true);
      expect(testRecipe.isCalorieDense(), false);
    });

    test('should identify quick recipes', () {
      final quickRecipe = testRecipe.copyWith(timeMins: 10);
      
      expect(quickRecipe.isQuick(), true);
      expect(testRecipe.isQuick(), false);
    });

    test('should support equality comparison', () {
      final sameRecipe = const Recipe(
        id: 'test_recipe',
        name: 'Test Recipe',
        servings: 4,
        timeMins: 30,
        cuisine: 'American',
        dietFlags: ['high_protein'],
        items: [
          RecipeItem(ingredientId: 'chicken_breast', qty: 400, unit: Unit.grams),
          RecipeItem(ingredientId: 'rice_brown', qty: 200, unit: Unit.grams),
        ],
        steps: [
          'Cook rice according to package directions',
          'Season and cook chicken breast',
          'Serve together',
        ],
        macrosPerServ: MacrosPerServing(
          kcal: 350,
          proteinG: 35,
          carbsG: 25,
          fatG: 8,
        ),
        costPerServCents: 250,
        source: RecipeSource.seed,
      );

      expect(testRecipe, equals(sameRecipe));
    });

    test('should serialize to JSON correctly', () {
      final json = testRecipe.toJson();
      expect(json, isA<Map<String, dynamic>>());
      expect(json['id'], testRecipe.id);
      expect(json['name'], testRecipe.name);
      // Note: Full JSON round-trip testing will be implemented in integration tests
    });
  });

  group('MacrosPerServing Tests', () {
    test('should scale macros correctly', () {
      const macros = MacrosPerServing(kcal: 100, proteinG: 20, carbsG: 15, fatG: 5);
      final scaled = macros.scale(2.5);
      
      expect(scaled.kcal, 250);
      expect(scaled.proteinG, 50);
      expect(scaled.carbsG, 37.5);
      expect(scaled.fatG, 12.5);
    });

    test('should add macros correctly', () {
      const macros1 = MacrosPerServing(kcal: 100, proteinG: 20, carbsG: 15, fatG: 5);
      const macros2 = MacrosPerServing(kcal: 50, proteinG: 10, carbsG: 8, fatG: 3);
      final sum = macros1 + macros2;
      
      expect(sum.kcal, 150);
      expect(sum.proteinG, 30);
      expect(sum.carbsG, 23);
      expect(sum.fatG, 8);
    });

    test('should subtract macros correctly', () {
      const macros1 = MacrosPerServing(kcal: 100, proteinG: 20, carbsG: 15, fatG: 5);
      const macros2 = MacrosPerServing(kcal: 30, proteinG: 5, carbsG: 5, fatG: 2);
      final difference = macros1 - macros2;
      
      expect(difference.kcal, 70);
      expect(difference.proteinG, 15);
      expect(difference.carbsG, 10);
      expect(difference.fatG, 3);
    });
  });

  group('RecipeItem Tests', () {
    test('should create with correct properties', () {
      const item = RecipeItem(
        ingredientId: 'test_ingredient',
        qty: 200,
        unit: Unit.grams,
      );

      expect(item.ingredientId, 'test_ingredient');
      expect(item.qty, 200);
      expect(item.unit, Unit.grams);
    });

    test('should support equality', () {
      const item1 = RecipeItem(ingredientId: 'test', qty: 100, unit: Unit.grams);
      const item2 = RecipeItem(ingredientId: 'test', qty: 100, unit: Unit.grams);
      
      expect(item1, equals(item2));
    });
  });
}
