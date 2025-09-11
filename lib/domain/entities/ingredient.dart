import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'ingredient.g.dart';

/// Unit types for ingredients
enum Unit {
  @JsonValue('g')
  grams('g'),
  @JsonValue('ml')
  milliliters('ml'),
  @JsonValue('piece')
  piece('piece');

  const Unit(this.value);
  final String value;
}

/// Aisle categories for shopping organization
enum Aisle {
  @JsonValue('produce')
  produce('produce'),
  @JsonValue('meat')
  meat('meat'),
  @JsonValue('dairy')
  dairy('dairy'),
  @JsonValue('pantry')
  pantry('pantry'),
  @JsonValue('frozen')
  frozen('frozen'),
  @JsonValue('condiments')
  condiments('condiments'),
  @JsonValue('bakery')
  bakery('bakery'),
  @JsonValue('household')
  household('household');

  const Aisle(this.value);
  final String value;
}

/// Data source for ingredient information
enum IngredientSource {
  @JsonValue('seed')
  seed('seed'),
  @JsonValue('fdc')
  fdc('fdc'),
  @JsonValue('off')
  off('off'),
  @JsonValue('manual')
  manual('manual');

  const IngredientSource(this.value);
  final String value;
}

/// Macronutrient information per 100g/ml
@JsonSerializable()
class MacrosPerHundred extends Equatable {
  const MacrosPerHundred({
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  final double kcal;
  final double proteinG;
  final double carbsG;
  final double fatG;

  factory MacrosPerHundred.fromJson(Map<String, dynamic> json) =>
      _$MacrosPerHundredFromJson(json);

  Map<String, dynamic> toJson() => _$MacrosPerHundredToJson(this);

  @override
  List<Object?> get props => [kcal, proteinG, carbsG, fatG];
}

/// Purchase pack information for store buying
@JsonSerializable()
class PurchasePack extends Equatable {
  const PurchasePack({
    required this.qty,
    required this.unit,
    this.priceCents,
  });

  final double qty;
  final Unit unit;
  final int? priceCents;

  factory PurchasePack.fromJson(Map<String, dynamic> json) =>
      _$PurchasePackFromJson(json);

  Map<String, dynamic> toJson() => _$PurchasePackToJson(this);

  @override
  List<Object?> get props => [qty, unit, priceCents];
}

/// Ingredient entity representing a food item with nutritional and cost data
@JsonSerializable()
class Ingredient extends Equatable {
  const Ingredient({
    required this.id,
    required this.name,
    required this.unit,
    required this.macrosPer100g,
    required this.pricePerUnitCents,
    required this.purchasePack,
    required this.aisle,
    required this.tags,
    required this.source,
    this.lastVerifiedAt,
  });

  /// Unique identifier for the ingredient
  final String id;

  /// Display name of the ingredient
  final String name;

  /// Base unit for pricing and calculations
  final Unit unit;

  /// Macronutrient information per 100g/ml
  final MacrosPerHundred macrosPer100g;

  /// Price per base unit in cents
  final int pricePerUnitCents;

  /// Purchase pack information for store buying
  final PurchasePack purchasePack;

  /// Aisle category for shopping organization
  final Aisle aisle;

  /// Tags for filtering and categorization
  final List<String> tags;

  /// Data source for tracking ingredient origin
  final IngredientSource source;

  /// Last verification timestamp for external data
  final DateTime? lastVerifiedAt;

  factory Ingredient.fromJson(Map<String, dynamic> json) =>
      _$IngredientFromJson(json);

  Map<String, dynamic> toJson() => _$IngredientToJson(this);

  /// Calculate macros for a specific quantity
  MacrosPerHundred calculateMacros(double quantity, Unit quantityUnit) {
    // Convert quantity to base unit (100g/ml)
    double baseQuantity;
    switch (quantityUnit) {
      case Unit.grams:
      case Unit.milliliters:
        baseQuantity = quantity / 100;
        break;
      case Unit.piece:
        // For pieces, assume 1 piece = 100g unless specified otherwise
        baseQuantity = quantity;
        break;
    }

    return MacrosPerHundred(
      kcal: macrosPer100g.kcal * baseQuantity,
      proteinG: macrosPer100g.proteinG * baseQuantity,
      carbsG: macrosPer100g.carbsG * baseQuantity,
      fatG: macrosPer100g.fatG * baseQuantity,
    );
  }

  /// Calculate cost for a specific quantity
  int calculateCost(double quantity, Unit quantityUnit) {
    // Convert to base unit and calculate cost
    double baseQuantity;
    switch (quantityUnit) {
      case Unit.grams:
      case Unit.milliliters:
        baseQuantity = quantity;
        break;
      case Unit.piece:
        // For pieces, use purchase pack conversion if available
        baseQuantity = quantity * purchasePack.qty;
        break;
    }

    return (baseQuantity * pricePerUnitCents / 100).round();
  }

  /// Check if ingredient has a specific tag
  bool hasTag(String tag) => tags.contains(tag);

  /// Check if ingredient is suitable for a diet
  bool isCompatibleWithDiet(List<String> dietFlags) {
    for (final dietFlag in dietFlags) {
      switch (dietFlag) {
        case 'vegetarian':
        case 'veg':
          if (!hasTag('veg')) return false;
          break;
        case 'gluten_free':
        case 'gf':
          if (!hasTag('gf')) return false;
          break;
        case 'dairy_free':
        case 'df':
          if (!hasTag('df')) return false;
          break;
        // Add more diet compatibility checks as needed
      }
    }
    return true;
  }

  /// Copy with new values
  Ingredient copyWith({
    String? id,
    String? name,
    Unit? unit,
    MacrosPerHundred? macrosPer100g,
    int? pricePerUnitCents,
    PurchasePack? purchasePack,
    Aisle? aisle,
    List<String>? tags,
    IngredientSource? source,
    DateTime? lastVerifiedAt,
  }) {
    return Ingredient(
      id: id ?? this.id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      macrosPer100g: macrosPer100g ?? this.macrosPer100g,
      pricePerUnitCents: pricePerUnitCents ?? this.pricePerUnitCents,
      purchasePack: purchasePack ?? this.purchasePack,
      aisle: aisle ?? this.aisle,
      tags: tags ?? this.tags,
      source: source ?? this.source,
      lastVerifiedAt: lastVerifiedAt ?? this.lastVerifiedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        unit,
        macrosPer100g,
        pricePerUnitCents,
        purchasePack,
        aisle,
        tags,
        source,
        lastVerifiedAt,
      ];
}
