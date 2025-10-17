import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../sync/snapshot_models.dart';
import '../entities/plan.dart';
import '../entities/recipe.dart';
import '../entities/ingredient.dart';
import '../entities/pantry_item.dart';
import '../../presentation/providers/recipe_providers.dart';
import '../../presentation/providers/ingredient_providers.dart';
import '../../presentation/providers/plan_providers.dart';
import '../../presentation/providers/pantry_providers.dart';
import '../services/budget_settings_service.dart';
import '../services/periodization_service.dart';
import '../services/taste_profile_service.dart';
import '../services/multiweek_series_service.dart';
import '../services/price_history_service.dart';
import '../services/sub_rules_service.dart';

final restoreServiceProvider = Provider<RestoreService>((ref) => RestoreService(ref));

class RestoreService {
  RestoreService(this.ref);
  final Ref ref;

  Future<void> apply(AppSnapshot snapshot) async {
    // Drift sections: simple truncate/replace for v1
    final planRepo = ref.read(planRepositoryProvider);
    final recipeRepo = ref.read(recipeRepositoryProvider);
    final ingRepo = ref.read(ingredientRepositoryProvider);
    final pantryRepo = ref.read(pantryRepositoryProvider);

    // Clear + import
    // Plans
    final existingPlans = await planRepo.getAllPlans();
    for (final p in existingPlans) {
      await planRepo.deletePlan(p.id);
    }
    for (final j in (snapshot.drift['plans'] as List).cast<Map>()) {
      await planRepo.savePlan(
        // ignore: avoid_dynamic_calls
        Plan.fromJson(Map<String, dynamic>.from(j as Map)),
      );
    }

    // Recipes: replace all manual + seed (safe for v1 since snapshot is authoritative)
    final existingRecipes = await recipeRepo.getAllRecipes();
    for (final r in existingRecipes) {
      await recipeRepo.deleteRecipe(r.id);
    }
    for (final j in (snapshot.drift['recipes'] as List).cast<Map>()) {
      await recipeRepo.addRecipe(
        Recipe.fromJson(Map<String, dynamic>.from(j as Map)),
      );
    }

    // Ingredients
    final existingIngs = await ingRepo.getAllIngredients();
    for (final i in existingIngs) {
      await ingRepo.deleteIngredient(i.id);
    }
    for (final j in (snapshot.drift['ingredients'] as List).cast<Map>()) {
      await ingRepo.addIngredient(
        Ingredient.fromJson(Map<String, dynamic>.from(j as Map)),
      );
    }

    // Pantry
    await pantryRepo.clearPantry();
    final pantryItems = (snapshot.drift['pantry'] as List)
        .cast<Map>()
        .map((m) => PantryItem.fromJson(Map<String, dynamic>.from(m as Map)))
        .toList();
    if (pantryItems.isNotEmpty) {
      await pantryRepo.bulkInsertPantryItems(pantryItems);
    }

    // SP sections
    final budgetSvc = ref.read(budgetSettingsServiceProvider);
    await budgetSvc.save(BudgetSettings.fromJson(
        (snapshot.sp['budget.settings.v2'] as Map).cast<String, dynamic>()));

    final periodSvc = ref.read(periodizationServiceProvider);
    final phases = (snapshot.sp['periodization.phases.v1'] as List)
        .cast<Map>()
        .map((m) => Phase.fromJson(Map<String, dynamic>.from(m as Map)))
        .toList();
    await periodSvc.saveAll(phases);

    final tasteSvc = ref.read(tasteProfileServiceProvider);
    await tasteSvc.save(TasteProfile.fromJson(
        (snapshot.sp['taste.profile.v1'] as Map).cast<String, dynamic>()));

    final seriesSvc = ref.read(multiweekSeriesServiceProvider);
    for (final m in (snapshot.sp['multiweek.series.v1'] as List).cast<Map>()) {
      await seriesSvc.upsert(
        MultiweekSeries.fromJson(Map<String, dynamic>.from(m as Map)),
      );
    }

    // Price history write back raw
    final sp = await SharedPreferences.getInstance();
    final priceRaw = snapshot.sp['price.history.v1'];
    if (priceRaw is Map<String, dynamic>) {
      await sp.setString('price.history.v1', jsonEncode(priceRaw));
    }

    final subSvc = ref.read(subRulesServiceProvider);
    final rules = (snapshot.sp['sub.rules.v1'] as List)
        .cast<Map>()
        .map((m) => SubRule.fromJson(Map<String, dynamic>.from(m as Map)))
        .toList();
    await subSvc.saveAll(rules);

    // Shopping checked states
    final shopping = snapshot.sp['shopping.checked.v1'];
    if (shopping is Map<String, dynamic>) {
      for (final e in shopping.entries) {
        final k = e.key;
        final v = e.value;
        if (v is List) {
          final xs = v.whereType<String>().toList();
          await sp.setStringList(k, xs);
        }
      }
    }

    if (kDebugMode) {
      debugPrint('[Cloud][restore] applied snapshot with ${phases.length} phases, ${rules.length} rules');
    }
  }
}
