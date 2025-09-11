// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'price_override.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PriceOverride _$PriceOverrideFromJson(Map<String, dynamic> json) =>
    PriceOverride(
      id: json['id'] as String,
      ingredientId: json['ingredientId'] as String,
      pricePerUnitCents: (json['pricePerUnitCents'] as num).toInt(),
      purchasePack: json['purchasePack'] == null
          ? null
          : PurchasePack.fromJson(json['purchasePack'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PriceOverrideToJson(PriceOverride instance) =>
    <String, dynamic>{
      'id': instance.id,
      'ingredientId': instance.ingredientId,
      'pricePerUnitCents': instance.pricePerUnitCents,
      'purchasePack': instance.purchasePack,
    };
