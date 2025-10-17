import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/formatters/units_formatter.dart';
import '../../domain/entities/ingredient.dart' as domain;
import '../../presentation/providers/ingredient_providers.dart';
import '../../domain/entities/recipe.dart';

/// Compute scaled ingredient lines for a session.
final scaledIngredientsProvider = FutureProvider.family<List<ScaledLine>, (Recipe recipe, int servingsOverride)>((ref, arg) async {
  final (recipe, override) = arg;
  final ings = await ref.read(allIngredientsProvider.future);
  final byId = {for (final i in ings) i.id: i};
  final factor = (override > 0 ? override : recipe.servings) / recipe.servings;
  final fmt = ref.read(unitsFormatterProvider);

  final out = <ScaledLine>[];
  for (final it in recipe.items) {
    final ing = byId[it.ingredientId];
    if (ing == null) continue;
    final qty = it.qty * factor; // display-only scaling
    final label = await fmt.formatQty(
      qty: qty,
      baseUnit: ing.unit,
      densityGPerMl: ing.densityGPerMl,
      gramsPerPiece: ing.gramsPerPiece,
      mlPerPiece: ing.mlPerPiece,
    );
    out.add(ScaledLine(name: ing.name, label: label, unit: ing.unit));
  }
  return out;
});

class ScaledLine {
  final String name;
  final String label;
  final domain.Unit unit;
  const ScaledLine({required this.name, required this.label, required this.unit});
}
