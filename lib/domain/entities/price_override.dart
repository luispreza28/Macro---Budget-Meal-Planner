import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'ingredient.dart';

part 'price_override.g.dart';

/// Price override for custom ingredient pricing
@JsonSerializable()
class PriceOverride extends Equatable {
  const PriceOverride({
    required this.id,
    required this.ingredientId,
    required this.pricePerUnitCents,
    this.purchasePack,
  });

  /// Unique identifier for the price override
  final String id;

  /// Reference to the ingredient ID
  final String ingredientId;

  /// Custom price per base unit in cents
  final int pricePerUnitCents;

  /// Optional custom purchase pack information
  final PurchasePack? purchasePack;

  factory PriceOverride.fromJson(Map<String, dynamic> json) =>
      _$PriceOverrideFromJson(json);

  Map<String, dynamic> toJson() => _$PriceOverrideToJson(this);

  /// Create price override from ingredient with new price
  factory PriceOverride.fromIngredient({
    required String id,
    required Ingredient ingredient,
    required int newPricePerUnitCents,
    PurchasePack? newPurchasePack,
  }) {
    return PriceOverride(
      id: id,
      ingredientId: ingredient.id,
      pricePerUnitCents: newPricePerUnitCents,
      purchasePack: newPurchasePack ?? ingredient.purchasePack,
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
        baseQuantity = quantity * (purchasePack?.qty ?? 1);
        break;
    }

    return (baseQuantity * pricePerUnitCents / 1).round();
  }

  /// Get price difference compared to original ingredient
  int getPriceDifference(Ingredient originalIngredient) {
    return pricePerUnitCents - originalIngredient.pricePerUnitCents;
  }

  /// Get price difference percentage
  double getPriceDifferencePercent(Ingredient originalIngredient) {
    if (originalIngredient.pricePerUnitCents == 0) return 0.0;
    return ((pricePerUnitCents - originalIngredient.pricePerUnitCents) / 
            originalIngredient.pricePerUnitCents) * 100;
  }

  /// Copy with new values
  PriceOverride copyWith({
    String? id,
    String? ingredientId,
    int? pricePerUnitCents,
    PurchasePack? purchasePack,
  }) {
    return PriceOverride(
      id: id ?? this.id,
      ingredientId: ingredientId ?? this.ingredientId,
      pricePerUnitCents: pricePerUnitCents ?? this.pricePerUnitCents,
      purchasePack: purchasePack ?? this.purchasePack,
    );
  }

  @override
  List<Object?> get props => [id, ingredientId, pricePerUnitCents, purchasePack];
}
