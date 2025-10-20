import 'package:collection/collection.dart';
import '../entities/ingredient.dart' as domain;

class IngredientSuggestion {
  final domain.Ingredient ingredient;
  final double score; // 0..1
  const IngredientSuggestion(this.ingredient, this.score);
}

class IngredientMatcher {
  static List<IngredientSuggestion> suggest({
    required String nameGuess,
    required List<domain.Ingredient> catalog,
    int limit = 5,
  }) {
    final q = nameGuess.toLowerCase();
    final scored = <IngredientSuggestion>[];
    for (final ing in catalog) {
      final n = ing.name.toLowerCase();
      double s = 0.0;
      if (n == q) s = 1.0;
      else if (n.contains(q)) s = 0.8;
      else s = _tokenJaccard(q, n) * 0.7;
      scored.add(IngredientSuggestion(ing, s));
    }
    return scored.sorted((a,b)=>b.score.compareTo(a.score)).take(limit).toList();
  }

  static double _tokenJaccard(String a, String b) {
    final as = a.split(RegExp(r'\W+')).where((t)=>t.isNotEmpty).toSet();
    final bs = b.split(RegExp(r'\W+')).where((t)=>t.isNotEmpty).toSet();
    if (as.isEmpty || bs.isEmpty) return 0;
    final inter = as.intersection(bs).length;
    final uni = as.union(bs).length;
    return inter / uni;
  }
}

