// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ingredient.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MacrosPerHundred _$MacrosPerHundredFromJson(Map<String, dynamic> json) =>
    MacrosPerHundred(
      kcal: (json['kcal'] as num).toDouble(),
      proteinG: (json['proteinG'] as num).toDouble(),
      carbsG: (json['carbsG'] as num).toDouble(),
      fatG: (json['fatG'] as num).toDouble(),
    );

Map<String, dynamic> _$MacrosPerHundredToJson(MacrosPerHundred instance) =>
    <String, dynamic>{
      'kcal': instance.kcal,
      'proteinG': instance.proteinG,
      'carbsG': instance.carbsG,
      'fatG': instance.fatG,
    };

PurchasePack _$PurchasePackFromJson(Map<String, dynamic> json) => PurchasePack(
  qty: (json['qty'] as num).toDouble(),
  unit: $enumDecode(_$UnitEnumMap, json['unit']),
  priceCents: (json['priceCents'] as num?)?.toInt(),
);

Map<String, dynamic> _$PurchasePackToJson(PurchasePack instance) =>
    <String, dynamic>{
      'qty': instance.qty,
      'unit': _$UnitEnumMap[instance.unit]!,
      'priceCents': instance.priceCents,
    };

const _$UnitEnumMap = {
  Unit.grams: 'g',
  Unit.milliliters: 'ml',
  Unit.piece: 'piece',
};

Ingredient _$IngredientFromJson(Map<String, dynamic> json) => Ingredient(
  id: json['id'] as String,
  name: json['name'] as String,
  unit: $enumDecode(_$UnitEnumMap, json['unit']),
  macrosPer100g: MacrosPerHundred.fromJson(
    json['macrosPer100g'] as Map<String, dynamic>,
  ),
  pricePerUnitCents: (json['pricePerUnitCents'] as num).toInt(),
  purchasePack: PurchasePack.fromJson(
    json['purchasePack'] as Map<String, dynamic>,
  ),
  aisle: $enumDecode(_$AisleEnumMap, json['aisle']),
  tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
  source: $enumDecode(_$IngredientSourceEnumMap, json['source']),
  lastVerifiedAt: json['lastVerifiedAt'] == null
      ? null
      : DateTime.parse(json['lastVerifiedAt'] as String),
);

Map<String, dynamic> _$IngredientToJson(Ingredient instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'unit': _$UnitEnumMap[instance.unit]!,
      'macrosPer100g': instance.macrosPer100g,
      'pricePerUnitCents': instance.pricePerUnitCents,
      'purchasePack': instance.purchasePack,
      'aisle': _$AisleEnumMap[instance.aisle]!,
      'tags': instance.tags,
      'source': _$IngredientSourceEnumMap[instance.source]!,
      'lastVerifiedAt': instance.lastVerifiedAt?.toIso8601String(),
    };

const _$AisleEnumMap = {
  Aisle.produce: 'produce',
  Aisle.meat: 'meat',
  Aisle.dairy: 'dairy',
  Aisle.pantry: 'pantry',
  Aisle.frozen: 'frozen',
  Aisle.condiments: 'condiments',
  Aisle.bakery: 'bakery',
  Aisle.household: 'household',
};

const _$IngredientSourceEnumMap = {
  IngredientSource.seed: 'seed',
  IngredientSource.fdc: 'fdc',
  IngredientSource.off: 'off',
  IngredientSource.manual: 'manual',
};
