import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:macro_budget_meal_planner/domain/entities/ingredient.dart';
import 'package:macro_budget_meal_planner/domain/entities/recipe.dart';
import 'package:macro_budget_meal_planner/domain/repositories/ingredient_repository.dart';
import 'package:macro_budget_meal_planner/domain/repositories/recipe_repository.dart';
import 'package:macro_budget_meal_planner/presentation/pages/recipes/recipe_details_page.dart';
import 'package:macro_budget_meal_planner/presentation/providers/database_providers.dart';
import 'package:macro_budget_meal_planner/presentation/providers/ingredient_providers.dart';
import 'package:macro_budget_meal_planner/presentation/providers/recipe_providers.dart';

class _FakeRecipeRepository implements RecipeRepository {
  _FakeRecipeRepository(Recipe initialRecipe)
      : _current = initialRecipe,
        _controller = StreamController<Recipe?>.broadcast();

  Recipe _current;
  final StreamController<Recipe?> _controller;
  Recipe? lastUpdated;

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(_current);
    }
  }

  Future<void> dispose() async {
    await _controller.close();
  }

  @override
  Stream<Recipe?> watchRecipeById(String id) {
    Future.microtask(_emit);
    return _controller.stream;
  }

  @override
  Future<void> updateRecipe(Recipe recipe) async {
    lastUpdated = recipe;
    _current = recipe;
    _emit();
  }

  @override
  Stream<List<Recipe>> watchAllRecipes() {
    Future.microtask(_emit);
    return _controller.stream.map((recipe) {
      if (recipe == null) return <Recipe>[];
      return [recipe];
    });
  }

  // Unused members throw to catch unexpected calls during the test.
  @override
  Future<void> addRecipe(Recipe recipe) => throw UnimplementedError();

  @override
  Future<void> bulkInsertRecipes(List<Recipe> recipes) =>
      throw UnimplementedError();

  @override
  Future<void> deleteRecipe(String id) => throw UnimplementedError();

  @override
  Future<List<Recipe>> getAllRecipes() => throw UnimplementedError();

  @override
  Future<List<Recipe>> getBulkingRecipes() => throw UnimplementedError();

  @override
  Future<List<Recipe>> getCostEffectiveRecipes({int limit = 50}) =>
      throw UnimplementedError();

  @override
  Future<List<Recipe>> getCuttingRecipes() => throw UnimplementedError();

  @override
  Future<List<Recipe>> getHighProteinRecipes({int limit = 50}) =>
      throw UnimplementedError();

  @override
  Future<Recipe?> getRecipeById(String id) => throw UnimplementedError();

  @override
  Future<List<Recipe>> getRecipesByCalorieRange({
    double? minKcal,
    double? maxKcal,
  }) =>
      throw UnimplementedError();

  @override
  Future<List<Recipe>> getRecipesByCostRange({
    int? minCostCents,
    int? maxCostCents,
  }) =>
      throw UnimplementedError();

  @override
  Future<List<Recipe>> getRecipesByCuisine(String cuisine) =>
      throw UnimplementedError();

  @override
  Future<List<Recipe>> getRecipesByIds(List<String> ids) =>
      throw UnimplementedError();

  @override
  Future<List<Recipe>> getRecipesForDiet(List<String> dietFlags) =>
      throw UnimplementedError();

  @override
  Future<int> getRecipesCount() => throw UnimplementedError();

  @override
  Future<List<Recipe>> getRecipesWithinTime(int maxTimeMins) =>
      throw UnimplementedError();

  @override
  Future<List<Recipe>> getQuickRecipes() => throw UnimplementedError();

  @override
  Future<bool> recipeExists(String id) => throw UnimplementedError();

  @override
  Future<List<Recipe>> searchRecipes(String query) =>
      throw UnimplementedError();

  @override
  Stream<List<Recipe>> watchRecipesForDiet(List<String> dietFlags) =>
      throw UnimplementedError();
}

