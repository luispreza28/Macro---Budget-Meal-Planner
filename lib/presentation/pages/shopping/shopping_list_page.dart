// lib/presentation/pages/shopping/shopping_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../router/app_router.dart';
import '../../providers/shopping_list_providers.dart';
import '../../../domain/entities/ingredient.dart' as ing;

/// Weekly Shopping List built from the current plan’s recipe.items via provider.
/// Uses `shoppingListItemsProvider` which returns grouped aisle sections with
/// pre-aggregated quantities and cost hints.
class ShoppingListPage extends ConsumerStatefulWidget {
  const ShoppingListPage({super.key});

  @override
  ConsumerState<ShoppingListPage> createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends ConsumerState<ShoppingListPage> {
  /// Track checked items by a stable key: "<ingredientId>|<unit>"
  final Set<String> _checked = <String>{};

  @override
  Widget build(BuildContext context) {
    final groupedAsync = ref.watch(shoppingListItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping List'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            final router = GoRouter.of(context);
            if (router.canPop()) {
              context.pop();
            } else {
              context.go(AppRouter.home);
            }
          },
          tooltip: 'Back',
        ),
        actions: [
          IconButton(
            tooltip: 'Export (copy to clipboard)',
            onPressed: () => _exportCurrent(context, groupedAsync),
            icon: const Icon(Icons.ios_share),
          ),
          IconButton(
            tooltip: 'Clear checked',
            onPressed:
                _checked.isEmpty ? null : () => setState(() => _checked.clear()),
            icon: const Icon(Icons.checklist_rtl_outlined),
          ),
        ],
      ),
      body: groupedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView('Failed to build shopping list: $e'),
        data: (groups) {
          if (groups.isEmpty) {
            return const _EmptyView(
              title: 'No items yet',
              message: 'Generate a weekly plan to populate your shopping list.',
            );
          }

          // Summary chips (aisle → count)
          final summaries = groups
              .map((g) => _AisleSummary(aisle: g.aisle, count: g.items.length))
              .toList();

          return Column(
            children: [
              // Summary chips row
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: summaries
                        .map((s) => _AisleChip(
                              label:
                                  '${_aisleDisplayName(s.aisle)} · ${s.count}',
                            ))
                        .toList(),
                  ),
                ),
              ),
              // Header row
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    Text(
                      'Items (${groups.fold<int>(0, (sum, g) => sum + g.items.length)})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const Spacer(),
                    const Icon(Icons.store_mall_directory_outlined, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Grouped by aisle',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Aisle sections
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    // copy & sort by ingredient name for stable UI
                    final items = [...group.items]
                      ..sort((a, b) => a.ingredient.name
                          .toLowerCase()
                          .compareTo(b.ingredient.name.toLowerCase()));
                    return _AisleSection(
                      title: _aisleDisplayName(group.aisle),
                      items: items,
                      isChecked: _isChecked,
                      toggleChecked: _toggleChecked,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------- Check state helpers ----------
  bool _isChecked(AggregatedShoppingItem item) =>
      _checked.contains(_itemKey(item));

  void _toggleChecked(AggregatedShoppingItem item) {
    final k = _itemKey(item);
    setState(() {
      if (_checked.contains(k)) {
        _checked.remove(k);
      } else {
        _checked.add(k);
      }
    });
  }

  String _itemKey(AggregatedShoppingItem it) =>
      '${it.ingredient.id}|${it.unit.name}';

  // ---------- Export ----------
  Future<void> _exportCurrent(
    BuildContext ctx,
    AsyncValue<List<ShoppingAisleGroup>> groupedAsync,
  ) async {
    final groups = groupedAsync.value;
    if (groups == null || groups.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Nothing to export yet')),
      );
      return;
    }

    final buf = StringBuffer();
    for (final g in groups) {
      buf.writeln('## ${_aisleDisplayName(g.aisle)}');
      final items = [...g.items]
        ..sort((a, b) =>
            a.ingredient.name.toLowerCase().compareTo(b.ingredient.name.toLowerCase()));
      for (final it in items) {
        final qty = _formatQty(it.totalQty, it.unit);
        buf.writeln('- ${it.ingredient.name} — $qty');
      }
      buf.writeln();
    }

    await Clipboard.setData(ClipboardData(text: buf.toString().trimRight()));
    if (!mounted) return;
    ScaffoldMessenger.of(ctx).showSnackBar(
      const SnackBar(content: Text('Shopping list copied to clipboard')),
    );
  }
}

// ---------- Small models ----------
class _AisleSummary {
  const _AisleSummary({required this.aisle, required this.count});
  final ing.Aisle? aisle;
  final int count;
}

// ---------- UI bits ----------
class _AisleChip extends StatelessWidget {
  const _AisleChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _AisleSection extends StatelessWidget {
  const _AisleSection({
    required this.title,
    required this.items,
    required this.isChecked,
    required this.toggleChecked,
  });

  final String title;
  final List<AggregatedShoppingItem> items;
  final bool Function(AggregatedShoppingItem item) isChecked;
  final void Function(AggregatedShoppingItem item) toggleChecked;

  @override
  Widget build(BuildContext context) {
    final checkedCount = items.where(isChecked).length;

    return Column(
      children: [
        // Section header with mini-summary
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(8, 14, 8, 8),
          child: Row(
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.primary,
                      letterSpacing: 0.2,
                    ),
              ),
              const SizedBox(width: 8),
              Text(
                '• ${items.length} items'
                '${checkedCount > 0 ? ' • $checkedCount checked' : ''}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        Card(
          margin: const EdgeInsets.only(bottom: 12),
          clipBehavior: Clip.antiAlias,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final it = items[i];
              final checked = isChecked(it);

              final qtyStr = _formatQty(it.totalQty, it.unit);
              final costStr =
                  it.estimatedCostCents != null ? ' • \$${(it.estimatedCostCents! / 100).toStringAsFixed(2)}' : '';
              final packHint = it.packsNeeded != null
                  ? ' • ~${it.packsNeeded} pack(s)'
                  : '';

              return ListTile(
                dense: true,
                leading: Checkbox.adaptive(
                  value: checked,
                  onChanged: (_) => toggleChecked(it),
                ),
                title: Text(
                  it.ingredient.name,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        decoration:
                            checked ? TextDecoration.lineThrough : null,
                        color: checked
                            ? Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                            : null,
                      ),
                ),
                trailing: Text(
                  '$qtyStr$costStr$packHint',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: checked
                            ? Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                onTap: () => toggleChecked(it),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---------- Helpers ----------
String _aisleDisplayName(ing.Aisle? aisle) {
  if (aisle == null) return 'Other';
  switch (aisle) {
    case ing.Aisle.produce:
      return 'Produce';
    case ing.Aisle.meat:
      return 'Meat';
    case ing.Aisle.dairy:
      return 'Dairy';
    case ing.Aisle.pantry:
      return 'Pantry';
    case ing.Aisle.frozen:
      return 'Frozen';
    case ing.Aisle.condiments:
      return 'Condiments';
    case ing.Aisle.bakery:
      return 'Bakery';
    case ing.Aisle.household:
      return 'Household';
  }
}

String _formatQty(double qty, ing.Unit unit) {
  // Compact 1-dec rounding
  final rounded = (qty * 10).round() / 10.0;
  final s = (rounded % 1 == 0)
      ? rounded.toStringAsFixed(0)
      : rounded.toStringAsFixed(1);
  switch (unit) {
    case ing.Unit.grams:
      return '$s g';
    case ing.Unit.milliliters:
      return '$s ml';
    case ing.Unit.piece:
      return '$s pc';
  }
}

// ---------- Generic views ----------
class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.title, required this.message});
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shopping_cart_outlined, size: 56),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color:
                        Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.red),
            const SizedBox(height: 12),
            Text('Oops', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
