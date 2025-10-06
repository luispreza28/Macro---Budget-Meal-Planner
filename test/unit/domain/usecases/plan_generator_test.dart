import 'package:flutter_test/flutter_test.dart';
import 'package:macro_budget_meal_planner/domain/entities/ingredient.dart';
import 'package:macro_budget_meal_planner/domain/entities/recipe.dart';
import 'package:macro_budget_meal_planner/domain/entities/user_targets.dart';
import 'package:macro_budget_meal_planner/domain/usecases/macro_calculator.dart';
import 'package:macro_budget_meal_planner/domain/usecases/plan_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlanGenerator', () {
    late PlanGenerator planGenerator;
    late MacroCalculator macroCalculator;
    late List<Recipe> testRecipes;
    late List<Ingredient> testIngredients;
    late UserTargets testTargets;

    setUp(() {
      macroCalculator = MacroCalculator();
      planGenerator = PlanGenerator(macroCalculator: macroCalculator);

      // Create test ingredients
      testIngredients = [
        Ingredient(
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
          tags: const ['high_protein', 'lean'],
          source: IngredientSource.seed,
        ),
        Ingredient(
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
        ),
        Ingredient(
          id: 'broccoli',
          name: 'Broccoli',
          unit: Unit.grams,
          macrosPer100g: const MacrosPerHundred(
            kcal: 34,
            proteinG: 2.8,
            carbsG: 7,
            fatG: 0.4,
          ),
          pricePerUnitCents: 80,
          purchasePack: const PurchasePack(qty: 500, unit: Unit.grams),
          aisle: Aisle.produce,
          tags: const ['high_volume', 'veg'],
          source: IngredientSource.seed,
        ),
      ];

      // Create test recipes
      testRecipes = [
        Recipe(
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
          macrosPerServ: const MacrosPerServing(
            kcal: 230,
            proteinG: 32,
            carbsG: 14,
            fatG: 4,
          ),
          costPerServCents: 500,
          source: RecipeSource.seed,
        ),
        Recipe(
          id: 'chicken_broccoli',
          name: 'Chicken and Broccoli',
          servings: 2,
          timeMins: 20,
          dietFlags: const ['high_volume'],
          items: const [
            RecipeItem(ingredientId: 'chicken', qty: 300, unit: Unit.grams),
            RecipeItem(ingredientId: 'broccoli', qty: 200, unit: Unit.grams),
          ],
          steps: const ['Cook chicken', 'Steam broccoli', 'Combine'],
          macrosPerServ: const MacrosPerServing(
            kcal: 282,
            proteinG: 49,
            carbsG: 7,
            fatG: 6,
          ),
          costPerServCents: 600,
          source: RecipeSource.seed,
        ),
        Recipe(
          id: 'rice_bowl',
          name: 'Rice Bowl',
          servings: 1,
          timeMins: 15,
          dietFlags: const ['quick'],
          items: const [
            RecipeItem(ingredientId: 'rice', qty: 150, unit: Unit.grams),
            RecipeItem(ingredientId: 'broccoli', qty: 100, unit: Unit.grams),
          ],
          steps: const ['Cook rice', 'Steam broccoli', 'Serve'],
          macrosPerServ: const MacrosPerServing(
            kcal: 229,
            proteinG: 7,
            carbsG: 49,
            fatG: 0.9,
          ),
          costPerServCents: 200,
          source: RecipeSource.seed,
        ),
      ];

      // Create test targets
      testTargets = UserTargets(
        id: 'test_user',
        kcal: 2000,
        proteinG: 150,
        carbsG: 250,
        fatG: 67,
        mealsPerDay: 3,
        dietFlags: const [],
        equipment: const [],
        planningMode: PlanningMode.cutting,
      );
    });

    group('generatePlan', () {
      test('should generate a valid 7-day plan', () async {
        // Act
        final result = await planGenerator.generatePlan(
          targets: testTargets,
          availableRecipes: testRecipes,
          ingredients: testIngredients,
          planName: 'Test Plan',
        );

        // Assert
        expect(result.plan.days.length, equals(7));
        expect(result.plan.name, equals('Test Plan'));
        expect(result.plan.userTargetsId, equals('test_user'));
        expect(result.generationTimeMs, lessThan(5000)); // Should be under 5 seconds
        
        // Each day should have the correct number of meals
        for (final day in result.plan.days) {
          expect(day.meals.length, equals(testTargets.mealsPerDay));
          
          // Each meal should have a valid recipe and positive servings
          for (final meal in day.meals) {
            expect(testRecipes.any((r) => r.id == meal.recipeId), isTrue);
            expect(meal.servings, greaterThan(0));
            expect(meal.servings, lessThanOrEqualTo(5)); // Reasonable serving size
          }
        }
      });

      test('should respect diet flags', () async {
        // Arrange
        final vegetarianTargets = testTargets.copyWith(
          dietFlags: ['veg'],
        );

        // Add a vegetarian recipe
        final vegRecipe = Recipe(
          id: 'veg_rice',
          name: 'Vegetarian Rice',
          servings: 2,
          timeMins: 25,
          dietFlags: const ['veg'],
          items: const [
            RecipeItem(ingredientId: 'rice', qty: 200, unit: Unit.grams),
            RecipeItem(ingredientId: 'broccoli', qty: 150, unit: Unit.grams),
          ],
          steps: const ['Cook rice', 'Steam broccoli', 'Mix'],
          macrosPerServ: const MacrosPerServing(
            kcal: 181,
            proteinG: 6,
            carbsG: 39,
            fatG: 0.7,
          ),
          costPerServCents: 150,
          source: RecipeSource.seed,
        );

        final vegRecipes = [vegRecipe]; // Only vegetarian recipes

        // Act
        final result = await planGenerator.generatePlan(
          targets: vegetarianTargets,
          availableRecipes: vegRecipes,
          ingredients: testIngredients,
          planName: 'Vegetarian Plan',
        );

        // Assert
        expect(result.plan.days.length, equals(7));
        
        // All meals should use the vegetarian recipe
        for (final day in result.plan.days) {
          for (final meal in day.meals) {
            expect(meal.recipeId, equals('veg_rice'));
          }
        }
      });

      test('should optimize for cutting mode', () async {
        // Arrange
        final cuttingTargets = testTargets.copyWith(
          planningMode: PlanningMode.cutting,
          kcal: 1800, // Lower calories for cutting
        );

        // Act
        final result = await planGenerator.generatePlan(
          targets: cuttingTargets,
          availableRecipes: testRecipes,
          ingredients: testIngredients,
          planName: 'Cutting Plan',
        );

        // Assert
        expect(result.plan.days.length, equals(7));
        
        // Should prefer high-protein, high-volume recipes
        // Check that the plan includes protein-rich recipes
        final recipeIds = <String>{};
        for (final day in result.plan.days) {
          for (final meal in day.meals) {
            recipeIds.add(meal.recipeId);
          }
        }
        
        // Should include at least one high-protein recipe
        expect(recipeIds.contains('chicken_rice') || recipeIds.contains('chicken_broccoli'), isTrue);
      });

      test('should optimize for bulking budget mode', () async {
        // Arrange
        final bulkingTargets = testTargets.copyWith(
          planningMode: PlanningMode.bulkingBudget,
          kcal: 3000, // Higher calories for bulking
          budgetCents: 5000, // $50 weekly budget
        );

        // Act
        final result = await planGenerator.generatePlan(
          targets: bulkingTargets,
          availableRecipes: testRecipes,
          ingredients: testIngredients,
          planName: 'Bulking Budget Plan',
        );

        // Assert
        expect(result.plan.days.length, equals(7));
        expect(result.budgetError, lessThanOrEqualTo(500)); // Within reasonable budget
        
        // Should include cost-effective recipes
        final recipeIds = <String>{};
        for (final day in result.plan.days) {
          for (final meal in day.meals) {
            recipeIds.add(meal.recipeId);
          }
        }
        
        // Should include at least one cost-effective recipe
        expect(recipeIds.contains('rice_bowl'), isTrue);
      });

      test('should handle time constraints', () async {
        // Arrange
        final quickTargets = testTargets.copyWith(
          timeCapMins: 20, // Only quick recipes
        );

        // Act
        final result = await planGenerator.generatePlan(
          targets: quickTargets,
          availableRecipes: testRecipes,
          ingredients: testIngredients,
          planName: 'Quick Plan',
        );

        // Assert
        expect(result.plan.days.length, equals(7));
        
        // Should prefer quick recipes (rice_bowl and chicken_broccoli fit)
        for (final day in result.plan.days) {
          for (final meal in day.meals) {
            final recipe = testRecipes.firstWhere((r) => r.id == meal.recipeId);
            expect(recipe.timeMins, lessThanOrEqualTo(20));
          }
        }
      });

      test('should throw error for no suitable recipes', () async {
        // Arrange
        final impossibleTargets = testTargets.copyWith(
          dietFlags: ['impossible_diet'],
        );

        // Act & Assert
        expect(
          () => planGenerator.generatePlan(
            targets: impossibleTargets,
            availableRecipes: testRecipes,
            ingredients: testIngredients,
            planName: 'Impossible Plan',
          ),
          throwsArgumentError,
        );
      });
    });

    group('OptimizationWeights', () {
      test('should have correct weights for cutting mode', () {
        // Act
        final weights = OptimizationWeights.forMode(PlanningMode.cutting);

        // Assert
        expect(weights.macroError, equals(2.0)); // High macro precision
        expect(weights.budgetError, equals(1.0)); // Moderate budget concern
        expect(weights.varietyPenalty, equals(0.5)); // Allow some repetition
        expect(weights.prepTimePenalty, equals(0.3)); // Low time penalty
        expect(weights.pantryBonus, equals(1.5)); // Encourage pantry use
      });

      test('should have correct weights for bulking budget mode', () {
        // Act
        final weights = OptimizationWeights.forMode(PlanningMode.bulkingBudget);

        // Assert
        expect(weights.macroError, equals(1.5)); // Moderate macro precision
        expect(weights.budgetError, equals(2.0)); // High budget concern
        expect(weights.varietyPenalty, equals(0.3)); // Allow repetition for cost
        expect(weights.prepTimePenalty, equals(0.5)); // Moderate time penalty
        expect(weights.pantryBonus, equals(2.0)); // High pantry use for cost
      });

      test('should have correct weights for bulking no-budget mode', () {
        // Act
        final weights = OptimizationWeights.forMode(PlanningMode.bulkingNoBudget);

        // Assert
        expect(weights.macroError, equals(1.5)); // Moderate macro precision
        expect(weights.budgetError, equals(0.2)); // Very low budget concern
        expect(weights.varietyPenalty, equals(1.0)); // More variety desired
        expect(weights.prepTimePenalty, equals(2.0)); // High time penalty (quick meals)
        expect(weights.pantryBonus, equals(0.5)); // Lower pantry priority
      });
    });
  });
}

extension UserTargetsTestExtension on UserTargets {
  UserTargets copyWith({
    String? id,
    double? kcal,
    double? proteinG,
    double? carbsG,
    double? fatG,
    int? budgetCents,
    int? mealsPerDay,
    int? timeCapMins,
    List<String>? dietFlags,
    List<String>? equipment,
    PlanningMode? planningMode,
  }) {
    return UserTargets(
      id: id ?? this.id,
      kcal: kcal ?? this.kcal,
      proteinG: proteinG ?? this.proteinG,
      carbsG: carbsG ?? this.carbsG,
      fatG: fatG ?? this.fatG,
      budgetCents: budgetCents ?? this.budgetCents,
      mealsPerDay: mealsPerDay ?? this.mealsPerDay,
      timeCapMins: timeCapMins ?? this.timeCapMins,
      dietFlags: dietFlags ?? this.dietFlags,
      equipment: equipment ?? this.equipment,
      planningMode: planningMode ?? this.planningMode,
    );
  }
}
