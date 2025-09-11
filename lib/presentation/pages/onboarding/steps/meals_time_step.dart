import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../onboarding_controller.dart';

/// Step 5: Meals per day and time constraints
class MealsTimeStep extends ConsumerWidget {
  const MealsTimeStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);

    final hasTimeLimit = state.timeCapMins != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meal planning preferences',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Set how many meals you want per day and any time constraints.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 32),
        
        // Meals per day
        Text(
          'Meals per day',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [2, 3, 4, 5].map((meals) {
            final isSelected = state.mealsPerDay == meals;
            return GestureDetector(
              onTap: () => controller.setMealsPerDay(meals),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        )
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      meals.toString(),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      'meals',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        
        const SizedBox(height: 32),
        
        // Time constraint toggle
        SwitchListTile(
          title: const Text('Set cooking time limit'),
          subtitle: const Text('Limit prep time per meal'),
          value: hasTimeLimit,
          onChanged: (value) {
            if (value) {
              controller.setTimeCapMins(30); // 30 min default
            } else {
              controller.setTimeCapMins(null);
            }
          },
        ),
        
        if (hasTimeLimit) ...[
          const SizedBox(height: 16),
          Text(
            'Maximum prep time per meal',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [10, 20, 30, 45, 60].map((minutes) {
              final isSelected = state.timeCapMins == minutes;
              return GestureDetector(
                onTap: () => controller.setTimeCapMins(minutes),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(20),
                    border: isSelected
                        ? Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          )
                        : null,
                  ),
                  child: Text(
                    '${minutes} min',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
        
        const SizedBox(height: 24),
        
        // Summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Planning Summary',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Text(
                '• ${state.mealsPerDay} meals per day',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (hasTimeLimit)
                Text(
                  '• Maximum ${state.timeCapMins} minutes prep time per meal',
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              else
                Text(
                  '• No time limits (may include longer prep recipes)',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
