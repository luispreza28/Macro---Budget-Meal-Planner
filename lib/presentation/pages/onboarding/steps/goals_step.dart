import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../widgets/preset_card.dart';
import '../onboarding_controller.dart';

/// Step 1: Goal selection (Cutting, Bulking Budget, Bulking No-Budget, Custom)
class GoalsStep extends ConsumerWidget {
  const GoalsStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What\'s your goal?',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Choose a preset to get started quickly, or customize your own targets.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        PresetCard(
          title: 'Cutting',
          description: 'High protein, calorie deficit, high-volume foods for fat loss',
          icon: Icons.trending_down,
          isSelected: state.selectedGoal == 'cutting',
          onTap: () => controller.setGoal('cutting'),
        ),
        const SizedBox(height: 12),
        PresetCard(
          title: 'Bulking (Budget)',
          description: 'Calorie surplus with cost optimization for muscle gain',
          icon: Icons.trending_up,
          badge: 'Budget',
          isSelected: state.selectedGoal == 'bulking_budget',
          onTap: () => controller.setGoal('bulking_budget'),
        ),
        const SizedBox(height: 12),
        PresetCard(
          title: 'Bulking (No Budget)',
          description: 'Calorie surplus with time optimization for muscle gain',
          icon: Icons.trending_up,
          badge: 'Fast',
          isSelected: state.selectedGoal == 'bulking_no_budget',
          onTap: () => controller.setGoal('bulking_no_budget'),
        ),
        const SizedBox(height: 12),
        PresetCard(
          title: 'Solo on a Budget',
          description: 'Balanced nutrition optimized for single-person budgets',
          icon: Icons.person,
          badge: 'Popular',
          isSelected: state.selectedGoal == 'solo_budget',
          onTap: () => controller.setGoal('solo_budget'),
        ),
        const SizedBox(height: 12),
        PresetCard(
          title: 'Custom',
          description: 'Set your own macro targets and preferences',
          icon: Icons.tune,
          isSelected: state.selectedGoal == 'custom',
          onTap: () => controller.setGoal('custom'),
        ),
      ],
    );
  }
}