class _FakeIngredientRepository implements IngredientRepository {
  _FakeIngredientRepository(List<Ingredient> initial)
      : _ingredients = initial,
        _controller = StreamController<List<Ingredient>>.broadcast();

  List<Ingredient> _ingredients;
  final StreamController<List<Ingredient>> _controller;

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(List<Ingredient>.from(_ingredients));
    }
  }

  Future<void> dispose() async {
    await _controller.close();
  }

  @override
  Stream<List<Ingredient>> watchAllIngredients() {
    Future.microtask(_emit);
    return _controller.stream;
  }

  // Remaining members throw when invoked unexpectedly.
  @override
  Future<void> addIngredient(Ingredient ingredient) =>
      throw UnimplementedError();

  @override
  Future<void> bulkInsertIngredients(List<Ingredient> ingredients) =>
      throw UnimplementedError();

  @override
  Future<void> deleteIngredient(String id) => throw UnimplementedError();

  @override
  Future<List<Ingredient>> getAllIngredients() => throw UnimplementedError();

  @override
  Future<List<Ingredient>> getCheapestIngredients({int limit = 50}) =>
      throw UnimplementedError();

  @override
  Future<Ingredient?> getIngredientById(String id) =>
      throw UnimplementedError();

  @override
  Future<int> getIngredientsCount() => throw UnimplementedError();

  @override
  Future<List<Ingredient>> getIngredientsByAisle(Aisle aisle) =>
      throw UnimplementedError();

  @override
  Future<List<Ingredient>> getIngredientsByTags(List<String> tags) =>
      throw UnimplementedError();

  @override
  Future<List<Ingredient>> getIngredientsForDiet(List<String> dietFlags) =>
      throw UnimplementedError();

  @override
  Future<List<Ingredient>> getHighProteinIngredients({
    double minProteinPer100g = 15.0,
    int limit = 50,
  }) =>
      throw UnimplementedError();

  @override
  Future<bool> ingredientExists(String id) => throw UnimplementedError();

  @override
  Future<List<Ingredient>> searchIngredients(String query) =>
      throw UnimplementedError();

  @override
  Future<void> updateIngredient(Ingredient ingredient) =>
      throw UnimplementedError();

  @override
  Stream<Ingredient?> watchIngredientById(String id) =>
      throw UnimplementedError();

  @override
  Future<void> upsertNutritionAndPrice({
    required String id,
    required NutritionPer100 per100,
    required Unit unit,
    int? pricePerUnitCents,
    double packQty = 0,
    int? packPriceCents,
  }) =>
      throw UnimplementedError();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const recipeId = 'recipe-1';

  late Recipe baseRecipe;
  late List<Ingredient> testIngredients;

  setUp(() {
    baseRecipe = Recipe(
      id: recipeId,
      name: 'Sample Bowl',
      servings: 2,
      timeMins: 20,
      cuisine: 'test',
      dietFlags: const <String>['veg'],
      items: const [
        RecipeItem(
          ingredientId: 'tofu',
          qty: 200,
          unit: Unit.grams,
        ),
      ],
      steps: const <String>[],
      macrosPerServ: const MacrosPerServing(
        kcal: 300,
        proteinG: 20,
        carbsG: 30,
        fatG: 10,
      ),
      costPerServCents: 399,
      source: RecipeSource.manual,
    );

    testIngredients = <Ingredient>[
      const Ingredient(
        id: 'tofu',
        name: 'Firm Tofu',
        unit: Unit.grams,
        macrosPer100g: MacrosPerHundred(
          kcal: 148,
          proteinG: 15,
          carbsG: 3,
          fatG: 9,
        ),
        pricePerUnitCents: 250,
        purchasePack: PurchasePack(qty: 400, unit: Unit.grams, priceCents: 399),
        aisle: Aisle.produce,
        tags: <String>['veg'],
        source: IngredientSource.manual,
      ),
      const Ingredient(
        id: 'rice',
        name: 'Brown Rice',
        unit: Unit.grams,
        macrosPer100g: MacrosPerHundred(
          kcal: 360,
          proteinG: 7,
          carbsG: 76,
          fatG: 3,
        ),
        pricePerUnitCents: 120,
        purchasePack: PurchasePack(qty: 1000, unit: Unit.grams, priceCents: 1200),
        aisle: Aisle.pantry,
        tags: <String>['veg'],
        source: IngredientSource.manual,
      ),
    ];
  });

  Future<void> _pumpPage(
    WidgetTester tester, {
    required _FakeRecipeRepository recipeRepository,
    required _FakeIngredientRepository ingredientRepository,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          recipeRepositoryProvider.overrideWithValue(recipeRepository),
          ingredientRepositoryProvider.overrideWithValue(ingredientRepository),
        ],
        child: const MaterialApp(
          home: RecipeDetailsPage(recipeId: recipeId),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders existing items and live totals', (tester) async {
    final recipeRepository = _FakeRecipeRepository(baseRecipe);
    final ingredientRepository = _FakeIngredientRepository(testIngredients);
    addTearDown(() async {
      await recipeRepository.dispose();
      await ingredientRepository.dispose();
    });

    await _pumpPage(
      tester,
      recipeRepository: recipeRepository,
      ingredientRepository: ingredientRepository,
    );

    expect(find.text('Firm Tofu'), findsOneWidget);
    expect(find.text('\$2.50'), findsOneWidget);
  });

  testWidgets('blocks adding ingredient when units mismatch', (tester) async {
    final recipeRepository = _FakeRecipeRepository(baseRecipe);
    final ingredientRepository = _FakeIngredientRepository(testIngredients);
    addTearDown(() async {
      await recipeRepository.dispose();
      await ingredientRepository.dispose();
    });

    await _pumpPage(
      tester,
      recipeRepository: recipeRepository,
      ingredientRepository: ingredientRepository,
    );

    await tester.tap(
      find.byKey(const ValueKey('add-ingredient-dropdown')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Brown Rice').last);
    await tester.pumpAndSettle();

    final unitDropdown = find.byKey(const ValueKey('add-unit-dropdown'));
    await tester.ensureVisible(unitDropdown);
    await tester.tap(unitDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('ml').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('add-qty-field')),
      '50',
    );
    await tester.pump();

    final addButton = find.byKey(const ValueKey('add-ingredient-button'));
    await tester.ensureVisible(addButton);
    await tester.tap(addButton);
    await tester.pump();

    expect(find.textContaining('Unit mismatch'), findsOneWidget);
    expect(
      tester.widgetList(find.byIcon(Icons.delete_outline)).length,
      1,
    );
  });

  testWidgets('adds ingredient, recalculates totals, and saves update',
      (tester) async {
    final recipeRepository = _FakeRecipeRepository(baseRecipe);
    final ingredientRepository = _FakeIngredientRepository(testIngredients);
    addTearDown(() async {
      await recipeRepository.dispose();
      await ingredientRepository.dispose();
    });

    await _pumpPage(
      tester,
      recipeRepository: recipeRepository,
      ingredientRepository: ingredientRepository,
    );

    await tester.tap(
      find.byKey(const ValueKey('add-ingredient-dropdown')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Brown Rice').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('add-qty-field')),
      '100',
    );
    await tester.pump();

    final addButton = find.byKey(const ValueKey('add-ingredient-button'));
    await tester.ensureVisible(addButton);
    await tester.tap(addButton);
    await tester.pumpAndSettle();

    expect(find.text('Brown Rice'), findsOneWidget);
    expect(find.textContaining('\$3.10'), findsWidgets);

    await tester.tap(find.byTooltip('Save'));
    await tester.pumpAndSettle();

    final updated = recipeRepository.lastUpdated;
    expect(updated, isNotNull);
    expect(updated!.items.length, 2);
    expect(updated.costPerServCents, 310);
  });
}
