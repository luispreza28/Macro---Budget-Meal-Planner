// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_targets.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserTargets _$UserTargetsFromJson(Map<String, dynamic> json) => UserTargets(
  id: json['id'] as String,
  kcal: (json['kcal'] as num).toDouble(),
  proteinG: (json['proteinG'] as num).toDouble(),
  carbsG: (json['carbsG'] as num).toDouble(),
  fatG: (json['fatG'] as num).toDouble(),
  budgetCents: (json['budgetCents'] as num?)?.toInt(),
  mealsPerDay: (json['mealsPerDay'] as num).toInt(),
  timeCapMins: (json['timeCapMins'] as num?)?.toInt(),
  dietFlags: (json['dietFlags'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  equipment: (json['equipment'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  planningMode: $enumDecode(_$PlanningModeEnumMap, json['planningMode']),
);

Map<String, dynamic> _$UserTargetsToJson(UserTargets instance) =>
    <String, dynamic>{
      'id': instance.id,
      'kcal': instance.kcal,
      'proteinG': instance.proteinG,
      'carbsG': instance.carbsG,
      'fatG': instance.fatG,
      'budgetCents': instance.budgetCents,
      'mealsPerDay': instance.mealsPerDay,
      'timeCapMins': instance.timeCapMins,
      'dietFlags': instance.dietFlags,
      'equipment': instance.equipment,
      'planningMode': _$PlanningModeEnumMap[instance.planningMode]!,
    };

const _$PlanningModeEnumMap = {
  PlanningMode.cutting: 'cutting',
  PlanningMode.bulkingBudget: 'bulking_budget',
  PlanningMode.bulkingNoBudget: 'bulking_no_budget',
  PlanningMode.maintenance: 'maintenance',
};
