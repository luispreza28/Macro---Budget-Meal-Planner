import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/ingredient.dart' as domain;
import 'price_history_service.dart';

final priceAnalyticsServiceProvider =
    Provider<PriceAnalyticsService>((ref) => PriceAnalyticsService(ref));

class PriceAnalyticsService {
  PriceAnalyticsService(this.ref);
  final Ref ref;

  /// Compute canonical PPU (cents per base unit) using unit alignment.
  /// Rules: grams<->ml require density (else return null); piece->base uses gramsPerPiece/mlPerPiece if available; else null.
  int? computeCanonicalPpuCents({
    required int priceCents,
    required double packQty,
    required domain.Unit packUnit,
    required domain.Ingredient ingredient,
  }) {
    double qtyInBase = packQty;
    if (packUnit != ingredient.unit) {
      // grams <-> ml
      if ((packUnit == domain.Unit.grams &&
              ingredient.unit == domain.Unit.milliliters) ||
          (packUnit == domain.Unit.milliliters &&
              ingredient.unit == domain.Unit.grams)) {
        final d = ingredient.densityGPerMl;
        if (d == null) return null;
        qtyInBase = (packUnit == domain.Unit.grams) ? (packQty / d) : (packQty * d);
      } else if (packUnit == domain.Unit.piece) {
        if (ingredient.unit == domain.Unit.grams &&
            ingredient.gramsPerPiece != null) {
          qtyInBase = packQty * ingredient.gramsPerPiece!;
        } else if (ingredient.unit == domain.Unit.milliliters &&
            ingredient.mlPerPiece != null) {
          qtyInBase = packQty * ingredient.mlPerPiece!;
        } else {
          return null;
        }
      } else if (ingredient.unit == domain.Unit.piece) {
        // converting mass/volume -> piece requires gramsPerPiece/mlPerPiece
        final gpp = ingredient.gramsPerPiece ?? ingredient.mlPerPiece;
        if (gpp == null) return null;
        qtyInBase = packQty / gpp;
      }
    }
    if (qtyInBase <= 0) return null;
    return (priceCents / qtyInBase).round();
  }

  /// Alerts based on historical comparison windows.
  Future<PriceAlert?> computeAlert({
    required String ingredientId,
    required String storeId,
    required int ppuNowCents,
  }) async {
    final history = await ref.read(priceHistoryServiceProvider).list(ingredientId);
    final xs = history.where((p) => p.storeId == storeId).toList();
    if (xs.isEmpty) return null;

    // 90d baseline (use avg if >=5 points else median)
    final since = DateTime.now().subtract(const Duration(days: 90));
    final last90 = xs
        .where((p) => p.at.isAfter(since))
        .map((p) => p.ppuCents)
        .toList()
      ..sort();
    if (last90.isEmpty) return null;

    final avg = last90.reduce((a, b) => a + b) / last90.length;
    final median = last90[last90.length ~/ 2];
    final baseline = last90.length >= 5 ? avg : median.toDouble();

    final changePct = ((ppuNowCents - baseline) / baseline) * 100.0;
    if (kDebugMode) {
      debugPrint('[PriceAnalytics] ppuNow=$ppuNowCents baseline=${baseline.toStringAsFixed(2)} change=${changePct.toStringAsFixed(1)}%');
    }

    // Lowest in 180d?
    final since180 = DateTime.now().subtract(const Duration(days: 180));
    final last180 = xs
        .where((p) => p.at.isAfter(since180))
        .map((p) => p.ppuCents)
        .toList()
      ..sort();
    final historicalMin = last180.isEmpty ? null : last180.first;

    if (historicalMin != null && ppuNowCents <= historicalMin) {
      return PriceAlert(kind: AlertKind.lowest180, changePct: changePct);
    }
    if (changePct <= -10.0) {
      return PriceAlert(kind: AlertKind.dropVs90, changePct: changePct);
    }
    if (changePct >= 15.0) {
      return PriceAlert(kind: AlertKind.spikeVs90, changePct: changePct);
    }
    return null;
  }
}

class PriceAlert {
  final AlertKind kind;
  final double changePct;
  const PriceAlert({required this.kind, required this.changePct});
}

enum AlertKind { dropVs90, lowest180, spikeVs90 }

