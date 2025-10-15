import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/insights_providers.dart';

class PantryUsageCard extends ConsumerWidget {
  const PantryUsageCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(insightsPantryProvider);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 160,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: async.when(
            loading: () => const Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))),
            error: (e, _) => Text('Pantry usage failed: $e', style: Theme.of(context).textTheme.labelSmall),
            data: (p) {
              final pct = (p.coverageRatio * 100).round();
              final rescuedAsync = ref.watch(insightsLeftoversRescuedProvider);
              final rescued = rescuedAsync.asData?.value ?? 0;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pantry Usage', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Text('$pct%', style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('covered by pantry inputs', style: Theme.of(context).textTheme.labelSmall),
                  const Spacer(),
                  Text('Servings rescued: $rescued', style: Theme.of(context).textTheme.labelMedium),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
