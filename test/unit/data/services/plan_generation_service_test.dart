import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:macro_budget_meal_planner/data/services/plan_generation_service.dart';
import 'package:macro_budget_meal_planner/domain/entities/ingredient.dart';
import 'package:macro_budget_meal_planner/domain/entities/plan.dart';
import 'package:macro_budget_meal_planner/domain/entities/recipe.dart';
import 'package:macro_budget_meal_planner/domain/entities/user_targets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const baseIngredient = Ingredient(
    id: 'base',
    name: 'Base Ingredient',
    unit: Unit.grams,
    macrosPer100g: MacrosPerHundred(
      kcal: 100,
      proteinG: 10,
      carbsG: 10,
      fatG: 2,
    ),
    pricePerUnitCents: 100,
    purchasePack: PurchasePack(qty: 100, unit: Unit.grams),
    aisle: Aisle.pantry,
    tags: <String>[],
    source: IngredientSource.seed,
  );

  const defaultTargets = UserTargets(
    id: 'user',
    kcal: 2000,
    proteinG: 150,
    carbsG: 200,
    fatG: 67,
    budgetCents: 5000,
    mealsPerDay: 3,
    timeCapMins: 30,
    dietFlags: <String>[],
    equipment: <String>['stove'],
    planningMode: PlanningMode.maintenance,
  );

  Recipe buildRecipe(String id, {bool itemized = true}) {
    return Recipe(
      id: id,
      name: 'Recipe $id',
      servings: 1,
      timeMins: 10,
      cuisine: null,
      dietFlags: const <String>[],
      items: itemized
          ? const <RecipeItem>[
              RecipeItem(ingredientId: 'base', qty: 100, unit: Unit.grams),
            ]
          : const <RecipeItem>[],
      steps: const <String>['step'],
      macrosPerServ: const MacrosPerServing(
        kcal: 400,
        proteinG: 30,
        carbsG: 35,
        fatG: 12,
      ),
      costPerServCents: 350,
      source: RecipeSource.manual,
    );
  }

  Set<String> _idsFor(List<Recipe> recipes, bool itemized) {
    return recipes
        .where((r) => itemized ? r.items.isNotEmpty : r.items.isEmpty)
        .map((r) => r.id)
        .toSet();
  }

  List<String> _plannedIds(Plan plan) {
    return plan.days
        .expand((day) => day.meals.map((meal) => meal.recipeId))
        .toList();
  }

  group('PlanGenerationService pooling and selection', () {
    test(
      'prefers itemized recipes but keeps some non-itemized for variety',
      () async {
        final recipes = <Recipe>[
          for (int i = 0; i < 8; i++) buildRecipe('item_$i'),
          for (int i = 0; i < 2; i++) buildRecipe('non_$i', itemized: false),
        ];

        final service = PlanGenerationService(rng: Random(1));
        final plan = await service.generate(
          targets: defaultTargets,
          recipes: recipes,
          ingredients: const <Ingredient>[baseIngredient],
        );

        final plannedIds = _plannedIds(plan);
        final itemizedIds = _idsFor(recipes, true);
        final nonItemizedIds = _idsFor(recipes, false);
        final itemizedCount = plannedIds.where(itemizedIds.contains).length;
        final nonItemizedCount = plannedIds
            .where(nonItemizedIds.contains)
            .length;

        expect(plannedIds.length, 21);
        expect(itemizedCount, greaterThan(nonItemizedCount));
        expect(nonItemizedCount, greaterThan(0));
      },
    );

    test(
      'falls back to non-itemized when itemized supply is limited',
      () async {
        final recipes = <Recipe>[
          for (int i = 0; i < 2; i++) buildRecipe('item_$i'),
          for (int i = 0; i < 6; i++) buildRecipe('non_$i', itemized: false),
        ];

        final service = PlanGenerationService(rng: Random(2));
        final plan = await service.generate(
          targets: defaultTargets,
          recipes: recipes,
          ingredients: const <Ingredient>[baseIngredient],
        );

        final plannedIds = _plannedIds(plan);
        final itemizedIds = _idsFor(recipes, true);
        final nonItemizedIds = _idsFor(recipes, false);
        final itemizedCount = plannedIds.where(itemizedIds.contains).length;
        final nonItemizedCount = plannedIds
            .where(nonItemizedIds.contains)
            .length;

        expect(plannedIds.length, 21);
        expect(nonItemizedCount, greaterThan(itemizedCount));
        expect(itemizedCount, greaterThan(0));
      },
    );

    test(
      'uses non-itemized recipes exclusively when no itemized options exist',
      () async {
        final recipes = <Recipe>[
          for (int i = 0; i < 5; i++) buildRecipe('non_$i', itemized: false),
        ];

        final service = PlanGenerationService(rng: Random(3));
        final plan = await service.generate(
          targets: defaultTargets,
          recipes: recipes,
          ingredients: const <Ingredient>[baseIngredient],
        );

        final plannedIds = _plannedIds(plan);
        final nonItemizedIds = _idsFor(recipes, false);
        final nonItemizedCount = plannedIds
            .where(nonItemizedIds.contains)
            .length;

        expect(plannedIds.length, 21);
        expect(nonItemizedCount, plannedIds.length);
      },
    );

    test(
      'avoids immediate repeats and duplicate meals within the same day',
      () async {
        final recipes = <Recipe>[
          for (int i = 0; i < 5; i++) buildRecipe('item_$i'),
          for (int i = 0; i < 3; i++) buildRecipe('non_$i', itemized: false),
        ];

        final service = PlanGenerationService(rng: Random(4));
        final plan = await service.generate(
          targets: defaultTargets,
          recipes: recipes,
          ingredients: const <Ingredient>[baseIngredient],
        );

        final plannedIds = _plannedIds(plan);
        for (int i = 1; i < plannedIds.length; i++) {
          expect(plannedIds[i], isNot(plannedIds[i - 1]));
        }

        for (final day in plan.days) {
          final ids = day.meals.map((meal) => meal.recipeId).toList();
          expect(ids.toSet().length, ids.length);
        }
      },
    );
  });
}
