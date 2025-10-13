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
  const PurchasePack({required this.qty, required this.unit, this.priceCents});

  final double qty;
  final Unit unit;
  final int? priceCents;

  factory PurchasePack.fromJson(Map<String, dynamic> json) =>
      _$PurchasePackFromJson(json);

  Map<String, dynamic> toJson() => _$PurchasePackToJson(this);

  @override
  List<Object?> get props => [qty, unit, priceCents];
}

/// Value object: Nutrition per 100 base units (g/ml) or per piece.
class NutritionPer100 {
  const NutritionPer100({
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  final double kcal;
  final double proteinG;
  final double carbsG;
  final double fatG;

  Map<String, dynamic> toJson() => {
        'kcal': kcal,
        'proteinG': proteinG,
        'carbsG': carbsG,
        'fatG': fatG,
      };

  factory NutritionPer100.fromJson(Map<String, dynamic> j) => NutritionPer100(
        kcal: (j['kcal'] ?? 0).toDouble(),
        proteinG: (j['proteinG'] ?? 0).toDouble(),
        carbsG: (j['carbsG'] ?? 0).toDouble(),
        fatG: (j['fatG'] ?? 0).toDouble(),
      );
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
    this.nutritionPer100gKcal,
    this.nutritionPer100gProteinG,
    this.nutritionPer100gCarbsG,
    this.nutritionPer100gFatG,
    this.nutritionPerPieceKcal,
    this.nutritionPerPieceProteinG,
    this.nutritionPerPieceCarbsG,
    this.nutritionPerPieceFatG,
    this.densityGPerMl,
    this.gramsPerPiece,
    this.mlPerPiece,
    this.per100Json,
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

  /// Optional granular nutrition overrides per 100g/ml.
  final double? nutritionPer100gKcal;
  final double? nutritionPer100gProteinG;
  final double? nutritionPer100gCarbsG;
  final double? nutritionPer100gFatG;

  /// Optional granular nutrition overrides per piece.
  final double? nutritionPerPieceKcal;
  final double? nutritionPerPieceProteinG;
  final double? nutritionPerPieceCarbsG;
  final double? nutritionPerPieceFatG;

  /// Optional conversion helpers
  /// Density in g/ml for grams<->ml conversions when known
  final double? densityGPerMl;
  /// Typical grams per piece when base unit is piece, or to convert pieces
  final double? gramsPerPiece;
  /// Typical ml per piece when base unit is piece, or to convert pieces
  final double? mlPerPiece;

  /// Optional nested JSON field for per-100 macros, if ever serialized that way
  /// Note: DB currently stores flat fields; this is for forward-compat JSON.
  final NutritionPer100? per100Json;

  factory Ingredient.fromJson(Map<String, dynamic> json) =>
      _$IngredientFromJson(json);

  Map<String, dynamic> toJson() => _$IngredientToJson(this);

  /// Backward-compatible adapter to expose per-100 macros in a single object.
  ///
  /// Priority cascade (unifies legacy and new storage):
  /// 1) If per-piece overrides exist AND unit==piece, use them as "per piece".
  /// 2) Else, if per-100 overrides exist, use them.
  /// 3) Else, if legacy macrosPer100g has any non-zero, use them.
  /// 4) Else, fall back to nested per100Json.
  /// 5) If none available, return null.
  NutritionPer100? get per100 {
    // 1) Per-piece overrides when base unit is piece
    if (_hasPerPieceOverrides && unit == Unit.piece) {
      return NutritionPer100(
        kcal: nutritionPerPieceKcal ?? 0,
        proteinG: nutritionPerPieceProteinG ?? 0,
        carbsG: nutritionPerPieceCarbsG ?? 0,
        fatG: nutritionPerPieceFatG ?? 0,
      );
    }

    // 2) Per-100 overrides
    if (_hasPer100Overrides) {
      return NutritionPer100(
        kcal: nutritionPer100gKcal ?? 0,
        proteinG: nutritionPer100gProteinG ?? 0,
        carbsG: nutritionPer100gCarbsG ?? 0,
        fatG: nutritionPer100gFatG ?? 0,
      );
    }

    // 3) Legacy macrosPer100g if any non-zero
    final m = macrosPer100g;
    final hasAny = (m.kcal != 0) || (m.proteinG != 0) || (m.carbsG != 0) || (m.fatG != 0);
    if (hasAny) {
      return NutritionPer100(
        kcal: m.kcal,
        proteinG: m.proteinG,
        carbsG: m.carbsG,
        fatG: m.fatG,
      );
    }

    // 4) Fallback to nested JSON if present
    if (per100Json != null) return per100Json;

    // 5) Nothing available
    return null;
  }

  // Helper flags to keep per100 cascade readable
  bool get _hasPerPieceOverrides =>
      nutritionPerPieceKcal != null ||
      nutritionPerPieceProteinG != null ||
      nutritionPerPieceCarbsG != null ||
      nutritionPerPieceFatG != null;

  bool get _hasPer100Overrides =>
      nutritionPer100gKcal != null ||
      nutritionPer100gProteinG != null ||
      nutritionPer100gCarbsG != null ||
      nutritionPer100gFatG != null;

  // Optional: quick check for non-zero nutrition (used in logging)
  bool get hasAnyNutrition =>
      per100 != null &&
      ((per100!.kcal + per100!.proteinG + per100!.carbsG + per100!.fatG) > 0);

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
    double? Function()? nutritionPer100gKcal,
    double? Function()? nutritionPer100gProteinG,
    double? Function()? nutritionPer100gCarbsG,
    double? Function()? nutritionPer100gFatG,
    double? Function()? nutritionPerPieceKcal,
    double? Function()? nutritionPerPieceProteinG,
    double? Function()? nutritionPerPieceCarbsG,
    double? Function()? nutritionPerPieceFatG,
    double? Function()? densityGPerMl,
    double? Function()? gramsPerPiece,
    double? Function()? mlPerPiece,
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
      nutritionPer100gKcal: nutritionPer100gKcal != null
          ? nutritionPer100gKcal()
          : this.nutritionPer100gKcal,
      nutritionPer100gProteinG: nutritionPer100gProteinG != null
          ? nutritionPer100gProteinG()
          : this.nutritionPer100gProteinG,
      nutritionPer100gCarbsG: nutritionPer100gCarbsG != null
          ? nutritionPer100gCarbsG()
          : this.nutritionPer100gCarbsG,
      nutritionPer100gFatG: nutritionPer100gFatG != null
          ? nutritionPer100gFatG()
          : this.nutritionPer100gFatG,
      nutritionPerPieceKcal: nutritionPerPieceKcal != null
          ? nutritionPerPieceKcal()
          : this.nutritionPerPieceKcal,
      nutritionPerPieceProteinG: nutritionPerPieceProteinG != null
          ? nutritionPerPieceProteinG()
          : this.nutritionPerPieceProteinG,
      nutritionPerPieceCarbsG: nutritionPerPieceCarbsG != null
          ? nutritionPerPieceCarbsG()
          : this.nutritionPerPieceCarbsG,
      nutritionPerPieceFatG: nutritionPerPieceFatG != null
          ? nutritionPerPieceFatG()
          : this.nutritionPerPieceFatG,
      densityGPerMl: densityGPerMl != null ? densityGPerMl() : this.densityGPerMl,
      gramsPerPiece: gramsPerPiece != null ? gramsPerPiece() : this.gramsPerPiece,
      mlPerPiece: mlPerPiece != null ? mlPerPiece() : this.mlPerPiece,
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
    nutritionPer100gKcal,
    nutritionPer100gProteinG,
    nutritionPer100gCarbsG,
    nutritionPer100gFatG,
    nutritionPerPieceKcal,
    nutritionPerPieceProteinG,
    nutritionPerPieceCarbsG,
    nutritionPerPieceFatG,
    densityGPerMl,
    gramsPerPiece,
    mlPerPiece,
  ];
}

extension IngredientPieceHelpers on Ingredient {
  bool get hasPerPieceOverride =>
      (nutritionPerPieceKcal ?? 0) > 0 ||
      (nutritionPerPieceProteinG ?? 0) > 0 ||
      (nutritionPerPieceCarbsG ?? 0) > 0 ||
      (nutritionPerPieceFatG ?? 0) > 0;

  NutritionPer100? get perPieceAsNutrition => hasPerPieceOverride
      ? NutritionPer100(
          kcal: nutritionPerPieceKcal ?? 0,
          proteinG: nutritionPerPieceProteinG ?? 0,
          carbsG: nutritionPerPieceCarbsG ?? 0,
          fatG: nutritionPerPieceFatG ?? 0,
        )
      : null;
}
