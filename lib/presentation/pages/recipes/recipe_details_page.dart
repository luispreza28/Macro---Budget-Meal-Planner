import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/ingredient.dart' as domain;
import '../../../domain/entities/recipe.dart';
import '../../../data/services/recipe_calculator.dart';
import '../../../domain/services/recipe_math.dart';
import '../../providers/ingredient_providers.dart';
import '../../providers/recipe_providers.dart';
import '../../providers/shortfall_providers.dart';
import '../../providers/plan_providers.dart';
import '../../providers/database_providers.dart';
import '../../../domain/value/shortfall_item.dart';
import '../../providers/shopping_list_providers.dart';
import '../../providers/recipe_pref_providers.dart';
import '../../../domain/services/recipe_prefs_service.dart';
import '../../../domain/services/substitutions_service.dart';
import '../../../domain/services/substitution_math.dart';
import '../../../domain/services/substitution_cost_service.dart';
import '../../providers/pantry_providers.dart';

class RecipeDetailsPage extends ConsumerStatefulWidget {
  const RecipeDetailsPage({super.key, required this.recipeId});

  final String recipeId;

  @override
  ConsumerState<RecipeDetailsPage> createState() => _RecipeDetailsPageState();
}

class _RecipeDetailsPageState extends ConsumerState<RecipeDetailsPage> {
  Recipe? _original;
  Recipe? _draft;
  RecipeDerived? _preview;
  bool _initialized = false;
  bool _hasUnsavedChanges = false;
  domain.Ingredient? _selectedIngredient;
  double _newQty = 0;
  domain.Unit _newUnit = domain.Unit.grams;
  String _search = '';
  // Diagnostics state
  RecipeDerivedTotals? _derived;
  Map<String, domain.Ingredient> _ingById = {};
  List<String> _missingLines = [];
  bool _addingShortfalls = false;

