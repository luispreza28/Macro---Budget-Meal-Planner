import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/insights_providers.dart';
import '../../providers/recipe_providers.dart';

class TopMoversCard extends ConsumerWidget {
  const TopMoversCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(insightsTopMoversProvider);
    final recipesAsync = ref.watch(allRecipesProvider);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 200,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: async.when(
            loading: () => const Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))),
            error: (e, _) => Text('Top movers failed: $e', style: Theme.of(context).textTheme.labelSmall),
            data: (tm) {
              return recipesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                error: (e, _) => Text('Recipes load failed: $e', style: Theme.of(context).textTheme.labelSmall),
                data: (recipes) {
                  final byId = {for (final r in recipes) r.id: r};
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Top Movers', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(child: _list(context, 'Most used', tm.mostUsedRecipeIds, byId)),
                            const SizedBox(width: 12),
                            Expanded(child: _list(context, 'Least used', tm.leastUsedRecipeIds, byId)),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _list(BuildContext context, String title, List<String> ids, Map<String, dynamic> byId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        ...ids.map((id) {
          final name = byId[id]?.name ?? id;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                const Icon(Icons.restaurant_menu, size: 16),
                const SizedBox(width: 6),
                Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}

