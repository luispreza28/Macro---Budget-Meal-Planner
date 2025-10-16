import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/pantry_expiry_service.dart';
import '../../domain/services/waste_log_service.dart';
import '../../presentation/providers/ingredient_providers.dart';

final pantryItemsProvider = FutureProvider<List<PantryItem>>((ref) async {
  return ref.read(pantryExpiryServiceProvider).list();
});

final useSoonItemsProvider = FutureProvider<List<PantryItem>>((ref) async {
  final xs = await ref.watch(pantryItemsProvider.future);
  final now = DateTime.now();
  bool soon(DateTime? d) {
    if (d == null) return false;
    final diff = d
        .difference(DateTime(now.year, now.month, now.day))
        .inDays; // local midnight anchor
    return diff <= 3 && diff >= 0;
  }

  return xs
      .where((x) => !x.consumed && !x.discarded && (soon(x.bestBy) || soon(x.expiresAt)))
      .toList();
});

final expiredItemsProvider = FutureProvider<List<PantryItem>>((ref) async {
  final xs = await ref.watch(pantryItemsProvider.future);
  final now = DateTime.now();
  return xs
      .where((x) {
        final d = x.expiresAt ?? x.bestBy;
        return !x.consumed && !x.discarded && d != null && d.isBefore(now);
      })
      .toList();
});

/// Insights: totals for last 30/90 days
final wasteInsightsProvider = FutureProvider<WasteInsights>((ref) async {
  final log = await ref.read(wasteLogServiceProvider).list();
  final now = DateTime.now();
  int sumDays(int days) => log
      .where((e) => now.difference(e.at).inDays <= days)
      .fold(0, (a, e) => a + e.costCentsEstimate);
  return WasteInsights(
    wasted30Cents: sumDays(30),
    wasted90Cents: sumDays(90),
  );
});

class WasteInsights {
  final int wasted30Cents;
  final int wasted90Cents;
  const WasteInsights({required this.wasted30Cents, required this.wasted90Cents});
}

