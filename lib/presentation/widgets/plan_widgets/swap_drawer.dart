import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/recipe.dart';
import '../../providers/recipe_pref_providers.dart';

/// Bottom drawer for showing meal swap options
class SwapDrawer extends ConsumerStatefulWidget {
  const SwapDrawer({
    super.key,
    required this.currentRecipe,
    required this.alternatives,
    required this.onSwapSelected,
    required this.onClose,
    this.errorMessage,
    this.isLoading = false,
  });

  const SwapDrawer.loading({
    super.key,
    required this.currentRecipe,
    required this.onClose,
  }) : alternatives = const [],
       onSwapSelected = _noRecipe,
       errorMessage = null,
       isLoading = true;

  const SwapDrawer.error({
    super.key,
    required this.currentRecipe,
    required this.onClose,
    String message = 'Error',
  }) : alternatives = const [],
       onSwapSelected = _noRecipe,
       errorMessage = message,
       isLoading = false;

  final Recipe currentRecipe;
  final List<SwapOption> alternatives;
  final void Function(Recipe newRecipe) onSwapSelected;
  final VoidCallback onClose;
  final String? errorMessage;
  final bool isLoading;

  @override
  ConsumerState<SwapDrawer> createState() => _SwapDrawerState();
}

class _SwapDrawerState extends ConsumerState<SwapDrawer> {
  bool _favoritesOnly = false;
  bool _hideExcluded = true;

  @override
  Widget build(BuildContext context) {
    final alternatives = widget.alternatives;
    Widget content;
    if (widget.isLoading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (widget.errorMessage != null) {
      content = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 36, color: Colors.redAccent),
            const SizedBox(height: 8),
            Text(
              widget.errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    } else if (alternatives.isEmpty) {
      content = const Center(child: Text('No alternatives available'));
    } else {
      final favAsync = ref.watch(favoriteRecipesProvider);
      final exAsync = ref.watch(excludedRecipesProvider);
      final favs = favAsync.asData?.value ?? const <String>{};
      final excluded = exAsync.asData?.value ?? const <String>{};

      final filtered = alternatives.where((opt) {
        final isFav = favs.contains(opt.recipe.id);
        final isEx = excluded.contains(opt.recipe.id);
        if (_hideExcluded && isEx) return false;
        if (_favoritesOnly && !isFav) return false;
        return true;
      }).toList(growable: false);

      content = ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final option = filtered[index];
          final isFav = favs.contains(option.recipe.id);
          return _SwapOptionCard(
            option: option,
            isFavorite: isFav,
            onTap: () {
              widget.onSwapSelected(option.recipe);
              widget.onClose();
            },
          );
        },
      );
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Swap Meal',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Currently: ${widget.currentRecipe.name}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(onPressed: widget.onClose, icon: const Icon(Icons.close)),
              ],
            ),
          ),
          // Filters
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Favorites only'),
                  selected: _favoritesOnly,
                  onSelected: (v) => setState(() => _favoritesOnly = v),
                  avatar: const Icon(Icons.star, size: 16, color: Colors.amber),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Hide excluded'),
                  selected: _hideExcluded,
                  onSelected: (v) => setState(() => _hideExcluded = v),
                ),
              ],
            ),
          ),
          // Alternatives list
          Expanded(child: content),
        ],
      ),
    );
  }
}

class _SwapOptionCard extends StatelessWidget {
  const _SwapOptionCard({required this.option, required this.onTap, this.isFavorite = false});

  final SwapOption option;
  final VoidCallback onTap;
  final bool isFavorite;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recipe name and basic info
              Row(
                children: [
                  if (isFavorite) ...[
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      option.recipe.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${option.recipe.timeMins} min',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Reason badges
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: option.reasons.map((reason) {
                  return _ReasonBadge(reason: reason);
                }).toList(),
              ),

              const SizedBox(height: 12),

              // Impact summary
              Row(
                children: [
                  if (option.costDeltaCents != 0) ...[
                    _ImpactChip(
                      label: option.costDeltaCents > 0
                          ? '+\$${(option.costDeltaCents / 100).toStringAsFixed(2)}'
                          : '-\$${(-option.costDeltaCents / 100).toStringAsFixed(2)}',
                      isPositive: option.costDeltaCents < 0,
                      icon: Icons.attach_money,
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (option.proteinDeltaG != 0) ...[
                    _ImpactChip(
                      label:
                          '${option.proteinDeltaG > 0 ? '+' : ''}${option.proteinDeltaG.toStringAsFixed(0)}g protein',
                      isPositive: option.proteinDeltaG > 0,
                      icon: Icons.fitness_center,
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (option.kcalDelta != 0) ...[
                    _ImpactChip(
                      label:
                          '${option.kcalDelta > 0 ? '+' : ''}${option.kcalDelta.toStringAsFixed(0)} cal',
                      isPositive:
                          option.kcalDelta.abs() <
                          50, // Small calorie changes are good
                      icon: Icons.local_fire_department,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReasonBadge extends StatelessWidget {
  const _ReasonBadge({required this.reason});

  final SwapReason reason;

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    IconData? icon;

    switch (reason.type) {
      case SwapReasonType.cheaper:
        backgroundColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green;
        icon = Icons.savings;
        break;
      case SwapReasonType.moreExpensive:
        backgroundColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red;
        icon = Icons.price_change;
        break;
      case SwapReasonType.higherProtein:
        backgroundColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red;
        icon = Icons.fitness_center;
        break;
      case SwapReasonType.lowerProtein:
        backgroundColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
        icon = Icons.fitness_center;
        break;
      case SwapReasonType.fasterPrep:
        backgroundColor = Colors.blue.withOpacity(0.1);
        textColor = Colors.blue;
        icon = Icons.timer;
        break;
      case SwapReasonType.pantryItem:
        backgroundColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange;
        icon = Icons.kitchen;
        break;
      case SwapReasonType.betterMacros:
        backgroundColor = Colors.purple.withOpacity(0.1);
        textColor = Colors.purple;
        icon = Icons.analytics;
        break;
      case SwapReasonType.higherCalories:
        backgroundColor = Colors.deepOrange.withOpacity(0.1);
        textColor = Colors.deepOrange;
        icon = Icons.local_fire_department;
        break;
      case SwapReasonType.lowerCalories:
        backgroundColor = Colors.teal.withOpacity(0.1);
        textColor = Colors.teal;
        icon = Icons.ac_unit;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            reason.description,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImpactChip extends StatelessWidget {
  const _ImpactChip({
    required this.label,
    required this.isPositive,
    required this.icon,
  });

  final String label;
  final bool isPositive;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final color = isPositive ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Data classes for swap functionality
class SwapOption {
  const SwapOption({
    required this.recipe,
    required this.reasons,
    required this.costDeltaCents,
    required this.proteinDeltaG,
    required this.kcalDelta,
  });

  final Recipe recipe;
  final List<SwapReason> reasons;
  final int costDeltaCents; // Cost difference in cents
  final double proteinDeltaG; // Protein difference in grams
  final double kcalDelta; // Calorie difference
}

class SwapReason {
  const SwapReason({required this.type, required this.description});

  final SwapReasonType type;
  final String description;
}

enum SwapReasonType {
  cheaper,
  moreExpensive,
  higherProtein,
  lowerProtein,
  fasterPrep,
  pantryItem,
  betterMacros,
  higherCalories,
  lowerCalories,
}

void _noRecipe(Recipe _) {}
