import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/sub_rules_service.dart';
import '../../presentation/providers/ingredient_providers.dart';
import '../../domain/entities/ingredient.dart';

final subRulesProvider = FutureProvider<List<SubRule>>((ref) async {
  return ref.read(subRulesServiceProvider).list();
});

/// Build fast-lookup indices for generator/swaps/shopping.
class SubRulesIndex {
  final List<SubRule> rules; // already priority-sorted
  const SubRulesIndex(this.rules);

  Iterable<SubRule> matchingForIngredient(Ingredient ing, Set<String> recipeTags) sync* {
    for (final r in rules) {
      if (!r.appliesTo(recipeTags)) continue;
      if (r.from.matchesIngredient(ing.id, ing.tags.toSet())) yield r;
      if (r.from.kind == 'tag' && ing.tags.contains(r.from.value)) yield r;
      if (r.from.kind == 'any') yield r;
    }
  }
}

final subRulesIndexProvider = FutureProvider<SubRulesIndex>((ref) async {
  final rules = await ref.watch(subRulesProvider.future);
  return SubRulesIndex(rules.where((r) => r.enabled).toList()..sort((a, b) => a.priority.compareTo(b.priority)));
});

/// Helper to map ingredientId according to ALWAYS rules (first match wins).
Future<String> mapAlwaysIngredient({
  required Ref ref,
  required Ingredient ing,
  required Set<String> recipeTags,
}) async {
  final idx = await ref.read(subRulesIndexProvider.future);
  for (final r in idx.matchingForIngredient(ing, recipeTags)) {
    if (r.action == SubAction.always && r.to != null && r.to!.kind == 'ingredient') {
      return r.to!.value; // substitute id
    }
  }
  return ing.id;
}

/// Whether an ingredient is globally “never” under recipe tags.
Future<bool> isNeverIngredient({
  required Ref ref,
  required Ingredient ing,
  required Set<String> recipeTags,
}) async {
  final idx = await ref.read(subRulesIndexProvider.future);
  for (final r in idx.matchingForIngredient(ing, recipeTags)) {
    if (r.action == SubAction.never) return true;
  }
  return false;
}

