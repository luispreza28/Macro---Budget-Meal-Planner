import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/plan_providers.dart';
import '../../providers/recipe_providers.dart';
import '../../providers/user_targets_providers.dart';
import '../../router/app_router.dart';
import '../../widgets/plan_widgets/totals_bar.dart';
import '../../widgets/plan_widgets/weekly_plan_grid.dart';
import '../../../domain/entities/recipe.dart';
import '../../../domain/entities/plan.dart';
import '../../../domain/entities/user_targets.dart';
import '../../widgets/plan_widgets/swap_drawer.dart';
import '../../providers/database_providers.dart';
import '../../services/export_service.dart';
import '../../../domain/entities/ingredient.dart';

// NEW: watch ingredients so we can pass them into WeeklyPlanGrid
import '../../providers/ingredient_providers.dart';

/// Comprehensive plan page with 7-day grid, totals bar, and swap functionality
class PlanPage extends ConsumerStatefulWidget {
  const PlanPage({super.key});

  @override
  ConsumerState<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends ConsumerState<PlanPage> {
  int? selectedMealIndex;
  bool isSwapDrawerOpen = false;

  PlanTotals _recomputeTotals({
    required Plan plan,
    required Map<String, Recipe> recipeMap,
  }) {
    double kcal = 0;
    double protein = 0;
    double carbs = 0;
    double fat = 0;
    int costCents = 0;

    for (final day in plan.days) {
      for (final meal in day.meals) {
        final recipe = recipeMap[meal.recipeId];
        if (recipe == null) continue;

        final servings = meal.servings;
        kcal += recipe.macrosPerServ.kcal * servings;
        protein += recipe.macrosPerServ.proteinG * servings;
        carbs += recipe.macrosPerServ.carbsG * servings;
        fat += recipe.macrosPerServ.fatG * servings;
        costCents += (recipe.costPerServCents * servings).round();
      }
    }

    return PlanTotals(
      kcal: kcal,
      proteinG: protein,
      carbsG: carbs,
      fatG: fat,
      costCents: costCents,
    );
  }

  Plan _planWithSwappedMeal({
    required Plan plan,
    required int dayIndex,
    required int mealIndex,
    required String newRecipeId,
    required Map<String, Recipe> recipeMap,
  }) {
    final newDays = plan.days.asMap().entries.map((entry) {
      final index = entry.key;
      final day = entry.value;

      if (index != dayIndex) {
        return day;
      }

      final newMeals = day.meals.asMap().entries.map((mealEntry) {
        final currentMealIndex = mealEntry.key;
        final meal = mealEntry.value;

        if (currentMealIndex != mealIndex) {
          return meal;
        }

        return meal.copyWith(recipeId: newRecipeId);
      }).toList();

      return day.copyWith(meals: newMeals);
    }).toList();

    final tempPlan = plan.copyWith(days: newDays);
    final newTotals = _recomputeTotals(plan: tempPlan, recipeMap: recipeMap);

    return tempPlan.copyWith(totals: newTotals);
  }

  @override
  Widget build(BuildContext context) {
    final currentPlanAsync = ref.watch(currentPlanProvider);
    final userTargetsAsync = ref.watch(currentUserTargetsProvider);
    final recipesAsync = ref.watch(allRecipesProvider);
    final ingredientsAsync = ref.watch(allIngredientsProvider); // <— NEW

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Plan'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              )
            : null,
        actions: [
          IconButton(
            onPressed: () => context.go(AppRouter.shoppingList),
            icon: const Icon(Icons.shopping_cart_outlined),
            tooltip: 'Shopping List',
          ),
          IconButton(
            onPressed: () async {
              await _generateNewPlan();
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Generate New Plan',
          ),
          PopupMenuButton(
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Settings'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.share),
                    SizedBox(width: 8),
                    Text('Export Plan'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              switch (value) {
                case 'settings':
                  context.go(AppRouter.settings);
                  break;
                case 'export':
                  final plan = currentPlanAsync.asData?.value;
                  final recipes = recipesAsync.asData?.value;
                  final ingredients = ingredientsAsync.asData?.value;

                  if (plan == null || recipes == null || ingredients == null) {
                    if (!mounted) {
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Plan data still loading. Try again.'),
                      ),
                    );
                    break;
                  }

                  final recipeMap = {
                    for (final recipe in recipes) recipe.id: recipe,
                  };
                  final ingredientMap = {
                    for (final ingredient in ingredients)
                      ingredient.id: ingredient,
                  };

                  _showExportChooser(plan, recipeMap, ingredientMap);
                  break;
              }
            },
          ),
        ],
      ),
      body: userTargetsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(error.toString()),
        data: (targets) {
          if (targets == null) {
            return _buildNoTargetsState();
          }

          return currentPlanAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => _buildErrorState(error.toString()),
            data: (plan) {
              if (plan == null) {
                return _buildNoPlanState();
              }

              return recipesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => _buildErrorState(error.toString()),
                data: (recipes) {
                  // Wait for ingredients too
                  return ingredientsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => _buildErrorState(error.toString()),
                    data: (ingredients) {
                      final recipeMap = {for (var r in recipes) r.id: r};
                      final ingredientMap = {
                        for (var i in ingredients) i.id: i,
                      };

                      return Stack(
                        children: [
                          Column(
                            children: [
                              // Totals bar
                              TotalsBar(
                                targets: targets,
                                actualKcal:
                                    plan.totals.kcal / 7, // Daily average
                                actualProteinG: plan.totals.proteinG / 7,
                                actualCarbsG: plan.totals.carbsG / 7,
                                actualFatG: plan.totals.fatG / 7,
                                actualCostCents: (plan.totals.costCents / 7)
                                    .round(),
                                showBudget: targets.budgetCents != null,
                              ),

                              // Plan grid
                              Expanded(
                                child: WeeklyPlanGrid(
                                  plan: plan,
                                  recipes: recipeMap,
                                  ingredients:
                                      ingredientMap, // <— NEW required param
                                  selectedMealIndex: selectedMealIndex,
                                  onMealTap: (dayIndex, mealIndex) {
                                    _handleMealTap(
                                      dayIndex,
                                      mealIndex,
                                      plan,
                                      recipeMap,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),

                          // Swap drawer
                          if (isSwapDrawerOpen && selectedMealIndex != null)
                            Positioned.fill(
                              child: GestureDetector(
                                onTap: _closeSwapDrawer,
                                child: Container(
                                  color: Colors.black.withOpacity(0.5),
                                  child: Align(
                                    alignment: Alignment.bottomCenter,
                                    child: GestureDetector(
                                      onTap:
                                          () {}, // Prevent closing when tapping drawer
                                      child: _buildSwapDrawer(
                                        plan,
                                        recipeMap,
                                        targets,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error loading plan',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              ref.invalidate(currentPlanProvider);
              ref.invalidate(currentUserTargetsProvider);
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoTargetsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.settings, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Setup Required',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Please complete your setup to generate meal plans.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.go(AppRouter.onboarding),
            child: const Text('Complete Setup'),
          ),
        ],
      ),
    );
  }

  Widget _buildNoPlanState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No Meal Plan',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Generate your first meal plan to get started.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              await _generateNewPlan();
            },
            child: const Text('Generate Plan'),
          ),
        ],
      ),
    );
  }

  Widget _buildSwapDrawer(
    Plan plan,
    Map<String, Recipe> recipeMap,
    UserTargets targets,
  ) {
    if (selectedMealIndex == null) return const SizedBox.shrink();

    // Get current meal details
    int dayIndex = 0;
    int mealIndex = 0;
    int currentIndex = 0;
    var found = false;

    // Find the selected meal
    for (int d = 0; d < plan.days.length && !found; d++) {
      final day = plan.days[d];
      for (int m = 0; m < day.meals.length; m++) {
        if (currentIndex == selectedMealIndex) {
          dayIndex = d;
          mealIndex = m;
          found = true;
          break;
        }
        currentIndex++;
      }
    }

    final currentMeal = plan.days[dayIndex].meals[mealIndex];
    final currentRecipe = recipeMap[currentMeal.recipeId];

    if (currentRecipe == null) {
      return const SizedBox.shrink();
    }

    final mealsInDay = plan.days[dayIndex].meals.length;
    final perMealCount = mealsInDay < 1 ? 1 : (mealsInDay > 6 ? 6 : mealsInDay);

    final perMealKcal = targets.kcal / perMealCount;
    final perMealProtein = targets.proteinG / perMealCount;
    final perMealCarbs = targets.carbsG / perMealCount;
    final perMealFat = targets.fatG / perMealCount;

    int? perMealBudgetCents;
    if (targets.budgetCents != null) {
      final dailyBudget = targets.budgetCents! / 7.0;
      perMealBudgetCents = (dailyBudget / perMealCount).round();
    }

    final ctx = SwapContext(
      currentRecipeId: currentRecipe.id,
      targetKcal: perMealKcal,
      targetProteinG: perMealProtein,
      targetCarbsG: perMealCarbs,
      targetFatG: perMealFat,
      mealIndex: selectedMealIndex!,
      targetsId: targets.id,
      budgetCents: perMealBudgetCents,
      limit: 12,
    );

    return Consumer(
      builder: (context, ref, _) {
        final suggestionsAsync = ref.watch(swapSuggestionsProvider(ctx));

        return suggestionsAsync.when(
          loading: () => SwapDrawer.loading(
            currentRecipe: currentRecipe,
            onClose: _closeSwapDrawer,
          ),
          error: (error, stackTrace) => SwapDrawer.error(
            currentRecipe: currentRecipe,
            onClose: _closeSwapDrawer,
            message: 'Couldn’t load suggestions',
          ),
          data: (alternatives) {
            final fallback = recipeMap.values
                .where((recipe) => recipe.id != currentRecipe.id)
                .take(5)
                .map(
                  (recipe) => SwapOption(
                    recipe: recipe,
                    reasons: const [],
                    costDeltaCents:
                        recipe.costPerServCents -
                        currentRecipe.costPerServCents,
                    proteinDeltaG:
                        recipe.macrosPerServ.proteinG -
                        currentRecipe.macrosPerServ.proteinG,
                    kcalDelta:
                        recipe.macrosPerServ.kcal -
                        currentRecipe.macrosPerServ.kcal,
                  ),
                )
                .toList(growable: false);

            final options = alternatives.isNotEmpty ? alternatives : fallback;

            return SwapDrawer(
              currentRecipe: currentRecipe,
              alternatives: options,
              onSwapSelected: (newRecipe) {
                unawaited(_handleSwapSelected(dayIndex, mealIndex, newRecipe));
              },
              onClose: _closeSwapDrawer,
            );
          },
        );
      },
    );
  }

  void _handleMealTap(
    int dayIndex,
    int mealIndex,
    plan,
    Map<String, Recipe> recipeMap,
  ) {
    final globalMealIndex = dayIndex * plan.days[0].meals.length + mealIndex;

    setState(() {
      if (selectedMealIndex == globalMealIndex) {
        // Same meal tapped - open swap drawer
        isSwapDrawerOpen = true;
      } else {
        // Different meal selected
        selectedMealIndex = globalMealIndex.toInt();
        isSwapDrawerOpen = false;
      }
    });
  }

  void _closeSwapDrawer() {
    setState(() {
      isSwapDrawerOpen = false;
    });
  }

  Future<void> _handleSwapSelected(
    int dayIndex,
    int mealIndex,
    Recipe newRecipe,
  ) async {
    final planAsync = ref.read(currentPlanProvider);
    final recipes = await ref.read(allRecipesProvider.future);
    final recipeMap = {for (final recipe in recipes) recipe.id: recipe};
    final plan = planAsync.asData?.value;

    if (plan == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No active plan to update')));
      return;
    }

    try {
      final updated = _planWithSwappedMeal(
        plan: plan,
        dayIndex: dayIndex,
        mealIndex: mealIndex,
        newRecipeId: newRecipe.id,
        recipeMap: recipeMap,
      );

      final notifier = ref.read(planNotifierProvider.notifier);
      await notifier.updatePlan(updated);

      if (!mounted) return;
      setState(() {
        isSwapDrawerOpen = false;
        selectedMealIndex = null;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Swapped to ${newRecipe.name}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to swap: $e')));
    }
  }

  /// Generate a new plan (now also fetching ingredients so the generator
  /// can compute totals from recipe.items).
  Future<void> _generateNewPlan() async {
    try {
      final recipes = await ref.read(allRecipesProvider.future);
      final targets = await ref.read(currentUserTargetsProvider.future);
      final ingredients = await ref.read(allIngredientsProvider.future);

      if (targets == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please complete setup first')),
        );
        return;
      }

      final generator = ref.read(planGenerationServiceProvider);
      final plan = await generator.generate(
        targets: targets,
        recipes: recipes,
        ingredients: ingredients,
      );

      final notifier = ref.read(planNotifierProvider.notifier);
      await notifier.savePlan(plan);
      await notifier.setCurrentPlan(plan.id);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Weekly plan generated')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to generate plan: $e')));
    }
  }

  void _showExportChooser(
    Plan plan,
    Map<String, Recipe> recipeMap,
    Map<String, Ingredient> ingredientMap,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Export Plan'),
        children: [
          SimpleDialogOption(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              try {
                await ExportService.sharePlanText(
                  plan: plan,
                  recipes: recipeMap,
                  ingredients: ingredientMap,
                );
                if (!mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Shared as text')));
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
              }
            },
            child: const Text('Share as Text (.txt)'),
          ),
          SimpleDialogOption(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              try {
                await ExportService.sharePlanCsv(
                  plan: plan,
                  recipes: recipeMap,
                  ingredients: ingredientMap,
                );
                if (!mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Shared as CSV')));
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
              }
            },
            child: const Text('Share as CSV (.csv)'),
          ),
        ],
      ),
    );
  }
}
