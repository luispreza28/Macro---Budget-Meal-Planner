import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/ingredient.dart';
import '../../../domain/services/shortfall_service.dart';
import '../../providers/shortfall_providers.dart';
import '../../providers/ingredient_providers.dart';
import '../../providers/database_providers.dart';
import '../../providers/shopping_list_providers.dart';
import '../../providers/plan_providers.dart';
import '../../providers/pantry_providers.dart';
import '../../../domain/value/shortfall_item.dart' as v1;
import '../../../domain/services/unit_align.dart';

class ShortfallFixItSheet extends ConsumerWidget {
  const ShortfallFixItSheet({
    super.key,
    required this.recipeId,
    required this.servingsForMeal,
    this.onSwapRequested,
  });

  final String recipeId;
  final int servingsForMeal;
  final VoidCallback? onSwapRequested;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = (recipeId: recipeId, servingsForMeal: servingsForMeal);
    final async = ref.watch(mealShortfallProvider(args));
    final ingsAsync = ref.watch(allIngredientsProvider);

    return async.when(
      loading: () => const SizedBox(height: 180, child: Center(child: CircularProgressIndicator())),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Failed to compute shortfalls: $e'),
      ),
      data: (ms) {
        final coverage = ms.coverageRatio;
        final lines = ms.lines;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Fix It', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: coverage.clamp(0, 1).toDouble(),
                            minHeight: 8,
                          ),
                          const SizedBox(height: 4),
                          Text('${(coverage * 100).round()}% covered', style: Theme.of(context).textTheme.labelSmall),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: lines.isEmpty ? null : () async {
                        await _addAllToShopping(context, ref, lines);
                      },
                      icon: const Icon(Icons.add_shopping_cart),
                      label: const Text('Fix All'),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                ingsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('Failed to load ingredients: $e'),
                  ),
                  data: (ings) {
                    final ingById = {for (final i in ings) i.id: i};
                    if (lines.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text('No shortfalls for this meal', style: Theme.of(context).textTheme.bodyMedium),
                      );
                    }

                    return Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: lines.length,
                        separatorBuilder: (_, __) => const Divider(height: 12, thickness: 0.5),
                        itemBuilder: (_, i) {
                          final l = lines[i];
                          final ing = ingById[l.ingredientId];
                          final need = _fmt(l.requiredQty, l.displayUnit);
                          final have = _fmt(l.onHandQty, l.displayUnit);
                          final add = _fmt(l.remainingQty, l.displayUnit);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${l.ingredientName} • need $need, have $have → add $add',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  if (l.unitMismatch)
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.tertiaryContainer,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        "Unit mismatch",
                                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                              color: Theme.of(context).colorScheme.onTertiaryContainer,
                                            ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: FilledButton(
                                      onPressed: l.unitMismatch || l.remainingQty <= 0
                                          ? null
                                          : () async {
                                              await _addToShopping(context, ref, l, ing);
                                            },
                                      child: const Text('Add to Shopping'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton(
                                    onPressed: (l.unitMismatch || (l.onHandQty <= 0) || ing == null)
                                        ? null
                                        : () async {
                                            await _usePantry(context, ref, l, ing);
                                          },
                                    child: const Text('Use Pantry'),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    tooltip: 'Smart Swap',
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      onSwapRequested?.call();
                                      if (onSwapRequested == null) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Open Swap from the meal slot to filter by Pantry-first/Cheaper')),
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.swap_horiz),
                                  ),
                                ],
                              ),
                              if (l.unitMismatch)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    "Can’t convert on-hand to required unit (needs density or piece size).",
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Done'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _addAllToShopping(BuildContext context, WidgetRef ref, List<ShortfallLine> lines) async {
    try {
      final ings = await ref.read(allIngredientsProvider.future);
      final byId = {for (final i in ings) i.id: i};
      final plan = await ref.read(currentPlanProvider.future);
      final shop = ref.read(shoppingListRepositoryProvider);

      // Build items for non-mismatch lines
      final items = <v1.ShortfallItem>[];
      for (final l in lines) {
        if (l.unitMismatch || l.remainingQty <= 0) continue;
        final ing = byId[l.ingredientId];
        if (ing == null) continue;
        items.add(
          v1.ShortfallItem(
            ingredientId: l.ingredientId,
            name: ing.name,
            missingQty: l.remainingQty,
            unit: l.displayUnit,
            aisle: ing.aisle,
          ),
        );
      }
      if (items.isEmpty) return;
      await shop.addShortfalls(items, planId: plan?.id);
      if (kDebugMode) {
        debugPrint('[FixIt] Added ${items.length} items to shopping');
      }
      ref.invalidate(shoppingListItemsProvider);
      ref.invalidate(mealShortfallProvider((recipeId: recipeId, servingsForMeal: servingsForMeal)));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to Shopping')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _addToShopping(BuildContext context, WidgetRef ref, ShortfallLine l, Ingredient? ing) async {
    if (ing == null) return;
    try {
      final plan = await ref.read(currentPlanProvider.future);
      final shop = ref.read(shoppingListRepositoryProvider);
      final item = v1.ShortfallItem(
        ingredientId: l.ingredientId,
        name: ing.name,
        missingQty: l.remainingQty,
        unit: l.displayUnit,
        aisle: ing.aisle,
      );
      await shop.addShortfalls([item], planId: plan?.id);
      if (kDebugMode) {
        debugPrint('[FixIt] Added ${ing.name} ${l.remainingQty} ${l.displayUnit.name} to shopping');
      }
      ref.invalidate(shoppingListItemsProvider);
      ref.invalidate(mealShortfallProvider((recipeId: recipeId, servingsForMeal: servingsForMeal)));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to Shopping')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _usePantry(BuildContext context, WidgetRef ref, ShortfallLine l, Ingredient ing) async {
    try {
      // Consume required from pantry now: min(on-hand, required)
      final consumeAligned = l.onHandQty <= 0 ? 0 : (l.onHandQty > l.requiredQty ? l.requiredQty : l.onHandQty);
      if (consumeAligned <= 0) return;

      // Convert aligned display unit back to ingredient base unit
      final toBase = alignQty(qty: consumeAligned, from: l.displayUnit, to: ing.unit, ing: ing);
      if (toBase == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Conversion not possible')));
        return;
      }

      final pantry = ref.read(pantryRepositoryProvider);
      await pantry.addOnHandDeltas([
        (ingredientId: ing.id, qty: -toBase, unit: ing.unit),
      ]);

      if (kDebugMode) {
        debugPrint('[FixIt] Used pantry: ${ing.name} ${toBase.toStringAsFixed(2)} ${ing.unit.name}');
      }

      // Invalidate: pantry + shopping + this meal shortfall
      ref.invalidate(allPantryItemsProvider);
      ref.invalidate(shoppingListItemsProvider);
      ref.invalidate(mealShortfallProvider((recipeId: recipeId, servingsForMeal: servingsForMeal)));

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pantry updated')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  String _fmt(double v, Unit u) {
    final rounded = ((v * 10).round() / 10.0);
    final s = (rounded % 1 == 0) ? rounded.toStringAsFixed(0) : rounded.toStringAsFixed(1);
    switch (u) {
      case Unit.grams:
        return '$s g';
      case Unit.milliliters:
        return '$s ml';
      case Unit.piece:
        return '$s pc';
    }
  }
}
