import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/services/prepared_inventory_service.dart';
import '../../providers/recipe_providers.dart';
import '../../providers/prepared_providers.dart';

class PreparedPage extends ConsumerWidget {
  const PreparedPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipesAsync = ref.watch(allRecipesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Prepared / Leftovers')),
      body: recipesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed: $e')),
        data: (recipes) {
          return FutureBuilder<Map<String, List<PreparedEntry>>>(
            future: ref.read(preparedInventoryServiceProvider).all(),
            builder: (context, snap) {
              final m = snap.data ?? const <String, List<PreparedEntry>>{};
              if (m.isEmpty) {
                return const Center(child: Text('No prepared portions yet'));
              }
              final byId = {for (final r in recipes) r.id: r};
              final keys = m.keys.toList()..sort();
              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: keys.length,
                separatorBuilder: (_, __) => const Divider(height: 12),
                itemBuilder: (_, i) {
                  final id = keys[i];
                  final name = byId[id]?.name ?? id;
                  final entries = m[id] ?? const <PreparedEntry>[];
                  final total = entries.fold<int>(0, (a, e) => a + e.servings);
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text('$name — total servings ($total)', style: Theme.of(context).textTheme.titleMedium)),
                              TextButton(
                                onPressed: total <= 0
                                    ? null
                                    : () async {
                                        await ref.read(preparedInventoryServiceProvider).consume(id, total);
                                        ref.invalidate(preparedServingsProvider(id));
                                        ref.invalidate(preparedEntriesProvider(id));
                                        (context as Element).markNeedsBuild();
                                      },
                                child: const Text('Discard all'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: entries.map((e) {
                              final chipColor = e.storage == Storage.fridge ? Colors.blueGrey : Colors.teal;
                              final exp = e.expiresAt == null ? 'no expiry' : _fmtDate(e.expiresAt!);
                              return Chip(
                                avatar: Icon(e.storage == Storage.fridge ? Icons.kitchen : Icons.ac_unit, size: 16, color: Colors.white),
                                backgroundColor: chipColor.withOpacity(0.2),
                                label: Text('${e.servings} • $exp'),
                              );
                            }).toList(),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: OutlinedButton.icon(
                              onPressed: total > 0
                                  ? () async {
                                      final k = await showDialog<int>(
                                        context: context,
                                        builder: (_) => _PickServDialog(max: total),
                                      );
                                      if (k == null) return;
                                      await ref.read(preparedInventoryServiceProvider).consume(id, k);
                                      ref.invalidate(preparedServingsProvider(id));
                                      ref.invalidate(preparedEntriesProvider(id));
                                      (context as Element).markNeedsBuild();
                                    }
                                  : null,
                              icon: const Icon(Icons.playlist_add_check),
                              label: const Text('Use…'),
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _fmtDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}

class _PickServDialog extends StatefulWidget {
  const _PickServDialog({required this.max});
  final int max;
  @override
  State<_PickServDialog> createState() => _PickServDialogState();
}

class _PickServDialogState extends State<_PickServDialog> {
  int _v = 1;
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Servings to use'),
      content: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(onPressed: () => setState(() => _v = (_v - 1).clamp(1, widget.max)), icon: const Icon(Icons.remove_circle_outline)),
          Text('$_v / ${widget.max}', style: Theme.of(context).textTheme.titleMedium),
          IconButton(onPressed: () => setState(() => _v = (_v + 1).clamp(1, widget.max)), icon: const Icon(Icons.add_circle_outline)),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.of(context).pop(_v), child: const Text('Confirm')),
      ],
    );
  }
}

