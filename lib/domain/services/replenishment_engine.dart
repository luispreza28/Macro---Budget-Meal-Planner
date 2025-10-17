import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../presentation/providers/ingredient_providers.dart';
import '../../presentation/providers/recipe_providers.dart';
import '../../domain/entities/ingredient.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/entities/plan.dart';
import '../../presentation/providers/database_providers.dart';
import '../services/replenishment_prefs_service.dart';
import '../services/price_history_service.dart';
import '../services/budget_settings_service.dart';

final replenishmentEngineProvider = Provider<ReplenishmentEngine>((ref) => ReplenishmentEngine(ref));

class ReplenishmentEngine {
  ReplenishmentEngine(this.ref);
  final Ref ref;

  Future<List<RestockSuggestion>> computeSuggestions({
    required Plan plan,
    int horizonDays = 10,
  }) async {
    final ingById = {
      for (final i in await ref.read(allIngredientsProvider.future)) i.id: i
    };
    final prefs = await ref.read(replenishmentPrefsServiceProvider).all();
    final priceSvc = ref.read(priceHistoryServiceProvider);
    final budget = await ref.read(budgetSettingsServiceProvider).get();
    final preferredStore = budget.preferredStoreId;

    // 1) On-hand totals in base units (skip non-base unit rows conservatively)
    final pantryRepo = ref.read(pantryRepositoryProvider);
    final onHandMap = await pantryRepo.getOnHand();
    final onHand = <String, double>{};
    onHandMap.forEach((id, v) => onHand[id] = v.qty);

    // 2) Upcoming usage across horizon
    final usage = await _estimateUsage(plan, ingById, horizonDays);

    // 3) Build suggestions for ingredients with par prefs
    final out = <RestockSuggestion>[];
    for (final entry in ingById.entries) {
      final ing = entry.value;
      final pref = prefs[ing.id];
      if (pref == null || !pref.autoSuggest || pref.parQty <= 0) continue;

      final have = onHand[ing.id] ?? 0;
      final needSoon = usage[ing.id] ?? 0;
      final projected = have - needSoon;

      if (projected >= pref.parQty) continue; // enough even after usage

      final deficit = pref.parQty - projected;
      final suggestedQty = max(deficit, pref.minBuyQty > 0 ? pref.minBuyQty : 0);
      if (suggestedQty <= 0) continue;

      // Choose store by latest per-store PPU with preferred bias
      final points = await priceSvc.list(ing.id);
      final chosen = _pickBestStore(points, preferredStore);
      final estCostCents = chosen == null
          ? (ing.pricePerUnitCents * suggestedQty).round()
          : (chosen.ppuCents * suggestedQty).round();

      out.add(
        RestockSuggestion(
          id: const Uuid().v4(),
          ingredientId: ing.id,
          unit: ing.unit,
          qty: suggestedQty,
          storeId: chosen?.storeId ?? preferredStore,
          estCostCents: estCostCents,
          reason: projected < 0 ? 'Below zero in $horizonDays d' : 'Below par',
          priceHint: chosen == null
              ? null
              : PriceHint(storeId: chosen.storeId, ppuCents: chosen.ppuCents),
        ),
      );
    }

    // Rank: urgency, then price, then preferred store match
    out.sort((a, b) {
      final aUrg = a.reason.contains('Below zero') ? 0 : 1;
      final bUrg = b.reason.contains('Below zero') ? 0 : 1;
      int c = aUrg.compareTo(bUrg);
      if (c != 0) return c;
      c = (a.estCostCents).compareTo(b.estCostCents);
      if (c != 0) return c;
      final preferred = preferredStore;
      if (preferred != null) {
        final am = a.storeId == preferred ? 0 : 1;
        final bm = b.storeId == preferred ? 0 : 1;
        c = am.compareTo(bm);
      }
      return c;
    });

    if (kDebugMode) {
      for (final s in out) {
        debugPrint('[Replenish] ${s.ingredientId} qty=${s.qty} store=${s.storeId ?? '-'} cost=${s.estCostCents}');
      }
    }
    return out;
  }

  Future<Map<String, double>> _estimateUsage(
    Plan plan,
    Map<String, Ingredient> ingById,
    int horizonDays,
  ) async {
    final usage = <String, double>{};
    for (int d = 0; d < plan.days.length && d < horizonDays; d++) {
      final day = plan.days[d];
      for (final meal in day.meals) {
        final r = await ref.read(recipeByIdProvider(meal.recipeId).future);
        if (r == null) continue;
        for (final it in r.items) {
          final ing = ingById[it.ingredientId];
          if (ing == null) continue;
          final base = _toBase(it.qty, it.unit, ing.unit) * meal.servings;
          usage[ing.id] = (usage[ing.id] ?? 0) + base;
        }
      }
    }
    return usage;
  }

  double _toBase(double qty, Unit from, Unit to) {
    if (from == to) return qty;
    // No g<->ml without density; no piece<->(g|ml). For v1: keep qty as-is.
    return qty;
  }

  _StorePick? _pickBestStore(List<PricePoint> points, String? preferred) {
    if (points.isEmpty) return null;
    final latestByStore = <String, PricePoint>{};
    for (final p in points) {
      final cur = latestByStore[p.storeId];
      if (cur == null || p.at.isAfter(cur.at)) latestByStore[p.storeId] = p;
    }
    if (preferred != null && latestByStore.containsKey(preferred)) {
      final pref = latestByStore[preferred]!;
      final min = latestByStore.values.reduce((a, b) => a.ppuCents <= b.ppuCents ? a : b);
      if (pref.ppuCents <= min.ppuCents * 1.05) {
        return _StorePick(pref.storeId, pref.ppuCents);
      }
    }
    final best = latestByStore.values.reduce((a, b) => a.ppuCents <= b.ppuCents ? a : b);
    return _StorePick(best.storeId, best.ppuCents);
  }
}

class RestockSuggestion {
  final String id;
  final String ingredientId;
  final Unit unit;
  final double qty;
  final String? storeId;
  final int estCostCents;
  final String reason;
  final PriceHint? priceHint;
  const RestockSuggestion({
    required this.id,
    required this.ingredientId,
    required this.unit,
    required this.qty,
    required this.storeId,
    required this.estCostCents,
    required this.reason,
    this.priceHint,
  });
}

class PriceHint {
  final String storeId;
  final int ppuCents;
  const PriceHint({required this.storeId, required this.ppuCents});
}

class _StorePick {
  final String storeId;
  final int ppuCents;
  const _StorePick(this.storeId, this.ppuCents);
}

