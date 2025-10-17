import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/plan_providers.dart';
import '../../providers/recipe_providers.dart';
import '../../providers/user_targets_providers.dart';
import '../../providers/periodization_providers.dart';
import '../../../domain/services/periodization_service.dart';
import '../../router/app_router.dart';
import '../../widgets/plan_widgets/totals_bar.dart';
import '../../widgets/plan_widgets/weekly_plan_grid.dart';
import '../../../domain/entities/recipe.dart';
import '../../../domain/entities/plan.dart';
import '../../../domain/entities/user_targets.dart';
import '../../widgets/plan_widgets/swap_drawer.dart';
import '../../services/export_service.dart';
import '../../services/export_service.dart' as svc;
import '../../../domain/entities/ingredient.dart' as ing;
import '../../../domain/value/shortfall_item.dart';

// NEW: watch ingredients so we can pass them into WeeklyPlanGrid
import '../../providers/ingredient_providers.dart';
import '../../providers/shortfall_providers.dart';
import '../../providers/database_providers.dart';
import '../../providers/budget_providers.dart';
import 'budget_optimize_sheet.dart';
import '../../providers/shopping_list_providers.dart';
import '../../providers/plan_pin_providers.dart';
import '../../providers/recipe_pref_providers.dart';
import '../../../domain/services/variety_options.dart';
import '../../../domain/services/variety_prefs_service.dart';
import '../../providers/leftovers_providers.dart';
import '../../../domain/services/leftovers_overlay_service.dart';
import '../../../domain/services/leftovers_inventory_service.dart';
import '../../../domain/services/leftovers_scheduler_service.dart';
import '../../providers/pantry_expiry_providers.dart';
import '../../providers/multiweek_providers.dart';
import '../../../domain/services/budget_optimizer_service.dart';
import '../../../domain/services/budget_settings_service.dart';
import '../../../domain/services/plan_cost_estimator.dart';
import '../../providers/micro_providers.dart';