  @override
  Widget build(BuildContext context) {
    final recipeAsync = ref.watch(recipeByIdProvider(widget.recipeId));
    final ingredientsAsync = ref.watch(allIngredientsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe Details'),
        actions: [
          IconButton(
            tooltip: 'Save',
            icon: const Icon(Icons.save),
            onPressed: _hasUnsavedChanges
                ? () => _onSavePressed(recipeAsync, ingredientsAsync)
                : null,
          ),
        ],
      ),
      body: recipeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('Failed to load recipe: $error')),
        data: (recipe) {
          if (recipe == null) {
            return const Center(child: Text('Recipe not found'));
          }

          if (!_initialized) {
            _original = recipe;
            _draft = recipe;
            _initialized = true;
            _hasUnsavedChanges = false;
            _preview = null;
          } else if (!_hasUnsavedChanges && _original != recipe) {
            _original = recipe;
            _draft = recipe;
            _hasUnsavedChanges = false;
            _preview = null;
          }

          final draft = _draft;
          if (draft == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return ingredientsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) =>
                Center(child: Text('Failed to load ingredients: $error')),
            data: (ingredients) {
              final byId = {for (final i in ingredients) i.id: i};
              final missingIds = draft.items
                  .where((it) => !byId.containsKey(it.ingredientId))
                  .map((it) => it.ingredientId)
                  .toSet();
              if (kDebugMode) {
                debugPrint('[RecipeUI] ingCatalog ready: ${byId.length} '
                    'missingForDraft=${missingIds.isEmpty ? '-' : missingIds.join(',')}');
              }
              if (!mapEquals(_ingById, byId)) {
                _ingById = byId;
                _recompute();
              }

              final displayDerived = (_derived != null)
                  ? RecipeDerived(
                      kcalPerServ: _derived!.kcalPerServ,
                      proteinGPerServ: _derived!.proteinGPerServ,
                      carbsGPerServ: _derived!.carbsGPerServ,
                      fatGPerServ: _derived!.fatGPerServ,
                      costPerServCents: _derived!.costCentsPerServ,
                    )
                  : _derivedFromRecipe(draft);
              final hasUnitMismatch = _detectUnitMismatch(
                draft,
                byId,
              );
              final hasIncompleteNutrition = _derived?.missingNutrition ?? false;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(
                      recipe: recipe,
                      derived: displayDerived,
                      showPreviewBadge: _hasUnsavedChanges,
                    ),
                    const SizedBox(height: 16),
                    if (hasIncompleteNutrition) ...[
                      const _InlineWarning(
                        'Some ingredients are missing nutrition data. '
                        'Macros shown may be incomplete.',
                      ),
                      if (kDebugMode && _missingLines.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          _missingLines.join(', '),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                        ),
                      ],
                    ],
                    if (hasUnitMismatch) ...[
                      const SizedBox(height: 12),
                      const _InlineWarning(
                        'Unit mismatches detected. Align units with ingredient defaults before saving.',
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      'Ingredients',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: draft.items.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = draft.items[index];
                          final ingredient = byId[item.ingredientId];
                          final ingredientName =
                              ingredient?.name ?? item.ingredientId;

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ingredientName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      if (ingredient == null)
                                        Text(
                                          'Ingredient not found',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.error,
                                              ),
                                        ),
                                      if (ingredient != null)
                                        _ConversionHint(
                                          itemUnit: item.unit,
                                          baseUnit: ingredient.unit,
                                          density: ingredient.densityGPerMl,
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 80,
                                  child: TextFormField(
                                    key: ValueKey('${item.ingredientId}_qty'),
                                    initialValue: _formatNumber(
                                      item.qty,
                                      decimals: 2,
                                    ),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    decoration: const InputDecoration(
                                      labelText: 'Qty',
                                      isDense: true,
                                    ),
                                    onChanged: (value) {
                                      final parsed = double.tryParse(
                                        value.trim(),
                                      );
                                      if (parsed == null || parsed <= 0) {
                                        return;
                                      }
                                    _replaceItem(
                                      index: index,
                                      updated: item.copyWith(qty: parsed),
                                      ingredientById: byId,
                                    );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                DropdownButton<domain.Unit>(
                                  value: item.unit,
                                  onChanged: (selectedUnit) {
                                    if (selectedUnit == null) return;
                                    _replaceItem(
                                      index: index,
                                      updated: item.copyWith(
                                        unit: selectedUnit,
                                      ),
                                      ingredientById: byId,
                                    );
                                  },
                                  items: domain.Unit.values
                                      .map(
                                        (unit) => DropdownMenuItem(
                                          value: unit,
                                          child: Text(_unitLabel(unit)),
                                        ),
                                      )
                                      .toList(),
                                ),
                                IconButton(
                                  tooltip: 'Remove',
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () {
                                    _removeItem(
                                      index: index,
                                      ingredientById: byId,
                                    );
                                  },
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  tooltip: 'Substitute',
                                  icon: const Icon(Icons.swap_horiz),
                                  onPressed: () async {
                                    final sourceIng = ingredient;
                                    if (sourceIng == null) return;
                                    await showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      showDragHandle: true,
                                      builder: (_) => _SubstituteSheet(
                                        sourceItem: item,
                                        sourceIng: sourceIng,
                                        ingredientById: byId,
                                        onApply: (candIng, candQty, candUnit, approx, deltaPerServCents) async {
                                          // Replace item in draft
                                          _replaceItem(
                                            index: index,
                                            updated: item.copyWith(
                                              ingredientId: candIng.id,
                                              qty: candQty,
                                              unit: candUnit,
                                            ),
                                            ingredientById: byId,
                                          );
                                          if (!mounted) return;
                                          final note = deltaPerServCents == null
                                              ? ''
                                              : (deltaPerServCents == 0
                                                  ? ' (no cost change)'
                                                  : (deltaPerServCents < 0
                                                      ? ' (−\$${(-deltaPerServCents / 100).toStringAsFixed(2)}/serv)'
                                                      : ' (+\$${(deltaPerServCents / 100).toStringAsFixed(2)}/serv)'));
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Replaced ${sourceIng.name} → ${candIng.name}$note'),
                                              action: SnackBarAction(
                                                label: 'Undo',
                                                onPressed: () {
                                                  _replaceItem(
                                                    index: index,
                                                    updated: item,
                                                    ingredientById: byId,
                                                  );
                                                },
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  _AddItemSection(
                      search: _search,
                      onSearchChanged: (value) {
                        setState(() => _search = value);
                      },
                      candidates: _filterIngredients(
                        ingredients,
                        _search,
                      ).toList(),
                      selected: _selectedIngredient,
                      onSelected: (selected) {
                        setState(() {
                          _selectedIngredient = selected;
                          if (selected != null) {
                            _newUnit = selected.unit;
                          }
                        });
                      },
                      qty: _newQty,
                      onQtyChanged: (value) {
                        setState(() {
                          _newQty = value;
                        });
                      },
                      unit: _newUnit,
                      onUnitChanged: (value) {
                        setState(() {
                          _newUnit = value;
                        });
                      },
                      onAdd: () => _tryAddItem(byId),
                    ),
                    const SizedBox(height: 24),
                    // Missing from Pantry card (Recipe level)
                    _RecipeShortfallCard(recipeId: widget.recipeId),
                    const SizedBox(height: 16),
                    _TotalsPanel(
                      derived: displayDerived,
                      hasUnsavedChanges: _hasUnsavedChanges,
                    ),
                    if (kDebugMode && _derived != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'DEBUG per serv: \$${(_derived!.costCentsPerServ / 100).toStringAsFixed(2)} '
                        '• kcal ${_derived!.kcalPerServ.toStringAsFixed(0)} '
                        '• p ${_derived!.proteinGPerServ.toStringAsFixed(1)} '
                        '• c ${_derived!.carbsGPerServ.toStringAsFixed(1)} '
                        '• f ${_derived!.fatGPerServ.toStringAsFixed(1)} '
                        '• missing=${_derived!.missingNutrition}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  List<domain.Ingredient> _filterIngredients(
    List<domain.Ingredient> all,
    String query,
  ) {
    if (query.trim().isEmpty) {
      return all.take(25).toList();
    }

    final lowerQuery = query.toLowerCase();
    final filtered = all
        .where((ingredient) {
          final name = ingredient.name.toLowerCase();
          final id = ingredient.id.toLowerCase();
          return name.contains(lowerQuery) || id.contains(lowerQuery);
        })
        .take(25);

    return filtered.toList();
  }

  void _tryAddItem(Map<String, domain.Ingredient> ingredientById) {
    final candidate = _selectedIngredient;
    final draft = _draft;
    if (candidate == null || draft == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select an ingredient to add.')),
      );
      return;
    }
    if (_newQty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a quantity greater than zero.')),
      );
      return;
    }
    if (candidate.unit != _newUnit) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unit mismatch. ${candidate.name} uses ${_unitLabel(candidate.unit)}.',
          ),
        ),
      );
      return;
    }

    final updatedItems = [
      ...draft.items,
      RecipeItem(
        ingredientId: candidate.id,
        qty: _newQty,
        unit: candidate.unit,
      ),
    ];
    if (kDebugMode) {
      debugPrint('[RecipeUI] itemAdded id=${candidate.id} qty=${_newQty} unit=${candidate.unit}');
    }
    _applyDraft(draft.copyWith(items: updatedItems), ingredientById);

    setState(() {
      _selectedIngredient = null;
      _newQty = 0;
      _newUnit = candidate.unit;
      _search = '';
    });
  }

  Future<void> _onSavePressed(
    AsyncValue<Recipe?> recipeAsync,
    AsyncValue<List<domain.Ingredient>> ingredientsAsync,
  ) async {
    final original = recipeAsync.value;
    final draft = _draft;
    if (original == null || draft == null) {
      return;
    }

    final ingredients = ingredientsAsync.value ?? const <domain.Ingredient>[];
    final ingredientById = {
      for (final ingredient in ingredients) ingredient.id: ingredient,
    };

    if (_detectUnitMismatch(draft, ingredientById)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fix unit mismatches before saving.')),
      );
      return;
    }

    final totals = RecipeCalculator.compute(
      recipe: draft,
      ingredientsById: ingredientById,
      debug: true,
    );

    final updatedRecipe = draft.copyWith(
      macrosPerServ: draft.macrosPerServ.copyWith(
        kcal: totals.kcalPerServ,
        proteinG: totals.proteinGPerServ,
        carbsG: totals.carbsGPerServ,
        fatG: totals.fatGPerServ,
      ),
      costPerServCents: totals.costCentsPerServ,
    );

    final notifier = ref.read(recipeNotifierProvider.notifier);
    await notifier.updateRecipe(updatedRecipe);

    if (!mounted) return;
    setState(() {
      _original = updatedRecipe;
      _draft = updatedRecipe;
      _preview = null;
      _hasUnsavedChanges = false;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Recipe updated')));
    Navigator.of(context).pop();
  }

  void _applyDraft(
    Recipe newDraft,
    Map<String, domain.Ingredient> ingredientById,
  ) {
    final totals = RecipeCalculator.compute(
      recipe: newDraft,
      ingredientsById: ingredientById,
      debug: true,
    );
    final derived = RecipeDerived(
      kcalPerServ: totals.kcalPerServ,
      proteinGPerServ: totals.proteinGPerServ,
      carbsGPerServ: totals.carbsGPerServ,
      fatGPerServ: totals.fatGPerServ,
      costPerServCents: totals.costCentsPerServ,
    );
    setState(() {
      _draft = newDraft;
      _preview = derived;
      _derived = totals;
      _hasUnsavedChanges = _original == null || newDraft != _original;
    });
  }

  void _replaceItem({
    required int index,
    required RecipeItem updated,
    required Map<String, domain.Ingredient> ingredientById,
  }) {
    final draft = _draft;
    if (draft == null) return;
    final items = List<RecipeItem>.from(draft.items);
    items[index] = updated;
    if (kDebugMode) {
      debugPrint('[RecipeUI] itemChanged id=${updated.ingredientId} qty=${updated.qty} unit=${updated.unit}');
      const bool _debugCalc = true;
      if (_debugCalc) {
        final ing = ingredientById[updated.ingredientId];
        debugPrint('[RecipeUI]   per100=${ing?.per100?.kcal}/${ing?.per100?.proteinG}/${ing?.per100?.carbsG}/${ing?.per100?.fatG} '
            'unit=${ing?.unit} perPieceOverride=${ing?.nutritionPerPieceKcal != null}');
        debugPrint('[RecipeUI]   pricePerUnitCents=${ing?.pricePerUnitCents}');
        debugPrint('[RecipeUI]   pack qty=${ing?.purchasePack.qty} unit=${ing?.purchasePack.unit} priceCents=${ing?.purchasePack.priceCents}');
      }
    }
    _applyDraft(draft.copyWith(items: items), ingredientById);
  }

  void _removeItem({
    required int index,
    required Map<String, domain.Ingredient> ingredientById,
  }) {
    final draft = _draft;
    if (draft == null) return;
    final removed = draft.items[index];
    final items = List<RecipeItem>.from(draft.items)..removeAt(index);
    if (kDebugMode) {
      debugPrint('[RecipeUI] itemRemoved id=${removed.ingredientId}');
    }
    _applyDraft(draft.copyWith(items: items), ingredientById);
  }

  RecipeDerived _derivedFromRecipe(Recipe recipe) {
    return RecipeDerived(
      kcalPerServ: recipe.macrosPerServ.kcal,
      proteinGPerServ: recipe.macrosPerServ.proteinG,
      carbsGPerServ: recipe.macrosPerServ.carbsG,
      fatGPerServ: recipe.macrosPerServ.fatG,
      costPerServCents: recipe.costPerServCents,
    );
  }

  bool _detectUnitMismatch(
    Recipe recipe,
    Map<String, domain.Ingredient> ingredientById,
  ) {
    for (final item in recipe.items) {
      final ingredient = ingredientById[item.ingredientId];
      if (ingredient == null) return true;
      if (!_unitsConvertible(item.unit, ingredient.unit)) {
        return true;
      }
    }
    return false;
  }

  bool _detectMissingNutrition(
    Recipe recipe,
    Map<String, domain.Ingredient> ingredientById,
  ) {
    // Fallback check: use calculator's missing flag
    final totals = RecipeCalculator.compute(
      recipe: recipe,
      ingredientsById: ingredientById,
      debug: true,
    );
    return totals.missingNutrition;
  }

  void _recompute() {
    final draft = _draft;
    if (draft == null) return;
    if (_ingById.isEmpty) {
      if (kDebugMode) debugPrint('[RecipeUI] compute skipped: ingById empty');
      return;
    }
    if (kDebugMode) {
      debugPrint('[RecipeUI] recompute: servings=${draft.servings} items=${draft.items.length}');
    }
    final missing = <String>[];
    _derived = RecipeCalculator.compute(
      recipe: draft,
      ingredientsById: _ingById,
      debug: true,
      outMissingLines: missing,
    );
    _missingLines = missing;
    setState(() {});
  }

  void _onServingsChanged(double s) {
    if (kDebugMode) debugPrint('[RecipeUI] servings=$s');
    final servingsInt = s.round();
    setState(() => _draft = _draft?.copyWith(servings: servingsInt));
    _recompute();
  }

  bool _unitsConvertible(domain.Unit from, domain.Unit to) {
    if (from == to) return true;
    final convertiblePairs = {
      {domain.Unit.grams, domain.Unit.milliliters},
    };
    for (final pair in convertiblePairs) {
      if (pair.contains(from) && pair.contains(to)) {
        return true;
      }
    }
    return false;
  }

  String _unitLabel(domain.Unit unit) {
    switch (unit) {
      case domain.Unit.grams:
        return 'g';
      case domain.Unit.milliliters:
        return 'ml';
      case domain.Unit.piece:
        return 'pc';
    }
  }
}

// ---------- Substitute Sheet ----------
class _SubstituteSheet extends ConsumerWidget {
  const _SubstituteSheet({
    required this.sourceItem,
    required this.sourceIng,
    required this.ingredientById,
    this.onApply,
  });
  final RecipeItem sourceItem;
  final domain.Ingredient sourceIng;
  final Map<String, domain.Ingredient> ingredientById;
  final Future<void> Function(domain.Ingredient candIng, double candQty, domain.Unit candUnit, bool approx, int? deltaPerServCents)? onApply;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allIngredients = ingredientById.values.toList();
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(left: 16, right: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16, top: 8),
        child: FutureBuilder<List<_CandRow>>(
          future: _buildCandidates(context, ref, allIngredients),
          builder: (context, snap) {
            final rows = snap.data ?? const <_CandRow>[];
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Substitute • ${sourceIng.name}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                if (rows.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('No sensible alternatives found')),
                  )
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(r.ing.name, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                                    ),
                                    FilledButton(
                                      onPressed: r.qty <= 0 || r.unit == null
                                          ? null
                                          : () async {
                                              if (onApply != null) {
                                                await onApply!(r.ing, r.qty, r.unit!, r.approx, r.deltaPerServCents);
                                              }
                                              if (context.mounted) Navigator.of(context).pop();
                                            },
                                      child: const Text('Replace'),
                                    )
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text('Use: $qtyStr'),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  children: [
                                    if (r.pantry) _chip(context, 'Pantry', Icons.kitchen),
                                    if (cheaper) _chip(context, 'Cheaper −\$${(-r.deltaPerServCents! / 100).toStringAsFixed(2)}/serv', Icons.savings),
                                    if (r.approx) _chip(context, '≈ Approx', Icons.info_outline),
                                  ],
                                )
                              ],
                            ),
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

  Future<List<_CandRow>> _buildCandidates(BuildContext context, WidgetRef ref, List<domain.Ingredient> ings) async {
    final svc = ref.read(substitutionsServiceProvider);
    final cat = await svc.catalog();
    final pantry = await ref.read(allPantryItemsProvider.future);
    final onHand = pantry.fold<Map<String, double>>({}, (m, p) {
      m[p.ingredientId] = (m[p.ingredientId] ?? 0) + p.qty;
      return m;
    });

    final list = <domain.Ingredient>[];
    // Catalog candidates
    final catIds = cat[sourceIng.id]?.map((c) => c.ingredientId).toSet() ?? const <String>{};
    for (final id in catIds) {
      final ing = ingredientById[id];
      if (ing != null) list.add(ing);
    }
    // Same-aisle heuristics (±30% kcal per100)
    final per = sourceIng.per100;
    if (per != null) {
      final kcal = per.kcal;
      for (final ing in ings) {
        if (ing.id == sourceIng.id) continue;
        if (ing.aisle != sourceIng.aisle) continue;
        final p = ing.per100;
        if (p == null || p.kcal <= 0) continue;
        final ratio = p.kcal / kcal;
        if (ratio >= 0.7 && ratio <= 1.3) list.add(ing);
      }
    }
    // Unique by id
    final seen = <String>{};
    final uniq = <domain.Ingredient>[];
    for (final ing in list) {
      if (seen.add(ing.id)) uniq.add(ing);
    }

    final costSvc = ref.read(substitutionCostServiceProvider);
    final rows = <_CandRow>[];
    for (final cand in uniq) {
      final res = SubstitutionMath.matchKcal(
        sourceQty: sourceItem.qty,
        sourceUnit: sourceItem.unit,
        sourceIng: sourceIng,
        candIng: cand,
      );
      if (res.qty == null || res.unit == null) {
        rows.add(_CandRow(ing: cand, qty: 0, unit: null, approx: true, pantry: (onHand[cand.id] ?? 0) > 0, deltaPerServCents: null));
        continue;
      }
      final delta = await costSvc.deltaCentsPerServ(
        sourceIng: sourceIng,
        sourceQty: sourceItem.qty,
        sourceUnit: sourceItem.unit,
        candIng: cand,
        candQtyBase: res.qty!,
      );
      rows.add(_CandRow(ing: cand, qty: res.qty!.clamp(0.0, 999999.0), unit: res.unit, approx: res.approximate, pantry: (onHand[cand.id] ?? 0) > 0, deltaPerServCents: delta));
    }
    // Order: pantry first, cheaper better, then name
    rows.sort((a, b) {
      final pa = a.pantry ? 1 : 0;
      final pb = b.pantry ? 1 : 0;
      if (pa != pb) return pb.compareTo(pa);
      final da = a.deltaPerServCents ?? 0;
      final db = b.deltaPerServCents ?? 0;
      if (da != db) return da.compareTo(db); // negative first
      return a.ing.name.compareTo(b.ing.name);
    });
    return rows;
  }

  String _fmtQty(double? q, domain.Unit? u) {
    if (q == null || u == null) return 'n/a';
    final v = ((q * 10).round() / 10.0);
    final s = v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
    switch (u) {
      case domain.Unit.grams:
        return '$s g';
      case domain.Unit.milliliters:
        return '$s ml';
      case domain.Unit.piece:
        return '$s pc';
    }
  }

  Widget _chip(BuildContext context, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}

class _CandRow {
  _CandRow({required this.ing, required this.qty, required this.unit, required this.approx, required this.pantry, required this.deltaPerServCents});
  final domain.Ingredient ing;
  final double qty;
  final domain.Unit? unit;
  final bool approx;
  final bool pantry;
  final int? deltaPerServCents;
}

class _ConversionHint extends StatelessWidget {
  const _ConversionHint({
    required this.itemUnit,
    required this.baseUnit,
    required this.density,
  });
  final domain.Unit itemUnit;
  final domain.Unit baseUnit;
  final double? density;

  @override
  Widget build(BuildContext context) {
    final involvesMassVol =
        (itemUnit == domain.Unit.grams && baseUnit == domain.Unit.milliliters) ||
        (itemUnit == domain.Unit.milliliters && baseUnit == domain.Unit.grams);
    if (!involvesMassVol) return const SizedBox.shrink();
    final textTheme = Theme.of(context).textTheme;
    final onVar = Theme.of(context).colorScheme.onSurfaceVariant;
    if (density != null && density! > 0) {
      return Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          'Converted with density (g↔ml)',
          style: textTheme.labelSmall?.copyWith(color: onVar),
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          'No density set; cannot convert g↔ml',
          style: textTheme.labelSmall?.copyWith(color: onVar),
        ),
      );
    }
  }
}

class _RecipeShortfallCard extends ConsumerStatefulWidget {
  const _RecipeShortfallCard({required this.recipeId});
  final String recipeId;

  @override
  ConsumerState<_RecipeShortfallCard> createState() => _RecipeShortfallCardState();
}

class _RecipeShortfallCardState extends ConsumerState<_RecipeShortfallCard> {
  bool _adding = false;

  @override
  Widget build(BuildContext context) {
    final shortfallsAsync = ref.watch(shortfallForRecipeProvider(widget.recipeId));
    return shortfallsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _InlineError(message: 'Failed to load pantry shortfall. ${e.toString()}'),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Missing from Pantry',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                ...items.map((it) => _ShortfallRow(item: it)).toList(),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _adding ? null : () async {
                      setState(() => _adding = true);
                      try {
                        final plan = await ref.read(currentPlanProvider.future);
                        final repo = ref.read(shoppingListRepositoryProvider);
                        await repo.addShortfalls(items, planId: plan?.id);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Added ${items.length} items to Shopping List')),
                        );
                        // Invalidate shopping list so UI recomputes
                        ref.invalidate(shoppingListItemsProvider);
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to add: $e')),
                        );
                      } finally {
                        if (mounted) setState(() => _adding = false);
                      }
                    },
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('Add to Shopping List'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ShortfallRow extends StatelessWidget {
  const _ShortfallRow({required this.item});
  final ShortfallItem item;

  @override
  Widget build(BuildContext context) {
    final qty = _formatQty(item.missingQty, item.unit);
    final aisle = _aisleDisplay(item.aisle);
    final reason = item.reason;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.name,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('• $qty • $aisle', style: Theme.of(context).textTheme.labelMedium),
                    if (reason != null) ...[
                      const SizedBox(width: 6),
                      Tooltip(
                        message: reason,
                        child: Icon(Icons.warning_amber_outlined,
                            size: 16, color: Theme.of(context).colorScheme.tertiary),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatQty(double qty, domain.Unit unit) {
    final rounded = (qty * 10).round() / 10.0;
    final s = (rounded % 1 == 0) ? rounded.toStringAsFixed(0) : rounded.toStringAsFixed(1);
    switch (unit) {
      case domain.Unit.grams:
        return '$s g';
      case domain.Unit.milliliters:
        return '$s ml';
      case domain.Unit.piece:
        return '$s pc';
    }
  }

  String _aisleDisplay(domain.Aisle aisle) {
    switch (aisle) {
      case domain.Aisle.produce:
        return 'Produce';
      case domain.Aisle.meat:
        return 'Meat';
      case domain.Aisle.dairy:
        return 'Dairy';
      case domain.Aisle.pantry:
        return 'Pantry';
      case domain.Aisle.frozen:
        return 'Frozen';
      case domain.Aisle.condiments:
        return 'Condiments';
      case domain.Aisle.bakery:
        return 'Bakery';
      case domain.Aisle.household:
        return 'Household';
    }
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({
    required this.recipe,
    required this.derived,
    required this.showPreviewBadge,
  });

  final Recipe recipe;
  final RecipeDerived derived;
  final bool showPreviewBadge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    recipe.name,
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                // Favorite toggle
                Consumer(builder: (context, ref, _) {
                  final favAsync = ref.watch(isFavoriteProvider(recipe.id));
                  final isFav = favAsync.asData?.value ?? false;
                  return IconButton(
                    tooltip: isFav ? 'Unfavorite' : 'Favorite',
                    icon: Icon(isFav ? Icons.star : Icons.star_border),
                    color: isFav ? Colors.amber : null,
                    onPressed: () async {
                      final svc = ref.read(recipePrefsServiceProvider);
                      await svc.toggleFavorite(recipe.id, value: !isFav);
                      ref.invalidate(favoriteRecipesProvider);
                      ref.invalidate(isFavoriteProvider(recipe.id));
                    },
                  );
                }),
                // Exclude toggle
                Consumer(builder: (context, ref, _) {
                  final exAsync = ref.watch(isExcludedProvider(recipe.id));
                  final isExcluded = exAsync.asData?.value ?? false;
                  return IconButton(
                    tooltip: isExcluded ? 'Include in suggestions' : 'Exclude from suggestions',
                    icon: Icon(isExcluded ? Icons.visibility_off : Icons.visibility_off_outlined),
                    onPressed: () async {
                      final svc = ref.read(recipePrefsServiceProvider);
                      final next = !isExcluded;
                      await svc.toggleExcluded(recipe.id, value: next);
                      ref.invalidate(excludedRecipesProvider);
                      ref.invalidate(isExcludedProvider(recipe.id));
                      if (next) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Excluded from suggestions and generation.')),
                        );
                      }
                    },
                  );
                }),
              ],
            ),
            if (showPreviewBadge) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Recalculated preview',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time, size: 16),
                    const SizedBox(width: 4),
                    Text('${recipe.timeMins} min'),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.groups, size: 16),
                    const SizedBox(width: 4),
                    Text('${recipe.servings} servings'),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.attach_money, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '\$${(derived.costPerServCents / 100).toStringAsFixed(2)} / serv',
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_fire_department, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${derived.kcalPerServ.toStringAsFixed(0)} kcal / serv',
                    ),
                  ],
                ),
              ],
            ),
            if (recipe.dietFlags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                children: recipe.dietFlags
                    .map(
                      (flag) => Chip(
                        label: Text(flag.toUpperCase()),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AddItemSection extends StatelessWidget {
  const _AddItemSection({
    required this.search,
    required this.onSearchChanged,
    required this.candidates,
    required this.selected,
    required this.onSelected,
    required this.qty,
    required this.onQtyChanged,
    required this.unit,
    required this.onUnitChanged,
    required this.onAdd,
  });

  final String search;
  final ValueChanged<String> onSearchChanged;
  final List<domain.Ingredient> candidates;
  final domain.Ingredient? selected;
  final ValueChanged<domain.Ingredient?> onSelected;
  final double qty;
  final ValueChanged<double> onQtyChanged;
  final domain.Unit unit;
  final ValueChanged<domain.Unit> onUnitChanged;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Ingredient',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search ingredients',
              ),
              onChanged: onSearchChanged,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<domain.Ingredient>(
              key: const ValueKey('add-ingredient-dropdown'),
              value: selected,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Ingredient'),
              items: candidates
                  .map(
                    (ingredient) => DropdownMenuItem(
                      value: ingredient,
                      child: Text(ingredient.name),
                    ),
                  )
                  .toList(),
              onChanged: onSelected,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: const ValueKey('add-qty-field'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Qty'),
                    onChanged: (value) =>
                        onQtyChanged(double.tryParse(value) ?? 0),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<domain.Unit>(
                  key: const ValueKey('add-unit-dropdown'),
                  value: unit,
                  onChanged: (selectedUnit) {
                    if (selectedUnit != null) {
                      onUnitChanged(selectedUnit);
                    }
                  },
                  items: domain.Unit.values
                      .map(
                        (u) => DropdownMenuItem(
                          value: u,
                          child: Text(_unitLabel(u)),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  key: const ValueKey('add-ingredient-button'),
                  onPressed: onAdd,
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _unitLabel(domain.Unit unit) {
    switch (unit) {
      case domain.Unit.grams:
        return 'g';
      case domain.Unit.milliliters:
        return 'ml';
      case domain.Unit.piece:
        return 'pc';
    }
  }
}

class _TotalsPanel extends StatelessWidget {
  const _TotalsPanel({required this.derived, required this.hasUnsavedChanges});

  final RecipeDerived derived;
  final bool hasUnsavedChanges;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hasUnsavedChanges ? 'Recalculated Preview' : 'Current Totals',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _SummaryChip(
                  label: 'Cost / serv',
                  value:
                      '\$${(derived.costPerServCents / 100).toStringAsFixed(2)}',
                ),
                _SummaryChip(
                  label: 'Kcal / serv',
                  value: derived.kcalPerServ.toStringAsFixed(0),
                ),
                _SummaryChip(
                  label: 'Protein g / serv',
                  value: derived.proteinGPerServ.toStringAsFixed(1),
                ),
                _SummaryChip(
                  label: 'Carbs g / serv',
                  value: derived.carbsGPerServ.toStringAsFixed(1),
                ),
                _SummaryChip(
                  label: 'Fat g / serv',
                  value: derived.fatGPerServ.toStringAsFixed(1),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(width: 6),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _InlineWarning extends StatelessWidget {
  const _InlineWarning(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: scheme.onErrorContainer,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatNumber(double value, {int decimals = 1}) {
  final scale = pow(10, decimals).toDouble();
  final rounded = (value * scale).round() / scale;
  final formatted = rounded.toStringAsFixed(decimals);
  if (formatted.contains('.') && formatted.endsWith('0')) {
    return formatted
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
  return formatted;
}
