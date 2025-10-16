import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/taste_profile_service.dart';
import '../../domain/entities/ingredient.dart';
import '../../domain/entities/recipe.dart';
import '../../presentation/providers/ingredient_providers.dart';
import '../../presentation/providers/recipe_providers.dart';

final tasteProfileProvider = FutureProvider<TasteProfile>((ref) async {
  return ref.read(tasteProfileServiceProvider).get();
});

/// Derived filters/scorers used by generator and swap suggester.
class TasteRules {
  final Set<String> hardBanIng;
  final Set<String> hardBanTags;
  final Set<String> likeIng;
  final Set<String> dislikeIng;
  final Set<String> likeTags;
  final Set<String> dislikeTags;
  final Map<String,double> cuisineW;
  final Set<String> hideRecipes;
  final Set<String> allowRecipes;
  final Set<String> dietFlags;

  const TasteRules({
    required this.hardBanIng, required this.hardBanTags,
    required this.likeIng, required this.dislikeIng,
    required this.likeTags, required this.dislikeTags,
    required this.cuisineW, required this.hideRecipes,
    required this.allowRecipes, required this.dietFlags,
  });
}

final tasteRulesProvider = FutureProvider<TasteRules>((ref) async {
  final p = await ref.watch(tasteProfileProvider.future);
  return TasteRules(
    hardBanIng: p.hardBanIngredients.toSet(),
    hardBanTags: p.hardBanTags.toSet(),
    likeIng: p.likeIngredients.toSet(),
    dislikeIng: p.dislikeIngredients.toSet(),
    likeTags: p.likeTags.toSet(),
    dislikeTags: p.dislikeTags.toSet(),
    cuisineW: p.cuisineWeights,
    hideRecipes: p.perRecipeHide.entries.where((e)=>e.value).map((e)=>e.key).toSet(),
    allowRecipes: p.perRecipeAllow.entries.where((e)=>e.value).map((e)=>e.key).toSet(),
    dietFlags: p.dietFlags.toSet(),
  );
});

/// Simple compatibility check for a recipe given rules and ingredient catalog.
bool recipeHardBanned({
  required Recipe recipe,
  required TasteRules rules,
  required Map<String, Ingredient> ingById,
}) {
  if (rules.hideRecipes.contains(recipe.id)) return true;

  // Tag-level (dietFlags doubles as tags)
  for (final t in recipe.dietFlags) {
    if (rules.hardBanTags.contains(t)) return true;
  }

  // Ingredient-level
  for (final it in recipe.items) {
    final ing = ingById[it.ingredientId];
    if (ing == null) continue;
    if (rules.hardBanIng.contains(ing.id)) return true;
    // Optional: tag allergens e.g., 'nuts' on ingredient.tags → check hardBanTags
    final hasBannedTag = ing.tags.any((tg) => rules.hardBanTags.contains(tg));
    if (hasBannedTag) return true;
  }
  return false;
}

/// Scoring: base 0; +likes, -dislikes; cuisine weight multiplier.
double tasteScore({
  required Recipe recipe,
  required TasteRules rules,
  required Map<String, Ingredient> ingById,
}) {
  if (rules.hideRecipes.contains(recipe.id)) return -1e9;

  double score = 0.0;

  // Ingredients
  for (final it in recipe.items) {
    final ing = ingById[it.ingredientId];
    if (ing == null) continue;
    if (rules.likeIng.contains(ing.id)) score += 2.0;
    if (rules.dislikeIng.contains(ing.id)) score -= 1.0;
  }

  // Tags / cuisines
  for (final t in recipe.dietFlags) {
    if (rules.likeTags.contains(t)) score += 1.5;
    if (rules.dislikeTags.contains(t)) score -= 1.0;
    final w = rules.cuisineW[t];
    if (w != null && w != 1.0) score *= w;
  }

  // Diet flags (reinforce): if recipe lacks required dietFlags, penalize
  for (final need in rules.dietFlags) {
    if (!recipe.dietFlags.contains(need)) score -= 10.0;
  }

  return score;
}

