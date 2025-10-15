import '../entities/ingredient.dart';
import '../entities/recipe.dart';

class AllergenClassifier {
  /// Returns a set of allergen tags present in a Recipe from its items/ingredient tags.
  static Set<String> allergensForRecipe(Recipe r, Map<String, Ingredient> byId) {
    final out = <String>{};
    for (final it in r.items) {
      final ing = byId[it.ingredientId];
      if (ing == null) continue;
      // Heuristics:
      // - Ingredient.tags may contain standardized keys: 'allergen:peanut', 'allergen:milk', etc.
      // - Also match name keywords as a fallback (lowercase).
      final lt = ing.tags.map((t) => t.toLowerCase());
      for (final t in lt) {
        if (t.startsWith('allergen:')) out.add(t.substring('allergen:'.length));
      }
      final name = ing.name.toLowerCase();
      if (name.contains('peanut')) out.add('peanut');
      if (name.contains('almond') || name.contains('walnut') || name.contains('cashew') || name.contains('pistachio') || name.contains('hazelnut')) out.add('tree_nut');
      if (name.contains('milk') || name.contains('cheese') || name.contains('butter') || name.contains('yogurt')) out.add('milk');
      if (name.contains('egg')) out.add('egg');
      if (name.contains('soy')) out.add('soy');
      if (name.contains('wheat')) out.add('wheat');
      if (name.contains('sesame')) out.add('sesame');
      if (name.contains('shrimp') || name.contains('crab') || name.contains('lobster')) out.add('shellfish');
      if (name.contains('fish')) out.add('fish'); // coarse heuristic
      // extend heuristics as needed
    }
    return out;
  }

  /// Returns true if recipe violates any required diet flags (e.g., veg, gf, df).
  static bool violatesDiet(Recipe r, List<String> requiredFlags) {
    for (final f in requiredFlags) {
      if (!r.dietFlags.contains(f)) return true;
    }
    return false;
  }
}

