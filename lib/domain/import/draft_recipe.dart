import '../entities/ingredient.dart' as domain;

class DraftIngredientLine {
  final String rawText; // original text, e.g. "1 cup rice"
  final double? qty; // parsed numerical qty (supports 1 1/2 => 1.5)
  final domain.Unit? unit; // grams | milliliters | piece | null
  final String name; // normalized name, e.g. "rice"
  final String? note; // e.g. "rinsed"
  final String? matchedIngredientId; // chosen in mapping step (or 'stub:<name>')
  const DraftIngredientLine({
    required this.rawText,
    required this.qty,
    required this.unit,
    required this.name,
    this.note,
    this.matchedIngredientId,
  });

  DraftIngredientLine copyWith({
    String? rawText,
    double? qty,
    domain.Unit? unit,
    String? name,
    String? note,
    String? matchedIngredientId,
  }) => DraftIngredientLine(
        rawText: rawText ?? this.rawText,
        qty: qty ?? this.qty,
        unit: unit ?? this.unit,
        name: name ?? this.name,
        note: note ?? this.note,
        matchedIngredientId: matchedIngredientId ?? this.matchedIngredientId,
      );
}

class DraftRecipe {
  final String sourceUrl;
  final String name;
  final int? servings; // may be null; user can edit
  final int? timeMins; // total time mins if available
  final List<DraftIngredientLine> ingredients;
  final List<String> steps;
  final List<String> dietFlags; // best-effort from tags (veg/gf/df)
  const DraftRecipe({
    required this.sourceUrl,
    required this.name,
    required this.servings,
    required this.timeMins,
    required this.ingredients,
    required this.steps,
    required this.dietFlags,
  });

  DraftRecipe copyWith({
    String? sourceUrl,
    String? name,
    int? servings,
    int? timeMins,
    List<DraftIngredientLine>? ingredients,
    List<String>? steps,
    List<String>? dietFlags,
  }) => DraftRecipe(
        sourceUrl: sourceUrl ?? this.sourceUrl,
        name: name ?? this.name,
        servings: servings ?? this.servings,
        timeMins: timeMins ?? this.timeMins,
        ingredients: ingredients ?? this.ingredients,
        steps: steps ?? this.steps,
        dietFlags: dietFlags ?? this.dietFlags,
      );
}

