import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/services/price_history_service.dart';
import '../providers/price_providers.dart';
import '../providers/store_providers.dart';
import '../providers/ingredient_providers.dart';
import '../pages/pantry/par_editor_sheet.dart';

class IngredientPricePanel extends ConsumerWidget {
  const IngredientPricePanel({super.key, required this.ingredientId, this.selectedStoreId});
  final String ingredientId;
  final String? selectedStoreId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(storeProfilesProvider);
    final historyAsync = ref.watch(priceHistoryByIngredientProvider(ingredientId));
    final fmt = NumberFormat.simpleCurrency();
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Prices', style: Theme.of(context).textTheme.titleMedium)),
                IconButton(
                  tooltip: 'Par Level',
                  icon: const Icon(Icons.auto_awesome),
                  onPressed: () async {
                    // Try get ingredient from profiles store? We only have id; defer to global providers.
                    final ing = await ref.read(ingredientByIdProvider(ingredientId).future);
                    if (ing != null && context.mounted) {
                      await showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        showDragHandle: true,
                        builder: (_) => ParEditorSheet(ingredient: ing),
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 6),
            profilesAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (profiles) {
                return historyAsync.when(
                  loading: () => const LinearProgressIndicator(minHeight: 2),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (points) {
                    if (points.isEmpty) {
                      return Text('No price history yet', style: Theme.of(context).textTheme.bodySmall);
                    }
                    // Latest per store
                    final byStore = <String, PricePoint>{};
                    for (final p in points) {
                      final prev = byStore[p.storeId];
                      if (prev == null || p.at.isAfter(prev.at)) byStore[p.storeId] = p;
                    }
                    final chips = <Widget>[];
                    byStore.forEach((sid, p) {
                      final s = profiles.firstWhere(
                        (x) => x.id == sid,
                        orElse: () => profiles.isNotEmpty ? profiles.first : null,
                      );
                      final name = s?.name ?? sid;
                      final per100 = (p.ppuCents * 100) / 100; // cents per unit → show per 100 units
                      final label = '$name: ${fmt.format(per100 / 100)} / 100';
                      chips.add(Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        margin: const EdgeInsets.only(right: 6, bottom: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSecondaryContainer)),
                      ));
                    });

                    // Sparkline for selected store
                    final sid = selectedStoreId ?? (byStore.isNotEmpty ? byStore.keys.first : null);
                    final storePoints = sid == null
                        ? const <PricePoint>[]
                        : (points.where((p) => p.storeId == sid).toList()..sort((a, b) => a.at.compareTo(b.at)));
                    final last10 = storePoints.length <= 10
                        ? storePoints
                        : storePoints.sublist(storePoints.length - 10);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(children: chips),
                        if (last10.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 56,
                            width: double.infinity,
                            child: CustomPaint(
                              painter: _SparklinePainter(
                                values: last10.map((e) => e.ppuCents.toDouble()).toList(),
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.values});
  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV).clamp(1, double.infinity);
    final dx = size.width / (values.length - 1);
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = i * dx;
      final norm = (values[i] - minV) / range;
      final y = size.height - (norm * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final paint = Paint()
      ..color = Colors.teal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.values != values;
}
