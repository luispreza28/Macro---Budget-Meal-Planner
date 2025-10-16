import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/services/price_history_service.dart';
import '../../domain/services/price_analytics_service.dart';

String newPricePointId() => const Uuid().v4();

final priceHistoryByIngredientProvider =
    FutureProvider.family<List<PricePoint>, String>((ref, ingredientId) async {
  return ref.read(priceHistoryServiceProvider).list(ingredientId);
});

/// Computes latest price summary + any alert for an ingredient at a store.
final priceSummaryProvider =
    FutureProvider.family<PriceSummaryArgs, PriceSummaryKey>((ref, key) async {
  final history =
      await ref.watch(priceHistoryByIngredientProvider(key.ingredientId).future);
  final latestForStore = history.where((p) => p.storeId == key.storeId).fold<PricePoint?>(
      null, (a, b) => a == null || b.at.isAfter(a.at) ? b : a);
  if (latestForStore == null) {
    return const PriceSummaryArgs(latestPpuCents: null, alert: null);
  }
  final alert = await ref.read(priceAnalyticsServiceProvider).computeAlert(
        ingredientId: key.ingredientId,
        storeId: key.storeId,
        ppuNowCents: latestForStore.ppuCents,
      );
  return PriceSummaryArgs(
      latestPpuCents: latestForStore.ppuCents, alert: alert);
});

class PriceSummaryKey {
  final String ingredientId;
  final String storeId;
  const PriceSummaryKey(this.ingredientId, this.storeId);
}

class PriceSummaryArgs {
  final int? latestPpuCents;
  final PriceAlert? alert;
  const PriceSummaryArgs({required this.latestPpuCents, required this.alert});
}

