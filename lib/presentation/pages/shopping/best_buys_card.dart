import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../domain/services/price_history_service.dart';
import '../../providers/price_providers.dart';
import '../../providers/store_providers.dart';
import '../../providers/plan_providers.dart';
import '../../providers/shopping_list_providers.dart';
import '../../providers/database_providers.dart';
import '../../../domain/entities/ingredient.dart' as ing;

class BestBuysCard extends ConsumerWidget {
  const BestBuysCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(currentPlanProvider).value;
    final planId = plan?.id;
    final selectedStore = ref.watch(selectedStoreProvider).value;
    if (planId == null || selectedStore == null) return const SizedBox.shrink();
    return FutureBuilder<_BestBuysData>(
      future: _compute(ref, planId, selectedStore.id),
      builder: (context, snap) {
        final data = snap.data;
        if (data == null || data.rows.isEmpty) {
          return Card(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Log prices as you buy to unlock Best Buys.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
          );
        }

        final fmt = NumberFormat.currency(symbol: '\$');
        return Card(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Best Buys', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                ...data.rows.take(5).map((r) {
                  final savings = fmt.format(r.savingsCents / 100);
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(r.ingredient.name),
                    subtitle: Text('Save ~$savings'),
                    trailing: r.lowest180
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.tertiaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('Lowest in 6 mo',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(color: Theme.of(context).colorScheme.onTertiaryContainer)),
                          )
                        : null,
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<_BestBuysData> _compute(WidgetRef ref, String planId, String storeId) async {
    final groups = await ref.watch(shoppingListItemsProvider.future);
    final prefs = ref.read(sharedPreferencesProvider);
    final checkedKey = 'shopping_checked_$planId';
    final checked = (prefs.getStringList(checkedKey) ?? const <String>[]).toSet();
    final rows = <_BestRow>[];

    for (final g in groups) {
      for (final it in g.items) {
        final lineId = '${it.ingredient.id}|${it.unit.name}';
        if (checked.contains(lineId)) continue;
        final latest = await ref.read(priceHistoryServiceProvider).list(it.ingredient.id);
        final storePoints = latest.where((p) => p.storeId == storeId).toList();
        if (storePoints.isEmpty) continue;
        storePoints.sort((a, b) => a.at.compareTo(b.at));
        final latestPPU = storePoints.last.ppuCents;
        // 90d baseline
        final since = DateTime.now().subtract(const Duration(days: 90));
        final last90 = storePoints.where((p) => p.at.isAfter(since)).map((p) => p.ppuCents).toList()..sort();
        if (last90.isEmpty) continue;
        final avg = last90.reduce((a, b) => a + b) / last90.length;
        final median = last90[last90.length ~/ 2];
        final baseline = last90.length >= 5 ? avg : median.toDouble();
        final delta = (baseline - latestPPU).clamp(0, double.infinity);
        if (delta <= 0) continue;
        final savingsCents = (delta * it.totalQty).round();
        // 180d lowest badge
        final since180 = DateTime.now().subtract(const Duration(days: 180));
        final last180 = storePoints.where((p) => p.at.isAfter(since180)).map((p) => p.ppuCents).toList()..sort();
        final lowest = last180.isNotEmpty && latestPPU <= last180.first;
        rows.add(_BestRow(ingredient: it.ingredient, savingsCents: savingsCents, lowest180: lowest));
      }
    }

    rows.sort((a, b) => b.savingsCents.compareTo(a.savingsCents));
    return _BestBuysData(rows: rows);
  }
}

class _BestBuysData {
  _BestBuysData({required this.rows});
  final List<_BestRow> rows;
}

class _BestRow {
  _BestRow({required this.ingredient, required this.savingsCents, required this.lowest180});
  final ing.Ingredient ingredient;
  final int savingsCents;
  final bool lowest180;
}

