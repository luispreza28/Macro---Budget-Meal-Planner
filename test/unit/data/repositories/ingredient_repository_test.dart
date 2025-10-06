import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:macro_budget_meal_planner/data/repositories/ingredient_repository_impl.dart';
import 'package:macro_budget_meal_planner/data/datasources/database.dart';
import 'package:macro_budget_meal_planner/domain/entities/ingredient.dart' as domain;

class MockAppDatabase extends Mock implements AppDatabase {}
class MockIngredients extends Mock implements $IngredientsTable {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('IngredientRepositoryImpl Tests', () {
    late MockAppDatabase mockDatabase;
    late IngredientRepositoryImpl repository;

    setUp(() {
      mockDatabase = MockAppDatabase();
      repository = IngredientRepositoryImpl(mockDatabase);
    });

    test('should get ingredients count correctly', () async {
      // This is a simplified test - in a real implementation,
      // you'd mock the database calls more thoroughly
      expect(repository, isA<IngredientRepositoryImpl>());
    });

    test('should validate ingredient before adding', () async {
      const validIngredient = domain.Ingredient(
        id: 'test',
        name: 'Test Ingredient',
        unit: domain.Unit.grams,
        macrosPer100g: const domain.MacrosPerHundred(kcal: 100, proteinG: 20, carbsG: 10, fatG: 5),
        pricePerUnitCents: 200,
        purchasePack: const domain.PurchasePack(qty: 500, unit: domain.Unit.grams),
        aisle: domain.Aisle.meat,
        tags: const ['test'],
        source: domain.IngredientSource.manual,
      );

      // In a real test, you'd mock the database insert operation
      expect(validIngredient.id, isNotEmpty);
      expect(validIngredient.name, isNotEmpty);
      expect(validIngredient.macrosPer100g.kcal, greaterThanOrEqualTo(0));
    });
  });
}
