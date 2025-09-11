import 'package:flutter/material.dart';
import '../../../domain/entities/recipe.dart';

/// Card displaying a meal in the plan grid
class MealCard extends StatelessWidget {
  const MealCard({
    super.key,
    required this.recipe,
    required this.servings,
    required this.onTap,
    this.isSelected = false,
    this.showMacros = true,
  });

  final Recipe recipe;
  final double servings;
  final VoidCallback onTap;
  final bool isSelected;
  final bool showMacros;

  @override
  Widget build(BuildContext context) {
    final totalKcal = recipe.macrosPerServ.kcal * servings;
    final totalProtein = recipe.macrosPerServ.proteinG * servings;
    final totalCost = recipe.costPerServCents * servings / 100;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: isSelected ? 4 : 1,
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
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Recipe name and servings
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
                          '${servings.toStringAsFixed(servings.truncateToDouble() == servings ? 0 : 1)}x',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Time and cost
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${recipe.timeMins} min',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.attach_money,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
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
                  
                  // Macros
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
                
                // Diet flags
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getFlagDisplayName(String flag) {
    switch (flag.toLowerCase()) {
      case 'vegetarian':
        return 'VEG';
      case 'vegan':
        return 'VEGAN';
      case 'gluten_free':
        return 'GF';
      case 'dairy_free':
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
        return flag.toUpperCase().substring(0, 3);
    }
  }
}

class _MacroChip extends StatelessWidget {
  const _MacroChip({
    required this.label,
    required this.color,
  });

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
