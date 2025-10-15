import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/entities/ingredient.dart' as domain;
import '../../../domain/entities/recipe.dart' as domainr;
import '../../../domain/import/draft_recipe.dart';
import '../../../domain/services/recipe_import_service.dart';
import '../../providers/ingredient_providers.dart';
import '../../providers/recipe_providers.dart';
import '../../providers/import_providers.dart';

class ImportRecipePage extends ConsumerStatefulWidget {
  const ImportRecipePage({super.key});

  @override
  ConsumerState<ImportRecipePage> createState() => _ImportRecipePageState();
}

class _ImportRecipePageState extends ConsumerState<ImportRecipePage> {
  final _urlCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final draft = ref.watch(draftRecipeProvider);
    final ingredientsAsync = ref.watch(allIngredientsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Import Recipe')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Step 1: Paste URL', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _urlCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Recipe URL',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.url,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _loading
                      ? null
                      : () async {
                          final url = _urlCtrl.text.trim();
                          if (url.isEmpty) return;
                          setState(() => _loading = true);
                          try {
                            final svc = ref.read(recipeImportServiceProvider);
                            final d = await svc.importFromUrl(url);
                            ref.read(draftRecipeProvider.notifier).state = d;
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Couldn't fetch page"),
                                ),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _loading = false);
                          }
                        },
                  child: _loading
                      ? const SizedBox(
                          width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Import'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (draft != null) ...[
              const Divider(),
              Text('Step 2: Preview & Map', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              _MetaEditor(draft: draft),
              const SizedBox(height: 12),
              Text('Ingredients', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              ingredientsAsync.when(
                data: (all) => _IngredientsEditor(
                  draft: draft,
                  allIngredients: all,
                  onChanged: (newDraft) =>
                      ref.read(draftRecipeProvider.notifier).state = newDraft,
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 12),
              Text('Steps', style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              _StepsEditor(
                draft: draft,
                onChanged: (newDraft) =>
                    ref.read(draftRecipeProvider.notifier).state = newDraft,
              ),
              const SizedBox(height: 12),
              Text('Diet flags', style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              _DietFlagsEditor(
                draft: draft,
                onChanged: (newDraft) =>
                    ref.read(draftRecipeProvider.notifier).state = newDraft,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () async {
                  await _saveDraft(context, draft);
                },
                icon: const Icon(Icons.save),
                label: const Text('Save'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _saveDraft(BuildContext context, DraftRecipe draft) async {
    // Resolve ingredient IDs (existing or stubs)
    final uuid = const Uuid();
    final ingredientNotifier = ref.read(ingredientNotifierProvider.notifier);

    final resolvedIds = <int, String>{};
    for (int i = 0; i < draft.ingredients.length; i++) {
      final line = draft.ingredients[i];
      final sel = line.matchedIngredientId;
      if (sel != null && sel.startsWith('stub:')) {
        final name = sel.substring(5).trim().isEmpty ? line.name : sel.substring(5).trim();
        final id = 'imp_${uuid.v4()}';
        final unit = line.unit ?? domain.Unit.grams;
        final stub = domain.Ingredient(
          id: id,
          name: name,
          unit: unit,
          macrosPer100g: const domain.MacrosPerHundred(
            kcal: 0,
            proteinG: 0,
            carbsG: 0,
            fatG: 0,
          ),
          pricePerUnitCents: 0,
          purchasePack: domain.PurchasePack(qty: 1, unit: unit, priceCents: null),
          aisle: domain.Aisle.pantry,
          tags: const ['import'],
          source: domain.IngredientSource.manual,
        );
        await ingredientNotifier.addIngredient(stub);
        resolvedIds[i] = id;
      }
    }

    // Build Recipe items
    final items = <domainr.RecipeItem>[];
    for (int i = 0; i < draft.ingredients.length; i++) {
      final line = draft.ingredients[i];
      String? finalId = resolvedIds[i];
      final sel = line.matchedIngredientId;
      if (finalId == null && sel != null && !sel.startsWith('stub:')) {
        finalId = sel;
      }
      // If still null, skip the line (no mapping). Alternatively create a stub with generic name.
      if (finalId == null) continue;
      final unit = line.unit ?? domain.Unit.grams;
      items.add(domainr.RecipeItem(
        ingredientId: finalId,
        qty: line.qty ?? 0,
        unit: unit,
      ));
    }

    // Compose Recipe
    final recipeId = 'rec_imp_${DateTime.now().millisecondsSinceEpoch}';
    final recipe = domainr.Recipe(
      id: recipeId,
      name: draft.name.isEmpty ? 'Imported Recipe' : draft.name,
      servings: draft.servings ?? 1,
      timeMins: draft.timeMins ?? 0,
      cuisine: null,
      dietFlags: draft.dietFlags,
      items: items,
      steps: draft.steps,
      macrosPerServ:
          const domainr.MacrosPerServing(kcal: 0, proteinG: 0, carbsG: 0, fatG: 0),
      costPerServCents: 0,
      source: domainr.RecipeSource.manual,
    );

    final notifier = ref.read(recipeNotifierProvider.notifier);
    await notifier.addRecipe(recipe);

    // refresh and navigate
    ref.invalidate(allRecipesProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imported. Review ingredients & macros.')),
      );
      context.go('/recipe/$recipeId');
    }
  }
}

class _MetaEditor extends ConsumerWidget {
  const _MetaEditor({required this.draft});
  final DraftRecipe draft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(draftRecipeProvider.notifier);
    final nameCtrl = TextEditingController(text: draft.name);
    final servCtrl = TextEditingController(text: (draft.servings ?? '').toString());
    final timeCtrl = TextEditingController(text: (draft.timeMins ?? '').toString());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
          ),
          onChanged: (v) => notifier.state = draft.copyWith(name: v),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: servCtrl,
                decoration: const InputDecoration(
                  labelText: 'Servings',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) => notifier.state =
                    draft.copyWith(servings: int.tryParse(v.isEmpty ? '0' : v)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: timeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Time (mins)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) => notifier.state =
                    draft.copyWith(timeMins: int.tryParse(v.isEmpty ? '0' : v)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _IngredientsEditor extends StatelessWidget {
  const _IngredientsEditor({
    required this.draft,
    required this.allIngredients,
    required this.onChanged,
  });

  final DraftRecipe draft;
  final List<domain.Ingredient> allIngredients;
  final ValueChanged<DraftRecipe> onChanged;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (int i = 0; i < draft.ingredients.length; i++) {
      rows.add(_IngredientRow(
        index: i,
        line: draft.ingredients[i],
        allIngredients: allIngredients,
        onLineChanged: (updated) {
          final list = [...draft.ingredients];
          list[i] = updated;
          onChanged(draft.copyWith(ingredients: list));
        },
      ));
      rows.add(const Divider(height: 16));
    }
    if (rows.isEmpty) {
      return const Text('No ingredients detected. You can still edit and save.');
    }
    return Column(children: rows);
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({
    required this.index,
    required this.line,
    required this.allIngredients,
    required this.onLineChanged,
  });

  final int index;
  final DraftIngredientLine line;
  final List<domain.Ingredient> allIngredients;
  final ValueChanged<DraftIngredientLine> onLineChanged;

  @override
  Widget build(BuildContext context) {
    final qtyCtrl = TextEditingController(
      text: line.qty == null ? '' : line.qty!.toString(),
    );
    final unit = line.unit;

    final lowerName = line.name.toLowerCase();
    final suggestions = allIngredients
        .where((ing) => ing.name.toLowerCase().contains(lowerName))
        .take(20)
        .toList();

    final currentSel = line.matchedIngredientId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(line.rawText, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 6),
        Row(
          children: [
            SizedBox(
              width: 90,
              child: TextField(
                controller: qtyCtrl,
                decoration: const InputDecoration(
                  labelText: 'Qty',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) => onLineChanged(
                  line.copyWith(qty: double.tryParse(v.isEmpty ? '0' : v)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            DropdownButton<domain.Unit>(
              value: unit,
              hint: const Text('Unit'),
              items: const [
                DropdownMenuItem(
                  value: domain.Unit.grams,
                  child: Text('grams (g)'),
                ),
                DropdownMenuItem(
                  value: domain.Unit.milliliters,
                  child: Text('milliliters (ml)'),
                ),
                DropdownMenuItem(
                  value: domain.Unit.piece,
                  child: Text('piece'),
                ),
              ],
              onChanged: (u) => onLineChanged(line.copyWith(unit: u)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: currentSel ?? '',
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Match Ingredient',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: '',
                    child: Text('— None —'),
                  ),
                  ...suggestions.map((ing) => DropdownMenuItem<String>(
                        value: ing.id,
                        child: Text(ing.name),
                      )),
                  DropdownMenuItem<String>(
                    value: 'stub:${line.name}',
                    child: Text('Create stub "${line.name}"'),
                  ),
                ],
                onChanged: (val) {
                  onLineChanged(line.copyWith(matchedIngredientId: (val ?? '').isEmpty ? null : val));
                },
              ),
            ),
          ],
        ),
        // Warning on unit mismatch
        if (currentSel != null && currentSel.isNotEmpty && !currentSel.startsWith('stub:'))
          Builder(builder: (context) {
            final match = allIngredients.where((i) => i.id == currentSel);
            if (match.isEmpty) return const SizedBox.shrink();
            final matched = match.first;
            if (line.unit != null && matched.unit != line.unit) {
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Warning: Selected unit differs from ingredient base (${matched.unit.value}).',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.orange),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
      ],
    );
  }
}

class _StepsEditor extends StatelessWidget {
  const _StepsEditor({required this.draft, required this.onChanged});
  final DraftRecipe draft;
  final ValueChanged<DraftRecipe> onChanged;

  @override
  Widget build(BuildContext context) {
    final steps = [...draft.steps];
    return Column(
      children: [
        for (int i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextFormField(
              initialValue: steps[i],
              maxLines: null,
              decoration: InputDecoration(
                labelText: 'Step ${i + 1}',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    steps.removeAt(i);
                    onChanged(draft.copyWith(steps: steps));
                  },
                ),
              ),
              onChanged: (v) {
                steps[i] = v;
                onChanged(draft.copyWith(steps: steps));
              },
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {
              steps.add('');
              onChanged(draft.copyWith(steps: steps));
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Step'),
          ),
        ),
      ],
    );
  }
}

class _DietFlagsEditor extends StatelessWidget {
  const _DietFlagsEditor({required this.draft, required this.onChanged});
  final DraftRecipe draft;
  final ValueChanged<DraftRecipe> onChanged;

  @override
  Widget build(BuildContext context) {
    final flags = {...draft.dietFlags};
    final chips = [
      _chip('veg', flags, onChanged, draft),
      _chip('gf', flags, onChanged, draft),
      _chip('df', flags, onChanged, draft),
    ];
    return Wrap(spacing: 8, children: chips);
  }

  Widget _chip(String key, Set<String> flags, ValueChanged<DraftRecipe> onChanged,
      DraftRecipe draft) {
    final sel = flags.contains(key);
    return FilterChip(
      label: Text(key),
      selected: sel,
      onSelected: (v) {
        if (v) {
          flags.add(key);
        } else {
          flags.remove(key);
        }
        onChanged(draft.copyWith(dietFlags: flags.toList()));
      },
    );
  }
}
