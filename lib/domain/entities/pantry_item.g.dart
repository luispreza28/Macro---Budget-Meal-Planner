// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pantry_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PantryItem _$PantryItemFromJson(Map<String, dynamic> json) => PantryItem(
  id: json['id'] as String,
  ingredientId: json['ingredientId'] as String,
  qty: (json['qty'] as num).toDouble(),
  unit: $enumDecode(_$UnitEnumMap, json['unit']),
  addedAt: DateTime.parse(json['addedAt'] as String),
);

Map<String, dynamic> _$PantryItemToJson(PantryItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'ingredientId': instance.ingredientId,
      'qty': instance.qty,
      'unit': _$UnitEnumMap[instance.unit]!,
      'addedAt': instance.addedAt.toIso8601String(),
    };

const _$UnitEnumMap = {
  Unit.grams: 'g',
  Unit.milliliters: 'ml',
  Unit.piece: 'piece',
};
