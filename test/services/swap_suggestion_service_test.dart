import 'package:flutter_test/flutter_test.dart';

import 'package:macro_budget_meal_planner/domain/entities/ingredient.dart';
import 'package:macro_budget_meal_planner/domain/entities/plan.dart';
import 'package:macro_budget_meal_planner/domain/entities/recipe.dart';
import 'package:macro_budget_meal_planner/domain/entities/user_targets.dart';
import 'package:macro_budget_meal_planner/domain/usecases/macro_calculator.dart';
import 'package:macro_budget_meal_planner/domain/usecases/swap_engine.dart';

MacrosPerServing macros({
  required double kcal,
  required double protein,
  required double carbs,
  required double fat,
}) {
  return MacrosPerServing(
    kcal: kcal,
    proteinG: protein,
    carbsG: carbs,
    fatG: fat,
  );
}

Recipe buildRecipe({
  required String id,
  required String name,
  required double kcal,
  required double protein,
  required double carbs,
  required double fat,
  int costPerServCents = 300,
  int timeMins = 10,
  int servings = 1,
  List<String> dietFlags = const [],
  List<RecipeItem> items = const [],
  List<String>? steps,
}) {
  return Recipe(
    id: id,
    name: name,
    servings: servings,
    timeMins: timeMins,
    cuisine: null,
    dietFlags: dietFlags,
    items: items,
    steps: steps ?? const ['Prep'],
    macrosPerServ: macros(
      kcal: kcal,
      protein: protein,
      carbs: carbs,
      fat: fat,
    ),
    costPerServCents: costPerServCents,
    source: RecipeSource.manual,
  );
}

UserTargets buildTargets({
  required double kcal,
  required double protein,
  required double carbs,
  required double fat,
  int? budgetCents,
  PlanningMode planningMode = PlanningMode.maintenance,
  int mealsPerDay = 3,
}) {
  return UserTargets(
    id: 'targets-1',
    kcal: kcal,
    proteinG: protein,
    carbsG: carbs,
    fatG: fat,
    budgetCents: budgetCents,
    mealsPerDay: mealsPerDay,
    timeCapMins: null,
    dietFlags: const [],
    equipment: const ['stove'],
    planningMode: planningMode,
  );
}