/// Comprehensive plan page with 7-day grid, totals bar, and swap functionality
class PlanPage extends ConsumerStatefulWidget {
  final String? planId;
  const PlanPage({super.key, this.planId});

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
    final currentPlanAsync = widget.planId == null
        ? ref.watch(currentPlanProvider)
        : ref.watch(planByIdProvider(widget.planId!));
    final decoratedTargetsAsync = ref.watch(decoratedUserTargetsProvider);
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
                value: 'taste',
                child: Row(
                  children: [
                    Icon(Icons.local_dining_outlined),
                    SizedBox(width: 8),
                    Text('Taste & Allergens'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'multiweek',
                child: Row(
                  children: [
                    Icon(Icons.view_week_outlined),
                    SizedBox(width: 8),
                    Text('Multi-Week Planning'),
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
                case 'taste':
                  context.go(AppRouter.tasteSettings);
                  break;
                case 'multiweek':
                  context.go(AppRouter.multiweek);
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
      body: decoratedTargetsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(error.toString()),
        data: (decorated) {
          if (decorated == null) {
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
                              // Auto-schedule leftovers controls
                              Padding(
                                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                                child: _LeftoversHeader(
                                  plan: plan,
                                  ref: ref,
                                  recipes: recipeMap,
                                ),
                              ),
                              // Phase banner (if active)
                              _PhaseBanner(decorated: decorated),
                              // Totals bar (use decorated targets copy)
                              TotalsBar(
                                targets: decorated.toUserTargets(),
                                actualKcal:
                                    plan.totals.kcal / 7, // Daily average
                                actualProteinG: plan.totals.proteinG / 7,
                                actualCarbsG: plan.totals.carbsG / 7,
                                actualFatG: plan.totals.fatG / 7,
                                actualCostCents: (plan.totals.costCents / 7)
                                    .round(),
                                showBudget: decorated.base.budgetCents != null,
                              ),

                              // Weekly Micros strip (v0)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                                child: Consumer(builder: (context, ref, _) {
                                  final microsAsync = ref.watch(weeklyMicrosProvider(plan));
                                  final settingsAsync = ref.watch(microSettingsProvider);
                                  return microsAsync.when(
                                    loading: () => const SizedBox.shrink(),
                                    error: (_, __) => const SizedBox.shrink(),
                                    data: (tot) {
                                      final s = settingsAsync.asData?.value ?? const MicroSettings();
                                      final fiber = tot.fiberG;
                                      final target = s.weeklyFiberTargetG > 0 ? s.weeklyFiberTargetG : 175.0;
                                      final pct = (fiber / target).clamp(0.0, 1.0);
                                      return Card(
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Micros (weekly)', style: Theme.of(context).textTheme.titleMedium),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text('Fiber: ${fiber.toStringAsFixed(0)} g / ${target.toStringAsFixed(0)} g'),
                                                        const SizedBox(height: 4),
                                                        ClipRRect(
                                                          borderRadius: BorderRadius.circular(4),
                                                          child: LinearProgressIndicator(value: pct),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Wrap(
                                                spacing: 12,
                                                runSpacing: 8,
                                                children: [
                                                  Row(children: [const Icon(Icons.water_drop, size: 16), const SizedBox(width: 4), Text('Sodium: ${tot.sodiumMg} mg')]),
                                                  Row(children: [const Icon(Icons.crisis_alert, size: 16), const SizedBox(width: 4), Text('Sat fat: ${tot.satFatG.toStringAsFixed(1)} g')]),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }),
                              ),

                              // Budget Guardrails v2: Weekly Budget Bar
                              Padding(
                                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                                child: _buildBudgetBar(plan: plan),
                              ),

                              // Week navigator if part of a series
                              Padding(
                                padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                                child: Consumer(builder: (context, ref, _) {
                                  final asyncSeries = ref.watch(seriesForPlanIdProvider(plan.id));
                                  return asyncSeries.when(
                                    loading: () => const SizedBox.shrink(),
                                    error: (_, __) => const SizedBox.shrink(),
                                    data: (info) {
                                      if (info == null) return const SizedBox.shrink();
                                      final s = info.series;
                                      final idx = info.index;
                                      return Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.chevron_left),
                                            onPressed: idx > 0
                                                ? () {
                                                    final prevId = s.planIds[idx - 1];
                                                    context.push('${AppRouter.plan}?id=$prevId');
                                                  }
                                                : null,
                                          ),
                                          Text('Week ${idx + 1} / ${s.weeks}'),
                                          IconButton(
                                            icon: const Icon(Icons.chevron_right),
                                            onPressed: idx < s.weeks - 1
                                                ? () {
                                                    final nextId = s.planIds[idx + 1];
                                                    context.push('${AppRouter.plan}?id=$nextId');
                                                  }
                                                : null,
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                }),
                              ),

                              // Use soon nudge
                              Padding(
                                padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                                child: Builder(builder: (context) {
                                  // Lazy import via function body to avoid new imports at top for providers
                                  return Consumer(builder: (context, ref, _) {
                                    final soon = ref.watch(useSoonItemsProvider).asData?.value ?? const [];
                                    if (soon.isEmpty) return const SizedBox.shrink();
                                    return Align(
                                      alignment: Alignment.centerLeft,
                                      child: ActionChip(
                                        avatar: const Icon(Icons.schedule, size: 16),
                                        label: Text('Use soon: ${soon.length}'),
                                        onPressed: () => context.go(AppRouter.pantry),
                                      ),
                                    );
                                  });
                                }),
                              ),

                              // Budget header (weekly)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                                child: _BudgetHeader(onGenerateCheaper: () => _generateCheaperPlan()),
                              ),

                              // Week Shortfalls card
                              Padding(
                                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                                child: _WeekShortfallsCard(),
                              ),

                              // Plan grid
                              Expanded(
                                child: WeeklyPlanGrid(
                                  plan: plan,
                                  recipes: recipeMap,
                                  ingredients:
                                      ingredientMap, // <- NEW required param
                                  selectedMealIndex: selectedMealIndex,
                                  planWeekKey: _planWeekKeyForPlan(plan),
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

  // Phase banner widget
}

class _PhaseBanner extends StatelessWidget {
  const _PhaseBanner({required this.decorated});
  final DecoratedTargets decorated;

  @override
  Widget build(BuildContext context) {
    final phase = decorated.phase;
    if (phase == null) return const SizedBox.shrink();
    final fmt = DateFormat.MMMd();
    final now = DateTime.now();
    final daysInPhase = phase.end.difference(DateTime(phase.start.year, phase.start.month, phase.start.day)).inDays + 1;
    final totalWeeks = ((daysInPhase + 6) / 7).ceil().clamp(1, 100);
    final weekIndex = ((DateTime(now.year, now.month, now.day).difference(DateTime(phase.start.year, phase.start.month, phase.start.day)).inDays) / 7).floor() + 1;
    final wk = weekIndex.clamp(1, totalWeeks);

    Widget chipFor(PhaseType t) {
      switch (t) {
        case PhaseType.cut:
          return const Chip(label: Text('CUT'));
        case PhaseType.maintain:
          return const Chip(label: Text('MAINTAIN'));
        case PhaseType.bulk:
          return const Chip(label: Text('BULK'));
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  chipFor(phase.type),
                  const SizedBox(width: 8),
                  Text('${fmt.format(phase.start)} → ${fmt.format(phase.end)} · wk $wk/$totalWeeks',
                      style: Theme.of(context).textTheme.bodyMedium),
                  const Spacer(),
                  TextButton(
                    onPressed: () => GoRouter.of(context).go(AppRouter.periodization),
                    child: const Text('Edit phases'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _pill(context, 'Target ${decorated.kcal.toStringAsFixed(0)} kcal'),
                  _pill(context, 'P ${decorated.p.toStringAsFixed(0)}'),
                  _pill(context, 'C ${decorated.c.toStringAsFixed(0)}'),
                  _pill(context, 'F ${decorated.f.toStringAsFixed(0)}'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(text, style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          )),
    );
  }
}

  String _planWeekKeyForPlan(Plan plan) {
    final overlaySvc = ref.read(leftoversOverlayServiceProvider);
    final first = plan.days.first.dateTime;
    // Align to Monday 00:00 of the week containing the first day
    final weekday = first.weekday; // Monday=1
    final monday = DateTime(first.year, first.month, first.day).subtract(Duration(days: weekday - DateTime.monday));
    final weekStart = DateTime(monday.year, monday.month, monday.day);
    return overlaySvc.planWeekKey(planId: plan.id, weekStart: weekStart);
  }

  // Header UI for leftovers toggle + review
  Widget _LeftoversHeader({required Plan plan, required WidgetRef ref, required Map<String, Recipe> recipes}) {
    final planWeekKey = _planWeekKeyForPlan(plan);
    return Consumer(
      builder: (context, ref, _) {
        final enabledAsync = ref.watch(autoLeftoversEnabledProvider(planWeekKey));
        final enabled = enabledAsync.asData?.value ?? false;
        return Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Auto-schedule leftovers',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        'Fill this week with leftover portions before they expire',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: enabled,
                  onChanged: (v) async {
                    final overlaySvc = ref.read(leftoversOverlayServiceProvider);
                    await overlaySvc.setAutoEnabled(planWeekKey, v);
                    if (v) {
                      // compute suggestions and persist overlays immediately
                      final firstDay = plan.days.first.dateTime;
                      final weekday = firstDay.weekday;
                      final monday = DateTime(firstDay.year, firstDay.month, firstDay.day)
                          .subtract(Duration(days: weekday - DateTime.monday));
                      final weekStart = DateTime(monday.year, monday.month, monday.day);
                      final args = LeftoverSuggestionArgs(planId: plan.id, weekStart: weekStart);
                      final suggestions = await ref.read(leftoverSuggestionsProvider(args).future);
                      await overlaySvc.saveAll(planWeekKey, suggestions);
                      ref.invalidate(overlaysForWeekProvider(planWeekKey));
                    } else {
                      // turning off doesn't clear overlays, just disables applying/visibility
                    }
                    ref.invalidate(autoLeftoversEnabledProvider(planWeekKey));
                    setState(() {});
                  },
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: () {
                    _showReviewLeftoversSheet(plan, planWeekKey, recipes);
                  },
                  child: const Text('Review leftovers'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showReviewLeftoversSheet(Plan plan, String planWeekKey, Map<String, Recipe> recipes) async {
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Consumer(builder: (context, ref, _) {
          final overlaysAsync = ref.watch(overlaysForWeekProvider(planWeekKey));
          final invSvc = ref.read(leftoversInventoryServiceProvider);
          return overlaysAsync.when(
            loading: () => const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
            error: (e, st) => Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Failed to load leftovers'),
            ),
            data: (overlays) {
              return FutureBuilder(
                future: invSvc.list(),
                builder: (context, snap) {
                  final portions = snap.data ?? const <PreparedPortion>[];
                  return SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12, left: 12, right: 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 8),
                            child: Text('Leftovers for this week', style: Theme.of(context).textTheme.titleMedium),
                          ),
                          if (overlays.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('No leftovers scheduled.'),
                            ),
                          Flexible(
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: overlays.length,
                              itemBuilder: (context, i) {
                                final p = overlays[i];
                                final matches = portions.where((x) => x.id == p.portionId).toList();
                                final PreparedPortion? portion = matches.isEmpty ? null : matches.first;
                                final recipe = recipes[p.recipeId];
                                final expiresIn = portion == null
                                    ? ''
                                    : 'expires in ${portion.expiresAt.difference(DateTime.now()).inDays}d';
                                return ListTile(
                                  title: Text(recipe?.name ?? p.recipeId),
                                  subtitle: Text('Day ${p.dayIndex + 1} • Meal ${p.mealIndex + 1}  ${expiresIn}'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Switch(
                                        value: p.confirmed,
                                        onChanged: (v) async {
                                          final svc = ref.read(leftoversOverlayServiceProvider);
                                          final list = List<LeftoverPlacement>.from(overlays);
                                          list[i] = list[i].copyWith(confirmed: v);
                                          await svc.saveAll(planWeekKey, list);
                                          ref.invalidate(overlaysForWeekProvider(planWeekKey));
                                        },
                                      ),
                                      IconButton(
                                        tooltip: 'Move',
                                        icon: const Icon(Icons.drive_file_move_outline),
                                        onPressed: () async {
                                          final picked = await showDialog<(int,int)?>(
                                            context: context,
                                            builder: (dctx) => _PickSlotDialog(initialDay: p.dayIndex, initialMeal: p.mealIndex, plan: plan),
                                          );
                                          if (picked != null) {
                                            final svc = ref.read(leftoversOverlayServiceProvider);
                                            final list = List<LeftoverPlacement>.from(overlays);
                                            list[i] = list[i].copyWith(dayIndex: picked.$1, mealIndex: picked.$2);
                                            await svc.saveAll(planWeekKey, list);
                                            ref.invalidate(overlaysForWeekProvider(planWeekKey));
                                          }
                                        },
                                      ),
                                      IconButton(
                                        tooltip: 'Skip',
                                        icon: const Icon(Icons.close),
                                        onPressed: () async {
                                          final svc = ref.read(leftoversOverlayServiceProvider);
                                          final list = List<LeftoverPlacement>.from(overlays)..removeAt(i);
                                          await svc.saveAll(planWeekKey, list);
                                          ref.invalidate(overlaysForWeekProvider(planWeekKey));
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              OutlinedButton(
                                onPressed: () async {
                                  // Clear all
                                  final svc = ref.read(leftoversOverlayServiceProvider);
                                  await svc.saveAll(planWeekKey, const []);
                                  ref.invalidate(overlaysForWeekProvider(planWeekKey));
                                },
                                child: const Text('Clear all'),
                              ),
                              const Spacer(),
                              FilledButton(
                                onPressed: () {
                                  Navigator.of(context).maybePop();
                                },
                                child: const Text('Done'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        });
      },
    );
  }

  // Simple slot picker dialog
  Widget _pickTile(String label, bool selected) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: selected ? Theme.of(context).colorScheme.primaryContainer : null,
        ),
        child: Text(label),
      );

  (int, int)? _validateDayMeal(Plan plan, int day, int meal) {
    if (day < 0 || day >= plan.days.length) return null;
    if (meal < 0 || meal >= plan.days[day].meals.length) return null;
    return (day, meal);
  }

  // ignore: non_constant_identifier_names
  Dialog _PickSlotDialog({required int initialDay, required int initialMeal, required Plan plan}) {
    int d = initialDay;
    int m = initialMeal;
    return Dialog(
      child: StatefulBuilder(builder: (context, setState) {
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Move to…', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Day:'),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: d,
                    items: List.generate(plan.days.length, (i) => DropdownMenuItem(value: i, child: Text('Day ${i + 1}'))),
                    onChanged: (v) => setState(() => d = v ?? d),
                  ),
                  const SizedBox(width: 16),
                  const Text('Meal:'),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: m,
                    items: List.generate(plan.days[d].meals.length, (i) => DropdownMenuItem(value: i, child: Text('Meal ${i + 1}'))),
                    onChanged: (v) => setState(() => m = v ?? m),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(_validateDayMeal(plan, d, m)),
                    child: const Text('Apply'),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
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
              ref.invalidate(decoratedUserTargetsProvider);
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

  // Budget Bar widget: price-aware estimate vs user-set budget in SharedPreferences
  Widget _buildBudgetBar({required Plan plan}) {
    final settingsAsync = ref.watch(budgetSettingsProvider);
    final statusAsync = ref.watch(weeklyBudgetStatusProvider(plan));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Budget', style: Theme.of(context).textTheme.titleMedium),
                ),
                TextButton.icon(
                  onPressed: () => context.push('/settings/budget'),
                  icon: const Icon(Icons.settings_outlined, size: 18),
                  label: const Text('Settings'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            settingsAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
              data: (settings) {
                return statusAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (s) {
                    final pct = s.budgetCents <= 0 ? 0.0 : (s.estimateCents / s.budgetCents).clamp(0.0, 1.0);
                    final over = s.estimateCents > s.budgetCents;
                    final tight = !over && s.estimateCents >= (s.budgetCents * 0.9);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LinearProgressIndicator(value: s.budgetCents == 0 ? null : pct),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: Text(s.label)),
                            if (over)
                              _chip('Over by ${NumberFormat.simpleCurrency().format((s.estimateCents - s.budgetCents)/100)}', Colors.red)
                            else if (tight)
                              _chip('Tight: ${NumberFormat.simpleCurrency().format((s.budgetCents - s.estimateCents)/100)} left', Colors.orange)
                            else
                              _chip('${NumberFormat.simpleCurrency().format((s.budgetCents - s.estimateCents)/100)} left', Colors.green),
                          ],
                        ),
                        if (settings.showNudges) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              OutlinedButton.icon(
                                icon: const Icon(Icons.auto_awesome),
                                label: const Text('Optimize Cost'),
                                onPressed: () async {
                                  await showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    builder: (_) => BudgetOptimizeSheet(plan: plan),
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              if (over)
                                Text('You’ll exceed by ~${NumberFormat.simpleCurrency().format((s.estimateCents - s.budgetCents)/100)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                            ],
                          ),
                        ],
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(text, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
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
              servingsForMeal: currentMeal.servings,
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

  /// Generate a new plan with a bias toward cheaper recipes.
  Future<void> _generateCheaperPlan() async {
    try {
      final recipes = await ref.read(allRecipesProvider.future);
      final decorated = await ref.read(decoratedUserTargetsProvider.future);
      final ingredients = await ref.read(allIngredientsProvider.future);
      // Keep room for future use of these signals
      // final pinnedSlots = await ref.read(pinsForCurrentPlanProvider.future);
      // final excluded = await ref.read(excludedRecipesProvider.future);
      // final favorites = await ref.read(favoriteRecipesProvider.future);

      if (decorated == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please complete setup first')),
        );
        return;
      }

      // Variety preferences + history
      final prefs = ref.read(varietyPrefsServiceProvider);
      final maxRepeats = await prefs.maxRepeatsPerWeek();
      final proteinSpread = await prefs.enableProteinSpread();
      final cuisineRotation = await prefs.enableCuisineRotation();
      final prepMix = await prefs.enablePrepMix();
      final lookback = await prefs.historyLookbackPlans();
      final recent = lookback > 0
          ? await ref.read(planRepositoryProvider).getRecentPlans(limit: lookback)
          : const <Plan>[];

      final generator = ref.read(planGenerationServiceProvider);
      final plan = await generator.generate(
        targets: decorated.toUserTargets(),
        recipes: recipes,
        ingredients: ingredients,
        costBias: 0.9, // Strong nudge toward cheaper options
        varietyOptions: VarietyOptions(
          maxRepeatsPerWeek: maxRepeats,
          enableProteinSpread: proteinSpread,
          enableCuisineRotation: cuisineRotation,
          enablePrepMix: prepMix,
          historyPlans: recent,
        ),
      );

      final notifier = ref.read(planNotifierProvider.notifier);
      await notifier.savePlan(plan);
      await notifier.setCurrentPlan(plan.id);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cheaper plan generated')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to generate plan: $e')));
    }
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
      final decorated = await ref.read(decoratedUserTargetsProvider.future);
      final ingredients = await ref.read(allIngredientsProvider.future);
      final pinnedSlots = await ref.read(pinsForCurrentPlanProvider.future);
      final excluded = await ref.read(excludedRecipesProvider.future);
      final favorites = await ref.read(favoriteRecipesProvider.future);

      if (decorated == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please complete setup first')),
        );
        return;
      }

      // Variety preferences + history
      final prefs = ref.read(varietyPrefsServiceProvider);
      final maxRepeats = await prefs.maxRepeatsPerWeek();
      final proteinSpread = await prefs.enableProteinSpread();
      final cuisineRotation = await prefs.enableCuisineRotation();
      final prepMix = await prefs.enablePrepMix();
      final lookback = await prefs.historyLookbackPlans();
      final recent = lookback > 0
          ? await ref.read(planRepositoryProvider).getRecentPlans(limit: lookback)
          : const <Plan>[];

      final generator = ref.read(planGenerationServiceProvider);
      var plan = await generator.generate(
        targets: decorated.toUserTargets(),
        recipes: recipes,
        ingredients: ingredients,
        favoriteBias: 0.25,
        pinnedSlots: pinnedSlots,
        excludedRecipeIds: excluded,
        favoriteRecipeIds: favorites,
        varietyOptions: VarietyOptions(
          maxRepeatsPerWeek: maxRepeats,
          enableProteinSpread: proteinSpread,
          enableCuisineRotation: cuisineRotation,
          enablePrepMix: prepMix,
          historyPlans: recent,
        ),
      );

      // Budget Guardrails v2: auto-cheap mode (post-generation, advisory)
      final budgetSettings = await ref.read(budgetSettingsServiceProvider).get();
      if (budgetSettings.autoCheapMode) {
        final estimator = ref.read(planCostEstimatorProvider);
        final est = await estimator.estimatePlanCostCents(plan: plan, storeId: budgetSettings.preferredStoreId);
        final over = est - budgetSettings.weeklyBudgetCents;
        if (over > 0) {
          final optimizer = ref.read(budgetOptimizerServiceProvider);
          final suggestions = await optimizer.suggestCheaperSwaps(
            plan: plan,
            targetSaveCents: over,
          );
          if (suggestions.isNotEmpty) {
            // Apply up to maxAutoSwaps
            final recipesAll = await ref.read(allRecipesProvider.future);
            final recipeMap = {for (final r in recipesAll) r.id: r};
            final newDays = plan.days.map((d) => d).toList(growable: true);
            for (final s in suggestions.take(budgetSettings.maxAutoSwaps)) {
              final day = newDays[s.dayIndex];
              final meals = day.meals.map((m) => m).toList(growable: true);
              meals[s.mealIndex] = meals[s.mealIndex].copyWith(recipeId: s.toRecipeId);
              newDays[s.dayIndex] = day.copyWith(meals: meals);
            }
            // Recompute totals (using fallback per-recipe cost)
            double kcal = 0, protein = 0, carbs = 0, fat = 0; int cost = 0;
            for (final day in newDays) {
              for (final meal in day.meals) {
                final r = recipeMap[meal.recipeId];
                if (r == null) continue;
                kcal += r.macrosPerServ.kcal * meal.servings;
                protein += r.macrosPerServ.proteinG * meal.servings;
                carbs += r.macrosPerServ.carbsG * meal.servings;
                fat += r.macrosPerServ.fatG * meal.servings;
                cost += (r.costPerServCents * meal.servings).round();
              }
            }
            plan = plan.copyWith(days: newDays, totals: PlanTotals(kcal: kcal, proteinG: protein, carbsG: carbs, fatG: fat, costCents: cost));
            if (kDebugMode) {
              debugPrint('[Budget] auto-cheap applied: ${suggestions.length} swaps');
            }
          }
        }
      }

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
    Map<String, ing.Ingredient> ingredientMap,
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
          SimpleDialogOption(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              // Small modal progress
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(child: CircularProgressIndicator()),
              );
              try {
                final now = DateTime.now();
                final endLocal = DateTime(now.year, now.month, now.day);
                const tz = 'local'; // persisted TZ not found; default to local

                if (kIsWeb) {
                  final result = await ref
                      .read(svc.exportServiceProvider)
                      .buildLast7DaysZipBytes(
                        endInclusiveLocal: endLocal,
                        timezone: tz,
                      );
                  await Share.shareXFiles(
                    [
                      XFile.fromData(
                        Uint8List.fromList(result.bytes),
                        name: result.filename,
                        mimeType: 'application/zip',
                      )
                    ],
                    text: 'Macro + Budget Meal Planner – Last 7 Days',
                  );
                } else {
                  final path = await ref.read(svc.exportServiceProvider).exportLast7DaysZip(
                        endInclusiveLocal: endLocal,
                        timezone: tz,
                      );
                  await Share.shareXFiles(
                    [XFile(path)],
                    text: 'Macro + Budget Meal Planner – Last 7 Days',
                  );
                }

                if (!mounted) return;
                Navigator.of(context, rootNavigator: true).pop(); // close progress
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Exported last 7 days.')),
                );
              } catch (e) {
                if (!mounted) return;
                Navigator.of(context, rootNavigator: true).pop(); // close progress
                // ignore: avoid_print
                if (kDebugMode) print('[Export] ERROR $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Export failed: $e')),
                );
              }
            },
            child: const Text('Export Last 7 Days (ZIP)'),
          ),
        ],
      ),
    );
  }
}

class _WeekShortfallsCard extends ConsumerStatefulWidget {
  @override
  ConsumerState<_WeekShortfallsCard> createState() => _WeekShortfallsCardState();
}

class _WeekShortfallsCardState extends ConsumerState<_WeekShortfallsCard> {
  bool _adding = false;

  @override
  Widget build(BuildContext context) {
    final asyncShortfalls = ref.watch(shortfallForCurrentPlanProvider);
    return asyncShortfalls.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();

        // compact: show at most 4 rows, then +N more
        final maxRows = 4;
        final more = items.length > maxRows ? items.length - maxRows : 0;
        final visible = items.take(maxRows).toList();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Week Shortfalls',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const Spacer(),
                    if (more > 0)
                      Text('+$more more', style: Theme.of(context).textTheme.labelMedium),
                  ],
                ),
                const SizedBox(height: 8),
                ...visible.map((it) => _WeekShortfallRow(item: it)).toList(),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _adding
                        ? null
                        : () async {
                            setState(() => _adding = true);
                            try {
                              final plan = await ref.read(currentPlanProvider.future);
                              final repo = ref.read(shoppingListRepositoryProvider);
                              await repo.addShortfalls(items, planId: plan?.id);
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Added ${items.length} items to Shopping List')),
                              );
                              ref.invalidate(shoppingListItemsProvider);
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to add: $e')),
                              );
                            } finally {
                              if (mounted) setState(() => _adding = false);
                            }
                          },
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('Add All to Shopping List'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

}

class _BudgetHeader extends ConsumerWidget {
  const _BudgetHeader({required this.onGenerateCheaper});
  final Future<void> Function() onGenerateCheaper;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetAsync = ref.watch(budgetStatusProvider);

    return budgetAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const SizedBox.shrink(),
      data: (vm) {
        if (vm.weeklyBudgetCents == null) {
          // Optional, unobtrusive tip to set budget
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.savings_outlined,
                    size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Set a weekly budget in Settings',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
                TextButton(
                  onPressed: () => context.go(AppRouter.settings),
                  child: const Text('Settings'),
                ),
              ],
            ),
          );
        }

        final util = vm.utilization ?? 0.0;
        final clamped = util.clamp(0.0, 1.25);

        Color badgeColor;
        String badgeLabel;
        switch (vm.status) {
          case BudgetStatus.under:
            badgeColor = Colors.green;
            badgeLabel = 'Under Budget';
            break;
          case BudgetStatus.near:
            badgeColor = Colors.orange;
            badgeLabel = 'Near Budget';
            break;
          case BudgetStatus.over:
            badgeColor = Colors.red;
            badgeLabel = 'Over Budget';
            break;
          default:
            badgeColor = Theme.of(context).colorScheme.outlineVariant;
            badgeLabel = 'Budget';
        }

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: badgeColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          badgeLabel,
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: badgeColor,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: clamped.toDouble(),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Estimated: ${formatCents(vm.weeklyTotalCents)} / Budget: ${formatCents(vm.weeklyBudgetCents ?? 0)}',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (vm.status == BudgetStatus.over && (vm.overageCents ?? 0) > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "You're ${formatCents(vm.overageCents!)} over this week. Try a cheaper plan?",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onErrorContainer,
                            ),
                      ),
                    ),
                    FilledButton(
                      onPressed: onGenerateCheaper,
                      child: const Text('Generate Cheaper Plan'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

// (Removed duplicate extension _CheaperPlanAction; class method _generateCheaperPlan is used.)

// Formatting helper: cents -> $dollars.xx
String formatCents(int cents) => '\$' + (cents / 100).toStringAsFixed(2);

class _WeekShortfallRow extends StatelessWidget {
  const _WeekShortfallRow({required this.item});
  final ShortfallItem item;

  @override
  Widget build(BuildContext context) {
    try {
      final name = item.name;
      final qty = item.missingQty;
      final unit = item.unit;
      final aisle = item.aisle;
      final reason = item.reason;

      final qtyStr = _fmtQty(qty, unit);
      final aisleStr = _aisleName(aisle);

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      name,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text('• $qtyStr • $aisleStr',
                      style: Theme.of(context).textTheme.labelMedium),
                  if (reason != null) ...[
                    const SizedBox(width: 6),
                    Tooltip(
                      message: reason,
                      child: Icon(Icons.warning_amber_outlined,
                          size: 16, color: Theme.of(context).colorScheme.tertiary),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }
}

String _fmtQty(double qty, ing.Unit unit) {
  final rounded = (qty * 10).round() / 10.0;
  final s = (rounded % 1 == 0) ? rounded.toStringAsFixed(0) : rounded.toStringAsFixed(1);
  switch (unit) {
    case ing.Unit.grams:
      return '$s g';
    case ing.Unit.milliliters:
      return '$s ml';
    case ing.Unit.piece:
      return '$s pc';
  }
}

String _aisleName(ing.Aisle aisle) {
  switch (aisle) {
    case ing.Aisle.produce:
      return 'Produce';
    case ing.Aisle.meat:
      return 'Meat';
    case ing.Aisle.dairy:
      return 'Dairy';
    case ing.Aisle.pantry:
      return 'Pantry';
    case ing.Aisle.frozen:
      return 'Frozen';
    case ing.Aisle.condiments:
      return 'Condiments';
    case ing.Aisle.bakery:
      return 'Bakery';
    case ing.Aisle.household:
      return 'Household';
  }
}


