import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/recipe.dart';
import "package:go_router/go_router.dart";
import '../../../domain/entities/ingredient.dart'; // Unit & Ingredient here\r\n\r\nconst bool kShowPantryBadges = false; // gate pantry badges
import '../../providers/diet_allergen_providers.dart';

/// Card displaying a meal in the plan grid
class MealCard extends ConsumerWidget {
  const MealCard({
    super.key,
    required this.recipe,
    required this.servings,
    required this.onTap,
    this.onInfoTap,
    this.ingredients = const {}, // optional map for pretty names
    this.isSelected = false,
    this.showMacros = true,
    this.ingredientNameById = const {},
  });

  final Recipe recipe;
  final double servings;
  final VoidCallback onTap;
  final VoidCallback? onInfoTap;
  final bool isSelected;
  final bool showMacros;

  /// ingredientId -> user-facing name (optional, used if provided)
  final Map<String, String> ingredientNameById;

  /// Optional: ingredientId -> Ingredient (used to show nicer names if available)
  final Map<String, Ingredient> ingredients;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalKcal = recipe.macrosPerServ.kcal * servings;
    final totalProtein = recipe.macrosPerServ.proteinG * servings;
    final totalCost = recipe.costPerServCents * servings / 100;
    // Diet/allergen conflict detection (best-effort)
    final reqDiet = ref.watch(dietFlagsPrefProvider).asData?.value ?? const <String>[];
    final pickedAllergens = ref.watch(allergensPrefProvider).asData?.value ?? const <String>[];
    final strict = ref.watch(strictModePrefProvider).asData?.value ?? true;
    bool dietMismatch = reqDiet.isNotEmpty && !recipe.isCompatibleWithDiet(reqDiet);
    bool allergenConflict = false;
    if (!dietMismatch && pickedAllergens.isNotEmpty && ingredients.isNotEmpty) {
      // Lightweight inline heuristic: check ingredient names/tags
      final set = <String>{};
      for (final it in recipe.items) {
        final ing = ingredients[it.ingredientId];
        if (ing == null) continue;
        final lt = ing.tags.map((t) => t.toLowerCase());
        for (final t in lt) {
          if (t.startsWith('allergen:')) set.add(t.substring('allergen:'.length));
        }
        final name = ing.name.toLowerCase();
        if (name.contains('peanut')) set.add('peanut');
        if (name.contains('almond') || name.contains('walnut') || name.contains('cashew') || name.contains('pistachio') || name.contains('hazelnut')) set.add('tree_nut');
        if (name.contains('milk') || name.contains('cheese') || name.contains('butter') || name.contains('yogurt')) set.add('milk');
        if (name.contains('egg')) set.add('egg');
        if (name.contains('soy')) set.add('soy');
        if (name.contains('wheat')) set.add('wheat');
        if (name.contains('sesame')) set.add('sesame');
        if (name.contains('shrimp') || name.contains('crab') || name.contains('lobster')) set.add('shellfish');
        if (name.contains('fish')) set.add('fish');
      }
      allergenConflict = set.any((a) => pickedAllergens.contains(a));
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: isSelected ? 4 : 1,
      child: Semantics(
        label: '${recipe.name}, ${recipe.macrosPerServ.kcal.toStringAsFixed(0)} kilocalories per serving, \$${(recipe.costPerServCents / 100).toStringAsFixed(2)} per serving',
        button: true,
        hint: 'Open meal details',
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: isSelected
                ? BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  )
                : null,
          child: Stack(
            children: [
              if (dietMismatch || allergenConflict)
                Positioned(
                  top: 4,
                  left: 4,
                  child: Tooltip(
                    message: 'Allergen/Diet conflict (tap to swap)',
                    child: Icon(Icons.warning_amber_outlined, size: 16, color: Theme.of(context).colorScheme.error),
                  ),
                ),
              Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + servings chip + cost/serv chip
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        recipe.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (servings != 1.0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _trimZeros(servings) + 'x',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                        ),
                      ),
                    if (recipe.costPerServCents > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '\$${(recipe.costPerServCents / 100).toStringAsFixed(2)} / serv',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    ],
                    if (onInfoTap != null) ...[
                      const SizedBox(width: 6),
                      Semantics(
                        label: 'Open meal details',
                        button: true,
                        child: IconButton(
                          tooltip: 'Details',
                          visualDensity: VisualDensity.compact,
                          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                          icon: const Icon(Icons.info_outline, size: 18),
                          onPressed: onInfoTap,
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        // ignore: use_build_context_synchronously
                        context.push('/cook/${recipe.id}');
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Cook'),
                    ),
                  ),
                ),

                // Time & cost
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      '${recipe.timeMins} min',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const Spacer(),
                    Icon(Icons.attach_money, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    Text(
                      '\$${totalCost.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),

                if (showMacros) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _MacroChip(
                        label: '${totalKcal.toStringAsFixed(0)} cal',
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      _MacroChip(
                        label: '${totalProtein.toStringAsFixed(0)}p',
                        color: Colors.red,
                      ),
                    ],
                  ),
                ],

                // Flags
                if (recipe.dietFlags.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    children: recipe.dietFlags.take(2).map((flag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getFlagDisplayName(flag),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontSize: 9,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 8),

                // Show measurements button
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _showMeasurements(context),
                    icon: const Icon(Icons.scale),
                    label: const Text('Show measurements'),
                  ),
                ),
              ],
            ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }

