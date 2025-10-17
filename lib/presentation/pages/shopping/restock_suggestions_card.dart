import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/plan.dart';
import '../../../domain/services/replenishment_engine.dart';
import '../../providers/replenishment_providers.dart';

class RestockSuggestionsCard extends ConsumerWidget {
  const RestockSuggestionsCard({super.key, required this.plan});
  final Plan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = NumberFormat.simpleCurrency();
    final async = ref.watch(replenishmentSuggestionsProvider(plan));
    return async.when(
      loading: () => const SizedBox(height: 4, child: LinearProgressIndicator(minHeight: 2)),
      error: (_, __) => const SizedBox.shrink(),
      data: (list) {
        if (list.isEmpty) {
          return Card(
            margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Set par levels to get automatic restock suggestions.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        final xs = list.take(5).toList();
        return Card(
          margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, size: 18),
                    const SizedBox(width: 6),
                    Text('Restock Suggestions', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 8),
                ...xs.map((s) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${s.ingredientId} · ${s.qty.toStringAsFixed(s.qty.truncateToDouble() == s.qty ? 0 : 1)} ${s.unit.value}',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  if (s.storeId != null)
                                    _Chip(label: s.storeId!),
                                  if (s.estCostCents > 0)
                                    _Chip(label: fmt.format(s.estCostCents / 100)),
                                  _Chip(label: s.reason),
                                ],
                              ),
                              if (s.priceHint != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    '~${fmt.format((s.priceHint!.ppuCents * 100) / 10000)} per 100 at ${s.priceHint!.storeId}',
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 36,
                          child: FilledButton.tonal(
                            onPressed: () async {
                              final ok = await ref.read(addSuggestionToShoppingProvider((plan.id, s)).future);
                              if (ok && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to Shopping')));
                              }
                            },
                            child: const Text('Add'),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: Theme.of(context).colorScheme.onSecondaryContainer),
      ),
    );
  }
}

