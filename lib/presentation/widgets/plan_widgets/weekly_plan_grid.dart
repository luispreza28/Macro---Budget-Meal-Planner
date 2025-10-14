import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/plan.dart';
import '../../../domain/entities/recipe.dart';
import '../../../domain/entities/ingredient.dart'; // NEW
import 'meal_card.dart';
import 'shortfall_fixit_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/shortfall_providers.dart';
// note: Consumer used locally for pins and shortfalls
import '../../providers/plan_pin_providers.dart';
import '../../../domain/services/plan_pin_service.dart';

/// 7-day meal plan grid widget
class WeeklyPlanGrid extends StatelessWidget {
  const WeeklyPlanGrid({
    super.key,
    required this.plan,
    required this.recipes,
    required this.onMealTap,
    required this.ingredients, // NEW
    this.selectedMealIndex,
    this.ingredientNameById = const {},
  });

  final Plan plan;
  final Map<String, Recipe> recipes; // recipeId -> Recipe
  final Map<String, Ingredient> ingredients; // NEW
  final Function(int dayIndex, int mealIndex) onMealTap;
  final int? selectedMealIndex;
  final Map<String, String> ingredientNameById;

  @override
  Widget build(BuildContext context) {
    if (plan.days.isEmpty) {
      return const Center(
        child: Text('No meal plan available'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: plan.days.asMap().entries.map((dayEntry) {
          final dayIndex = dayEntry.key;
          final day = dayEntry.value;
          final date = DateTime.tryParse(day.date) ??
              DateTime.now().add(Duration(days: dayIndex));

          return Column(
            children: [
              _DayHeader(date: date),
              const SizedBox(height: 12),
              _MealsRow(
                meals: day.meals,
                recipes: recipes,
                ingredients: ingredients, // NEW
                onMealTap: (mealIndex) => onMealTap(dayIndex, mealIndex),
                selectedMealIndex: selectedMealIndex,
                dayIndex: dayIndex,
                ingredientNameById: ingredientNameById,
                planId: plan.id,
              ),
              if (dayIndex < plan.days.length - 1) const SizedBox(height: 24),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
    final isTomorrow = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day + 1;

    String dateText;
    if (isToday) {
      dateText = 'Today';
    } else if (isTomorrow) {
      dateText = 'Tomorrow';
    } else {
      dateText = DateFormat('EEEE').format(date);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: isToday
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            dateText,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isToday
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(width: 8),
          Text(
            DateFormat('MMM d').format(date),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isToday
                      ? Theme.of(context)
                          .colorScheme
                          .onPrimaryContainer
                          .withOpacity(0.8)
                      : Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withOpacity(0.8),
                ),
          ),
        ],
      ),
    );
  }
}

class _MealsRow extends StatelessWidget {
  const _MealsRow({
    required this.meals,
    required this.recipes,
    required this.ingredients, // NEW
    required this.onMealTap,
    required this.dayIndex,
    this.selectedMealIndex,
    this.ingredientNameById = const {},
    required this.planId,
  });

  final List<PlanMeal> meals;
  final Map<String, Recipe> recipes;
  final Map<String, Ingredient> ingredients; // NEW
  final Function(int mealIndex) onMealTap;
  final int? selectedMealIndex;
  final int dayIndex;
  final Map<String, String> ingredientNameById;
  final String planId;

  @override
  Widget build(BuildContext context) {
    if (meals.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No meals planned for this day'),
        ),
      );
    }

    return Column(
      children: meals.asMap().entries.map((mealEntry) {
        final mealIndex = mealEntry.key;
        final meal = mealEntry.value;
        final recipe = recipes[meal.recipeId];

        if (recipe == null) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Recipe not found: ${meal.recipeId}'),
            ),
          );
        }

        final globalMealIndex = dayIndex * meals.length + mealIndex;
        final isSelected = selectedMealIndex == globalMealIndex;

        return Column(
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getMealLabel(mealIndex, meals.length),
                    style:
                        Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSecondaryContainer,
                              fontWeight: FontWeight.w500,
                            ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Consumer(
                    builder: (context, ref, _) {
                      final pinsAsync = ref.watch(pinsForCurrentPlanProvider);
                      final pins = pinsAsync.asData?.value ?? const <String, String>{};
                      final slotKey = 'd${dayIndex}-m${mealIndex}';
                      final pinned = pins.containsKey(slotKey);
                      return Stack(
                        children: [
                          MealCard(
                            recipe: recipe,
                            servings: meal.servings,
                            ingredients: ingredients, // NEW
                            onTap: () => onMealTap(mealIndex),
                            isSelected: isSelected,
                            ingredientNameById: ingredientNameById,
                            onInfoTap: () => context.push('/recipe/${recipe.id}'),
                          ),
                          // Fix It badge if shortfall exists
                          Positioned(
                            top: 2,
                            left: 2,
                            child: Consumer(
                              builder: (context, ref, _) {
                                final servingsInt = meal.servings.round();
                                final async = ref.watch(
                                  mealShortfallProvider((recipeId: recipe.id, servingsForMeal: servingsInt)),
                                );
                                final ms = async.asData?.value;
                                final hasShortfall = (ms != null) && (ms.coverageRatio < 1.0) && ms.lines.isNotEmpty;
                                if (!hasShortfall) return const SizedBox.shrink();
                                return Tooltip(
                                  message: 'Fix It',
                                  child: InkWell(
                                    onTap: () {
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        showDragHandle: true,
                                        builder: (_) => ShortfallFixItSheet(
                                          recipeId: recipe.id,
                                          servingsForMeal: servingsInt,
                                          onSwapRequested: () => onMealTap(mealIndex),
                                        ),
                                      );
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.errorContainer,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Fix It',
                                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                              color: Theme.of(context).colorScheme.onErrorContainer,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          // Pin badge
                          if (pinned)
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.tertiaryContainer,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'PINNED',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: Theme.of(context).colorScheme.onTertiaryContainer,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                            ),
                          // Pin/unpin button
                          Positioned(
                            top: 2,
                            right: 2,
                            child: IconButton(
                              tooltip: pinned ? 'Unpin' : 'Pin',
                              icon: Icon(pinned ? Icons.push_pin : Icons.push_pin_outlined, size: 18),
                              onPressed: () async {
                                final svc = ref.read(planPinServiceProvider);
                                if (pinned) {
                                  await svc.clearPin(planId: planId, slotKey: slotKey);
                                } else {
                                  await svc.setPin(planId: planId, slotKey: slotKey, recipeId: recipe.id);
                                }
                                ref.invalidate(pinsForCurrentPlanProvider);
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
            if (mealIndex < meals.length - 1) const SizedBox(height: 8),
          ],
        );
      }).toList(),
    );
  }

  String _getMealLabel(int mealIndex, int totalMeals) {
    if (totalMeals == 2) {
      return mealIndex == 0 ? 'Breakfast' : 'Dinner';
    } else if (totalMeals == 3) {
      switch (mealIndex) {
        case 0:
          return 'Breakfast';
        case 1:
          return 'Lunch';
        case 2:
          return 'Dinner';
        default:
          return 'Meal ${mealIndex + 1}';
      }
    } else if (totalMeals == 4) {
      switch (mealIndex) {
        case 0:
          return 'Breakfast';
        case 1:
          return 'Lunch';
        case 2:
          return 'Dinner';
        case 3:
          return 'Snack';
        default:
          return 'Meal ${mealIndex + 1}';
      }
    } else if (totalMeals == 5) {
      switch (mealIndex) {
        case 0:
          return 'Breakfast';
        case 1:
          return 'Snack 1';
        case 2:
          return 'Lunch';
        case 3:
          return 'Snack 2';
        case 4:
          return 'Dinner';
        default:
          return 'Meal ${mealIndex + 1}';
      }
    } else {
      return 'Meal ${mealIndex + 1}';
    }
  }
}
