import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/scan_providers.dart';
import '../../providers/ingredient_providers.dart';
import '../../../domain/entities/ingredient.dart' as ing;

class ScanQueuePage extends ConsumerWidget {
  const ScanQueuePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueAsync = ref.watch(scanQueueProvider);
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Scan Queue'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'All'),
              Tab(text: 'Pending'),
              Tab(text: 'Resolved'),
              Tab(text: 'Failed'),
            ],
          ),
        ),
        body: queueAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Failed to load queue: $e')),
          data: (items) {
            if (items.isEmpty) {
              return const _EmptyState();
            }
            final tabs = [
              items,
              items.where((e) => e.status == 'pending').toList(),
              items.where((e) => e.status == 'resolved').toList(),
              items.where((e) => e.status == 'failed').toList(),
            ];
            return TabBarView(
              children: tabs
                  .map((list) => ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
                        itemCount: list.length,
                        itemBuilder: (ctx, i) => _ScanItemCard(item: list[i]),
                      ))
                  .toList(),
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            await ref.read(processScanQueueProvider.future);
            // ignore: use_build_context_synchronously
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Processed queue')),
            );
          },
          icon: const Icon(Icons.playlist_add_check),
          label: const Text('Process All'),
        ),
      ),
    );
  }
}

class _ScanItemCard extends ConsumerStatefulWidget {
  const _ScanItemCard({required this.item});
  final ScanItem item;

  @override
  ConsumerState<_ScanItemCard> createState() => _ScanItemCardState();
}

class _ScanItemCardState extends ConsumerState<_ScanItemCard> {
  final _priceCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  ing.Unit? _unit;

  @override
  void initState() {
    super.initState();
    _priceCtrl.text = (widget.item.priceCents ?? '').toString();
    _qtyCtrl.text = (widget.item.packQty ?? '').toString();
    _unit = _fromString(widget.item.packUnit);
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _qtyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final created = DateFormat('y-MM-dd HH:mm').format(widget.item.createdAt);
    final statusColor = {
      'pending': Colors.orange,
      'resolved': Colors.green,
      'failed': Colors.red,
    }[widget.item.status];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('EAN ${widget.item.ean}', style: Theme.of(context).textTheme.titleSmall),
                      Text('Created $created', style: Theme.of(context).textTheme.labelMedium),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor?.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: statusColor ?? Colors.grey),
                  ),
                  child: Text(widget.item.status),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FutureBuilder(
                    future: ref.read(ingredientByIdProvider(widget.item.ingredientId ?? '').future),
                    builder: (ctx, snapshot) {
                      final ingMeta = snapshot.data;
                      return Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Chip(
                            label: Text(
                              ingMeta?.name ?? 'Unlinked',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.item.storeId != null)
                            Chip(label: Text('Store: ${widget.item.storeId}')),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () async {
                    final chosen = await showDialog<({String id, String name, ing.Unit unit})>(
                      context: context,
                      builder: (ctx) => _IngredientPickerDialog(),
                    );
                    if (chosen != null) {
                      await ref.read(linkScanToIngredientProvider((widget.item.id, chosen.id)).future);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Linked to ${chosen.name}')),
                      );
                    }
                  },
                  child: const Text('Link Ingredient'),
                )
              ],
            ),
            const Divider(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _qtyCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Pack Qty'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<ing.Unit>(
                    value: _unit,
                    items: ing.Unit.values
                        .map((u) => DropdownMenuItem(value: u, child: Text(u.name)))
                        .toList(),
                    onChanged: (v) => setState(() => _unit = v),
                    decoration: const InputDecoration(labelText: 'Unit'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Total Price (¢)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                FilledButton(
                  onPressed: () async {
                    final qty = double.tryParse(_qtyCtrl.text.trim()) ?? 0;
                    final price = int.tryParse(_priceCtrl.text.trim()) ?? 0;
                    await ref
                        .read(updateScanPriceProvider((widget.item.id,
                            priceCents: price,
                            packQty: qty,
                            packUnit: (_unit ?? ing.Unit.grams).name,
                            storeId: widget.item.storeId))
                        .future);
                    await ref.read(processScanQueueProvider.future);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Price updated')),
                    );
                  },
                  child: const Text('Update Price'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () async {
                    final ok = await ref.read(addScanToShoppingProvider(widget.item.id).future);
                    if (!mounted) return;
                    if (ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Added to Shopping')),
                      );
                    }
                  },
                  child: const Text('Add to Shopping'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  ing.Unit? _fromString(String? s) {
    if (s == null) return null;
    for (final u in ing.Unit.values) {
      if (u.name == s || u.value == s) return u;
    }
    return null;
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.qr_code_scanner, size: 48),
            const SizedBox(height: 12),
            Text(
              'No scans yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Scans are captured offline and can be processed later.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _IngredientPickerDialog extends ConsumerStatefulWidget {
  @override
  ConsumerState<_IngredientPickerDialog> createState() => _IngredientPickerDialogState();
}

class _IngredientPickerDialogState extends ConsumerState<_IngredientPickerDialog> {
  final _ctrl = TextEditingController();
  String _q = '';
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(ingredientSearchProvider(_q)).value ?? const [];
    return AlertDialog(
      title: const Text('Link ingredient'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _ctrl,
              decoration: const InputDecoration(labelText: 'Search'),
              onChanged: (v) => setState(() => _q = v.trim()),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: results.length,
                itemBuilder: (ctx, i) {
                  final it = results[i];
                  return ListTile(
                    title: Text(it.name),
                    subtitle: Text(
                      'Base: ${it.unit.name} • Aisle: ${it.aisle.name}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    onTap: () => Navigator.of(context).pop((id: it.id, name: it.name, unit: it.unit)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
