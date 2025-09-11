// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlanMeal _$PlanMealFromJson(Map<String, dynamic> json) => PlanMeal(
  recipeId: json['recipeId'] as String,
  servings: (json['servings'] as num).toDouble(),
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$PlanMealToJson(PlanMeal instance) => <String, dynamic>{
  'recipeId': instance.recipeId,
  'servings': instance.servings,
  'notes': instance.notes,
};

PlanDay _$PlanDayFromJson(Map<String, dynamic> json) => PlanDay(
  date: json['date'] as String,
  meals: (json['meals'] as List<dynamic>)
      .map((e) => PlanMeal.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$PlanDayToJson(PlanDay instance) => <String, dynamic>{
  'date': instance.date,
  'meals': instance.meals,
};

PlanTotals _$PlanTotalsFromJson(Map<String, dynamic> json) => PlanTotals(
  kcal: (json['kcal'] as num).toDouble(),
  proteinG: (json['proteinG'] as num).toDouble(),
  carbsG: (json['carbsG'] as num).toDouble(),
  fatG: (json['fatG'] as num).toDouble(),
  costCents: (json['costCents'] as num).toInt(),
);

Map<String, dynamic> _$PlanTotalsToJson(PlanTotals instance) =>
    <String, dynamic>{
      'kcal': instance.kcal,
      'proteinG': instance.proteinG,
      'carbsG': instance.carbsG,
      'fatG': instance.fatG,
      'costCents': instance.costCents,
    };

Plan _$PlanFromJson(Map<String, dynamic> json) => Plan(
  id: json['id'] as String,
  name: json['name'] as String,
  userTargetsId: json['userTargetsId'] as String,
  days: (json['days'] as List<dynamic>)
      .map((e) => PlanDay.fromJson(e as Map<String, dynamic>))
      .toList(),
  totals: PlanTotals.fromJson(json['totals'] as Map<String, dynamic>),
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$PlanToJson(Plan instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'userTargetsId': instance.userTargetsId,
  'days': instance.days,
  'totals': instance.totals,
  'createdAt': instance.createdAt.toIso8601String(),
};
