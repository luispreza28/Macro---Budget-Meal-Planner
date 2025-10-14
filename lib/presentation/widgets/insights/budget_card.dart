import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/insights_providers.dart';

class BudgetCard extends ConsumerWidget {
  const BudgetCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(insightsBudgetProvider);
    final currency = NumberFormat.simpleCurrency(name: 'USD');
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 140,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: async.when(
            loading: () => const Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))),
            error: (e, _) => Text('Budget failed: $e', style: Theme.of(context).textTheme.labelSmall),
            data: (b) {
              final planned = currency.format(b.plannedCents / 100);
              final trip = currency.format(b.tripTotalCents / 100);
              final delta = b.plannedCents - b.tripTotalCents;
              final deltaText = (delta >= 0 ? 'Save ' : '+ ') + currency.format(delta.abs() / 100);
              final deltaColor = delta >= 0 ? Colors.green : Colors.red;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Budget', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Text('Planned $planned - Trip $trip', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                  const Spacer(),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: deltaColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(deltaText, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: deltaColor, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