Plan buildPlan(List<List<PlanMeal>> dayMeals) {
  final days = <PlanDay>[];
  for (var i = 0; i < dayMeals.length; i++) {
    days.add(
      PlanDay(
        date: '2023-01-${(i + 1).toString().padLeft(2, '0')}',
        meals: dayMeals[i],
      ),
    );
  }

  return Plan(
    id: 'plan-1',
    name: 'Test Plan',
    userTargetsId: 'targets-1',
    days: days,
    totals: PlanTotals.empty(),
    createdAt: DateTime.utc(2023, 1, 1),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SwapEngine.generateSwapSuggestions', () {
    late SwapEngine engine;

    setUp(() {
      engine = SwapEngine(macroCalculator: MacroCalculator());
    });

    test('ranks cost-saving and higher-protein alternatives first', () {
      final current = buildRecipe(
        id: 'cur',
        name: 'Current',
        kcal: 600,
        protein: 30,
        carbs: 60,
        fat: 20,
        costPerServCents: 500,
      );
      final pool = <Recipe>[
        current,
        buildRecipe(
          id: 'A',
          name: 'CheaperHigherProtein',
          kcal: 580,
          protein: 45,
          carbs: 50,
          fat: 18,
          costPerServCents: 350,
        ),
        buildRecipe(
          id: 'B',
          name: 'CheaperLowerProtein',
          kcal: 590,
          protein: 25,
          carbs: 60,
          fat: 18,
          costPerServCents: 400,
        ),
        buildRecipe(
          id: 'C',
          name: 'MoreExpHigherProtein',
          kcal: 610,
          protein: 50,
          carbs: 40,
          fat: 20,
          costPerServCents: 700,
        ),
      ];
      final plan = buildPlan([
        [const PlanMeal(recipeId: 'cur', servings: 1)],
      ]);
      final targets = buildTargets(
        kcal: 600,
        protein: 40,
        carbs: 60,
        fat: 20,
        budgetCents: 7000,
      );

      final suggestions = engine.generateSwapSuggestions(
        plan: plan,
        dayIndex: 0,
        mealIndex: 0,
        targets: targets,
        availableRecipes: pool,
        ingredients: const <Ingredient>[],
        maxSuggestions: 5,
      );

      expect(
        suggestions.map((s) => s.alternativeRecipe.id).toList(),
        ['A', 'C', 'B'],
      );

      final best = suggestions.firstWhere((s) => s.alternativeRecipe.id == 'A');
      expect(best.reasons.contains(SwapReason.costSavings), isTrue);
      expect(best.reasons.contains(SwapReason.proteinIncrease), isTrue);
      expect(best.impact.costDeltaCents, lessThan(0));
      expect(best.impact.proteinDelta, greaterThan(0));
      expect(best.impact.kcalDelta.abs(), lessThanOrEqualTo(25));

      for (var i = 0; i < suggestions.length - 1; i++) {
        expect(
          suggestions[i].score <= suggestions[i + 1].score,
          isTrue,
        );
      }
    });

    test('prioritizes cheaper options under budget pressure', () {
      final current = buildRecipe(
        id: 'cur',
        name: 'Current',
        kcal: 700,
        protein: 35,
        carbs: 75,
        fat: 25,
        costPerServCents: 900,
      );
      final pool = <Recipe>[
        current,
        buildRecipe(
          id: 'cheap1',
          name: 'Cheap 1',
          kcal: 680,
          protein: 38,
          carbs: 70,
          fat: 22,
          costPerServCents: 500,
        ),
        buildRecipe(
          id: 'cheap2',
          name: 'Cheap 2',
          kcal: 720,
          protein: 40,
          carbs: 72,
          fat: 24,
          costPerServCents: 550,
        ),
        buildRecipe(
          id: 'exp',
          name: 'Expensive',
          kcal: 690,
          protein: 42,
          carbs: 68,
          fat: 22,
          costPerServCents: 1100,
        ),
      ];
      final plan = buildPlan([
        [const PlanMeal(recipeId: 'cur', servings: 1)],
      ]);
      final targets = buildTargets(
        kcal: 650,
        protein: 40,
        carbs: 70,
        fat: 20,
        budgetCents: 3500,
        planningMode: PlanningMode.bulkingBudget,
      );

      final suggestions = engine.generateSwapSuggestions(
        plan: plan,
        dayIndex: 0,
        mealIndex: 0,
        targets: targets,
        availableRecipes: pool,
        ingredients: const <Ingredient>[],
        maxSuggestions: 3,
      );

      expect(suggestions.first.alternativeRecipe.id, 'cheap1');
      expect(
        suggestions.first.reasons.contains(SwapReason.costSavings),
        isTrue,
      );
      expect(suggestions.last.alternativeRecipe.id, 'exp');
    });

    test('includes variety reason when current recipe is overused', () {
      final current = buildRecipe(
        id: 'cur',
        name: 'Chicken Bowl',
        kcal: 600,
        protein: 35,
        carbs: 60,
        fat: 18,
        costPerServCents: 600,
      );
      final pool = <Recipe>[
        current,
        buildRecipe(
          id: 'dup',
          name: 'Chicken Bowl',
          kcal: 595,
          protein: 35,
          carbs: 59,
          fat: 18,
          costPerServCents: 600,
        ),
        buildRecipe(
          id: 'alt',
          name: 'Beef Wrap',
          kcal: 610,
          protein: 42,
          carbs: 50,
          fat: 20,
          costPerServCents: 620,
        ),
      ];
      final plan = buildPlan([
        [const PlanMeal(recipeId: 'cur', servings: 1)],
        [const PlanMeal(recipeId: 'cur', servings: 1)],
        [const PlanMeal(recipeId: 'cur', servings: 1)],
      ]);
      final targets = buildTargets(
        kcal: 600,
        protein: 40,
        carbs: 60,
        fat: 20,
        budgetCents: 7000,
      );

      final suggestions = engine.generateSwapSuggestions(
        plan: plan,
        dayIndex: 0,
        mealIndex: 0,
        targets: targets,
        availableRecipes: pool,
        ingredients: const <Ingredient>[],
        maxSuggestions: 5,
      );

      expect(suggestions.first.alternativeRecipe.id, 'alt');
      expect(
        suggestions.first.reasons.contains(SwapReason.varietyImprovement),
        isTrue,
      );
    });

    test('respects maxSuggestions, excludes current recipe, and dedupes', () {
      final current = buildRecipe(
        id: 'cur',
        name: 'Current',
        kcal: 600,
        protein: 30,
        carbs: 60,
        fat: 20,
        costPerServCents: 500,
      );
      final pool = <Recipe>[
        current,
        buildRecipe(
          id: 'A',
          name: 'A',
          kcal: 590,
          protein: 35,
          carbs: 55,
          fat: 18,
          costPerServCents: 480,
        ),
        buildRecipe(
          id: 'B',
          name: 'B',
          kcal: 610,
          protein: 40,
          carbs: 50,
          fat: 20,
          costPerServCents: 520,
        ),
        buildRecipe(
          id: 'C',
          name: 'C',
          kcal: 620,
          protein: 42,
          carbs: 48,
          fat: 22,
          costPerServCents: 530,
        ),
      ];
      final plan = buildPlan([
        [const PlanMeal(recipeId: 'cur', servings: 1)],
      ]);
      final targets = buildTargets(
        kcal: 600,
        protein: 40,
        carbs: 60,
        fat: 20,
        budgetCents: 7000,
      );

      final suggestions = engine.generateSwapSuggestions(
        plan: plan,
        dayIndex: 0,
        mealIndex: 0,
        targets: targets,
        availableRecipes: pool,
        ingredients: const <Ingredient>[],
        maxSuggestions: 2,
      );

      expect(suggestions.length, 2);
      expect(
        suggestions.any((s) => s.alternativeRecipe.id == 'cur'),
        isFalse,
      );
      expect(
        suggestions.map((s) => s.alternativeRecipe.id).toSet().length,
        2,
      );
    });

    test('returns empty list when no alternative recipes are available', () {
      final current = buildRecipe(
        id: 'cur',
        name: 'Current',
        kcal: 600,
        protein: 30,
        carbs: 60,
        fat: 20,
        costPerServCents: 500,
      );
      final pool = <Recipe>[current];
      final plan = buildPlan([
        [const PlanMeal(recipeId: 'cur', servings: 1)],
      ]);
      final targets = buildTargets(
        kcal: 600,
        protein: 40,
        carbs: 60,
        fat: 20,
        budgetCents: 7000,
      );

      final suggestions = engine.generateSwapSuggestions(
        plan: plan,
        dayIndex: 0,
        mealIndex: 0,
        targets: targets,
        availableRecipes: pool,
        ingredients: const <Ingredient>[],
        maxSuggestions: 5,
      );

      expect(suggestions, isEmpty);
    });
  });
}
