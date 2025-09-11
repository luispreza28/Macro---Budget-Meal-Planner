import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../widgets/macro_input_field.dart';
import '../onboarding_controller.dart';

/// Step 3: Macro targets (calories, protein, carbs, fat)
class MacrosStep extends ConsumerWidget {
  const MacrosStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);

    // Calculate macro percentages
    final totalMacroCalories = (state.proteinG * 4) + (state.carbsG * 4) + (state.fatG * 9);
    final proteinPercent = totalMacroCalories > 0 ? (state.proteinG * 4) / totalMacroCalories * 100 : 0;
    final carbsPercent = totalMacroCalories > 0 ? (state.carbsG * 4) / totalMacroCalories * 100 : 0;
    final fatPercent = totalMacroCalories > 0 ? (state.fatG * 9) / totalMacroCalories * 100 : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Set your macro targets',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          state.selectedGoal == 'custom' 
              ? 'Set your daily macro targets.'
              : 'Review and adjust your calculated macro targets.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        
        // Calories
        MacroInputField(
          label: 'Daily Calories',
          unit: 'kcal',
          value: state.kcal,
          min: 800,
          max: 5000,
          onChanged: (value) => controller.setMacros(kcal: value),
        ),
        const SizedBox(height: 16),
        
        // Protein
        MacroInputField(
          label: 'Protein',
          unit: 'g',
          value: state.proteinG,
          min: 50,
          max: 300,
          suffix: '${proteinPercent.toStringAsFixed(0)}% of calories',
          onChanged: (value) => controller.setMacros(proteinG: value),
        ),
        const SizedBox(height: 16),
        
        // Carbs
        MacroInputField(
          label: 'Carbohydrates',
          unit: 'g',
          value: state.carbsG,
          min: 50,
          max: 500,
          suffix: '${carbsPercent.toStringAsFixed(0)}% of calories',
          onChanged: (value) => controller.setMacros(carbsG: value),
        ),
        const SizedBox(height: 16),
        
        // Fat
        MacroInputField(
          label: 'Fat',
          unit: 'g',
          value: state.fatG,
          min: 20,
          max: 200,
          suffix: '${fatPercent.toStringAsFixed(0)}% of calories',
          onChanged: (value) => controller.setMacros(fatG: value),
        ),
        const SizedBox(height: 24),
        
        // Macro summary card
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
                'Daily Macro Summary',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _MacroSummaryItem(
                      label: 'Calories',
                      value: '${state.kcal.toStringAsFixed(0)} kcal',
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Expanded(
                    child: _MacroSummaryItem(
                      label: 'Protein',
                      value: '${state.proteinG.toStringAsFixed(0)}g',
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _MacroSummaryItem(
                      label: 'Carbs',
                      value: '${state.carbsG.toStringAsFixed(0)}g',
                      color: Colors.orange,
                    ),
                  ),
                  Expanded(
                    child: _MacroSummaryItem(
                      label: 'Fat',
                      value: '${state.fatG.toStringAsFixed(0)}g',
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MacroSummaryItem extends StatelessWidget {
  const _MacroSummaryItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
      ],
    );
  }
}
