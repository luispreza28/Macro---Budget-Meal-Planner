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
import '../../../domain/services/substitutions_service.dart';
import '../../../domain/services/substitution_math.dart';
import '../../../domain/services/substitution_cost_service.dart';

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
                          LinearProgressIndicator(value: coverage.clamp(0, 1).toDouble(), minHeight: 8),
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
                  loading: () => const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: CircularProgressIndicator())),
                  error: (e, _) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('Failed to load ingredients: $e')),
                  data: (ings) {
                    final ingById = {for (final i in ings) i.id: i};
                    if (lines.isEmpty) {
                      return Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text('No shortfalls for this meal', style: Theme.of(context).textTheme.bodyMedium));
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
                                    child: Text(ing?.name ?? l.ingredientId, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondaryContainer, borderRadius: BorderRadius.circular(999)),
                                    child: Text('${(ms.coverageRatio * 100).round()}% covered', style: Theme.of(context).textTheme.labelSmall),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text('Need: $need • Have: $have • Add: $add', style: Theme.of(context).textTheme.bodySmall),
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
                                  OutlinedButton(
                                    onPressed: (ing == null)
                                        ? null
                                        : () async {
                                            await _substituteForLine(context, ref, l, ing);
                                          },
                                    child: const Text('Substitute'),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Done'))),
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
      final items = <v1.ShortfallItem>[];
      for (final l in lines) {
        if (l.unitMismatch || l.remainingQty <= 0) continue;
        final ing = byId[l.ingredientId];
        if (ing == null) continue;
        items.add(v1.ShortfallItem(ingredientId: l.ingredientId, name: ing.name, missingQty: l.remainingQty, unit: l.displayUnit, aisle: ing.aisle));
      }
      if (items.isEmpty) return;
      await shop.addShortfalls(items, planId: plan?.id);
      ref.invalidate(shoppingListItemsProvider);
      ref.invalidate(mealShortfallProvider((recipeId: recipeId, servingsForMeal: servingsForMeal)));
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to Shopping')));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _addToShopping(BuildContext context, WidgetRef ref, ShortfallLine l, Ingredient? ing) async {
    if (ing == null) return;
    try {
      final plan = await ref.read(currentPlanProvider.future);
      final shop = ref.read(shoppingListRepositoryProvider);
      final item = v1.ShortfallItem(ingredientId: l.ingredientId, name: ing.name, missingQty: l.remainingQty, unit: l.displayUnit, aisle: ing.aisle);
      await shop.addShortfalls([item], planId: plan?.id);
      ref.invalidate(shoppingListItemsProvider);
      ref.invalidate(mealShortfallProvider((recipeId: recipeId, servingsForMeal: servingsForMeal)));
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to Shopping')));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _usePantry(BuildContext context, WidgetRef ref, ShortfallLine l, Ingredient ing) async {
    try {
      final consumeAligned = l.onHandQty <= 0 ? 0 : (l.onHandQty > l.requiredQty ? l.requiredQty : l.onHandQty);
      if (consumeAligned <= 0) return;
      final toBase = alignQty(qty: consumeAligned, from: l.displayUnit, to: ing.unit, ing: ing);
      if (toBase == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Conversion not possible')));
        }
        return;
      }
      final pantry = ref.read(pantryRepositoryProvider);
      await pantry.addOnHandDeltas([(ingredientId: ing.id, qty: -toBase, unit: ing.unit)]);
      ref.invalidate(allPantryItemsProvider);
      ref.invalidate(shoppingListItemsProvider);
      ref.invalidate(mealShortfallProvider((recipeId: recipeId, servingsForMeal: servingsForMeal)));
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pantry updated')));
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _substituteForLine(BuildContext context, WidgetRef ref, ShortfallLine l, Ingredient ing) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _SubstituteSheetCore(
        title: 'Substitute • ${ing.name}',
        sourceQty: l.requiredQty,
        sourceUnit: l.displayUnit,
        sourceIng: ing,
        ingredientById: {for (final i in (ref.read(allIngredientsProvider).asData?.value ?? const <Ingredient>[])) i.id: i},
        onApply: (candIng, candQty, candUnit, approx, deltaPerServCents) async {
          final plan = await ref.read(currentPlanProvider.future);
          final shop = ref.read(shoppingListRepositoryProvider);
          final item = v1.ShortfallItem(ingredientId: candIng.id, name: candIng.name, missingQty: candQty, unit: candUnit, aisle: candIng.aisle);
          await shop.addShortfalls([item], planId: plan?.id);
          ref.invalidate(shoppingListItemsProvider);
          ref.invalidate(mealShortfallProvider((recipeId: recipeId, servingsForMeal: servingsForMeal)));
          if (context.mounted) Navigator.of(context).pop();
        },
      ),
    );
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

// Shared core for candidates used in Fix-It context
class _SubstituteSheetCore extends ConsumerWidget {
  const _SubstituteSheetCore({required this.title, required this.sourceQty, required this.sourceUnit, required this.sourceIng, required this.ingredientById, required this.onApply});
  final String title;
  final double sourceQty;
  final Unit sourceUnit;
  final Ingredient sourceIng;
  final Map<String, Ingredient> ingredientById;
  final Future<void> Function(Ingredient candIng, double candQty, Unit candUnit, bool approx, int? deltaPerServCents) onApply;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(left: 16, right: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16, top: 8),
        child: FutureBuilder<List<_CandRow>>(
          future: _buildCandidates(ref),
          builder: (context, snap) {
            final rows = snap.data ?? const <_CandRow>[];
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                if (rows.isEmpty)
                  const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: Text('No sensible alternatives')))
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemBuilder: (_, i) {
                        final r = rows[i];
                        final qtyStr = _fmtQty(r.qty, r.unit);
                        final cheaper = r.deltaPerServCents != null && r.deltaPerServCents! < 0;
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [Expanded(child: Text(r.ing.name, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600))), FilledButton(onPressed: r.qty <= 0 || r.unit == null ? null : () async { await onApply(r.ing, r.qty, r.unit!, r.approx, r.deltaPerServCents); }, child: const Text('Replace'))]),
                              const SizedBox(height: 6),
                              Text('Use: $qtyStr'),
                              const SizedBox(height: 6),
                              Wrap(spacing: 6, children: [if (r.pantry) _chip(context, 'Pantry', Icons.kitchen), if (cheaper) _chip(context, 'Cheaper −\$${(-r.deltaPerServCents! / 100).toStringAsFixed(2)}/serv', Icons.savings), if (r.approx) _chip(context, '≈ Approx', Icons.info_outline)])
                            ]),
                          ),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemCount: rows.length,
                    ),
                  ),
                const SizedBox(height: 8),
                SizedBox(width: double.infinity, child: TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<List<_CandRow>> _buildCandidates(WidgetRef ref) async {
    final svc = ref.read(substitutionsServiceProvider);
    final cat = await svc.catalog();
    final pantry = await ref.read(allPantryItemsProvider.future);
    final onHand = {for (final p in pantry) p.ingredientId: p.qty};
    final all = ingredientById.values.toList();
    final list = <Ingredient>[];
    final catIds = cat[sourceIng.id]?.map((c) => c.ingredientId).toSet() ?? const <String>{};
    for (final id in catIds) { final ing = ingredientById[id]; if (ing != null) list.add(ing); }
    final per = sourceIng.per100; if (per != null) { final kcal = per.kcal; for (final ing in all) { if (ing.id == sourceIng.id) continue; if (ing.aisle != sourceIng.aisle) continue; final p = ing.per100; if (p == null || p.kcal <= 0) continue; final ratio = p.kcal / kcal; if (ratio >= 0.7 && ratio <= 1.3) list.add(ing); } }
    final seen = <String>{}; final uniq = <Ingredient>[]; for (final ing in list) { if (seen.add(ing.id)) uniq.add(ing); }
    final costSvc = ref.read(substitutionCostServiceProvider);
    final rows = <_CandRow>[];
    for (final cand in uniq) {
      final res = SubstitutionMath.matchKcal(sourceQty: sourceQty, sourceUnit: sourceUnit, sourceIng: sourceIng, candIng: cand);
      if (res.qty == null || res.unit == null) { rows.add(_CandRow(ing: cand, qty: 0, unit: null, approx: true, pantry: (onHand[cand.id] ?? 0) > 0, deltaPerServCents: null)); continue; }
      final delta = await costSvc.deltaCentsPerServ(sourceIng: sourceIng, sourceQty: sourceQty, sourceUnit: sourceUnit, candIng: cand, candQtyBase: res.qty!);
      rows.add(_CandRow(ing: cand, qty: res.qty!, unit: res.unit, approx: res.approximate, pantry: (onHand[cand.id] ?? 0) > 0, deltaPerServCents: delta));
    }
    rows.sort((a, b) { final pa = a.pantry ? 1 : 0; final pb = b.pantry ? 1 : 0; if (pa != pb) return pb.compareTo(pa); final da = a.deltaPerServCents ?? 0; final db = b.deltaPerServCents ?? 0; if (da != db) return da.compareTo(db); return a.ing.name.compareTo(b.ing.name); });
    return rows;
  }

  String _fmtQty(double? q, Unit? u) {
    if (q == null || u == null) return 'n/a';
    final v = ((q * 10).round() / 10.0);
    final s = v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
    switch (u) { case Unit.grams: return '$s g'; case Unit.milliliters: return '$s ml'; case Unit.piece: return '$s pc'; }
  }

  Widget _chip(BuildContext context, String label, IconData icon) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondaryContainer, borderRadius: BorderRadius.circular(999)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 12), const SizedBox(width: 4), Text(label, style: Theme.of(context).textTheme.labelSmall)]));
  }
}

class _CandRow { _CandRow({required this.ing, required this.qty, required this.unit, required this.approx, required this.pantry, required this.deltaPerServCents}); final Ingredient ing; final double qty; final Unit? unit; final bool approx; final bool pantry; final int? deltaPerServCents; }
