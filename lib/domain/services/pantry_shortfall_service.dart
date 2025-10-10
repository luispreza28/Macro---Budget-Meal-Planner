import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../entities/ingredient.dart';
import '../entities/plan.dart';
import '../entities/recipe.dart';
import '../repositories/ingredient_repository.dart';
import '../repositories/pantry_repository.dart';
import '../value/shortfall_item.dart';
import '../../presentation/providers/database_providers.dart';

final pantryShortfallServiceProvider =
    Provider<PantryShortfallService>((ref) => PantryShortfallService(ref));

class PantryShortfallService {
  PantryShortfallService(this.ref);
  final Ref ref;

  /// For a single recipe: returns shortfalls after subtracting pantry stock.
  Future<List<ShortfallItem>> shortfallForRecipe(Recipe recipe) async {
    final requiredItems = <({String ingredientId, double qty, Unit unit})>[];
    for (final it in recipe.items) {
      requiredItems.add((ingredientId: it.ingredientId, qty: it.qty, unit: it.unit));
    }
    return computeShortfalls(requiredItems: requiredItems);
  }

  /// For the current plan: aggregates all meals across 7 days.
  Future<List<ShortfallItem>> shortfallForPlan(Plan plan) async {
    final recipeRepo = ref.read(recipeRepositoryProvider);
    final recipeIds = <String>{
      for (final d in plan.days) ...d.meals.map((m) => m.recipeId),
    }.toList();
    final recipes = await recipeRepo.getRecipesByIds(recipeIds);
    final recipeById = {for (final r in recipes) r.id: r};

    final requiredItems = <({String ingredientId, double qty, Unit unit})>[];
    for (final d in plan.days) {
      for (final m in d.meals) {
        final r = recipeById[m.recipeId];
        if (r == null) continue;
        for (final it in r.items) {
          requiredItems.add((
            ingredientId: it.ingredientId,
            qty: it.qty * m.servings,
            unit: it.unit,
          ));
        }
      }
    }
    return computeShortfalls(requiredItems: requiredItems);
  }

  /// Core utility: given required items (ingredientId, qty, unit) → shortfalls.
  Future<List<ShortfallItem>> computeShortfalls({
    required List<({String ingredientId, double qty, Unit unit})> requiredItems,
  }) async {
    if (requiredItems.isEmpty) return const [];

    // Aggregate required by ingredientId+unit to avoid unsafe conversions.
    final Map<String, Map<Unit, double>> requiredByIngredient = {};
    for (final r in requiredItems) {
      final byUnit = requiredByIngredient.putIfAbsent(r.ingredientId, () => {});
      byUnit.update(r.unit, (v) => v + r.qty, ifAbsent: () => r.qty);
    }

    if (kDebugMode) {
      requiredByIngredient.forEach((id, map) {
        map.forEach((unit, qty) {
          debugPrint('[Shortfall] REQ agg: $id -> ${qty.toStringAsFixed(2)} ${unit.name}');
        });
      });
    }

    final ingredientRepo = ref.read(ingredientRepositoryProvider);
    final allIngredients = await ingredientRepo.getAllIngredients();
    final ingById = {for (final i in allIngredients) i.id: i};

    final pantryRepo = ref.read(pantryRepositoryProvider);
    final pantryItems = await pantryRepo.getAllPantryItems();
    // Aggregate pantry on-hand by ingredientId+unit
    final Map<String, Map<Unit, double>> onHandByIngredient = {};
    for (final p in pantryItems) {
      final byUnit = onHandByIngredient.putIfAbsent(p.ingredientId, () => {});
      byUnit.update(p.unit, (v) => v + p.qty, ifAbsent: () => p.qty);
    }
    if (kDebugMode) {
      onHandByIngredient.forEach((id, map) {
        map.forEach((unit, qty) {
          debugPrint('[Shortfall] PANTRY onHand: $id -> ${qty.toStringAsFixed(2)} ${unit.name}');
        });
      });
    }

    final out = <ShortfallItem>[];
    for (final entry in requiredByIngredient.entries) {
      final ingredientId = entry.key;
      final requiredUnits = entry.value; // Map<Unit,double>
      final ingredient = ingById[ingredientId];
      if (ingredient == null) {
        // Unknown ingredient; still output missing based on required units.
        for (final req in requiredUnits.entries) {
          final missing = req.value;
          if (missing > 0.0001) {
            out.add(
              ShortfallItem(
                ingredientId: ingredientId,
                name: ingredientId,
                missingQty: missing,
                unit: req.key,
                aisle: Aisle.pantry,
                reason: 'ingredient metadata missing',
              ),
            );
          }
        }
        continue;
      }

      final onHandUnits = onHandByIngredient[ingredientId] ?? const {};

      for (final req in requiredUnits.entries) {
        final reqUnit = req.key;
        final reqQty = req.value;

        double missingQty = reqQty;
        String? reason;

        // Direct same-unit subtraction
        if (onHandUnits.containsKey(reqUnit)) {
          missingQty = (reqQty - (onHandUnits[reqUnit] ?? 0)).clamp(0.0, double.infinity);
        } else {
          // Attempt g<->ml conversion if density present.
          final canBeMassVolumePair =
              (reqUnit == Unit.grams && onHandUnits.keys.any((u) => u == Unit.milliliters)) ||
              (reqUnit == Unit.milliliters && onHandUnits.keys.any((u) => u == Unit.grams));

          final involvesPiece = reqUnit == Unit.piece ||
              onHandUnits.keys.any((u) => u == Unit.piece);

          if (involvesPiece && (reqUnit != Unit.piece || onHandUnits.isNotEmpty)) {
            // No piece<->mass/volume conversion
            reason = 'piece↔mass/volume mismatch';
            // keep required qty; do not subtract
          } else if (canBeMassVolumePair) {
            final density = ingredient.densityGPerMl;
            if (density == null || density <= 0) {
              reason = 'unit mismatch (needs density)';
              // keep required qty; do not subtract
            } else {
              // Convert all on-hand grams/ml to required unit using density and subtract
              double availableInReqUnit = 0.0;
              onHandUnits.forEach((u, qty) {
                if (u == Unit.grams && reqUnit == Unit.milliliters) {
                  availableInReqUnit += _gramsToMl(qty, density);
                } else if (u == Unit.milliliters && reqUnit == Unit.grams) {
                  availableInReqUnit += _mlToGrams(qty, density);
                }
              });
              missingQty = (reqQty - availableInReqUnit).clamp(0.0, double.infinity);
            }
          } else {
            // Other mismatches we cannot reconcile => keep required qty
            reason = 'unit mismatch';
          }
        }

        if (missingQty > 0.0001) {
          final item = ShortfallItem(
            ingredientId: ingredient.id,
            name: ingredient.name,
            missingQty: missingQty,
            unit: reqUnit,
            aisle: ingredient.aisle,
            reason: reason,
          );
          if (kDebugMode) {
            debugPrint('[Shortfall] OUT: ${item.name} missing=${item.missingQty.toStringAsFixed(2)} '
                '${item.unit.name} aisle=${item.aisle.name}');
          }
          out.add(item);
        } else {
          // Clamp to 0, don't emit negatives
        }
      }
    }

    return out;
  }

  double _mlToGrams(double qty, double densityGPerMl) => qty * densityGPerMl;
  double _gramsToMl(double qty, double densityGPerMl) => qty / densityGPerMl;
}

