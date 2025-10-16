import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../router/app_router.dart';
import '../../widgets/pro_feature_gate.dart';
import '../../../domain/entities/ingredient.dart' as domain;
import '../../../domain/services/pantry_expiry_service.dart';
import '../../../domain/services/waste_log_service.dart';
import '../../providers/ingredient_providers.dart';
import '../../providers/pantry_expiry_providers.dart';
import 'pantry_item_editor_sheet.dart';
import 'waste_insights_card.dart';

/// Pantry page with expiry tracking, actions, and insights
class PantryPage extends ConsumerStatefulWidget {
  const PantryPage({super.key});

  @override
  ConsumerState<PantryPage> createState() => _PantryPageState();
}

enum _PantryTab { all, soon, expired }

class _PantryPageState extends ConsumerState<PantryPage> {
  _PantryTab _tab = _PantryTab.all;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(pantryItemsProvider);
    final soonAsync = ref.watch(useSoonItemsProvider);
    final expiredAsync = ref.watch(expiredItemsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRouter.home);
            }
          },
        ),
        title: const Text('Pantry'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(),
        child: const Icon(Icons.add),
      ),
      body: ProFeatureGate(
        featureName: 'pantry',
        child: Column(
          children: [
            const SizedBox(height: 8),
            const WasteInsightsCard(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search pantry items…',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (v) => setState(() => _search = v.trim()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: _tab == _PantryTab.all,
                    onSelected: (_) => setState(() => _tab = _PantryTab.all),
                  ),
                  ChoiceChip(
                    label: soonAsync.maybeWhen(data: (xs) => Text('Use soon (${xs.length})'), orElse: () => const Text('Use soon')),
                    selected: _tab == _PantryTab.soon,
                    onSelected: (_) => setState(() => _tab = _PantryTab.soon),
                  ),
                  ChoiceChip(
                    label: expiredAsync.maybeWhen(data: (xs) => Text('Expired (${xs.length})'), orElse: () => const Text('Expired')),
                    selected: _tab == _PantryTab.expired,
                    onSelected: (_) => setState(() => _tab = _PantryTab.expired),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: itemsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Failed to load pantry: $e')),
                data: (items) {
                  List<PantryItem> xs = items.where((x) => !x.consumed && !x.discarded).toList();
                  if (_tab == _PantryTab.soon) {
                    final soon = soonAsync.asData?.value ?? const <PantryItem>[];
                    xs = soon;
                  } else if (_tab == _PantryTab.expired) {
                    final expired = expiredAsync.asData?.value ?? const <PantryItem>[];
                    xs = expired;
                  }
                  if (_search.isNotEmpty) {
                    // Filter by ingredient name
                    xs = xs.where((p) {
                      final ing = ref.read(ingredientByIdProvider(p.ingredientId)).asData?.value;
                      return (ing?.name.toLowerCase().contains(_search.toLowerCase()) ?? false);
                    }).toList();
                  }
                  if (xs.isEmpty) {
                    return const _EmptyView();
                  }
                  return ListView.builder(
                    itemCount: xs.length,
                    itemBuilder: (ctx, i) => _PantryListTile(item: xs[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEditor({PantryItem? initial, domain.Ingredient? ing}) async {
    await showModalBottomSheet<PantryItem>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => PantryItemEditorSheet(initial: initial, prefillIngredient: ing),
    );
    ref.invalidate(pantryItemsProvider);
  }
}

class _PantryListTile extends ConsumerWidget {
  const _PantryListTile({required this.item});
  final PantryItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ingAsync = ref.watch(ingredientByIdProvider(item.ingredientId));
    final fmt = DateFormat.yMMMd();
    final now = DateTime.now();
    final d = item.expiresAt ?? item.bestBy;
    final isExpired = d != null && d.isBefore(now);
    final soon = () {
      if (d == null) return false;
      final diff = d.difference(DateTime(now.year, now.month, now.day)).inDays;
      return diff <= 3 && diff >= 0;
    }();

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: ListTile(
        title: ingAsync.when(
          loading: () => const Text('…'),
          error: (e, _) => Text(item.ingredientId),
          data: (ing) => Text(ing?.name ?? item.ingredientId),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${_fmtQty(item.qty)} ${item.unit.value}'),
            Row(children: [
              if (item.openedAt != null) _Badge(label: 'Opened'),
              if (soon) _Badge(label: 'Use soon'),
              if (isExpired) _Badge(label: 'Expired', color: Theme.of(context).colorScheme.error),
            ]),
            if (d != null) Text('${item.expiresAt != null ? 'Expires' : 'Best-by'}: ${fmt.format(d)} ${_relativeDays(d)}'),
            if (item.note != null && item.note!.isNotEmpty) Text(item.note!),
          ],
        ),
        trailing: PopupMenuButton<String>(
          tooltip: 'Actions',
          onSelected: (v) async {
            switch (v) {
              case 'consume':
                await _consume(context, ref, item);
                break;
              case 'discard':
                await _discard(context, ref, item);
                break;
              case 'extend':
                await _extend(context, ref, item);
                break;
              case 'edit':
                final ing = ref.read(ingredientByIdProvider(item.ingredientId)).asData?.value;
                await showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  showDragHandle: true,
                  builder: (_) => PantryItemEditorSheet(initial: item, prefillIngredient: ing),
                );
                ref.invalidate(pantryItemsProvider);
                break;
            }
          },
          itemBuilder: (ctx) => const [
            PopupMenuItem<String>(value: 'consume', child: Text('Consume…')),
            PopupMenuItem<String>(value: 'discard', child: Text('Discard…')),
            PopupMenuItem<String>(value: 'extend', child: Text('Extend…')),
            PopupMenuItem<String>(value: 'edit', child: Text('Edit…')),
          ],
        ),
      ),
    );
  }

  String _fmtQty(double v) => v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 1);

  String _relativeDays(DateTime d) {
    final anchor = DateTime.now();
    final diff = d.difference(DateTime(anchor.year, anchor.month, anchor.day)).inDays;
    if (diff == 0) return '(today)';
    if (diff > 0) return '(in $diff days)';
    return '(${diff.abs()} days ago)';
  }

  Future<void> _consume(BuildContext ctx, WidgetRef ref, PantryItem item) async {
    final qty = await _pickQty(ctx, max: item.qty, initial: item.qty);
    if (qty == null) return;
    final newQty = (item.qty - qty).clamp(0, double.infinity);
    final updated = item.copyWith(qty: newQty, consumed: newQty == 0 ? true : null);
    await ref.read(pantryExpiryServiceProvider).upsert(updated);
    ref.invalidate(pantryItemsProvider);
    if (newQty == 0) {
      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Consumed — waste avoided')));
    }
  }

  Future<void> _discard(BuildContext ctx, WidgetRef ref, PantryItem item) async {
    final result = await showDialog<(double, String)?>(
      context: ctx,
      builder: (dctx) {
        final qtyCtrl = TextEditingController(text: _fmtQty(item.qty));
        String reason = 'expired';
        return AlertDialog(
          title: const Text('Discard'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: qtyCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(suffixText: item.unit.value, labelText: 'Quantity'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: reason,
                decoration: const InputDecoration(labelText: 'Reason'),
                items: const [
                  DropdownMenuItem(value: 'expired', child: Text('Expired')),
                  DropdownMenuItem(value: 'spoiled', child: Text('Spoiled')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (v) => reason = v ?? 'expired',
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dctx).pop(), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final q = double.tryParse(qtyCtrl.text) ?? 0;
                Navigator.of(dctx).pop((q, reason));
              },
              child: const Text('Discard'),
            ),
          ],
        );
      },
    );
    if (result == null) return;
    final qty = result.$1.clamp(0, item.qty);
    final reason = result.$2;

    // Cost estimate
    final ing = await ref.read(ingredientByIdProvider(item.ingredientId).future);
    int estimateCents = 0;
    if (ing != null) {
      final packPrice = ing.purchasePack.priceCents;
      final ppu = (packPrice != null && ing.purchasePack.qty > 0)
          ? (packPrice / ing.purchasePack.qty)
          : ing.pricePerUnitCents.toDouble();
      estimateCents = (qty * ppu).round();
    }

    final ev = WasteEvent(
      id: const Uuid().v4(),
      ingredientId: item.ingredientId,
      qty: qty,
      unit: item.unit.value,
      at: DateTime.now(),
      reason: reason,
      costCentsEstimate: estimateCents,
    );
    await ref.read(wasteLogServiceProvider).add(ev);

    final updated = item.copyWith(qty: (item.qty - qty).clamp(0, double.infinity), discarded: true);
    await ref.read(pantryExpiryServiceProvider).upsert(updated);
    ref.invalidate(pantryItemsProvider);
  }

  Future<void> _extend(BuildContext ctx, WidgetRef ref, PantryItem item) async {
    final days = await showDialog<int?>(
      context: ctx,
      builder: (dctx) {
        final ctrl = TextEditingController(text: '3');
        return AlertDialog(
          title: const Text('Extend / Snooze'),
          content: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Days'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dctx).pop(), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(dctx).pop(int.tryParse(ctrl.text) ?? 0), child: const Text('Apply')),
          ],
        );
      },
    );
    if (days == null || days <= 0) return;
    final base = item.expiresAt ?? item.bestBy ?? DateTime.now();
    final newDate = base.add(Duration(days: days));
    final updated = (item.expiresAt != null) ? item.copyWith(expiresAt: newDate) : item.copyWith(bestBy: newDate);
    await ref.read(pantryExpiryServiceProvider).upsert(updated);
    ref.invalidate(pantryItemsProvider);
  }

  Future<double?> _pickQty(BuildContext ctx, {required double max, double? initial}) async {
    return showDialog<double?>(
      context: ctx,
      builder: (dctx) {
        final ctrl = TextEditingController(text: _fmtQty(initial ?? max));
        return AlertDialog(
          title: const Text('Quantity'),
          content: TextField(
            controller: ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dctx).pop(), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(dctx).pop(double.tryParse(ctrl.text)), child: const Text('OK')),
          ],
        );
      },
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, this.color});
  final String label;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final bg = color ?? Theme.of(context).colorScheme.tertiary;
    final on = Theme.of(context).colorScheme.onTertiary;
    return Container(
      margin: const EdgeInsets.only(right: 6, top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: on)),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.kitchen, size: 56),
            const SizedBox(height: 8),
            Text('No pantry items', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Add items to track expiry and reduce waste', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

