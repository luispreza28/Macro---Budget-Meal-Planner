import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/pantry_expiry_providers.dart';

class WasteInsightsCard extends ConsumerWidget {
  const WasteInsightsCard({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insights = ref.watch(wasteInsightsProvider);
    final soon = ref.watch(useSoonItemsProvider);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: insights.when(
                loading: () => const Text('Wasting…'),
                error: (e, _) => Text('Insights error: $e'),
                data: (w) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Wasted last 30 days: \$${(w.wasted30Cents / 100).toStringAsFixed(2)}'),
                    const SizedBox(height: 4),
                    Text('Wasted last 90 days: \$${(w.wasted90Cents / 100).toStringAsFixed(2)}'),
                  ],
                ),
              ),
            ),
            soon.when(
              loading: () => const SizedBox.shrink(),
              error: (e, _) => const SizedBox.shrink(),
              data: (xs) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('Use soon: ${xs.length}', style: Theme.of(context).textTheme.labelLarge),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

