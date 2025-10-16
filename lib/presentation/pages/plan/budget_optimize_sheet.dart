import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/plan.dart';
import '../../../domain/entities/recipe.dart';
import '../../providers/recipe_providers.dart';
import '../../providers/plan_providers.dart';
import '../../../domain/services/budget_optimizer_service.dart';

class BudgetOptimizeSheet extends ConsumerStatefulWidget {
  const BudgetOptimizeSheet({super.key, required this.plan});
  final Plan plan;

  @override
  ConsumerState<BudgetOptimizeSheet> createState() => _BudgetOptimizeSheetState();
}

class _BudgetOptimizeSheetState extends ConsumerState<BudgetOptimizeSheet> {
  bool _loading = true;
  List<SwapSuggestion> _suggestions = const [];
  int _targetSave = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      setState(() => _targetSave = 0);
    });
    _compute();
  }

  Future<void> _compute() async {
    try {
      final optimizer = ref.read(budgetOptimizerServiceProvider);
      // The actual target is computed by caller; recompute here as overage vs budget not known
      // We use a heuristic: find up to 3 best swaps
      final xs = await optimizer.suggestCheaperSwaps(plan: widget.plan, targetSaveCents: 1 << 30);
      if (!mounted) return;
      setState(() {
        _suggestions = xs.take(3).toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() { _suggestions = const []; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.simpleCurrency();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Optimization Suggestions', style: Theme.of(context).textTheme.titleLarge),
                      const Spacer(),
                      IconButton(onPressed: () => Navigator.of(context).maybePop(), icon: const Icon(Icons.close)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_suggestions.isEmpty)
                    const Text('No cost-saving swaps found that meet your preferences.')
                  else
                    Flexible(
                      child: _SuggestionList(plan: widget.plan, suggestions: _suggestions),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        child: const Text('Skip'),
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        icon: const Icon(Icons.check),
                        label: const Text('Apply swaps'),
                        onPressed: _suggestions.isEmpty ? null : () async {
                          await _applySwaps(context, _suggestions);
                        },
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  int _estimateFromFallback(Plan plan, Map<String, Recipe> recipes) {
    int total = 0;
    for (final d in plan.days) {
      for (final m in d.meals) {
        final r = recipes[m.recipeId];
        if (r == null) continue;
        total += (r.costPerServCents * m.servings).round();
      }
    }
    return total;
  }

  Future<void> _applySwaps(BuildContext context, List<SwapSuggestion> xs) async {
    final plan = widget.plan;
    final recipes = await ref.read(allRecipesProvider.future);
    final recipeMap = {for (final r in recipes) r.id: r};

    // Apply suggestions
    final newDays = plan.days.map((day) => day).toList(growable: true);
    for (final s in xs) {
      final day = newDays[s.dayIndex];
      final meals = day.meals.map((m) => m).toList(growable: true);
      meals[s.mealIndex] = meals[s.mealIndex].copyWith(recipeId: s.toRecipeId);
      newDays[s.dayIndex] = day.copyWith(meals: meals);
    }
    final updated = plan.copyWith(days: newDays);

    // Recompute totals (macros + cost) based on recipes
    double kcal = 0, protein = 0, carbs = 0, fat = 0; int cost = 0;
    for (final day in updated.days) {
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
    final withTotals = updated.copyWith(
      totals: PlanTotals(kcal: kcal, proteinG: protein, carbsG: carbs, fatG: fat, costCents: cost),
    );

    final notifier = ref.read(planNotifierProvider.notifier);
    await notifier.updatePlan(withTotals);
    if (!mounted) return;
    Navigator.of(context).maybePop();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Applied cost-saving swaps')));
  }
}

class _SuggestionList extends ConsumerWidget {
  const _SuggestionList({required this.plan, required this.suggestions});
  final Plan plan;
  final List<SwapSuggestion> suggestions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipesAsync = ref.watch(allRecipesProvider);
    final fmt = NumberFormat.simpleCurrency();
    return recipesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error: $e')),
      data: (recipes) {
        final byId = {for (final r in recipes) r.id: r};
        return ListView.separated(
          shrinkWrap: true,
          itemCount: suggestions.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final s = suggestions[i];
            final from = byId[s.fromRecipeId];
            final to = byId[s.toRecipeId];
            if (from == null || to == null) {
              return const SizedBox.shrink();
            }
            final kcalDelta = (to.macrosPerServ.kcal - from.macrosPerServ.kcal).toStringAsFixed(0);
            final pDelta = (to.macrosPerServ.proteinG - from.macrosPerServ.proteinG).toStringAsFixed(0);
            return ListTile(
              title: Text('${from.name} → ${to.name}'),
              subtitle: Text('Δ ${kcalDelta} kcal • ${pDelta} g protein'),
              trailing: Text('Save ~${fmt.format(s.saveCents/100)}'),
            );
          },
        );
      },
    );
  }
}
