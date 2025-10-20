import 'package:flutter/material.dart';
import '../../../domain/entities/user_targets.dart';

/// Displays macro and budget totals vs targets
class TotalsBar extends StatelessWidget {
  const TotalsBar({
    super.key,
    required this.targets,
    required this.actualKcal,
    required this.actualProteinG,
    required this.actualCarbsG,
    required this.actualFatG,
    required this.actualCostCents,
    this.showBudget = true,
  });

  final UserTargets targets;
  final double actualKcal;
  final double actualProteinG;
  final double actualCarbsG;
  final double actualFatG;
  final int actualCostCents;
  final bool showBudget;

  @override
  Widget build(BuildContext context) {
    final budgetDollars = targets.budgetCents != null ? targets.budgetCents! / 100.0 : 0.0;
    final actualDollars = actualCostCents / 100.0;
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Totals',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Macros row
            Row(
              children: [
                Expanded(
                  child: _MacroIndicator(
                    label: 'Calories',
                    actual: actualKcal,
                    target: targets.kcal,
                    unit: 'kcal',
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MacroIndicator(
                    label: 'Protein',
                    actual: actualProteinG,
                    target: targets.proteinG,
                    unit: 'g',
                    color: Colors.red,
                    isProtein: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MacroIndicator(
                    label: 'Carbs',
                    actual: actualCarbsG,
                    target: targets.carbsG,
                    unit: 'g',
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MacroIndicator(
                    label: 'Fat',
                    actual: actualFatG,
                    target: targets.fatG,
                    unit: 'g',
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            
            // Budget section
            if (showBudget && targets.budgetCents != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              _BudgetIndicator(
                actual: actualDollars,
                target: budgetDollars / 7, // Daily budget
                weeklyBudget: budgetDollars,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MacroIndicator extends StatelessWidget {
  const _MacroIndicator({
    required this.label,
    required this.actual,
    required this.target,
    required this.unit,
    required this.color,
    this.isProtein = false,
  });

  final String label;
  final double actual;
  final double target;
  final String unit;
  final Color color;
  final bool isProtein;

  @override
  Widget build(BuildContext context) {
    final percentage = target > 0 ? (actual / target).clamp(0.0, 1.5) : 0.0;
    final isOverTarget = percentage > 1.0;
    final isUnderProtein = isProtein && percentage < 1.0;
    
    Color indicatorColor = color;
    if (isUnderProtein) {
      indicatorColor = Colors.red;
    } else if (isOverTarget && !isProtein) {
      indicatorColor = Colors.orange;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              '${actual.toStringAsFixed(0)}/${target.toStringAsFixed(0)} $unit',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage.clamp(0.0, 1.0),
          backgroundColor: color.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
        ),
        if (percentage != 1.0) ...[
          const SizedBox(height: 2),
          Text(
            percentage > 1.0 
                ? '+${((percentage - 1.0) * 100).toStringAsFixed(0)}%'
                : '-${((1.0 - percentage) * 100).toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: indicatorColor,
              fontSize: 10,
            ),
          ),
        ],
      ],
    );
  }
}

class _BudgetIndicator extends StatelessWidget {
  const _BudgetIndicator({
    required this.actual,
    required this.target,
    required this.weeklyBudget,
  });

  final double actual;
  final double target;
  final double weeklyBudget;

  @override
  Widget build(BuildContext context) {
    final percentage = target > 0 ? (actual / target).clamp(0.0, 1.5) : 0.0;
    final isOverBudget = percentage > 1.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: 'Daily budget: \$${actual.toStringAsFixed(2)} of \$${target.toStringAsFixed(2)}',
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily Budget',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                '\$${actual.toStringAsFixed(2)} / \$${target.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage.clamp(0.0, 1.0),
          backgroundColor: Colors.green.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(
            isOverBudget ? Colors.red : Colors.green,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Weekly: \$${weeklyBudget.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
