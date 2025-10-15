import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
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
import '../../providers/clipboard_providers.dart';
import '../../providers/diet_allergen_providers.dart';
import '../../../domain/services/allergen_classifier.dart';

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

  // Multi-select state
  bool _multiSelectMode = false;
  final Set<int> _selectedIndexes = <int>{};

  @override
  Widget build(BuildContext context) {
    final recipeAsync = ref.watch(recipeByIdProvider(widget.recipeId));
    final ingredientsAsync = ref.watch(allIngredientsProvider);

    final clipboardItems = ref.watch(recipeItemsClipboardProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe Details'),
        actions: [
          // Paste button available when clipboard has items
          if (clipboardItems != null && clipboardItems.isNotEmpty)
            IconButton(
              tooltip: 'Paste items',
              icon: const Icon(Icons.paste),
              onPressed: () {
                final draft = _draft;
                if (draft == null) return;
                final byId = _ingById;
                final updated = _pasteClipboard(draft, byId, clipboardItems);
                _applyDraft(updated, byId);
              },
            ),
          if (!_multiSelectMode) ...[
            IconButton(
              tooltip: 'Select',
              icon: const Icon(Icons.checklist),
              onPressed: () {
                setState(() {
                  _multiSelectMode = true;
                  _selectedIndexes.clear();
                });
              },
            ),
            IconButton(
              tooltip: 'Save as New',
              icon: const Icon(Icons.copy_all),
              onPressed: () => _onSaveAsNew(),
            ),
          ] else ...[
            TextButton(
              onPressed: () {
                setState(() {
                  _multiSelectMode = false;
                  _selectedIndexes.clear();
                });
              },
              child: const Text('Cancel'),
            ),
          ],
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
                      child: _multiSelectMode
                          ? ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: draft.items.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final item = draft.items[index];
                                final ingredient = byId[item.ingredientId];
                                final ingredientName = ingredient?.name ?? item.ingredientId;

                                final selected = _selectedIndexes.contains(index);
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Checkbox(
                                        value: selected,
                                        onChanged: (_) {
                                          setState(() {
                                            if (selected) {
                                              _selectedIndexes.remove(index);
                                            } else {
                                              _selectedIndexes.add(index);
                                            }
                                          });
                                        },
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              ingredientName,
                                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                            if (ingredient == null)
                                              Text(
                                                'Ingredient not found',
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                      color: Theme.of(context).colorScheme.error,
                                                    ),
                                              ),
                                            if (ingredient != null) ...[
                                              _ConversionHint(
                                                itemUnit: item.unit,
                                                baseUnit: ingredient.unit,
                                                density: ingredient.densityGPerMl,
                                              ),
                                              // Piece conversion caption
                                              if ((item.unit == domain.Unit.piece && (ingredient.gramsPerPiece ?? 0) > 0) ||
                                                  (item.unit == domain.Unit.piece && (ingredient.mlPerPiece ?? 0) > 0) ||
                                                  (ingredient.unit == domain.Unit.piece && item.unit != domain.Unit.piece &&
                                                      ((item.unit == domain.Unit.grams && (ingredient.gramsPerPiece ?? 0) > 0) ||
                                                       (item.unit == domain.Unit.milliliters && (ingredient.mlPerPiece ?? 0) > 0))))
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 2),
                                                  child: Text(
                                                    'Converted using per-piece size',
                                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                        ),
                                                  ),
                                                ),
                                              // Missing piece macros/size warning for piece items
                                              if (item.unit == domain.Unit.piece &&
                                                  (ingredient.nutritionPerPieceKcal ?? 0) <= 0 &&
                                                  (ingredient.nutritionPerPieceProteinG ?? 0) <= 0 &&
                                                  (ingredient.nutritionPerPieceCarbsG ?? 0) <= 0 &&
                                                  (ingredient.nutritionPerPieceFatG ?? 0) <= 0 &&
                                                  (ingredient.gramsPerPiece == null) &&
                                                  (ingredient.mlPerPiece == null))
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 2),
                                                  child: Text(
                                                    'Piece nutrition/size missing — macros may be incomplete; conversions disabled.',
                                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                        ),
                                                  ),
                                                ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      SizedBox(
                                        width: 80,
                                        child: TextFormField(
                                          key: ValueKey('${item.ingredientId}_qty'),
                                          initialValue: _formatNumber(item.qty, decimals: 2),
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          decoration: const InputDecoration(labelText: 'Qty', isDense: true),
                                          onChanged: (value) {
                                            final parsed = double.tryParse(value.trim());
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
                                            updated: item.copyWith(unit: selectedUnit),
                                            ingredientById: byId,
                                          );
                                        },
                                        items: domain.Unit.values
                                            .map((unit) => DropdownMenuItem(value: unit, child: Text(_unitLabel(unit))))
                                            .toList(),
                                      ),
                                      IconButton(
                                        tooltip: 'Remove',
                                        icon: const Icon(Icons.delete_outline),
                                        onPressed: () {
                                          _removeItem(index: index, ingredientById: byId);
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            )
                          : _ReorderableItemsList(
                              items: draft.items,
                              byId: byId,
                              onChanged: (index, updated) => _replaceItem(
                                index: index,
                                updated: updated,
                                ingredientById: byId,
                              ),
                              onRemove: (index) => _removeItem(index: index, ingredientById: byId),
                              onReorder: (oldIndex, newIndex) {
                                final newItems = List<RecipeItem>.from(draft.items);
                                if (newIndex > oldIndex) newIndex -= 1;
                                final moved = newItems.removeAt(oldIndex);
                                newItems.insert(newIndex, moved);
                                if (kDebugMode) {
                                  debugPrint('[BulkEdit] reorder old=$oldIndex new=$newIndex');
                                }
                                _applyDraft(draft.copyWith(items: newItems), byId);
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
      bottomNavigationBar: _multiSelectMode
          ? _BulkToolbar(
              enabled: _selectedIndexes.isNotEmpty,
              onScale: (pct) {
                final draft = _draft;
                if (draft == null) return;
                final updated = _bulkScale(draft, _ingById, pct);
                _applyDraft(updated, _ingById);
              },
              onScaleCustom: () async {
                final pct = await _showCustomScaleDialog(context);
                if (pct == null) return;
                final draft = _draft;
                if (draft == null) return;
                final updated = _bulkScale(draft, _ingById, pct);
                _applyDraft(updated, _ingById);
              },
              onChangeUnit: (unit) {
                final draft = _draft;
                if (draft == null) return;
                final before = draft.items.length;
                final updated = _bulkChangeUnit(draft, _ingById, unit);
                final after = updated.items.length;
                if (!mounted) return;
                _applyDraft(updated, _ingById);
                // Skipped count tracked via snack from helper
              },
              onDelete: () {
                final draft = _draft;
                if (draft == null) return;
                final updated = _bulkDelete(draft);
                _applyDraft(updated, _ingById);
              },
              onCopy: () {
                final draft = _draft;
                if (draft == null) return;
                final sel = _selectedSorted();
                final items = sel.map((i) => draft.items[i]).toList(growable: false);
                ref.read(recipeItemsClipboardProvider.notifier).state = items;
                setState(() {
                  _multiSelectMode = false;
                  _selectedIndexes.clear();
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Copied ${items.length} item(s)')),
                );
              },
            )
          : null,
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
    if (draft.id != original.id) {
      await notifier.addRecipe(updatedRecipe);
    } else {
      await notifier.updateRecipe(updatedRecipe);
    }

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

  void _onSaveAsNew() {
    final original = _original;
    final draft = _draft;
    final byId = _ingById;
    if (draft == null) return;
    final newId = const Uuid().v4();
    final duplicate = draft.copyWith(
      id: newId,
      name: '${draft.name} (copy)',
    );
    final totals = RecipeCalculator.compute(
      recipe: duplicate,
      ingredientsById: byId,
      debug: true,
    );
    final withPreview = duplicate.copyWith(
      macrosPerServ: duplicate.macrosPerServ.copyWith(
        kcal: totals.kcalPerServ,
        proteinG: totals.proteinGPerServ,
        carbsG: totals.carbsGPerServ,
        fatG: totals.fatGPerServ,
      ),
      costPerServCents: totals.costCentsPerServ,
    );
    if (kDebugMode) {
      debugPrint('[BulkEdit] duplicate id=$newId');
    }
    setState(() {
      _draft = withPreview;
      _preview = RecipeDerived(
        kcalPerServ: totals.kcalPerServ,
        proteinGPerServ: totals.proteinGPerServ,
        carbsGPerServ: totals.carbsGPerServ,
        fatGPerServ: totals.fatGPerServ,
        costPerServCents: totals.costCentsPerServ,
      );
      _hasUnsavedChanges = true;
    });
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

// Reorderable items list used when not in multi-select mode
class _ReorderableItemsList extends StatelessWidget {
  const _ReorderableItemsList({
    required this.items,
    required this.byId,
    required this.onChanged,
    required this.onRemove,
    required this.onReorder,
  });

  final List<RecipeItem> items;
  final Map<String, domain.Ingredient> byId;
  final void Function(int index, RecipeItem updated) onChanged;
  final void Function(int index) onRemove;
  final void Function(int oldIndex, int newIndex) onReorder;

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

  @override
  Widget build(BuildContext context) {
    // Estimated row height for a bounded box within a scroll view
    final estHeight = (items.length * 64.0).clamp(64.0, 420.0);
    return SizedBox(
      height: estHeight,
      child: ReorderableListView.builder(
        buildDefaultDragHandles: true,
        itemCount: items.length,
        onReorder: onReorder,
        itemBuilder: (context, index) {
          final item = items[index];
          final ingredient = byId[item.ingredientId];
          final ingredientName = ingredient?.name ?? item.ingredientId;
          return Container(
            key: ValueKey('${item.ingredientId}-$index'),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ingredientName,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      if (ingredient == null)
                        Text(
                          'Ingredient not found',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: Theme.of(context).colorScheme.error),
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
                    initialValue: _formatNumber(item.qty, decimals: 2),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Qty', isDense: true),
                    onChanged: (value) {
                      final parsed = double.tryParse(value.trim());
                      if (parsed == null || parsed <= 0) {
                        return;
                      }
                      onChanged(index, item.copyWith(qty: parsed));
                    },
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<domain.Unit>(
                  value: item.unit,
                  onChanged: (selectedUnit) {
                    if (selectedUnit == null) return;
                    onChanged(index, item.copyWith(unit: selectedUnit));
                  },
                  items: domain.Unit.values
                      .map((unit) => DropdownMenuItem(value: unit, child: Text(_unitLabel(unit))))
                      .toList(),
                ),
                IconButton(
                  tooltip: 'Remove',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => onRemove(index),
                ),
                const Icon(Icons.drag_handle),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BulkToolbar extends StatefulWidget {
  const _BulkToolbar({
    required this.enabled,
    required this.onScale,
    required this.onScaleCustom,
    required this.onChangeUnit,
    required this.onDelete,
    required this.onCopy,
  });

  final bool enabled;
  final void Function(double pct) onScale;
  final Future<void> Function() onScaleCustom;
  final void Function(domain.Unit unit) onChangeUnit;
  final VoidCallback onDelete;
  final VoidCallback onCopy;

  @override
  State<_BulkToolbar> createState() => _BulkToolbarState();
}

class _BulkToolbarState extends State<_BulkToolbar> {
  domain.Unit _unit = domain.Unit.grams;

  @override
  Widget build(BuildContext context) {
    final onSurfaceVar = Theme.of(context).colorScheme.onSurfaceVariant;
    return SafeArea(
      top: false,
      child: Material(
        elevation: 8,
        surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Text('Bulk', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: onSurfaceVar)),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: widget.enabled ? () => widget.onScale(-10) : null,
                child: const Text('-10%'),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: widget.enabled ? () => widget.onScale(10) : null,
                child: const Text('+10%'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: widget.enabled ? () => widget.onScaleCustom() : null,
                child: const Text('Custom %'),
              ),
              const SizedBox(width: 12),
              DropdownButton<domain.Unit>(
                value: _unit,
                onChanged: widget.enabled
                    ? (u) {
                        if (u == null) return;
                        setState(() => _unit = u);
                        widget.onChangeUnit(u);
                      }
                    : null,
                items: domain.Unit.values
                    .map((u) => DropdownMenuItem(value: u, child: Text(_unitLabel(u))))
                    .toList(),
              ),
              const SizedBox(width: 12),
              IconButton(
                tooltip: 'Delete',
                onPressed: widget.enabled ? widget.onDelete : null,
                icon: const Icon(Icons.delete_outline),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Copy',
                onPressed: widget.enabled ? widget.onCopy : null,
                icon: const Icon(Icons.copy_all),
              ),
            ],
          ),
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

  // ---- Bulk helpers ----
  List<int> _selectedSorted() {
    final list = _selectedIndexes.toList()..sort();
    return list;
  }

  Future<double?> _showCustomScaleDialog(BuildContext context) async {
    final ctrl = TextEditingController();
    return showDialog<double>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Scale by %'),
          content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(hintText: 'e.g., 15 or -10'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final v = double.tryParse(ctrl.text.trim());
                if (v == null) return;
                Navigator.of(ctx).pop(v);
              },
              child: const Text('Apply'),
            ),
          ],
        );
      },
    );
  }

  Recipe _bulkScale(Recipe draft, Map<String, domain.Ingredient> byId, double factorPct) {
    final sel = _selectedSorted();
    if (sel.isEmpty) return draft;
    final factor = 1.0 + (factorPct / 100.0);
    final updated = List<RecipeItem>.from(draft.items);
    for (final i in sel) {
      final it = updated[i];
      final scaled = max(0.0001, it.qty * factor);
      updated[i] = it.copyWith(qty: scaled);
    }
    if (kDebugMode) {
      debugPrint('[BulkEdit] scale=${factorPct.toStringAsFixed(2)}%');
    }
    return draft.copyWith(items: updated);
  }

  Recipe _bulkChangeUnit(Recipe draft, Map<String, domain.Ingredient> byId, domain.Unit targetUnit) {
    final sel = _selectedSorted();
    if (sel.isEmpty) return draft;
    final updated = List<RecipeItem>.from(draft.items);
    int skipped = 0;
    for (final i in sel) {
      final it = updated[i];
      final ing = byId[it.ingredientId];
      if (ing == null) {
        skipped++;
        continue;
      }
      if (it.unit == targetUnit) {
        updated[i] = it.copyWith(unit: targetUnit);
        continue;
      }
      // piece <-> mass/vol is not allowed
      if (it.unit == domain.Unit.piece || targetUnit == domain.Unit.piece) {
        skipped++;
        continue;
      }
      // grams <-> ml require density
      final d = ing.densityGPerMl;
      if (d == null || d <= 0) {
        skipped++;
        continue;
      }
      double newQty;
      if (it.unit == domain.Unit.grams && targetUnit == domain.Unit.milliliters) {
        newQty = it.qty / d;
      } else if (it.unit == domain.Unit.milliliters && targetUnit == domain.Unit.grams) {
        newQty = it.qty * d;
      } else {
        // same family (already handled) or unsupported
        newQty = it.qty;
      }
      updated[i] = it.copyWith(qty: newQty, unit: targetUnit);
    }
    if (skipped > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Changed ${sel.length - skipped} items • Skipped $skipped (unit mismatch or missing density)')),
      );
    }
    if (kDebugMode) {
      debugPrint('[BulkEdit] changeUnit target=$targetUnit skipped=$skipped');
    }
    return draft.copyWith(items: updated);
  }

  Recipe _bulkDelete(Recipe draft) {
    final sel = _selectedSorted();
    if (sel.isEmpty) return draft;
    final remaining = <RecipeItem>[];
    for (int i = 0; i < draft.items.length; i++) {
      if (!sel.contains(i)) remaining.add(draft.items[i]);
    }
    if (kDebugMode) {
      debugPrint('[BulkEdit] delete count=${sel.length}');
    }
    // Clear selection after delete
    setState(() => _selectedIndexes.clear());
    return draft.copyWith(items: remaining);
  }

  Recipe _pasteClipboard(Recipe draft, Map<String, domain.Ingredient> byId, List<RecipeItem> items) {
    int added = 0;
    int skipped = 0;
    final result = List<RecipeItem>.from(draft.items);
    for (final it in items) {
      final ing = byId[it.ingredientId];
      if (ing == null) {
        skipped++;
        continue;
      }
      // Align to ingredient base unit where needed using same rules as calculator
      final aligned = _convertQty(qty: it.qty, from: it.unit, to: ing.unit, ingredient: ing);
      // If piece <-> mass/vol attempted, _convertQty returns original qty but unit may be incompatible.
      // Skip if piece<->mass/vol mismatch
      if ((it.unit == domain.Unit.piece && ing.unit != domain.Unit.piece) ||
          (it.unit != domain.Unit.piece && ing.unit == domain.Unit.piece)) {
        skipped++;
        continue;
      }
      // For grams<->ml with missing density, _convertQty returns original qty and unit mismatch persists -> skip
      if ((it.unit == domain.Unit.grams && ing.unit == domain.Unit.milliliters) ||
          (it.unit == domain.Unit.milliliters && ing.unit == domain.Unit.grams)) {
        final d = ing.densityGPerMl;
        if (d == null || d <= 0) {
          skipped++;
          continue;
        }
      }
      result.add(RecipeItem(ingredientId: it.ingredientId, qty: aligned, unit: ing.unit));
      added++;
    }
    if (mounted) {
      final msg = 'Pasted $added item(s)${skipped > 0 ? ' ($skipped skipped: unit mismatch)' : ''}.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
    if (kDebugMode) {
      debugPrint('[BulkEdit] paste added=$added skipped=$skipped');
    }
    return draft.copyWith(items: result);
  }

  double _convertQty({
    required double qty,
    required domain.Unit from,
    required domain.Unit to,
    required domain.Ingredient ingredient,
  }) {
    if (from == to) return qty;
    if ((from == domain.Unit.grams && to == domain.Unit.milliliters) ||
        (from == domain.Unit.milliliters && to == domain.Unit.grams)) {
      final d = ingredient.densityGPerMl;
      if (d != null && d > 0) {
        return (from == domain.Unit.grams && to == domain.Unit.milliliters) ? (qty / d) : (qty * d);
      } else {
        return qty;
      }
    }
    if (from == domain.Unit.piece || to == domain.Unit.piece) {
      return qty;
    }
    return qty;
  }
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
    final reqDiet = ref.watch(dietFlagsPrefProvider).asData?.value ?? const <String>[];
    final pickedAllergens = ref.watch(allergensPrefProvider).asData?.value ?? const <String>[];
    final strict = ref.watch(strictModePrefProvider).asData?.value ?? true;
    final ingredients = ref.watch(allIngredientsProvider).asData?.value;
    bool dietMismatch = reqDiet.isNotEmpty && !recipe.isCompatibleWithDiet(reqDiet);
    bool hasAllergen = false;
    if (!dietMismatch && pickedAllergens.isNotEmpty && (ingredients != null)) {
      final byId = {for (final i in ingredients) i.id: i};
      final set = AllergenClassifier.allergensForRecipe(recipe, byId);
      hasAllergen = set.any((a) => pickedAllergens.contains(a));
    }
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
            if (dietMismatch || hasAllergen) ...[
              Wrap(
                spacing: 8,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_amber_outlined, size: 14, color: Theme.of(context).colorScheme.onErrorContainer),
                        const SizedBox(width: 4),
                        Text(
                          dietMismatch ? "Doesn't meet your diet" : 'Contains your allergen',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.onErrorContainer,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (strict)
                    Text(
                      'Will be excluded in plan generation & swaps.',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
            ],
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
