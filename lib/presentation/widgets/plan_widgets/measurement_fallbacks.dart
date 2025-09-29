import '../../../domain/entities/ingredient.dart';

class MeasurementItemSpec {
  final String name; // display name
  final double qty;  // quantity per SERVING
  final Unit unit;
  const MeasurementItemSpec({
    required this.name,
    required this.qty,
    required this.unit,
  });
}

/// Simple, per-serving fallbacks for demo recipes.
/// When your real recipes include `items`, this won't be used.
final Map<String, List<MeasurementItemSpec>> _fallbackBySlug = {
  'peanut_butter_oatmeal': const [
    MeasurementItemSpec(name: 'Rolled oats', qty: 40, unit: Unit.grams),
    MeasurementItemSpec(name: 'Peanut butter', qty: 32, unit: Unit.grams),
    MeasurementItemSpec(name: 'Milk or water', qty: 200, unit: Unit.milliliters),
    MeasurementItemSpec(name: 'Honey (optional)', qty: 10, unit: Unit.grams),
  ],
  'greek_yogurt_bowl': const [
    MeasurementItemSpec(name: 'Greek yogurt (2%)', qty: 170, unit: Unit.grams),
    MeasurementItemSpec(name: 'Berries', qty: 100, unit: Unit.grams),
    MeasurementItemSpec(name: 'Granola', qty: 40, unit: Unit.grams),
    MeasurementItemSpec(name: 'Honey (optional)', qty: 10, unit: Unit.grams),
  ],
  'chicken_rice': const [
    MeasurementItemSpec(name: 'Chicken breast (raw)', qty: 150, unit: Unit.grams),
    MeasurementItemSpec(name: 'Cooked white rice', qty: 150, unit: Unit.grams),
    MeasurementItemSpec(name: 'Olive oil', qty: 5, unit: Unit.grams),
    MeasurementItemSpec(name: 'Salt & pepper', qty: 1, unit: Unit.grams),
  ],
  'veggie_omelette': const [
    MeasurementItemSpec(name: 'Eggs', qty: 2, unit: Unit.piece),
    MeasurementItemSpec(name: 'Bell pepper', qty: 50, unit: Unit.grams),
    MeasurementItemSpec(name: 'Onion', qty: 30, unit: Unit.grams),
    MeasurementItemSpec(name: 'Cheddar (shredded)', qty: 30, unit: Unit.grams),
  ],
};

String _slug(String name) =>
    name.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');

List<MeasurementItemSpec>? fallbackMeasurementsForRecipeName(String name) {
  // Try direct slug
  final s = _slug(name);
  if (_fallbackBySlug.containsKey(s)) return _fallbackBySlug[s];

  // A couple of loose aliases
  if (s.contains('chicken') && s.contains('rice')) return _fallbackBySlug['chicken_rice'];
  if (s.contains('yogurt')) return _fallbackBySlug['greek_yogurt_bowl'];
  if (s.contains('oat')) return _fallbackBySlug['peanut_butter_oatmeal'];
  if (s.contains('omelet')) return _fallbackBySlug['veggie_omelette'];

  return null;
}
