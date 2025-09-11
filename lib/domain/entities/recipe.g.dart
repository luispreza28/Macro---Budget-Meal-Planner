// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecipeItem _$RecipeItemFromJson(Map<String, dynamic> json) => RecipeItem(
  ingredientId: json['ingredientId'] as String,
  qty: (json['qty'] as num).toDouble(),
  unit: $enumDecode(_$UnitEnumMap, json['unit']),
);

Map<String, dynamic> _$RecipeItemToJson(RecipeItem instance) =>
    <String, dynamic>{
      'ingredientId': instance.ingredientId,
      'qty': instance.qty,
      'unit': _$UnitEnumMap[instance.unit]!,
    };

const _$UnitEnumMap = {
  Unit.grams: 'g',
  Unit.milliliters: 'ml',
  Unit.piece: 'piece',
};

MacrosPerServing _$MacrosPerServingFromJson(Map<String, dynamic> json) =>
    MacrosPerServing(
      kcal: (json['kcal'] as num).toDouble(),
      proteinG: (json['proteinG'] as num).toDouble(),
      carbsG: (json['carbsG'] as num).toDouble(),
      fatG: (json['fatG'] as num).toDouble(),
    );

Map<String, dynamic> _$MacrosPerServingToJson(MacrosPerServing instance) =>
    <String, dynamic>{
      'kcal': instance.kcal,
      'proteinG': instance.proteinG,
      'carbsG': instance.carbsG,
      'fatG': instance.fatG,
    };

Recipe _$RecipeFromJson(Map<String, dynamic> json) => Recipe(
  id: json['id'] as String,
  name: json['name'] as String,
  servings: (json['servings'] as num).toInt(),
  timeMins: (json['timeMins'] as num).toInt(),
  cuisine: json['cuisine'] as String?,
  dietFlags: (json['dietFlags'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  items: (json['items'] as List<dynamic>)
      .map((e) => RecipeItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  steps: (json['steps'] as List<dynamic>).map((e) => e as String).toList(),
  macrosPerServ: MacrosPerServing.fromJson(
    json['macrosPerServ'] as Map<String, dynamic>,
  ),
  costPerServCents: (json['costPerServCents'] as num).toInt(),
  source: $enumDecode(_$RecipeSourceEnumMap, json['source']),
);

Map<String, dynamic> _$RecipeToJson(Recipe instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'servings': instance.servings,
  'timeMins': instance.timeMins,
  'cuisine': instance.cuisine,
  'dietFlags': instance.dietFlags,
  'items': instance.items,
  'steps': instance.steps,
  'macrosPerServ': instance.macrosPerServ,
  'costPerServCents': instance.costPerServCents,
  'source': _$RecipeSourceEnumMap[instance.source]!,
};

const _$RecipeSourceEnumMap = {
  RecipeSource.seed: 'seed',
  RecipeSource.manual: 'manual',
};
