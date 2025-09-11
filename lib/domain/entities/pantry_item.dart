import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import 'ingredient.dart';

part 'pantry_item.g.dart';

/// Pantry item representing ingredients on hand for pantry-first planning
@JsonSerializable()
class PantryItem extends Equatable {
  const PantryItem({
    required this.id,
    required this.ingredientId,
    required this.qty,
    required this.unit,
    required this.addedAt,
  });

  /// Unique identifier for the pantry item
  final String id;

  /// Reference to the ingredient ID
  final String ingredientId;

  /// Quantity available in pantry
  final double qty;

  /// Unit for the quantity
  final Unit unit;

  /// Date when the item was added to pantry
  final DateTime addedAt;

  factory PantryItem.fromJson(Map<String, dynamic> json) =>
      _$PantryItemFromJson(json);

  Map<String, dynamic> toJson() => _$PantryItemToJson(this);

  /// Check if pantry has enough quantity for a recipe requirement
  bool hasEnoughFor(double requiredQty, Unit requiredUnit) {
    // For simplicity, assume same unit for now
    // In production, would need unit conversion
    if (unit != requiredUnit) return false;
    return qty >= requiredQty;
  }

  /// Calculate remaining quantity after using some
  PantryItem useQuantity(double usedQty) {
    final remainingQty = (qty - usedQty).clamp(0.0, double.infinity);
    return PantryItem(
      id: id,
      ingredientId: ingredientId,
      qty: remainingQty,
      unit: unit,
      addedAt: addedAt,
    );
  }

  /// Check if pantry item is empty
  bool get isEmpty => qty <= 0;

  /// Copy with new values
  PantryItem copyWith({
    String? id,
    String? ingredientId,
    double? qty,
    Unit? unit,
    DateTime? addedAt,
  }) {
    return PantryItem(
      id: id ?? this.id,
      ingredientId: ingredientId ?? this.ingredientId,
      qty: qty ?? this.qty,
      unit: unit ?? this.unit,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  @override
  List<Object?> get props => [id, ingredientId, qty, unit, addedAt];
}
