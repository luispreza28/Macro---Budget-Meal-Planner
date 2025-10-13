import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:macro_budget_meal_planner/domain/entities/ingredient.dart'
    as ing;

import '../../router/app_router.dart';
import '../../providers/shopping_list_providers.dart';
import '../../providers/database_providers.dart';
import '../../providers/plan_providers.dart';
import '../../../domain/services/replenish_service.dart';

/// Weekly Shopping List built from the current planÃ¢â‚¬â„¢s recipe.items.
/// Uses shoppingListItemsProvider (reactive) which already aggregates and groups
/// by aisle. Includes aisle summary chips, checkboxes, and export to clipboard.
class ShoppingListPage extends ConsumerStatefulWidget {
  const ShoppingListPage({super.key});

  @override
  ConsumerState<ShoppingListPage> createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends ConsumerState<ShoppingListPage> {
  /// Track checked items by a stable key: "<ingredientId>|<unit>"
  Set<String> _checked = <String>{};
  // Track which plan's checked state is currently loaded.
  String? _loadedPlanId;
  late final ProviderSubscription<AsyncValue<dynamic>> _planListener;
  @override
  void initState() {
    super.initState();
    // Listen to plan changes OUTSIDE build.
    _planListener = ref.listenManual<AsyncValue<dynamic>>(currentPlanProvider, (
      prev,
      next,
    ) {
      next.whenOrNull(
        data: (plan) {
          final planId = plan?.id;
          _onPlanChanged(planId);
        },
      );
    });
    final initialPlan = ref.read(currentPlanProvider).asData?.value;
    _onPlanChanged(initialPlan?.id);
  }

  @override
  void dispose() {
    _planListener.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // IMPORTANT: shoppingListItemsProvider resolves asynchronously via FutureProvider.
    final groupedAsync = ref.watch(shoppingListItemsProvider);
    final groupedData =
        groupedAsync.asData?.value ?? const <ShoppingAisleGroup>[];

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
            onPressed: groupedData.isEmpty
                ? null
                : () => _exportCurrent(context, groupedData),
            icon: const Icon(Icons.ios_share),
          ),
          IconButton(
            tooltip: 'Clear checked',
            onPressed: _checked.isEmpty
                ? null
                : () {
                    setState(() => _checked.clear());
                    _saveCheckedForPlan();
                  },
            icon: const Icon(Icons.checklist_rtl_outlined),
          ),
        ],
      ),
      body: groupedAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _EmptyView(
          title: 'Shopping list unavailable',
          message: 'Failed to load shopping list data. ${error.toString()}',
        ),
        data: (grouped) {
          if (grouped.isEmpty) {
            final debug = ref
                .watch(shoppingListDebugProvider)
                .maybeWhen(data: (s) => s, orElse: () => '');
            return _EmptyView(
              title: 'Nothing to buy',
              message:
                  'Your current plan has no measurable items yet, or no plan is selected.\n$debug',
            );
          }

          final totalItems = grouped.fold<int>(
            0,
            (sum, g) => sum + g.items.length,
          );
          final summary = grouped
              .map(
                (g) => _AisleSummary(
                  aisleLabel: _aisleDisplayName(g.aisle),
                  count: g.items.length,
                ),
              )
              .toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: summary
                        .map(
                          (s) => _AisleChip(
                            label: '${s.aisleLabel} Ã‚Â· ${s.count}',
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: _checked.isEmpty
                            ? null
                            : () async {
                                final plan = ref.read(currentPlanProvider).asData?.value;
                                final svc = ref.read(replenishServiceProvider);
                                final res = await svc.markPurchasedAndReplenish(
                                  planId: plan?.id,
                                  clearAfter: true,
                                );
                                if (!mounted) return;
                                if (res.mismatchesKept == 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Added ${res.itemsMerged} items to Pantry'),
                                    ),
                                  );
                                } else {
                                  // Show mismatch details
                                  // ignore: use_build_context_synchronously
                                  await showModalBottomSheet(
                                    context: context,
                                    builder: (ctx) {
                                      return SafeArea(
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Some items could not be merged',
                                                style: Theme.of(ctx).textTheme.titleMedium,
                                              ),
                                              const SizedBox(height: 8),
                                              ...res.mismatchNotes.map((n) => Padding(
                                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                                    child: Text(n),
                                                  )),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }
                                // Reload checked for plan (it was cleared)
                                if (_loadedPlanId != null) {
                                  await _loadCheckedForPlan(_loadedPlanId!);
                                }
                              },
                        child: const Text('Mark Purchased → Replenish Pantry'),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    Text(
                      'Items ($totalItems)',
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
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  itemCount: grouped.length,
                  itemBuilder: (context, sectionIndex) {
                    final group = grouped[sectionIndex];
                    final title = _aisleDisplayName(group.aisle);
                    final items = group.items;

                    return _AisleSection(
                      title: title,
                      items: items,
                      isChecked: _isCheckedItem,
                      toggleChecked: _toggleCheckedItem,
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

  void _onPlanChanged(String? planId) {
    if (planId == _loadedPlanId) return;

    if (planId == null) {
      setState(() {
        _checked.clear();
        _loadedPlanId = null;
      });
      return;
    }

    _loadCheckedForPlan(planId);
  }

  Future<void> _loadCheckedForPlan(String planId) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final key = 'shopping_checked_$planId';
    final saved = prefs.getStringList(key);

    if (!mounted) return;
    setState(() {
      _checked
        ..clear()
        ..addAll(saved?.toSet() ?? const <String>{});
      _loadedPlanId = planId;
    });
  }

  Future<void> _saveCheckedForPlan() async {
    final planId = _loadedPlanId;
    if (planId == null) return;

    final prefs = ref.read(sharedPreferencesProvider);
    final key = 'shopping_checked_$planId';
    await prefs.setStringList(key, _checked.toList());
  }

  // ---------- Check helpers ----------

  bool _isCheckedItem(AggregatedShoppingItem item) =>
      _checked.contains(_itemKey(item));

  void _toggleCheckedItem(AggregatedShoppingItem item) {
    final k = _itemKey(item);
    setState(() {
      if (_checked.contains(k)) {
        _checked.remove(k);
      } else {
        _checked.add(k);
      }
    });
    _saveCheckedForPlan();
  }

  String _itemKey(AggregatedShoppingItem i) =>
      '${i.ingredient.id}|${i.unit.name}';

  // ---------- Export ----------

  Future<void> _exportCurrent(
    BuildContext ctx,
    List<ShoppingAisleGroup> grouped,
  ) async {
    if (grouped.isEmpty) {
      ScaffoldMessenger.of(
        ctx,
      ).showSnackBar(const SnackBar(content: Text('Shopping list is empty')));
      return;
    }

    final text = _buildExportText(grouped);
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Shopping list copied to clipboard')),
      );
    }
  }

  String _buildExportText(List<ShoppingAisleGroup> grouped) {
    final buf = StringBuffer();
    for (final group in grouped) {
      buf.writeln('## ${_aisleDisplayName(group.aisle)}');
      for (final it in group.items) {
        buf.writeln(
          '- ${it.ingredient.name} â€” ${_formatQty(it.totalQty, it.unit)}',
        );
      }
      buf.writeln();
    }
    return buf.toString().trimRight();
  }
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
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
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
              final name = it.ingredient.name;
              final qtyStr = _formatQty(it.totalQty, it.unit);
              final checked = isChecked(it);

              return ListTile(
                dense: true,
                leading: Checkbox.adaptive(
                  value: checked,
                  onChanged: (_) => toggleChecked(it),
                ),
                title: Text(
                  name,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    decoration: checked ? TextDecoration.lineThrough : null,
                    color: checked
                        ? Theme.of(context).colorScheme.onSurfaceVariant
                        : null,
                  ),
                ),
                subtitle: it.packsNeeded != null
                    ? Text(
                        '${it.packsNeeded} pack(s) suggested',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      )
                    : null,
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      qtyStr,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (it.estimatedCostCents > 0)
                      Text(
                        '\$${(it.estimatedCostCents / 100).toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
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
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AisleSummary {
  const _AisleSummary({required this.aisleLabel, required this.count});
  final String aisleLabel;
  final int count;
}

// ---------- Formatting helpers ----------

String _formatQty(double qty, ing.Unit unit) {
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

String _aisleDisplayName(ing.Aisle aisle) {
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
