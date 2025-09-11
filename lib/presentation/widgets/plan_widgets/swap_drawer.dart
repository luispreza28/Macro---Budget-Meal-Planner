import 'package:flutter/material.dart';
import '../../../domain/entities/recipe.dart';

/// Bottom drawer for showing meal swap options
class SwapDrawer extends StatelessWidget {
  const SwapDrawer({
    super.key,
    required this.currentRecipe,
    required this.alternatives,
    required this.onSwapSelected,
    required this.onClose,
  });

  final Recipe currentRecipe;
  final List<SwapOption> alternatives;
  final Function(Recipe newRecipe) onSwapSelected;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
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
              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4),
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
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Currently: ${currentRecipe.name}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          // Alternatives list
          Expanded(
            child: alternatives.isEmpty
                ? const Center(
                    child: Text('No alternatives available'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: alternatives.length,
                    itemBuilder: (context, index) {
                      final option = alternatives[index];
                      return _SwapOptionCard(
                        option: option,
                        onTap: () {
                          onSwapSelected(option.recipe);
                          onClose();
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SwapOptionCard extends StatelessWidget {
  const _SwapOptionCard({
    required this.option,
    required this.onTap,
  });

  final SwapOption option;
  final VoidCallback onTap;

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
                      label: '${option.proteinDeltaG > 0 ? '+' : ''}${option.proteinDeltaG.toStringAsFixed(0)}g protein',
                      isPositive: option.proteinDeltaG > 0,
                      icon: Icons.fitness_center,
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (option.kcalDelta != 0) ...[
                    _ImpactChip(
                      label: '${option.kcalDelta > 0 ? '+' : ''}${option.kcalDelta.toStringAsFixed(0)} cal',
                      isPositive: option.kcalDelta.abs() < 50, // Small calorie changes are good
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
      case SwapReasonType.higherProtein:
        backgroundColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red;
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
            Icon(
              icon,
              size: 12,
              color: textColor,
            ),
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
          Icon(
            icon,
            size: 12,
            color: color,
          ),
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
  const SwapReason({
    required this.type,
    required this.description,
  });

  final SwapReasonType type;
  final String description;
}

enum SwapReasonType {
  cheaper,
  higherProtein,
  fasterPrep,
  pantryItem,
  betterMacros,
}
