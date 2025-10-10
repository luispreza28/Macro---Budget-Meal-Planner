import 'package:meta/meta.dart';

import '../entities/ingredient.dart';

/// Lightweight value object describing a missing quantity for an ingredient,
/// after accounting for pantry on-hand and unit alignment rules.
@immutable
class ShortfallItem {
  const ShortfallItem({
    required this.ingredientId,
    required this.name,
    required this.missingQty,
    required this.unit,
    required this.aisle,
    this.reason,
  });

  final String ingredientId;
  final String name;
  /// Positive missing quantity, already aligned to a concrete unit.
  final double missingQty;
  final Unit unit;
  final Aisle aisle;
  /// Optional mismatch/diagnostic reason (e.g., unit mismatch, insufficient pantry)
  final String? reason;

  ShortfallItem copyWith({
    String? ingredientId,
    String? name,
    double? missingQty,
    Unit? unit,
    Aisle? aisle,
    String? Function()? reason,
  }) {
    return ShortfallItem(
      ingredientId: ingredientId ?? this.ingredientId,
      name: name ?? this.name,
      missingQty: missingQty ?? this.missingQty,
      unit: unit ?? this.unit,
      aisle: aisle ?? this.aisle,
      reason: reason != null ? reason() : this.reason,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ShortfallItem &&
        other.ingredientId == ingredientId &&
        other.name == name &&
        other.missingQty == missingQty &&
        other.unit == unit &&
        other.aisle == aisle &&
        other.reason == reason;
  }

  @override
  int get hashCode => Object.hash(
        ingredientId,
        name,
        missingQty,
        unit,
        aisle,
        reason,
      );
}

