import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../entities/ingredient.dart';
import '../entities/store_profile.dart';

final tripCostServiceProvider =
    Provider<TripCostService>((ref) => TripCostService(ref));

class TripCostService {
  TripCostService(this.ref);
  final Ref ref;

  /// Compute estimated trip total in cents for the current shopping list,
  /// using selected store's price overrides when present, else purchasePack/PPU fallback.
  Future<int> computeTripTotalCents({
    required List<({String ingredientId, double qty, Unit unit})> items,
    StoreProfile? store,
    Map<String, Ingredient>? ingredientsById,
  }) async {
    if (items.isEmpty) return 0;
    final byId = ingredientsById ??
        {for (final i in <Ingredient>[]) i.id: i}; // expect caller to pass

    int total = 0;
    for (final it in items) {
      final ing = byId[it.ingredientId];
      if (ing == null) continue;

      final overridePerBase = store?.priceOverrideCentsByIngredientId
          ?.[ing.id]; // cents per base unit

      final add = priceCentsFor(
        ing: ing,
        qty: it.qty,
        unit: it.unit,
        overridePriceCentsPerBase: overridePerBase,
      );

      if (kDebugMode) {
        debugPrint(
            '[TripCost] item=${ing.id} qty=${it.qty}${it.unit.name} ppu=${_ppuFor(ing, overridePerBase)} override?=${overridePerBase != null} add=$add');
      }
      total += add;
    }
    if (kDebugMode) debugPrint('[TripCost] total=$total');
    return total;
  }

  /// Compute totals for all provided stores using the same item list.
  /// Does not include a baseline entry here; callers can compute baseline via
  /// [computeTripTotalCents] with store=null if desired.
  Future<List<StoreQuote>> quoteAllStores({
    required List<({String ingredientId, double qty, Unit unit})> items,
    required List<StoreProfile> stores,
    Map<String, Ingredient>? ingredientsById,
  }) async {
    if (items.isEmpty) return const [];

    // Ensure we have an ingredient cache to avoid repeated lookups.
    final byId = ingredientsById ?? {for (final i in <Ingredient>[]) i.id: i};

    final List<StoreQuote> out = [];
    for (final s in stores) {
      final total = await computeTripTotalCents(
        items: items,
        store: s,
        ingredientsById: byId,
      );
      if (kDebugMode) {
        debugPrint('[TripCost] quote store=${s.name} total=$total');
      }
      out.add(
        StoreQuote(
          storeId: s.id,
          displayName: '${s.emoji ?? '🧺'} ${s.name}',
          totalCents: total,
        ),
      );
    }

    return out;
  }

  /// Unit-aware price retrieval: returns cents for qty in item.unit
  int priceCentsFor({
    required Ingredient ing,
    required double qty,
    required Unit unit,
    int? overridePriceCentsPerBase, // cents per base unit in store
  }) {
    // Determine cents per base unit (ingredient.unit)
    final ppu = _ppuFor(ing, overridePriceCentsPerBase);

    // Align unit
    double baseQty;
    if (unit == ing.unit) {
      baseQty = qty;
    } else if ((unit == Unit.grams && ing.unit == Unit.milliliters) ||
        (unit == Unit.milliliters && ing.unit == Unit.grams)) {
      final d = ing.densityGPerMl;
      if (d == null || d <= 0) {
        if (kDebugMode) {
          debugPrint(
              '[TripCost][WARN] density missing for ${ing.id}; using raw qty without conversion');
        }
        baseQty = qty; // documented behavior
      } else {
        baseQty = (unit == Unit.grams) ? qty / d : qty * d;
      }
    } else {
      // piece<->mass/volume are not auto-converted; only price per piece when base is piece
      baseQty = qty;
    }

    final cents = (baseQty * ppu).round();
    return cents;
  }

  int _ppuFor(Ingredient ing, int? overridePriceCentsPerBase) {
    if (overridePriceCentsPerBase != null) return overridePriceCentsPerBase;

    // Fallback to purchase pack PPU if available
    final packPrice = ing.purchasePack.priceCents;
    final packQty = ing.purchasePack.qty;
    if (packPrice != null && packQty > 0) {
      return (packPrice / packQty).round();
    }
    // Else use ingredient.pricePerUnitCents
    return ing.pricePerUnitCents;
  }
}

class StoreQuote {
  final String? storeId; // null = Baseline (no store / default prices)
  final String displayName; // e.g., "🧺 Trader Joe's" or "Baseline"
  final int totalCents;
  const StoreQuote({
    required this.storeId,
    required this.displayName,
    required this.totalCents,
  });
}
