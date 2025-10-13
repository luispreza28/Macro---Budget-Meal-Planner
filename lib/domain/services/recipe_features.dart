import '../entities/recipe.dart';

class RecipeFeatures {
  static String proteinTag(Recipe r, {Map<String, String>? tagMap}) {
    if (tagMap != null && tagMap.containsKey(r.id)) return tagMap[r.id]!;
    final name = r.name.toLowerCase();
    final tags = r.dietFlags.map((e) => e.toLowerCase()).toList();
    bool has(List<String> keys) =>
        keys.any((k) => name.contains(k) || tags.any((t) => t.contains(k)));

    if (has(['chicken'])) return 'chicken';
    if (has(['beef'])) return 'beef';
    if (has(['pork'])) return 'pork';
    if (has(['turkey'])) return 'turkey';
    if (has(['tofu', 'tempeh'])) return 'tofu';
    if (has(['egg', 'eggs'])) return 'egg';
    if (has(['fish', 'salmon', 'tuna', 'shrimp', 'prawn', 'cod'])) return 'fish';
    if (has(['beans', 'bean', 'chickpea', 'garbanzo'])) return 'beans';
    if (has(['lentil', 'lentils'])) return 'lentil';
    if (has(['cheese', 'paneer'])) return 'dairy';
    if (has(['vegan'])) return 'vegan';
    if (has(['vegetarian'])) return 'vegetarian';
    return 'unknown';
  }

  static String cuisineTag(Recipe r) {
    final c = r.cuisine?.toLowerCase().trim();
    if (c != null && c.isNotEmpty) return c;
    final name = r.name.toLowerCase();
    final tags = r.dietFlags.map((e) => e.toLowerCase()).toList();
    bool has(List<String> keys) =>
        keys.any((k) => name.contains(k) || tags.any((t) => t.contains(k)));

    if (has(['italian', 'pasta', 'pizza'])) return 'italian';
    if (has(['mexican', 'taco', 'burrito', 'salsa'])) return 'mexican';
    if (has(['indian', 'curry', 'masala', 'dal'])) return 'indian';
    if (has(['chinese', 'stir fry', 'stir-fry'])) return 'chinese';
    if (has(['japanese', 'sushi', 'ramen'])) return 'japanese';
    if (has(['thai'])) return 'thai';
    if (has(['mediterranean'])) return 'mediterranean';
    if (has(['american', 'burger'])) return 'american';
    return 'unknown';
  }

  static String prepBucket(Recipe r) {
    final t = r.timeMins;
    if (t <= 15) return 'quick';
    if (t <= 30) return 'medium';
    return 'long';
  }
}

