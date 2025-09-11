import 'package:drift/drift.dart';
import 'dart:convert';

import '../../domain/entities/plan.dart' as domain;
import '../../domain/repositories/plan_repository.dart';
import '../datasources/database.dart';

/// Concrete implementation of PlanRepository using Drift
class PlanRepositoryImpl implements PlanRepository {
  const PlanRepositoryImpl(this._database);

  final AppDatabase _database;

  @override
  Future<List<domain.Plan>> getAllPlans() async {
    final plans = await _database.select(_database.plans).get();
    return plans.map(_mapToEntity).toList();
  }

  @override
  Future<domain.Plan?> getPlanById(String id) async {
    final plan = await (_database.select(_database.plans)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
    
    return plan != null ? _mapToEntity(plan) : null;
  }

  @override
  Future<domain.Plan?> getCurrentPlan() async {
    final plan = await (_database.select(_database.plans)
          ..where((tbl) => tbl.isCurrent.equals(true)))
        .getSingleOrNull();
    
    return plan != null ? _mapToEntity(plan) : null;
  }

  @override
  Future<void> savePlan(domain.Plan plan) async {
    await _database.into(_database.plans).insert(_mapFromEntity(plan));
  }

  @override
  Future<void> updatePlan(domain.Plan plan) async {
    await _database.update(_database.plans).replace(_mapFromEntity(plan));
  }

  @override
  Future<void> deletePlan(String id) async {
    await (_database.delete(_database.plans)
          ..where((tbl) => tbl.id.equals(id)))
        .go();
  }

  @override
  Future<void> setCurrentPlan(String id) async {
    await _database.transaction(() async {
      // Clear current flag from all plans
      await (_database.update(_database.plans)
            ..where((tbl) => tbl.isCurrent.equals(true)))
          .write(const PlansCompanion(isCurrent: Value(false)));
      
      // Set current flag for the specified plan
      await (_database.update(_database.plans)
            ..where((tbl) => tbl.id.equals(id)))
          .write(const PlansCompanion(isCurrent: Value(true)));
    });
  }

  @override
  Future<void> clearCurrentPlan() async {
    await (_database.update(_database.plans)
          ..where((tbl) => tbl.isCurrent.equals(true)))
        .write(const PlansCompanion(isCurrent: Value(false)));
  }

  @override
  Future<int> getPlansCount() async {
    final count = await (_database.selectOnly(_database.plans)
          ..addColumns([_database.plans.id.count()]))
        .getSingle();
    
    return count.read(_database.plans.id.count()) ?? 0;
  }

  @override
  Stream<List<domain.Plan>> watchAllPlans() {
    return _database.select(_database.plans).watch().map(
          (plans) => plans.map(_mapToEntity).toList(),
        );
  }

  @override
  Stream<domain.Plan?> watchCurrentPlan() {
    return (_database.select(_database.plans)
          ..where((tbl) => tbl.isCurrent.equals(true)))
        .watchSingleOrNull()
        .map((plan) => plan != null ? _mapToEntity(plan) : null);
  }

  /// Map from database model to domain entity
  domain.Plan _mapToEntity(PlanData data) {
    final daysJson = jsonDecode(data.days) as List<dynamic>;
    final days = daysJson.map((dayJson) => _mapDayFromJson(dayJson)).toList();
    
    return domain.Plan(
      id: data.id,
      name: data.name,
      days: days,
      totalKcal: data.totalKcal,
      totalProteinG: data.totalProteinG,
      totalCarbsG: data.totalCarbsG,
      totalFatG: data.totalFatG,
      totalCostCents: data.totalCostCents,
      score: data.score,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
    );
  }

  /// Map from domain entity to database companion
  PlansCompanion _mapFromEntity(domain.Plan plan) {
    final daysJson = plan.days.map(_mapDayToJson).toList();
    
    return PlansCompanion(
      id: Value(plan.id),
      name: Value(plan.name),
      days: Value(jsonEncode(daysJson)),
      totalKcal: Value(plan.totalKcal),
      totalProteinG: Value(plan.totalProteinG),
      totalCarbsG: Value(plan.totalCarbsG),
      totalFatG: Value(plan.totalFatG),
      totalCostCents: Value(plan.totalCostCents),
      score: Value(plan.score),
      isCurrent: Value(false), // Will be set separately if needed
      createdAt: Value(plan.createdAt),
      updatedAt: Value(plan.updatedAt),
    );
  }

  /// Map day from JSON
  domain.PlanDay _mapDayFromJson(dynamic dayJson) {
    final mealsJson = dayJson['meals'] as List<dynamic>;
    final meals = mealsJson.map((mealJson) => _mapMealFromJson(mealJson)).toList();
    
    return domain.PlanDay(
      date: DateTime.parse(dayJson['date']),
      meals: meals,
    );
  }

  /// Map day to JSON
  Map<String, dynamic> _mapDayToJson(domain.PlanDay day) {
    return {
      'date': day.date.toIso8601String(),
      'meals': day.meals.map(_mapMealToJson).toList(),
    };
  }

  /// Map meal from JSON
  domain.PlanMeal _mapMealFromJson(dynamic mealJson) {
    return domain.PlanMeal(
      recipeId: mealJson['recipeId'],
      servings: (mealJson['servings'] as num).toDouble(),
      mealType: domain.MealType.values.firstWhere(
        (type) => type.name == mealJson['mealType'],
        orElse: () => domain.MealType.breakfast,
      ),
      notes: mealJson['notes'],
    );
  }

  /// Map meal to JSON
  Map<String, dynamic> _mapMealToJson(domain.PlanMeal meal) {
    return {
      'recipeId': meal.recipeId,
      'servings': meal.servings,
      'mealType': meal.mealType.name,
      'notes': meal.notes,
    };
  }
}
