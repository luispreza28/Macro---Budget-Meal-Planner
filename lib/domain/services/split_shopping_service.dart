import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../entities/ingredient.dart' as domain;
import '../entities/store_profile.dart';
import 'store_profile_service.dart';
import 'unit_align.dart';

class SplitShoppingService {
  SplitShoppingService(this.ref);
  final Ref ref;
  static const _tag = '[Split]';

  /// Compute assignment of each ShoppingListLine to a store, honoring locks and store cap.
  /// Returns: SplitResult { assignments: Map<lineId, storeId>, perStoreTotalsCents, combinedTotalCents, baselineSingleStoreCents }
  Future<SplitResult> compute({
    required String planId,
    required List<ShoppingListLine> lines,
    required Map<String, domain.Ingredient> ingredientsById,
    required List<StoreProfile> stores,
    required String? selectedStoreId,
    required int storeCap, // 1 or 2
    required Map<String, String> locks, // lineId -> storeId
  }) async {
    // 1) Precompute line cost per store (normalized to ingredient base, include tax)
    final perStorePPU = <String, Map<String, int>>{}; // storeId -> { ingredientId -> centsPerUnit }
    for (final s in stores) {
      perStorePPU[s.id] = await ref.read(storeProfileServiceProvider).priceOverrides(s.id);
    }

    int? lineCostAt(String storeId, ShoppingListLine line) {
      final ing = ingredientsById[line.ingredientId];
      if (ing == null) return null;
      final qtyBase = alignQty(qty: line.qty, from: line.unit, to: ing.unit, ing: ing);
      if (qtyBase == null) {
        if (kDebugMode) debugPrint('$_tag WARN no density/size for ${line.ingredientId}');
        return null; // skipped; consistent with existing behavior
      }
      final ppu = (perStorePPU[storeId]?[ing.id]) ?? ing.pricePerUnitCents;
      final subtotal = (qtyBase * ppu).round();
      final store = stores.firstWhere((x) => x.id == storeId);
      final tax = (subtotal * (store.taxPct / 100)).round();
      return subtotal + tax;
    }

    // 2) Best store per line (without cap/locks)
    final naiveBest = <String, String>{}; // lineId -> storeId
    for (final line in lines) {
      int? bestCost;
      String? bestStore;
      for (final s in stores) {
        final c = lineCostAt(s.id, line);
        if (c == null) continue;
        if (bestCost == null || c < bestCost) {
          bestCost = c;
          bestStore = s.id;
        }
      }
      if (bestStore != null) naiveBest[line.id] = bestStore!;
    }

    // 3) Apply locks
    final seed = Map<String, String>.from(naiveBest);
    locks.forEach((lineId, storeId) => seed[lineId] = storeId);

    // 4) If cap == 1 → force all lines to a single store (selected or fallback)
    if (storeCap <= 1) {
      final singleId = selectedStoreId ?? (stores.isNotEmpty ? stores.first.id : null);
      final singleAssign = <String, String>{};
      for (final line in lines) {
        final sid = singleId ?? seed[line.id];
        if (sid == null) continue;
        singleAssign[line.id] = sid;
      }
      return _resultFor(singleAssign, stores, lines, lineCostAt, selectedStoreId);
    }

    // 5) Cap == 2 → evaluate all 2-store combinations; keep locks fixed; choose min total
    int? bestTotal;
    Map<String, String>? bestAssign;
    for (int i = 0; i < stores.length; i++) {
      for (int j = i; j < stores.length; j++) {
        final allowed = {stores[i].id, stores[j].id};
        final assign = <String, String>{};
        for (final line in lines) {
          if (locks.containsKey(line.id)) {
            assign[line.id] = locks[line.id]!;
            continue;
          }
          int? lineBestCost;
          String? lineBestStore;
          for (final sid in allowed) {
            final c = lineCostAt(sid, line);
            if (c == null) continue;
            if (lineBestCost == null || c < lineBestCost) {
              lineBestCost = c;
              lineBestStore = sid;
            }
          }
          if (lineBestStore != null) assign[line.id] = lineBestStore!;
        }
        final r = _sum(assign, lines, lineCostAt);
        if (r != null && (bestTotal == null || r < bestTotal)) {
          bestTotal = r;
          bestAssign = assign;
        }
      }
    }
    final chosen = bestAssign ?? seed;
    return _resultFor(chosen, stores, lines, lineCostAt, selectedStoreId);
  }

  int? _sum(
      Map<String, String> assign, List<ShoppingListLine> lines, int? Function(String, ShoppingListLine) costAt) {
    int total = 0;
    bool any = false;
    for (final line in lines) {
      final sid = assign[line.id];
      if (sid == null) continue;
      final c = costAt(sid, line);
      if (c != null) {
        total += c;
        any = true;
      }
    }
    return any ? total : null;
  }

  SplitResult _resultFor(
    Map<String, String> assign,
    List<StoreProfile> stores,
    List<ShoppingListLine> lines,
    int? Function(String, ShoppingListLine) costAt,
    String? baselineStoreId,
  ) {
    final perStoreTotals = <String, int>{};
    int combined = 0;
    for (final line in lines) {
      final sid = assign[line.id];
      if (sid == null) continue;
      final c = costAt(sid, line);
      if (c == null) continue;
      combined += c;
      perStoreTotals[sid] = (perStoreTotals[sid] ?? 0) + c;
    }

    // Baseline: all lines at baseline store (or the cheapest single store if null)
    int? baseline;
    if (baselineStoreId != null) {
      int tot = 0;
      bool any = false;
      for (final line in lines) {
        final c = costAt(baselineStoreId, line);
        if (c != null) {
          tot += c;
          any = true;
        }
      }
      baseline = any ? tot : null;
    }
    baseline ??= () {
      int? best;
      for (final s in stores) {
        int tot = 0;
        bool any = false;
        for (final line in lines) {
          final c = costAt(s.id, line);
          if (c != null) {
            tot += c;
            any = true;
          }
        }
        if (any && (best == null || tot < best)) best = tot;
      }
      return best ?? combined;
    }();

    return SplitResult(
      assignments: assign,
      perStoreTotalsCents: perStoreTotals,
      combinedTotalCents: combined,
      baselineSingleStoreCents: baseline,
    );
  }
}

class SplitResult {
  final Map<String, String> assignments; // lineId -> storeId
  final Map<String, int> perStoreTotalsCents; // storeId -> cents
  final int combinedTotalCents; // cents
  final int baselineSingleStoreCents; // cents
  const SplitResult({
    required this.assignments,
    required this.perStoreTotalsCents,
    required this.combinedTotalCents,
    required this.baselineSingleStoreCents,
  });
}

final splitShoppingServiceProvider = Provider<SplitShoppingService>((ref) => SplitShoppingService(ref));

/// Minimal line model; reuse existing type if available.
class ShoppingListLine {
  final String id; // stable (e.g., ingredientId|unit)
  final String ingredientId;
  final double qty;
  final domain.Unit unit;
  const ShoppingListLine({required this.id, required this.ingredientId, required this.qty, required this.unit});
}

