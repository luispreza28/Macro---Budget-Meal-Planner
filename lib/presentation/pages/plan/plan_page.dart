import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/plan_providers.dart';
import '../../providers/recipe_providers.dart';
import '../../providers/user_targets_providers.dart';
import '../../router/app_router.dart';
import '../../widgets/plan_widgets/totals_bar.dart';
import '../../widgets/plan_widgets/weekly_plan_grid.dart';
import '../../widgets/plan_widgets/swap_drawer.dart';
import '../../../domain/entities/recipe.dart';
import '../../providers/database_providers.dart';

/// Comprehensive plan page with 7-day grid, totals bar, and swap functionality
class PlanPage extends ConsumerStatefulWidget {
  const PlanPage({super.key});

  @override
  ConsumerState<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends ConsumerState<PlanPage> {
  int? selectedMealIndex;
  bool isSwapDrawerOpen = false;

  @override
  Widget build(BuildContext context) {
    final currentPlanAsync = ref.watch(currentPlanProvider);
    final userTargetsAsync = ref.watch(currentUserTargetsProvider);
    final recipesAsync = ref.watch(allRecipesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Plan'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go(AppRouter.home);
            }
          },
        ),
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
                  _showExportDialog();
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
                  final recipeMap = {for (var r in recipes) r.id: r};

