import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/ingredient.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/repositories/ingredient_repository.dart';
import '../../domain/repositories/recipe_repository.dart';

class DataIntegrityService {
  DataIntegrityService({
    required this.ingredientRepository,
    required this.recipeRepository,
    required this.prefs,
  });

  final IngredientRepository ingredientRepository;
  final RecipeRepository recipeRepository;
  final SharedPreferences prefs;

  static const _healFlag = 'integrity_healed_v1';

  Future<void> healMissingIngredientsOnce() async {
    if (prefs.getBool(_healFlag) == true) return;
    await _healMissingIngredients();
    await prefs.setBool(_healFlag, true);
  }

  Future<void> _healMissingIngredients() async {
    final recipes = await recipeRepository.getAllRecipes();
    if (recipes.isEmpty) return;
    final ingredients = await ingredientRepository.getAllIngredients();

    final existingIds = {for (final i in ingredients) i.id};
    final itemByIngredientId = <String, RecipeItem>{};

    for (final recipe in recipes) {
      for (final item in recipe.items) {
        itemByIngredientId.putIfAbsent(item.ingredientId, () => item);
      }
    }

    final missingIds = itemByIngredientId.keys
        .where((id) => !existingIds.contains(id))
        .toList();
    if (missingIds.isEmpty) return;

    for (final id in missingIds) {
      final hint = itemByIngredientId[id];
      final unit = hint?.unit ?? Unit.grams;

      final placeholder = Ingredient(
        id: id,
        name: _humanizeId(id),
        unit: unit,
        macrosPer100g: const MacrosPerHundred(
          kcal: 0.0,
          proteinG: 0.0,
          carbsG: 0.0,
          fatG: 0.0,
        ),
        pricePerUnitCents: 0,
        purchasePack: PurchasePack(qty: 1.0, unit: unit, priceCents: null),
        aisle: Aisle.pantry,
        tags: const [],
        source: IngredientSource.manual,
        lastVerifiedAt: null,
      );

      await ingredientRepository.addIngredient(placeholder);
    }
  }

  String _humanizeId(String id) {
    final cleaned = id.replaceAll(RegExp(r'[_\-]+'), ' ').trim();
    if (cleaned.isEmpty) return id;
    return cleaned
        .split(' ')
        .where((segment) => segment.isNotEmpty)
        .map(_capitalize)
        .join(' ');
  }

  String _capitalize(String segment) {
    if (segment.isEmpty) return segment;
    final lower = segment.toLowerCase();
    return '${lower[0].toUpperCase()}${lower.substring(1)}';
  }
}
