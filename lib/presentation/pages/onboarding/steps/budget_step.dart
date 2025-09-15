import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../widgets/macro_input_field.dart';
import '../onboarding_controller.dart';

/// Step 4: Budget setting (weekly budget, optional)
class BudgetStep extends ConsumerStatefulWidget {
  const BudgetStep({super.key});

  @override
  ConsumerState<BudgetStep> createState() => _BudgetStepState();
}

class _BudgetStepState extends ConsumerState<BudgetStep> {
  bool _ignoreBudgetChanges = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);

    final hasBudget = state.budgetCents != null;
    final budgetDollars = hasBudget ? (state.budgetCents! / 100.0) : 50.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Set your weekly budget',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Set a weekly grocery budget to optimize your meal plans for cost, or skip this step.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 24),

        // Budget toggle
        SwitchListTile(
          title: const Text('Set a weekly budget'),
          subtitle: const Text('Optimize meal plans for cost'),
          value: hasBudget,
          onChanged: (value) {
            if (value) {
              // Re-enable budget editing
              setState(() => _ignoreBudgetChanges = false);
              controller.setBudget(5000); // $50 default
            } else {
              // Prevent a final onChanged from MacroInputField re-enabling budget
              setState(() => _ignoreBudgetChanges = true);
              FocusScope.of(context).unfocus();
              controller.setBudget(null);
            }
          },
        ),

        const SizedBox(height: 8),

        // Animated swap between "has budget" vs "no budget" sections
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: hasBudget
              ? Column(
                  key: const ValueKey('has_budget'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Center(
                      child: SizedBox(
                        width: 200,
                        child: MacroInputField(
                          label: 'Weekly Budget',
                          unit: '\$',
                          value: budgetDollars,
                          min: 10,
                          max: 500,
                          helperText: 'Total grocery budget per week',
                          onChanged: (value) {
                            if (_ignoreBudgetChanges) return; // <- key guard
                            controller.setBudget((value * 100).round());
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Budget breakdown
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Budget Breakdown',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 12),
                          _BudgetItem(
                            label: 'Weekly Budget',
                            value: '\$${budgetDollars.toStringAsFixed(2)}',
                          ),
                          _BudgetItem(
                            label: 'Daily Budget',
                            value: '\$${(budgetDollars / 7).toStringAsFixed(2)}',
                          ),
                          _BudgetItem(
                            label: 'Per Meal Budget',
                            value:
                                '\$${(budgetDollars / 7 / state.mealsPerDay).toStringAsFixed(2)}',
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Container(
                  key: const ValueKey('no_budget'),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceVariant
                        .withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Without a budget, meal plans will focus on time optimization and nutritional quality.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _BudgetItem extends StatelessWidget {
  const _BudgetItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}