                  return Stack(
                    children: [
                      Column(
                        children: [
                          // Totals bar
                          TotalsBar(
                            targets: targets,
                            actualKcal: plan.totals.kcal / 7, // Daily average
                            actualProteinG: plan.totals.proteinG / 7,
                            actualCarbsG: plan.totals.carbsG / 7,
                            actualFatG: plan.totals.fatG / 7,
                            actualCostCents: (plan.totals.costCents / 7).round(),
                            showBudget: targets.budgetCents != null,
                          ),

                          // Plan grid
                          Expanded(
                            child: WeeklyPlanGrid(
                              plan: plan,
                              recipes: recipeMap,
                              selectedMealIndex: selectedMealIndex,
                              onMealTap: (dayIndex, mealIndex) {
                                _handleMealTap(dayIndex, mealIndex, plan, recipeMap);
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
                                  onTap: () {}, // Prevent closing when tapping drawer
                                  child: _buildSwapDrawer(plan, recipeMap),
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
          Text('Error loading plan', style: Theme.of(context).textTheme.headlineSmall),
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
          Text('Setup Required', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text('Please complete your setup to generate meal plans.', textAlign: TextAlign.center),
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
          Text('No Meal Plan', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text('Generate your first meal plan to get started.', textAlign: TextAlign.center),
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

  Widget _buildSwapDrawer(plan, Map<String, Recipe> recipeMap) {
    int dayIndex = 0;
    int mealIndex = 0;
    int currentIndex = 0;

    for (int d = 0; d < plan.days.length; d++) {
      final day = plan.days[d];
      for (int m = 0; m < day.meals.length; m++) {
        if (currentIndex == selectedMealIndex) {
          dayIndex = d;
          mealIndex = m;
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

    final alternatives = _generateMockSwapOptions(currentRecipe, recipeMap);

    return SwapDrawer(
      currentRecipe: currentRecipe,
      alternatives: alternatives,
      onSwapSelected: (newRecipe) {
        _handleSwapSelected(dayIndex, mealIndex, newRecipe);
      },
      onClose: _closeSwapDrawer,
    );
  }

  void _handleMealTap(int dayIndex, int mealIndex, plan, Map<String, Recipe> recipeMap) {
    final globalMealIndex = dayIndex * plan.days[0].meals.length + mealIndex;

    setState(() {
      if (selectedMealIndex == globalMealIndex) {
        isSwapDrawerOpen = true;
      } else {
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

  void _handleSwapSelected(int dayIndex, int mealIndex, Recipe newRecipe) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Swapped to ${newRecipe.name}'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {},
        ),
      ),
    );
  }

  // -------- NEW: seed minimal recipes if DB is empty --------
  Future<void> _ensureSeedRecipesIfEmpty() async {
    final repo = ref.read(recipeRepositoryProvider);
    final count = await repo.getRecipesCount();
    if (count > 0) return;

    final seeds = <Recipe>[
      Recipe(
        id: 'seed_oatmeal_pb',
        name: 'Peanut Butter Oatmeal',
        servings: 1,
        timeMins: 8,
        cuisine: 'American',
        dietFlags: const ['quick', 'high_volume'],
        items: const [],
        steps: const ['Cook oats with water/milk', 'Stir in peanut butter'],
        macrosPerServ: const MacrosPerServing(kcal: 400, proteinG: 18, carbsG: 55, fatG: 12),
        costPerServCents: 120,
        source: RecipeSource.seed,
      ),
      Recipe(
        id: 'seed_chicken_rice',
        name: 'Chicken & Rice',
        servings: 1,
        timeMins: 25,
        cuisine: 'American',
        dietFlags: const ['high_protein'],
        items: const [],
        steps: const ['Cook rice', 'Sauté chicken, combine'],
        macrosPerServ: const MacrosPerServing(kcal: 550, proteinG: 45, carbsG: 65, fatG: 12),
        costPerServCents: 250,
        source: RecipeSource.seed,
      ),
      Recipe(
        id: 'seed_yogurt_bowl',
        name: 'Greek Yogurt Bowl',
        servings: 1,
        timeMins: 5,
        cuisine: 'American',
        dietFlags: const ['quick', 'high_protein'],
        items: const [],
        steps: const ['Mix yogurt, fruit, and honey'],
        macrosPerServ: const MacrosPerServing(kcal: 300, proteinG: 22, carbsG: 35, fatG: 6),
        costPerServCents: 180,
        source: RecipeSource.seed,
      ),
      Recipe(
        id: 'seed_veggie_omelette',
        name: 'Veggie Omelette',
        servings: 1,
        timeMins: 12,
        cuisine: 'American',
        dietFlags: const ['quick', 'high_protein'],
        items: const [],
        steps: const ['Beat eggs', 'Cook with veggies'],
        macrosPerServ: const MacrosPerServing(kcal: 350, proteinG: 24, carbsG: 6, fatG: 24),
        costPerServCents: 160,
        source: RecipeSource.seed,
      ),
      Recipe(
        id: 'seed_tuna_sandwich',
        name: 'Tuna Sandwich',
        servings: 1,
        timeMins: 7,
        cuisine: 'American',
        dietFlags: const ['quick'],
        items: const [],
        steps: const ['Mix tuna with mayo', 'Assemble sandwich'],
        macrosPerServ: const MacrosPerServing(kcal: 420, proteinG: 28, carbsG: 45, fatG: 12),
        costPerServCents: 210,
        source: RecipeSource.seed,
      ),
      Recipe(
        id: 'seed_pasta_bolognese',
        name: 'Pasta Bolognese',
        servings: 1,
        timeMins: 30,
        cuisine: 'Italian',
        dietFlags: const ['calorie_dense'],
        items: const [],
        steps: const ['Cook pasta', 'Simmer sauce', 'Combine'],
        macrosPerServ: const MacrosPerServing(kcal: 700, proteinG: 30, carbsG: 90, fatG: 20),
        costPerServCents: 300,
        source: RecipeSource.seed,
      ),
      Recipe(
        id: 'seed_pb_toast',
        name: 'PB Toast',
        servings: 1,
        timeMins: 3,
        cuisine: 'American',
        dietFlags: const ['quick'],
        items: const [],
        steps: const ['Toast bread', 'Spread PB'],
        macrosPerServ: const MacrosPerServing(kcal: 320, proteinG: 12, carbsG: 28, fatG: 18),
        costPerServCents: 80,
        source: RecipeSource.seed,
      ),
      Recipe(
        id: 'seed_bean_chili',
        name: 'Bean Chili',
        servings: 1,
        timeMins: 35,
        cuisine: 'Mexican',
        dietFlags: const ['high_volume'],
        items: const [],
        steps: const ['Simmer beans with spices and tomatoes'],
        macrosPerServ: const MacrosPerServing(kcal: 450, proteinG: 22, carbsG: 60, fatG: 12),
        costPerServCents: 180,
        source: RecipeSource.seed,
      ),
    ];

    await repo.bulkInsertRecipes(seeds);
  }

  /// Generate a plan using repository data; seed recipes if needed.
  Future<void> _generateNewPlan() async {
    try {
      // Make sure we have some recipes the first time.
      await _ensureSeedRecipesIfEmpty();

      // Fetch directly from repository to avoid timing issues with streams.
      final recipeRepo = ref.read(recipeRepositoryProvider);
      final recipes = await recipeRepo.getAllRecipes();

      final targets = await ref.read(currentUserTargetsProvider.future);
      if (targets == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please complete setup first')),
        );
        return;
      }

      final generator = ref.read(planGenerationServiceProvider);
      final plan = generator.generate(targets: targets, recipes: recipes);

      final notifier = ref.read(planNotifierProvider.notifier);
      await notifier.savePlan(plan);
      await notifier.setCurrentPlan(plan.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Weekly plan generated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate plan: $e')),
      );
    }
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Plan'),
        content: const Text('Export functionality will be implemented in Stage 5.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  List<SwapOption> _generateMockSwapOptions(Recipe currentRecipe, Map<String, Recipe> recipeMap) {
    final alternatives = recipeMap.values
        .where((r) => r.id != currentRecipe.id)
        .take(3)
        .map((r) => SwapOption(
              recipe: r,
              reasons: const [
                SwapReason(
                  type: SwapReasonType.cheaper,
                  description: 'Save \$2.50/week',
                ),
                SwapReason(
                  type: SwapReasonType.higherProtein,
                  description: '+15g protein',
                ),
              ],
              costDeltaCents: -250,
              proteinDeltaG: 15,
              kcalDelta: -50,
            ))
        .toList();

    return alternatives;
  }
}
