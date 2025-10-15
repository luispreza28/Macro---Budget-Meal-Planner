import 'package:flutter/foundation.dart';

import '../entities/ingredient.dart';
import 'density_service.dart';

/// Align quantity from one unit to another using density rules when applicable.
/// - Supports grams <-> milliliters when density can be resolved.
/// - Returns null for unsupported conversions (e.g., piece <-> mass/volume) or when density is missing.
/// This is synchronous and uses the in-memory DensityCache best-effort.
double? alignQty({
  required double qty,
  required Unit from,
  required Unit to,
  required Ingredient ing,
}) {
  if (from == to) return qty;
  if (from == Unit.piece || to == Unit.piece) return null; // never auto-convert piece

  final res = DensityCache.tryResolve(ing);
  if (res == null || res.gPerMl <= 0) {
    if (kDebugMode) {
      debugPrint('[Density] align: skip ${ing.id} (no density) ${qty.toStringAsFixed(2)}${from.name}');
    }
    return null;
  }

  final d = res.gPerMl;
  final fromStr = from.name;
  final toStr = to.name;
  if (from == Unit.grams && to == Unit.milliliters) {
    final out = qty / d;
    if (kDebugMode) {
      debugPrint('[Density] align g→ml src=${res.source.name} d=${d.toStringAsFixed(3)} : ${qty.toStringAsFixed(2)}$fromStr -> ${out.toStringAsFixed(2)}$toStr');
    }
    return out;
  }
  if (from == Unit.milliliters && to == Unit.grams) {
    final out = qty * d;
    if (kDebugMode) {
      debugPrint('[Density] align ml→g src=${res.source.name} d=${d.toStringAsFixed(3)} : ${qty.toStringAsFixed(2)}$fromStr -> ${out.toStringAsFixed(2)}$toStr');
    }
    return out;
  }
  return null;
}
