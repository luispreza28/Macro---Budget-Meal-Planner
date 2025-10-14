import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/insights_providers.dart';

class TrendsCard extends ConsumerWidget {
  const TrendsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(insightsTrendsProvider);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 180,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: async.when(
            loading: () => const Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))),
            error: (e, _) => Text('Trends failed: $e', style: Theme.of(context).textTheme.labelSmall),
            data: (t) {
              final kcalSeries = t.kcalDeltaSeries;
              final costSeries = t.costSeriesCents.map((e) => e.toDouble()).toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Trends (last ${kcalSeries.length} plans)', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  _Bars(title: 'Avg kcal Δ', values: kcalSeries.map((e) => e.abs()).toList(), positiveNeg: kcalSeries),
                  const SizedBox(height: 12),
                  _Bars(title: 'Planned cost', values: costSeries),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Bars extends StatelessWidget {
  const _Bars({required this.title, required this.values, this.positiveNeg});
  final String title;
  final List<double> values; // non-negative for rendering height
  final List<double>? positiveNeg; // if provided, sign colors bars

  @override
  Widget build(BuildContext context) {
    final maxV = values.isEmpty ? 1.0 : values.reduce((a, b) => a > b ? a : b);
    final bars = <Widget>[];
    for (int i = 0; i < values.length; i++) {
      final v = values[i];
      final h = maxV <= 0 ? 0.0 : (v / maxV);
      final col = positiveNeg == null
          ? Theme.of(context).colorScheme.primary
          : ((positiveNeg![i] >= 0) ? Colors.orange : Colors.green);
      bars.add(Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: (h.clamp(0.05, 1.0)),
              child: Container(
                decoration: BoxDecoration(
                  color: col.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ),
      ));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        SizedBox(
          height: 48,
          child: Row(children: bars),
        ),
      ],
    );
  }
}

