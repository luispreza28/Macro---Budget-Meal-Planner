import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/insights_providers.dart';
import '../../providers/plan_providers.dart';
import '../../providers/recipe_providers.dart';
import '../../providers/ingredient_providers.dart';
import '../../providers/database_providers.dart';
import '../../providers/plan_pin_providers.dart';
import '../../providers/recipe_pref_providers.dart';
import '../../providers/user_targets_providers.dart';
import '../../router/app_router.dart';
import '../plan_widgets/shortfall_fixit_sheet.dart';
import '../../../domain/services/variety_options.dart';
import '../../../domain/services/variety_prefs_service.dart';
import '../../../domain/services/pantry_utilization_service.dart';

class QuickActionsCard extends ConsumerWidget {
  const QuickActionsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final anyShortfalls = ref.watch(anyShortfallsThisWeekProvider);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () async {
                    await _regenerateWithGoals(context, ref);
                  },
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Regenerate with goals'),
                ),
                anyShortfalls.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (hasShort) => hasShort
                      ? OutlinedButton.icon(
                          onPressed: () async {
                            await _openFixIt(context, ref);
                          },
                          icon: const Icon(Icons.build),
                          label: const Text('Open Fix-It'),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _regenerateWithGoals(BuildContext context, WidgetRef ref) async {
    try {
      final recipes = await ref.read(allRecipesProvider.future);
      final targets = await ref.read(currentUserTargetsProvider.future);
      final ingredients = await ref.read(allIngredientsProvider.future);
      final pinnedSlots = await ref.read(pinsForCurrentPlanProvider.future);
      final excluded = await ref.read(excludedRecipesProvider.future);
      final favorites = await ref.read(favoriteRecipesProvider.future);

      if (targets == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please complete setup first')));
        }
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
        targets: targets,
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

      final notifier = ref.read(planNotifierProvider.notifier);
      await notifier.savePlan(plan);
      await notifier.setCurrentPlan(plan.id);
      if (context.mounted) {
        context.go(AppRouter.plan);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Weekly plan regenerated')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to regenerate: $e')));
      }
    }
  }

  Future<void> _openFixIt(BuildContext context, WidgetRef ref) async {
    try {
      final plan = await ref.read(currentPlanNonNullProvider.future);
      final recipes = await ref.read(allRecipesProvider.future);
      final byId = {for (final r in recipes) r.id: r};
      final pantrySvc = ref.read(pantryUtilizationServiceProvider);

      for (final d in plan.days) {
        for (final m in d.meals) {
          final r = byId[m.recipeId];
          if (r == null) continue;
          final util = await pantrySvc.scoreRecipePantryUse(r);
          if (util.coverageRatio < 1.0) {
            if (!context.mounted) return;
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => ShortfallFixItSheet(
                recipeId: r.id,
                servingsForMeal: m.servings.round(),
              ),
            );
            return;
          }
        }
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No shortfalls detected')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to open Fix-It: $e')));
      }
    }
  }
}