  void _showMeasurements(BuildContext context) {
    final hasRealItems = recipe.items.isNotEmpty;
    final List<RecipeItem> items = hasRealItems ? recipe.items : _fallbackItems();

    if (items.isEmpty) {
      showModalBottomSheet(
        context: context,
        showDragHandle: true,
        builder: (ctx) => const _SimpleSheetMessage(
          title: 'Ingredients',
          message:
              'Measurements for this recipe are not available yet. They will appear once the recipe includes ingredient details.',
        ),
      );
      return;
    }

    final title =
        'Ingredients • ${_trimZeros(servings)}× serving${servings == 1 ? '' : 's'}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    recipe.name,
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text(
                    title,
                    style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                          color: Theme.of(ctx).colorScheme.primary,
                        ),
                  ),
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 12, thickness: 0.5),
                    itemBuilder: (_, i) {
                      final it = items[i];

                      final name =
                          ingredients[it.ingredientId]?.name ??
                          ingredientNameById[it.ingredientId] ??
                          _humanizeId(it.ingredientId);

                      final qty = it.qty * servings; // per-serving * servings
                      final unit = it.unit;

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: Theme.of(ctx).textTheme.bodyMedium,
                            ),
                          ),
                          Text(
                            _formatQty(qty, unit),
                            style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row( children: [ Expanded(child: OutlinedButton.icon(onPressed: () { Navigator.of(ctx).pop(); if (context.mounted) { context.push('/cook/'); } }, icon: const Icon(Icons.play_arrow), label: const Text('Cook')), ), const SizedBox(width: 12), Expanded(child: FilledButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Done'))), ], ),),
              ],
            ),
          ),
        );
      },
    );
  }

  // Now returns an empty list (no external constant needed).
  List<RecipeItem> _fallbackItems() => const <RecipeItem>[];

  String _trimZeros(double n) {
    final s = n.toStringAsFixed(1);
    return s.endsWith('.0') ? n.toStringAsFixed(0) : s;
    }

  String _formatQty(double qty, Unit unit) {
    final rounded = (qty * 10).round() / 10.0;
    final numStr = (rounded % 1 == 0)
        ? rounded.toStringAsFixed(0)
        : rounded.toStringAsFixed(1);
    switch (unit) {
      case Unit.grams:
        return '$numStr g';
      case Unit.milliliters:
        return '$numStr ml';
      case Unit.piece:
        return '$numStr pc';
    }
  }

  String _humanizeId(String id) =>
      id.replaceAll('_', ' ').replaceAll('-', ' ');

  String _getFlagDisplayName(String flag) {
    switch (flag.toLowerCase()) {
      case 'vegetarian':
      case 'veg':
        return 'VEG';
      case 'vegan':
        return 'VEGAN';
      case 'gluten_free':
      case 'gf':
        return 'GF';
      case 'dairy_free':
      case 'df':
        return 'DF';
      case 'keto':
        return 'KETO';
      case 'paleo':
        return 'PALEO';
      case 'low_sodium':
        return 'LOW-NA';
      case 'nut_free':
        return 'NF';
      default:
        final up = flag.toUpperCase();
        return up.length <= 3 ? up : up.substring(0, 3);
    }
  }
}

class _MacroChip extends StatelessWidget {
  const _MacroChip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 10,
            ),
      ),
    );
  }
}

/// Simple one-message bottom sheet used when nothing to show.
class _SimpleSheetMessage extends StatelessWidget {
  const _SimpleSheetMessage({required this.title, required this.message});
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
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
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(message, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
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
  }
}


