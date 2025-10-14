import '../entities/ingredient.dart';

/// Align a quantity from one unit to another, using ingredient metadata.
/// Rules:
/// - g <-> ml only if `densityGPerMl` available (allowDensity=true)
/// - piece <-> (g|ml) only if `gramsPerPiece`/`mlPerPiece` available (allowPiece=true)
/// - same unit returns qty unchanged
/// - returns null on mismatch
double? alignQty({
  required double qty,
  required Unit from,
  required Unit to,
  required Ingredient ing,
  bool allowPiece = true,
  bool allowDensity = true,
}) {
  if (from == to) return qty;

  // piece <-> grams/ml using per-piece sizes
  if (allowPiece && (from == Unit.piece || to == Unit.piece)) {
    if (from == Unit.piece && to == Unit.grams) {
      final gpp = ing.gramsPerPiece;
      if (gpp == null || gpp <= 0) return null;
      return qty * gpp;
    }
    if (from == Unit.piece && to == Unit.milliliters) {
      final mpp = ing.mlPerPiece;
      if (mpp == null || mpp <= 0) return null;
      return qty * mpp;
    }
    if (to == Unit.piece && from == Unit.grams) {
      final gpp = ing.gramsPerPiece;
      if (gpp == null || gpp <= 0) return null;
      return qty / gpp;
    }
    if (to == Unit.piece && from == Unit.milliliters) {
      final mpp = ing.mlPerPiece;
      if (mpp == null || mpp <= 0) return null;
      return qty / mpp;
    }
  }

  // grams <-> ml using density
  if (allowDensity) {
    final d = ing.densityGPerMl;
    if (d != null && d > 0) {
      if (from == Unit.grams && to == Unit.milliliters) {
        return qty / d;
      }
      if (from == Unit.milliliters && to == Unit.grams) {
        return qty * d;
      }
    }
  }

  // unsupported
  return null;
}

