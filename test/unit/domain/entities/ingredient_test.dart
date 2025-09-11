import 'package:flutter_test/flutter_test.dart';
import 'package:macro_budget_meal_planner/domain/entities/ingredient.dart';

void main() {
  group('Ingredient Entity Tests', () {
    late Ingredient testIngredient;

    setUp(() {
      testIngredient = const Ingredient(
        id: 'test_ingredient',
        name: 'Test Ingredient',
        unit: Unit.grams,
        macrosPer100g: MacrosPerHundred(
          kcal: 100,
          proteinG: 20,
          carbsG: 10,
          fatG: 5,
        ),
        pricePerUnitCents: 200,
        purchasePack: PurchasePack(
          qty: 500,
          unit: Unit.grams,
          priceCents: 1000,
        ),
        aisle: Aisle.meat,
        tags: ['high_protein', 'lean'],
        source: IngredientSource.seed,
      );
    });

    test('should create ingredient with correct properties', () {
      expect(testIngredient.id, 'test_ingredient');
      expect(testIngredient.name, 'Test Ingredient');
      expect(testIngredient.unit, Unit.grams);
      expect(testIngredient.macrosPer100g.kcal, 100);
      expect(testIngredient.macrosPer100g.proteinG, 20);
      expect(testIngredient.pricePerUnitCents, 200);
      expect(testIngredient.aisle, Aisle.meat);
      expect(testIngredient.tags, ['high_protein', 'lean']);
      expect(testIngredient.source, IngredientSource.seed);
    });

    test('should calculate macros for given quantity correctly', () {
      final macros = testIngredient.calculateMacros(200, Unit.grams);
      
      expect(macros.kcal, 200); // 100 * 2
      expect(macros.proteinG, 40); // 20 * 2
      expect(macros.carbsG, 20); // 10 * 2
      expect(macros.fatG, 10); // 5 * 2
    });

    test('should calculate cost for given quantity correctly', () {
      final cost = testIngredient.calculateCost(100, Unit.grams);
      
      expect(cost, 200); // 200 cents per 100g
    });

    test('should check if ingredient has specific tag', () {
      expect(testIngredient.hasTag('high_protein'), true);
      expect(testIngredient.hasTag('lean'), true);
      expect(testIngredient.hasTag('cheap'), false);
    });

    test('should check diet compatibility correctly', () {
      expect(testIngredient.isCompatibleWithDiet([]), true);
      expect(testIngredient.isCompatibleWithDiet(['vegetarian']), false);
      
      final vegIngredient = testIngredient.copyWith(
        tags: ['veg', 'high_protein'],
      );
      expect(vegIngredient.isCompatibleWithDiet(['vegetarian']), true);
    });

    test('should support equality comparison', () {
      final sameIngredient = const Ingredient(
        id: 'test_ingredient',
        name: 'Test Ingredient',
        unit: Unit.grams,
        macrosPer100g: MacrosPerHundred(
          kcal: 100,
          proteinG: 20,
          carbsG: 10,
          fatG: 5,
        ),
        pricePerUnitCents: 200,
        purchasePack: PurchasePack(
          qty: 500,
          unit: Unit.grams,
          priceCents: 1000,
        ),
        aisle: Aisle.meat,
        tags: ['high_protein', 'lean'],
        source: IngredientSource.seed,
      );

      expect(testIngredient, equals(sameIngredient));
    });

    test('should serialize to JSON correctly', () {
      final json = testIngredient.toJson();
      expect(json, isA<Map<String, dynamic>>());
      expect(json['id'], testIngredient.id);
      expect(json['name'], testIngredient.name);
      // Note: Full JSON round-trip testing will be implemented in integration tests
    });
  });

  group('Unit Enum Tests', () {
    test('should have correct string values', () {
      expect(Unit.grams.value, 'g');
      expect(Unit.milliliters.value, 'ml');
      expect(Unit.piece.value, 'piece');
    });
  });

  group('Aisle Enum Tests', () {
    test('should have correct string values', () {
      expect(Aisle.produce.value, 'produce');
      expect(Aisle.meat.value, 'meat');
      expect(Aisle.dairy.value, 'dairy');
      expect(Aisle.pantry.value, 'pantry');
    });
  });

  group('MacrosPerHundred Tests', () {
    test('should create with correct values', () {
      const macros = MacrosPerHundred(
        kcal: 150,
        proteinG: 25,
        carbsG: 15,
        fatG: 8,
      );

      expect(macros.kcal, 150);
      expect(macros.proteinG, 25);
      expect(macros.carbsG, 15);
      expect(macros.fatG, 8);
    });

    test('should support equality', () {
      const macros1 = MacrosPerHundred(kcal: 100, proteinG: 20, carbsG: 10, fatG: 5);
      const macros2 = MacrosPerHundred(kcal: 100, proteinG: 20, carbsG: 10, fatG: 5);
      
      expect(macros1, equals(macros2));
    });
  });
}
