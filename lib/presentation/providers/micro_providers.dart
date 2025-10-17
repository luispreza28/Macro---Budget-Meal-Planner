import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/micro_settings_service.dart';
import '../../domain/services/micro_calculator.dart';
import '../../presentation/providers/ingredient_providers.dart';
import '../../presentation/providers/recipe_providers.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/entities/plan.dart';

final microSettingsProvider = FutureProvider<MicroSettings>((ref) async {
  return ref.read(microSettingsServiceProvider).get();
});

class MicroHints {
  final bool highSodium;
  final bool highSatFat;
  final bool lowFiber;
  const MicroHints({required this.highSodium, required this.highSatFat, required this.lowFiber});
}

final recipeMicroReportProvider = FutureProvider.family<(RecipeMicros, MicroHints), String>((ref, recipeId) async {
  final r = await ref.watch(recipeByIdProvider(recipeId).future);
  if (r == null) {
    return (
      const RecipeMicros(fiberGPerServ: 0, sodiumMgPerServ: 0, satFatGPerServ: 0),
      const MicroHints(highSodium: false, highSatFat: false, lowFiber: false),
    );
  }
  final ings = {for (final i in await ref.read(allIngredientsProvider.future)) i.id: i};
  final micros = await ref.read(microCalculatorProvider).compute(recipe: r, ingById: ings, debug: false);
  final s = await ref.read(microSettingsProvider.future);

  final kcal = r.macrosPerServ.kcal;
  final satFatKcalPct = kcal > 0 ? ((micros.satFatGPerServ * 9.0) / kcal) * 100.0 : 0.0;

  final hints = MicroHints(
    highSodium: micros.sodiumMgPerServ >= s.sodiumHighMgPerServ,
    highSatFat: micros.satFatGPerServ >= s.satFatHighGPerServ || satFatKcalPct >= s.satFatHighPctKcal,
    lowFiber: micros.fiberGPerServ < s.fiberLowGPerServ,
  );
  return (micros, hints);
});

class WeeklyMicroTotals {
  final double fiberG;
  final int sodiumMg;
  final double satFatG;
  const WeeklyMicroTotals({required this.fiberG, required this.sodiumMg, required this.satFatG});
}

final weeklyMicrosProvider = FutureProvider.family<WeeklyMicroTotals, Plan>((ref, plan) async {
  final ings = {for (final i in await ref.read(allIngredientsProvider.future)) i.id: i};
  final calc = ref.read(microCalculatorProvider);
  double fiber = 0, sat = 0;
  int sod = 0;

  for (final day in plan.days) {
    for (final meal in day.meals) {
      final r = await ref.read(recipeByIdProvider(meal.recipeId).future);
      if (r == null) continue;
      final m = await calc.compute(recipe: r, ingById: ings);
      fiber += m.fiberGPerServ * meal.servings;
      sat += m.satFatGPerServ * meal.servings;
      sod += m.sodiumMgPerServ * meal.servings;
    }
  }
  return WeeklyMicroTotals(fiberG: fiber, sodiumMg: sod, satFatG: sat);
});

