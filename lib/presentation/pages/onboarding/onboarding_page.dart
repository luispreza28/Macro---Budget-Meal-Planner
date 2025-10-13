import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../router/app_router.dart';
import '../../providers/user_targets_providers.dart';
import '../../providers/database_providers.dart';
import '../../providers/plan_providers.dart';
import '../../providers/recipe_providers.dart';
import '../../providers/ingredient_providers.dart';
import '../../providers/budget_providers.dart';
import '../../widgets/onboarding_step_indicator.dart';
import 'onboarding_controller.dart';
import 'steps/goals_step.dart';
import 'steps/body_weight_step.dart';
import 'steps/macros_step.dart';
import 'steps/budget_step.dart';
import 'steps/meals_time_step.dart';
import 'steps/diet_equipment_step.dart';

/// Comprehensive onboarding page with multi-step flow
class OnboardingPage extends ConsumerWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final userTargetsNotifier = ref.read(userTargetsNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Step indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: OnboardingStepIndicator(
              currentStep: state.currentStep,
              totalSteps: OnboardingController.totalSteps,
            ),
          ),
          
          // Step content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _buildStepContent(state.currentStep),
            ),
          ),
          
          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Back button
                if (state.currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: controller.previousStep,
                      child: const Text('Back'),
                    ),
                  )
                else
                  const Spacer(),
                
                const SizedBox(width: 16),
                
                // Next/Finish button
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: state.canProceed
                        ? () => _handleNextStep(context, ref, state, controller, userTargetsNotifier)
                        : null,
                    child: Text(
                      state.currentStep == OnboardingController.totalSteps - 1
                          ? 'Get Started'
                          : 'Continue',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(int step) {
    switch (step) {
      case 0:
        return const GoalsStep();
      case 1:
        return const BodyWeightStep();
      case 2:
        return const MacrosStep();
      case 3:
        return const BudgetStep();
      case 4:
        return const MealsTimeStep();
      case 5:
        return const DietEquipmentStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _handleNextStep(
    BuildContext context,
    WidgetRef ref,
    OnboardingState state,
    OnboardingController controller,
    UserTargetsNotifier userTargetsNotifier,
  ) async {
    if (state.currentStep == OnboardingController.totalSteps - 1) {
      // Final step - save user targets, generate first plan, and complete onboarding
      try {
        final userTargets = state.toUserTargets();
        // Persist targets
        await userTargetsNotifier.saveUserTargets(userTargets);
        await userTargetsNotifier.markOnboardingCompleted();

        // Also set the v1 onboarding flag explicitly for gating
        final prefs = ref.read(sharedPreferencesProvider);
        await prefs.setBool(kOnboardingDone, true);

        // Generate first plan
        final gen = ref.read(planGenerationServiceProvider);
        final recipes = await ref.read(allRecipesProvider.future);
        final ingredients = await ref.read(allIngredientsProvider.future);
        // Respect diet flags on first generation if provided
        final filteredRecipes = userTargets.dietFlags.isEmpty
            ? recipes
            : recipes
                .where((r) => r.isCompatibleWithDiet(userTargets.dietFlags))
                .toList(growable: false);

        final plan = await gen.generate(
          targets: userTargets,
          recipes: filteredRecipes.isEmpty ? recipes : filteredRecipes,
          ingredients: ingredients,
        );

        // Save and select plan
        final planRepo = ref.read(planRepositoryProvider);
        await planRepo.addPlan(plan);
        await ref.read(planNotifierProvider.notifier).setCurrentPlan(plan.id);

        // Invalidate dependent providers so UI refreshes
        ref.invalidate(currentUserTargetsProvider);
        ref.invalidate(currentPlanProvider);
        ref.invalidate(weeklyCostSummaryProvider);
        ref.invalidate(budgetStatusProvider);

        if (context.mounted) {
          // Navigate to plan page after success
          context.go(AppRouter.plan);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error completing setup: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      // Go to next step
      controller.nextStep();
    }
  }
}
