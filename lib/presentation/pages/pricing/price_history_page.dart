import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../domain/services/price_history_service.dart';
import '../../../domain/services/price_analytics_service.dart';
import '../../providers/ingredient_providers.dart';

class PriceHistoryPage extends ConsumerWidget {
  const PriceHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ingredientsAsync = ref.watch(allIngredientsProvider);
    final fmt = NumberFormat.simpleCurrency();
    return Scaffold(
      appBar: AppBar(title: const Text('Price History')),
      body: ingredientsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Failed to load: $e')),
        data: (ings) {
          if (ings.isEmpty) return const SizedBox.shrink();
          return FutureBuilder<Widget>(
            future: () async {
              final children = <Widget>[];
              for (final ing in ings) {
                final points = await ref.read(priceHistoryServiceProvider).list(ing.id);
                if (points.isEmpty) continue;
                final last = points.length > 10 ? points.sublist(points.length - 10) : points;
                // Alerts: compute per store for latest
                final byStore = <String, PricePoint>{};
                for (final p in points) {
                  final prev = byStore[p.storeId];
                  if (prev == null || p.at.isAfter(prev.at)) byStore[p.storeId] = p;
                }
                final alerts = <Widget>[];
                for (final entry in byStore.entries) {
                  final a = await ref.read(priceAnalyticsServiceProvider).computeAlert(
                        ingredientId: ing.id,
                        storeId: entry.key,
                        ppuNowCents: entry.value.ppuCents,
                      );
                  if (a == null) continue;
                  alerts.add(_alertBadge(context, a));
                }
                children.add(
                  Card(
                    margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text(ing.name, style: Theme.of(context).textTheme.titleSmall)),
                              if (alerts.isNotEmpty) Wrap(spacing: 6, runSpacing: 6, children: alerts),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...last.reversed.map((p) => Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${p.storeId} • ${DateFormat.yMMMd().format(p.at)}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                                  Text('${fmt.format(p.priceCents / 100)} • ${p.packQty.toStringAsFixed(0)} ${p.packUnit.value} • ${p.ppuCents}c/u',
                                      style: Theme.of(context).textTheme.labelSmall),
                                ],
                              )),
                        ],
                      ),
                    ),
                  ),
                );
              }
              if (children.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('No history yet. Log prices from the Shopping List.',
                        style: Theme.of(context).textTheme.bodySmall),
                  ),
                );
              }
              return ListView(children: children);
            }(),
            builder: (context, snap) {
              return snap.data ?? const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }
}

Widget _alertBadge(BuildContext context, PriceAlert a) {
  String label;
  switch (a.kind) {
    case AlertKind.dropVs90:
      label = '↓ ${a.changePct.toStringAsFixed(0)}% vs 90d';
      break;
    case AlertKind.lowest180:
      label = 'Lowest in 6 mo';
      break;
    case AlertKind.spikeVs90:
      label = '↑ ${a.changePct.toStringAsFixed(0)}% vs 90d';
      break;
  }
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSecondaryContainer)),
  );
}
