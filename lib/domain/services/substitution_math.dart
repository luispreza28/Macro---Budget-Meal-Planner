import 'package:flutter/foundation.dart';
import '../../domain/entities/ingredient.dart' as domain;
import '../services/unit_align.dart';

class SubstitutionMath {
  // Returns candidateQty + flags (approximate when missing density/piece size)
  static SubResult matchKcal({
    required double sourceQty,
    required domain.Unit sourceUnit,
    required domain.Ingredient sourceIng,
    required domain.Ingredient candIng,
  }) {
    final srcBase = alignQty(qty: sourceQty, from: sourceUnit, to: sourceIng.unit, ing: sourceIng);
    final srcPer = sourceIng.per100;
    if (srcBase == null || srcPer == null) {
      if (kDebugMode) debugPrint('[Subs] missing source conversion/macros');
      return SubResult.approx(null, missingData: true);
    }
    // kcal target from source
    final srcFactor = _factorForBase(srcBase, sourceIng.unit, sourceIng);
    final targetKcal = srcPer.kcal * srcFactor;

    return _solveForKcal(targetKcal: targetKcal, candIng: candIng);
  }

  static SubResult _solveForKcal({required double targetKcal, required domain.Ingredient candIng}) {
    final per = candIng.per100;
    if (per == null || per.kcal <= 0) return SubResult.approx(null, missingData: true);
    // g/ml straightforward; pieces use per-piece if available, else size
    if (candIng.unit == domain.Unit.piece) {
      if (candIng.nutritionPerPieceKcal != null && candIng.nutritionPerPieceKcal! > 0) {
        final pieces = targetKcal / candIng.nutritionPerPieceKcal!;
        return SubResult(pieces, domain.Unit.piece, approximate: false, missingData: false);
      }
      // approximate via grams/ml per piece if present
      if (candIng.gramsPerPiece != null && candIng.gramsPerPiece! > 0) {
        final grams = (targetKcal / per.kcal) * 100.0; // grams equivalent
        final pieces = grams / candIng.gramsPerPiece!;
        return SubResult(pieces, domain.Unit.piece, approximate: true, missingData: false);
      }
      if (candIng.mlPerPiece != null && candIng.mlPerPiece! > 0) {
        final ml = (targetKcal / per.kcal) * 100.0;
        final pieces = ml / candIng.mlPerPiece!;
        return SubResult(pieces, domain.Unit.piece, approximate: true, missingData: false);
      }
      return SubResult.approx(null, missingData: true);
    }
    // grams/ml base
    final qty = (targetKcal / per.kcal) * 100.0;
    return SubResult(qty, candIng.unit, approximate: false, missingData: false);
  }

  static double _factorForBase(double qtyBase, domain.Unit base, domain.Ingredient ing) {
    switch (base) {
      case domain.Unit.grams:
      case domain.Unit.milliliters:
        return qtyBase / 100.0;
      case domain.Unit.piece:
        if (ing.nutritionPerPieceKcal != null && ing.nutritionPerPieceKcal! > 0) return qtyBase; // pieces
        if (ing.gramsPerPiece != null && ing.gramsPerPiece! > 0) return (qtyBase * ing.gramsPerPiece!) / 100.0;
        if (ing.mlPerPiece != null && ing.mlPerPiece! > 0) return (qtyBase * ing.mlPerPiece!) / 100.0;
        return 0.0;
    }
  }
}

class SubResult {
  final double? qty; // in candidate base unit
  final domain.Unit? unit;
  final bool approximate;
  final bool missingData;
  const SubResult(this.qty, this.unit, {required this.approximate, required this.missingData});
  factory SubResult.approx(double? _, {required bool missingData}) => SubResult(_, null, approximate: true, missingData: missingData);
}

