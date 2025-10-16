import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/services/multiweek_series_service.dart';
import '../providers/recipe_providers.dart';
import '../providers/plan_providers.dart';
import '../providers/ingredient_providers.dart';
import '../providers/periodization_providers.dart';
import '../providers/database_providers.dart';
import '../../domain/entities/plan.dart';

final multiweekSeriesListProvider = FutureProvider<List<MultiweekSeries>>((ref) async {
  return ref.read(multiweekSeriesServiceProvider).list();
});

final multiweekSeriesByIdProvider = FutureProvider.family<MultiweekSeries?, String>((ref, id) async {
  return ref.read(multiweekSeriesServiceProvider).byId(id);
});

String newSeriesId() => const Uuid().v4();

/// Generates N weeks starting at week0Start. Creates N Plans via existing generator & repo.
final generateSeriesPlansProvider = FutureProvider.family<MultiweekSeries, GenerateSeriesArgs>((ref, args) async {
  final repo = ref.read(planRepositoryProvider);
  final gen = ref.read(planGenerationServiceProvider);
  final ings = await ref.read(allIngredientsProvider.future);
  final recipes = await ref.read(allRecipesProvider.future);
  final decorated = await ref.read(decoratedUserTargetsProvider.future);
  if (decorated == null) {
    throw StateError('No user targets available');
  }

  final planIds = <String>[];
  var start = DateTime(args.week0Start.year, args.week0Start.month, args.week0Start.day); // local midnight
  for (int w = 0; w < args.weeks; w++) {
    final plan = await gen.generate(
      targets: decorated.toUserTargets(),
      recipes: recipes,
      ingredients: ings,
    );
    // Align plan days to the desired week start, preserving number of meals per day
    final adjustedDays = List<PlanDay>.generate(7, (d) {
      final date = start.add(Duration(days: d));
      final existing = (d < plan.days.length) ? plan.days[d] : plan.days.last;
      return existing.copyWith(date: DateTime(date.year, date.month, date.day).toIso8601String());
    });

    final named = plan.copyWith(
      name: '${args.name} • Week ${w + 1}',
      days: adjustedDays,
      createdAt: start,
    );

    await repo.savePlan(named);
    planIds.add(named.id);
    // advance 7 days for the next week anchor
    start = start.add(const Duration(days: 7));
  }

  final series = MultiweekSeries(
    id: args.seriesId,
    name: args.name,
    createdAt: DateTime.now(),
    week0Start: args.week0Start,
    weeks: args.weeks,
    planIds: planIds,
  );
  await ref.read(multiweekSeriesServiceProvider).upsert(series);
  return series;
});

class GenerateSeriesArgs {
  final String seriesId;
  final String name;
  final DateTime week0Start;
  final int weeks; // 2..4
  const GenerateSeriesArgs({required this.seriesId, required this.name, required this.week0Start, required this.weeks});
}

/// Helper: find series containing a specific planId
final seriesForPlanIdProvider = FutureProvider.family<({MultiweekSeries series, int index})?, String>((ref, planId) async {
  final xs = await ref.read(multiweekSeriesServiceProvider).list();
  for (final s in xs) {
    final idx = s.planIds.indexOf(planId);
    if (idx >= 0) return (series: s, index: idx);
  }
  return null;
});

