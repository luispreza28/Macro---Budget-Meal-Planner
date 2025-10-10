import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'ingredient.dart';

part 'recipe.g.dart';

/// Recipe source for tracking origin
enum RecipeSource {
  @JsonValue('seed')
  seed('seed'),
  @JsonValue('manual')
  manual('manual');

  const RecipeSource(this.value);
  final String value;
}

/// Recipe ingredient item with quantity and unit
@JsonSerializable()
class RecipeItem extends Equatable {
  const RecipeItem({
    required this.ingredientId,
    required this.qty,
    required this.unit,
  });

  /// Reference to ingredient ID
  final String ingredientId;

  /// Quantity needed for the recipe
  final double qty;

  /// Unit for the quantity
  final Unit unit;

  factory RecipeItem.fromJson(Map<String, dynamic> json) =>
      _$RecipeItemFromJson(json);

  Map<String, dynamic> toJson() => _$RecipeItemToJson(this);

  RecipeItem copyWith({String? ingredientId, double? qty, Unit? unit}) {
    return RecipeItem(
      ingredientId: ingredientId ?? this.ingredientId,
      qty: qty ?? this.qty,
      unit: unit ?? this.unit,
    );
  }

  @override
  List<Object?> get props => [ingredientId, qty, unit];
}

/// Macronutrient information per serving
@JsonSerializable()
class MacrosPerServing extends Equatable {
  const MacrosPerServing({
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  final double kcal;
  final double proteinG;
  final double carbsG;
  final double fatG;

  factory MacrosPerServing.fromJson(Map<String, dynamic> json) =>
      _$MacrosPerServingFromJson(json);

  Map<String, dynamic> toJson() => _$MacrosPerServingToJson(this);

  /// Scale macros for a different number of servings
  MacrosPerServing scale(double servings) {
    return MacrosPerServing(
      kcal: kcal * servings,
      proteinG: proteinG * servings,
      carbsG: carbsG * servings,
      fatG: fatG * servings,
    );
  }

  MacrosPerServing copyWith({
    double? kcal,
    double? proteinG,
    double? carbsG,
    double? fatG,
  }) {
    return MacrosPerServing(
      kcal: kcal ?? this.kcal,
      proteinG: proteinG ?? this.proteinG,
      carbsG: carbsG ?? this.carbsG,
      fatG: fatG ?? this.fatG,
    );
  }

  /// Add macros from another serving
  MacrosPerServing operator +(MacrosPerServing other) {
    return MacrosPerServing(
      kcal: kcal + other.kcal,
      proteinG: proteinG + other.proteinG,
      carbsG: carbsG + other.carbsG,
      fatG: fatG + other.fatG,
    );
  }

  /// Subtract macros from another serving
  MacrosPerServing operator -(MacrosPerServing other) {
    return MacrosPerServing(
      kcal: kcal - other.kcal,
      proteinG: proteinG - other.proteinG,
      carbsG: carbsG - other.carbsG,
      fatG: fatG - other.fatG,
    );
  }

  @override
  List<Object?> get props => [kcal, proteinG, carbsG, fatG];
}

/// Recipe entity representing a meal with ingredients and instructions
@JsonSerializable()
class Recipe extends Equatable {
  const Recipe({
    required this.id,
    required this.name,
    required this.servings,
    required this.timeMins,
    this.cuisine,
    required this.dietFlags,
    required this.items,
    required this.steps,
    required this.macrosPerServ,
    required this.costPerServCents,
    required this.source,
  });

  /// Unique identifier for the recipe
  final String id;

  /// Display name of the recipe
  final String name;

  /// Number of servings this recipe makes
  final int servings;

  /// Preparation and cooking time in minutes
  final int timeMins;

  /// Optional cuisine type
  final String? cuisine;

  /// Diet compatibility flags (e.g., 'veg', 'gf', 'df')
  final List<String> dietFlags;

  /// List of ingredients with quantities
  final List<RecipeItem> items;

  /// Cooking instructions
  final List<String> steps;

  /// Calculated macros per serving
  final MacrosPerServing macrosPerServ;

  /// Calculated cost per serving in cents
  final int costPerServCents;

  /// Data source for tracking recipe origin
  final RecipeSource source;

  factory Recipe.fromJson(Map<String, dynamic> json) => _$RecipeFromJson(json);

  Map<String, dynamic> toJson() => _$RecipeToJson(this);

  /// Calculate total macros for a specific number of servings
  MacrosPerServing calculateTotalMacros(double servings) {
    return macrosPerServ.scale(servings);
  }

  /// Calculate total cost for a specific number of servings
  int calculateTotalCost(double servings) {
    return (costPerServCents * servings).round();
  }

  /// Check if recipe is compatible with diet flags
  bool isCompatibleWithDiet(List<String> requiredDietFlags) {
    for (final flag in requiredDietFlags) {
      if (!dietFlags.contains(flag)) {
        return false;
      }
    }
    return true;
  }

  /// Check if recipe can be made within time constraint
  bool fitsTimeConstraint(int? maxTimeMins) {
    if (maxTimeMins == null) return true;
    return timeMins <= maxTimeMins;
  }

  /// Check if recipe has a specific tag
  bool hasTag(String tag) => dietFlags.contains(tag);

  /// Get cost efficiency in cents per 1000 kcal
  double getCostEfficiency() {
    if (macrosPerServ.kcal <= 0) return double.infinity;
    return (costPerServCents * 1000) / macrosPerServ.kcal;
  }

  /// Get protein density in grams per 100 kcal
  double getProteinDensity() {
    if (macrosPerServ.kcal <= 0) return 0;
    return (macrosPerServ.proteinG * 100) / macrosPerServ.kcal;
  }

  /// Check if recipe is high volume (good for cutting)
  bool isHighVolume() {
    return hasTag('high_volume') ||
        dietFlags.any((flag) => ['salad', 'soup', 'vegetables'].contains(flag));
  }

  /// Check if recipe is calorie dense (good for bulking)
  bool isCalorieDense() {
    return macrosPerServ.kcal > 400 || hasTag('calorie_dense');
  }

  /// Check if recipe is quick to prepare
  bool isQuick() {
    return timeMins <= 15 || hasTag('quick');
  }

  /// Copy with new values
  Recipe copyWith({
    String? id,
    String? name,
    int? servings,
    int? timeMins,
    String? cuisine,
    List<String>? dietFlags,
    List<RecipeItem>? items,
    List<String>? steps,
    MacrosPerServing? macrosPerServ,
    int? costPerServCents,
    RecipeSource? source,
  }) {
    return Recipe(
      id: id ?? this.id,
      name: name ?? this.name,
      servings: servings ?? this.servings,
      timeMins: timeMins ?? this.timeMins,
      cuisine: cuisine ?? this.cuisine,
      dietFlags: dietFlags ?? this.dietFlags,
      items: items ?? this.items,
      steps: steps ?? this.steps,
      macrosPerServ: macrosPerServ ?? this.macrosPerServ,
      costPerServCents: costPerServCents ?? this.costPerServCents,
      source: source ?? this.source,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    servings,
    timeMins,
    cuisine,
    dietFlags,
    items,
    steps,
    macrosPerServ,
    costPerServCents,
    source,
  ];
}
