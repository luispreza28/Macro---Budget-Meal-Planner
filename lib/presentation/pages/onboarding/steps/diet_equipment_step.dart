import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../widgets/tag_selector.dart';
import '../onboarding_controller.dart';

/// Step 6: Diet flags and equipment selection
class DietEquipmentStep extends ConsumerWidget {
  const DietEquipmentStep({super.key});

  static const Map<String, String> dietOptions = {
    'vegetarian': 'Vegetarian',
    'vegan': 'Vegan',
    'gluten_free': 'Gluten Free',
    'dairy_free': 'Dairy Free',
    'keto': 'Keto',
    'paleo': 'Paleo',
    'low_sodium': 'Low Sodium',
    'nut_free': 'Nut Free',
  };

  static const Map<String, String> equipmentOptions = {
    'stove': 'Stove/Cooktop',
    'oven': 'Oven',
    'microwave': 'Microwave',
    'slow_cooker': 'Slow Cooker',
    'instant_pot': 'Instant Pot',
    'air_fryer': 'Air Fryer',
    'grill': 'Grill',
    'blender': 'Blender',
    'food_processor': 'Food Processor',
    'rice_cooker': 'Rice Cooker',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dietary preferences & equipment',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Select any dietary restrictions and the cooking equipment you have available.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 32),
        
        // Diet flags
        TagSelector(
          title: 'Dietary Restrictions (optional)',
          options: dietOptions,
          selectedOptions: state.dietFlags,
          onChanged: (flags) => controller.setDietFlags(flags),
        ),
        
        const SizedBox(height: 32),
        
        // Equipment
        TagSelector(
          title: 'Available Cooking Equipment',
          options: equipmentOptions,
          selectedOptions: state.equipment,
          onChanged: (equipment) => controller.setEquipment(equipment),
        ),
        
        const SizedBox(height: 24),
        
        // Information cards
        if (state.dietFlags.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.restaurant,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Recipes will be filtered to match your dietary restrictions.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.kitchen,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Only recipes that can be made with your available equipment will be suggested.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 32),
        
        // Ready to start
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primaryContainer,
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'You\'re all set!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your personalized meal planner is ready. Tap "Get Started" to generate your first meal plan.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
