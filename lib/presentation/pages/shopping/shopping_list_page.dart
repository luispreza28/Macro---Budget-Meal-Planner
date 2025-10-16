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
import '../../providers/store_providers.dart';
import '../../../domain/services/store_profile_service.dart';
import '../../../domain/services/trip_cost_service.dart';
import 'package:intl/intl.dart';
import '../../providers/store_compare_providers.dart';
import '../../providers/plan_providers.dart';
import '../../providers/store_providers.dart';
import '../../providers/shopping_list_providers.dart';
import '../pantry/pantry_item_editor_sheet.dart';
import '../../providers/pantry_expiry_providers.dart';
import '../../../domain/services/pantry_expiry_service.dart';
import '../../providers/database_providers.dart';
import '../../../domain/services/route_prefs_service.dart';
import '../../providers/route_providers.dart';
import '../../../domain/value/shortfall_item.dart' as v1;
import '../../providers/pantry_providers.dart';
import '../../../domain/services/substitutions_service.dart';
import '../../../domain/services/substitution_math.dart';
import '../../../domain/services/substitution_cost_service.dart';
import '../../../domain/entities/store_profile.dart';
import '../../../domain/services/split_shopping_prefs.dart';
import '../../providers/split_shopping_providers.dart';
import 'best_buys_card.dart';
// Price history & analytics
import '../../../domain/services/price_history_service.dart';
import '../../../domain/services/price_analytics_service.dart';
import '../../providers/price_providers.dart';

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
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _sectionKeys = {};
  int _lastAisleIndex = -1;
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
    final groupedData = groupedAsync.asData?.value ?? const <ShoppingAisleGroup>[];
    final storeAsync = ref.watch(selectedStoreProvider);
    final profilesAsync = ref.watch(storeProfilesProvider);

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
          Builder(builder: (context) {
            final planId = ref.watch(currentPlanProvider).asData?.value?.id;
            if (planId == null) return const SizedBox.shrink();
            final mode = ref.watch(instoreModeProvider(planId)).value ?? 'normal';
            if (mode != 'instore') return const SizedBox.shrink();
            return PopupMenuButton<String>(
              tooltip: 'More',
              onSelected: (v) async {
                final allKeys = ing.Aisle.values.map((a) => a.value).toSet();
                if (v == 'collapse') {
                  await ref.read(routePrefsServiceProvider).setCollapsed(planId, allKeys);
                } else if (v == 'expand') {
                  await ref.read(routePrefsServiceProvider).setCollapsed(planId, <String>{});
                } else if (v == 'history') {
                  context.go(AppRouter.priceHistory);
                }
                ref.invalidate(collapsedSectionsProvider(planId));
              },
              itemBuilder: (_) => const [
                PopupMenuItem<String>(value: 'collapse', child: Text('Collapse all')),
                PopupMenuItem<String>(value: 'expand', child: Text('Expand all')),
                PopupMenuDivider(),
                PopupMenuItem<String>(value: 'history', child: Text('Price History')),
              ],
            );
          }),
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
                    // Keep compare totals in sync with checked state
                    ref.invalidate(storeQuotesProvider);
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
          // Order sections by selected store aisle order
          final store = storeAsync.value;
          final defaultOrder = ing.Aisle.values.map((a) => a.value).toList();
          final order = store?.aisleOrder ?? defaultOrder;
          final sortedGroups = [...grouped];
          int idxOf(ing.Aisle a) {
            final i = order.indexOf(a.value);
            return i < 0 ? 999 : i;
          }
          sortedGroups.sort((a, b) => idxOf(a.aisle).compareTo(idxOf(b.aisle)));

          final plan = ref.read(currentPlanProvider).asData?.value;
          final planId = plan?.id;
          final mode = planId != null ? ref.watch(instoreModeProvider(planId)).value ?? 'normal' : 'normal';
          final isInstore = mode == 'instore';
          final uncheckedOnly = planId != null ? (ref.watch(showUncheckedOnlyProvider(planId)).value ?? false) : false;
          final collapsed = planId != null ? (ref.watch(collapsedSectionsProvider(planId)).value ?? <String>{}) : <String>{};

          // Apply unchecked-only filter (after grouping/ordering)
          List<ShoppingAisleGroup> visibleGroups = sortedGroups;
          if (isInstore && uncheckedOnly) {
            visibleGroups = [];
            for (final g in sortedGroups) {
              final filtered = g.items.where((it) => !_isCheckedItem(it)).toList();
              if (filtered.isNotEmpty) {
                visibleGroups.add(ShoppingAisleGroup(aisle: g.aisle, items: filtered));
              }
            }
          }

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

          final totalItems = sortedGroups.fold<int>(
            0,
            (sum, g) => sum + g.items.length,
          );
          final summary = sortedGroups
              .map(
                (g) => _AisleSummary(
                  aisleLabel: _aisleDisplayName(g.aisle),
                  count: g.items.length,
                ),
              )
              .toList();

          // Build header controls (mode toggle, unchecked-only, hint)
          final storeName = store?.name ?? 'Default';
          final routeHint = 'Route ordered for $storeName';

          // Ensure keys for headers
          _sectionKeys.clear();
          for (final g in visibleGroups) {
            _sectionKeys.putIfAbsent(g.aisle.value, () => GlobalKey());
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ...summary
                          .map(
                            (s) => _AisleChip(
                              label: '${s.aisleLabel} Ã‚Â· ${s.count}',
                            ),
                          )
                          .toList(),
                      Builder(builder: (context) {
                        final soon = ref.watch(useSoonItemsProvider).asData?.value ?? const [];
                        if (soon.isEmpty) return const SizedBox.shrink();
                        return ActionChip(
                          avatar: const Icon(Icons.schedule, size: 16),
                          label: Text('Use soon: ${soon.length}'),
                          onPressed: () => context.go(AppRouter.pantry),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              // Best Buys card
              const BestBuysCard(),
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
                    _StoreSwitcher(
                      profilesAsync: profilesAsync,
                      selectedStoreAsync: storeAsync,
                      onChanged: (id) async {
                        await ref.read(storeProfileServiceProvider).setSelected(id);
                        ref.invalidate(selectedStoreProvider);
                        ref.invalidate(storeQuotesProvider);
                        ref.invalidate(shoppingListItemsProvider);
                      },
                    ),
                  ],
                ),
              ),
              // Split mode toggle and totals
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _SplitHeaderAndTotals(checkedKeys: _checked),
              ),
              // Cheapest store banner
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                child: _CheapestStoreBanner(),
              ),
              // Trip total (kept for baseline when single mode)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: _TripTotalBar(groups: sortedGroups, checked: _checked, store: storeAsync.value),
              ),
              const SizedBox(height: 8),
              // In-Store Mode controls
              if (planId != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      Switch.adaptive(
                        value: isInstore,
                        onChanged: (v) async {
                          await ref.read(routePrefsServiceProvider).setMode(planId, v ? 'instore' : 'normal');
                          ref.invalidate(instoreModeProvider(planId));
                        },
                      ),
                      const SizedBox(width: 8),
                      const Text('In-Store Mode'),
                      const Spacer(),
                      if (isInstore)
                        Row(
                          children: [
                            Checkbox.adaptive(
                              value: uncheckedOnly,
                              onChanged: (v) async {
                                await ref.read(routePrefsServiceProvider).setUncheckedOnly(planId, v ?? false);
                                ref.invalidate(showUncheckedOnlyProvider(planId));
                              },
                            ),
                            const Text('Show unchecked only'),
                          ],
                        ),
                    ],
                  ),
                ),
              if (isInstore)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      routeHint,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Expanded(
                child: isInstore
                    ? CustomScrollView(
                        controller: _scrollController,
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                            sliver: SliverList(
                              delegate: SliverChildListDelegate([
                                // Keep existing summary/header cards in flow already above
                              ]),
                            ),
                          ),
                          ...visibleGroups.expand((g) {
                            final headerKey = _sectionKeys[g.aisle.value]!;
                            final isCollapsed = collapsed.contains(g.aisle.value);
                            return [
                              SliverPersistentHeader(
                                pinned: true,
                                delegate: _SimpleHeaderDelegate(
                                  minExtent: 44,
                                  maxExtent: 48,
                                  child: Container(
                                    key: headerKey,
                                    color: Theme.of(context).colorScheme.surface,
                                    padding: const EdgeInsets.fromLTRB(8, 10, 8, 6),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: () async {
                                              if (planId == null) return;
                                              final next = {...collapsed};
                                              if (isCollapsed) {
                                                next.remove(g.aisle.value);
                                              } else {
                                                next.add(g.aisle.value);
                                              }
                                              await ref.read(routePrefsServiceProvider).setCollapsed(planId, next);
                                              ref.invalidate(collapsedSectionsProvider(planId));
                                            },
                                            child: Row(
                                              children: [
                                                Text(
                                                  _aisleDisplayName(g.aisle),
                                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                        fontWeight: FontWeight.w800,
                                                        color: Theme.of(context).colorScheme.primary,
                                                        letterSpacing: 0.2,
                                                      ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  '• ${g.items.length} items',
                                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Icon(isCollapsed ? Icons.expand_more : Icons.expand_less),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              if (!isCollapsed)
                                SliverToBoxAdapter(
                                  child: Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    clipBehavior: Clip.antiAlias,
                                    child: ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      itemCount: g.items.length,
                                      separatorBuilder: (_, __) => const Divider(height: 1),
                                      itemBuilder: (context, i) {
                                        final it = g.items[i];
                                        final name = it.ingredient.name;
                                        final qtyStr = _formatQty(it.totalQty, it.unit);
                                        final checked = _isCheckedItem(it);
                                        final lineId = '${it.ingredient.id}|${it.unit.name}';
                                        return ListTile(
                                          minVerticalPadding: 12,
                                          leading: Transform.scale(
                                            scale: 1.2,
                                            child: Checkbox.adaptive(
                                              value: checked,
                                              onChanged: (_) => _toggleCheckedItem(it),
                                            ),
                                          ),
                                          title: Text(
                                            name,
                                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                  decoration: checked ? TextDecoration.lineThrough : null,
                                                  color: checked ? Theme.of(context).colorScheme.onSurfaceVariant : null,
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
                                              if (planId != null) _SplitStoreBadge(planId: planId, lineId: lineId),
                                              if (it.estimatedCostCents > 0)
                                                Text(
                                                  '\$${(it.estimatedCostCents / 100).toStringAsFixed(2)}',
                                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                      ),
                                                ),
                                            ],
                                          ),
                                          onTap: () => _toggleCheckedItem(it),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                            ];
                          }),
                        ],
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                        itemCount: sortedGroups.length,
                        itemBuilder: (context, sectionIndex) {
                          final group = sortedGroups[sectionIndex];
                          final title = _aisleDisplayName(group.aisle);
                          final items = group.items;

                          return _AisleSection(
                            title: title,
                            items: items,
                            isChecked: _isCheckedItem,
                            toggleChecked: _toggleCheckedItem,
                            planId: ref.read(currentPlanProvider).asData?.value?.id,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: () {
        final pid = ref.watch(currentPlanProvider).asData?.value?.id;
        if (pid == null) return null;
        final inMode = ref.watch(instoreModeProvider(pid)).value ?? 'normal';
        if (inMode != 'instore') return null;
        return FloatingActionButton(
          onPressed: () async {
            final plan = ref.read(currentPlanProvider).asData?.value;
            final planId = plan?.id;
            if (planId == null) return;
            final uncheckedOnly = ref.read(showUncheckedOnlyProvider(planId)).value ?? false;
            // Build current groups view
            final groups = (ref.read(shoppingListItemsProvider).asData?.value ?? const <ShoppingAisleGroup>[]);
            final store = ref.read(selectedStoreProvider).value;
            final defaultOrder = ing.Aisle.values.map((a) => a.value).toList();
            final order = store?.aisleOrder ?? defaultOrder;
            List<ShoppingAisleGroup> sorted = [...groups]
              ..sort((a, b) => (order.indexOf(a.aisle.value)).compareTo(order.indexOf(b.aisle.value)));
            if (uncheckedOnly) {
              sorted = sorted
                  .map((g) => ShoppingAisleGroup(
                      aisle: g.aisle, items: g.items.where((it) => !_isCheckedItem(it)).toList()))
                  .where((g) => g.items.isNotEmpty)
                  .toList();
            }
            if (sorted.isEmpty) return;
            // Find next aisle with any unchecked
            int start = _lastAisleIndex;
            int next = -1;
            for (int i = 0; i < sorted.length; i++) {
              final idx = (start + 1 + i) % sorted.length;
              final hasUnchecked = sorted[idx].items.any((it) => !_isCheckedItem(it));
              if (hasUnchecked) {
                next = idx;
                break;
              }
            }
            if (next == -1) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All done')));
              }
              return;
            }
            _lastAisleIndex = next;
            final key = _sectionKeys[sorted[next].aisle.value];
            if (key?.currentContext != null) {
              await Scrollable.ensureVisible(
                key!.currentContext!,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
              );
            }
          },
          child: const Icon(Icons.arrow_downward),
        );
      }(),
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
        // Price confirm sheet (log to history) then Pantry editor
        _maybeConfirmAndLogPrice(item);
        // Prompt to add to Pantry (non-blocking)
        final ingredient = item.ingredient;
        final qty = item.totalQty; // already in ingredient base unit
        // Only nudge once per line add
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          final res = await ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Add ${ingredient.name} to Pantry?'),
              action: SnackBarAction(
                label: 'Add',
                onPressed: () {},
              ),
              duration: const Duration(seconds: 3),
            ),
          );
          // If action tapped, open editor prefilled
          // Note: SnackBarAction onPressed cannot be awaited directly; open sheet regardless during duration if user pressed.
          // Workaround: open sheet immediately on showing with queued microtask if Add tapped is not capturable here.
        });
        // Open editor quickly with sensible defaults (non-blocking UX)
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (_) => PantryItemEditorSheet(
            prefillIngredient: ingredient,
            prefillQty: qty,
          ),
        ).then((_) {
          ref.invalidate(pantryItemsProvider);
        });
      }
    });
    _saveCheckedForPlan();
    // Keep compare totals in sync with checked state
    ref.invalidate(storeQuotesProvider);
  }

  Future<void> _maybeConfirmAndLogPrice(AggregatedShoppingItem item) async {
    final plan = ref.read(currentPlanProvider).asData?.value;
    final planId = plan?.id;
    String? preselectedStoreId;
    if (planId != null) {
      final mode = ref.read(splitModeProvider(planId)).value;
      final lineId = '${item.ingredient.id}|${item.unit.name}';
      if (mode == 'split') {
        final r = ref.read(splitResultProvider(planId)).value;
        preselectedStoreId = r?.assignments[lineId];
      }
    }
    preselectedStoreId ??= ref.read(selectedStoreProvider).value?.id;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ConfirmPriceSheet(
        ingredientItem: item,
        preselectedStoreId: preselectedStoreId,
      ),
    );
    // Invalidate price history for this ingredient so any panels/cards refresh
    ref.invalidate(priceHistoryByIngredientProvider(item.ingredient.id));
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
    required this.planId,
  });

  final String title;
  final List<AggregatedShoppingItem> items;
  final bool Function(AggregatedShoppingItem item) isChecked;
  final void Function(AggregatedShoppingItem item) toggleChecked;
  final String? planId;

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

              final lineId = '${it.ingredient.id}|${it.unit.name}';
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
                    if (planId != null) _SplitStoreBadge(planId: planId!, lineId: lineId),
                    // TODO: Future – attach quick price chips/sparkline here
                    PopupMenuButton<String>(
                      tooltip: 'More',
                      onSelected: (v) async {
                        if (v == 'sub') {
                          await showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            showDragHandle: true,
                            builder: (_) => _ShoppingSubstituteSheet(item: it),
                          );
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem<String>(value: 'sub', child: Text('Substitute ingredient…')),
                      ],
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

class _ConfirmPriceSheet extends ConsumerStatefulWidget {
  const _ConfirmPriceSheet({required this.ingredientItem, this.preselectedStoreId});
  final AggregatedShoppingItem ingredientItem;
  final String? preselectedStoreId;

  @override
  ConsumerState<_ConfirmPriceSheet> createState() => _ConfirmPriceSheetState();
}

class _ConfirmPriceSheetState extends ConsumerState<_ConfirmPriceSheet> {
  final _priceController = TextEditingController();
  final _qtyController = TextEditingController();
  ing.Unit _unit = ing.Unit.grams;
  String? _storeId;
  String? _note;
  String? _warning;

  @override
  void initState() {
    super.initState();
    final ingMeta = widget.ingredientItem.ingredient;
    final pack = ingMeta.purchasePack;
    _qtyController.text = (pack.qty > 0 ? pack.qty : 0).toStringAsFixed(0);
    _unit = pack.unit;
    _storeId = widget.preselectedStoreId;
  }

  @override
  Widget build(BuildContext context) {
    final ingMeta = widget.ingredientItem.ingredient;
    final storesAsync = ref.watch(storeProfilesProvider);
    final currency = NumberFormat.simpleCurrency();
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          top: 8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Confirm Price', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(ingMeta.name, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(labelText: 'Price paid (${currency.currencySymbol})'),
                    controller: _priceController,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Pack qty'),
                    controller: _qtyController,
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<ing.Unit>(
                  value: _unit,
                  onChanged: (v) => setState(() => _unit = v ?? _unit),
                  items: const [
                    DropdownMenuItem(value: ing.Unit.grams, child: Text('g')),
                    DropdownMenuItem(value: ing.Unit.milliliters, child: Text('ml')),
                    DropdownMenuItem(value: ing.Unit.piece, child: Text('pc')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            storesAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (stores) {
                final id = _storeId ?? (stores.isNotEmpty ? stores.first.id : null);
                _storeId = id;
                return Row(children: [
                  const Icon(Icons.store_mall_directory_outlined, size: 18),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _storeId,
                    onChanged: (v) => setState(() => _storeId = v),
                    items: [
                      for (final s in stores)
                        DropdownMenuItem<String>(
                          value: s.id,
                          child: Text('${s.emoji ?? '🏬'} ${s.name}'),
                        ),
                    ],
                  ),
                ]);
              },
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(labelText: 'Note (promo, club, clearance)'),
              onChanged: (v) => _note = v.trim().isEmpty ? null : v.trim(),
            ),
            if (_warning != null) ...[
              const SizedBox(height: 8),
              Text(_warning!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Skip'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () async {
                    final price = double.tryParse(_priceController.text.trim());
                    final qty = double.tryParse(_qtyController.text.trim());
                    if (price == null || price <= 0 || qty == null || qty <= 0 || _storeId == null) {
                      setState(() => _warning = 'Enter price, pack size, and store');
                      return;
                    }
                    final priceCents = (price * 100).round();
                    final ppu = ref.read(priceAnalyticsServiceProvider).computeCanonicalPpuCents(
                          priceCents: priceCents,
                          packQty: qty,
                          packUnit: _unit,
                          ingredient: ingMeta,
                        );
                    if (ppu == null) {
                      setState(() => _warning = 'Cannot compute PPU: unit conversion requires density or per-piece size');
                      return;
                    }
                    final p = PricePoint(
                      id: newPricePointId(),
                      ingredientId: ingMeta.id,
                      storeId: _storeId!,
                      priceCents: priceCents,
                      packQty: qty,
                      packUnit: _unit,
                      ppuCents: ppu,
                      at: DateTime.now(),
                      note: _note,
                    );
                    await ref.read(priceHistoryServiceProvider).add(p);
                    if (mounted) Navigator.of(context).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Inline substitute sheet for shopping row
class _ShoppingSubstituteSheet extends ConsumerWidget {
  const _ShoppingSubstituteSheet({required this.item});
  final AggregatedShoppingItem item;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ingsAsync = ref.watch(allIngredientsProvider);
    return ingsAsync.when(
      loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
      error: (e, _) => Padding(padding: const EdgeInsets.all(16), child: Text('Failed: $e')),
      data: (ings) {
        final byId = {for (final i in ings) i.id: i};
        return _SubSheetCore(
          sourceQty: item.totalQty,
          sourceUnit: item.unit,
          sourceIng: item.ingredient,
          ingredientById: byId,
          onApply: (candIng, candQty, candUnit, approx, deltaPerServCents) async {
            final plan = ref.read(currentPlanProvider).value;
            final shop = ref.read(shoppingListRepositoryProvider);
            final s = v1.ShortfallItem(
              ingredientId: candIng.id,
              name: candIng.name,
              missingQty: candQty,
              unit: candUnit,
              aisle: candIng.aisle,
            );
            await shop.addShortfalls([s], planId: plan?.id);
            ref.invalidate(shoppingListItemsProvider);
            if (context.mounted) Navigator.of(context).pop();
          },
        );
      },
    );
  }
}

class _SubSheetCore extends ConsumerWidget {
  const _SubSheetCore({required this.sourceQty, required this.sourceUnit, required this.sourceIng, required this.ingredientById, required this.onApply});
  final double sourceQty;
  final ing.Unit sourceUnit;
  final ing.Ingredient sourceIng;
  final Map<String, ing.Ingredient> ingredientById;
  final Future<void> Function(ing.Ingredient, double, ing.Unit, bool, int?) onApply;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(left: 16, right: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16, top: 8),
        child: FutureBuilder<List<_CandRow>>(
          future: _buildCandidates(ref),
          builder: (context, snap) {
            final rows = snap.data ?? const <_CandRow>[];
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Substitute • ${sourceIng.name}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                if (rows.isEmpty)
                  const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: Text('No sensible alternatives')))
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemBuilder: (_, i) {
                        final r = rows[i];
                        final qtyStr = _fmtQty(r.qty, r.unit);
                        final cheaper = r.deltaPerServCents != null && r.deltaPerServCents! < 0;
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [Expanded(child: Text(r.ing.name, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600))), FilledButton(onPressed: r.qty <= 0 || r.unit == null ? null : () async { await onApply(r.ing, r.qty, r.unit!, r.approx, r.deltaPerServCents); }, child: const Text('Replace'))]),
                              const SizedBox(height: 6),
                              Text('Use: $qtyStr'),
                              const SizedBox(height: 6),
                              Wrap(spacing: 6, children: [if (r.pantry) _chip(context, 'Pantry', Icons.kitchen), if (cheaper) _chip(context, 'Cheaper −\$${(-r.deltaPerServCents! / 100).toStringAsFixed(2)}/serv', Icons.savings), if (r.approx) _chip(context, '≈ Approx', Icons.info_outline)])
                            ]),
                          ),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemCount: rows.length,
                    ),
                  ),
                const SizedBox(height: 8),
                SizedBox(width: double.infinity, child: TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<List<_CandRow>> _buildCandidates(WidgetRef ref) async {
    final svc = ref.read(substitutionCostServiceProvider);
    final catSvc = ref.read(substitutionsServiceProvider);
    final cat = await catSvc.catalog();
    final pantry = await ref.read(allPantryItemsProvider.future);
    final onHand = {for (final p in pantry) p.ingredientId: p.qty};
    final all = ingredientById.values.toList();
    final list = <ing.Ingredient>[];
    final catIds = cat[sourceIng.id]?.map((c) => c.ingredientId).toSet() ?? const <String>{};
    for (final id in catIds) { final i = ingredientById[id]; if (i != null) list.add(i); }
    final per = sourceIng.per100; if (per != null) { final kcal = per.kcal; for (final i in all) { if (i.id == sourceIng.id) continue; if (i.aisle != sourceIng.aisle) continue; final p = i.per100; if (p == null || p.kcal <= 0) continue; final ratio = p.kcal / kcal; if (ratio >= 0.7 && ratio <= 1.3) list.add(i); } }
    final seen = <String>{}; final uniq = <ing.Ingredient>[]; for (final i in list) { if (seen.add(i.id)) uniq.add(i); }
    final rows = <_CandRow>[];
    for (final cand in uniq) {
      final res = SubstitutionMath.matchKcal(sourceQty: sourceQty, sourceUnit: sourceUnit, sourceIng: sourceIng, candIng: cand);
      if (res.qty == null || res.unit == null) { rows.add(_CandRow(ing: cand, qty: 0, unit: null, approx: true, pantry: (onHand[cand.id] ?? 0) > 0, deltaPerServCents: null)); continue; }
      final delta = await svc.deltaCentsPerServ(sourceIng: sourceIng, sourceQty: sourceQty, sourceUnit: sourceUnit, candIng: cand, candQtyBase: res.qty!);
      rows.add(_CandRow(ing: cand, qty: res.qty!, unit: res.unit, approx: res.approximate, pantry: (onHand[cand.id] ?? 0) > 0, deltaPerServCents: delta));
    }
    rows.sort((a, b) { final pa = a.pantry ? 1 : 0; final pb = b.pantry ? 1 : 0; if (pa != pb) return pb.compareTo(pa); final da = a.deltaPerServCents ?? 0; final db = b.deltaPerServCents ?? 0; if (da != db) return da.compareTo(db); return a.ing.name.compareTo(b.ing.name); });
    return rows;
  }

  String _fmtQty(double? q, ing.Unit? u) { if (q == null || u == null) return 'n/a'; final v = ((q * 10).round() / 10.0); final s = v % 1 == 0 ? v.toStringAsFixed(0) : v.toStringAsFixed(1); switch (u) { case ing.Unit.grams: return '$s g'; case ing.Unit.milliliters: return '$s ml'; case ing.Unit.piece: return '$s pc'; } }
  Widget _chip(BuildContext context, String label, IconData icon) { return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondaryContainer, borderRadius: BorderRadius.circular(999)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 12), const SizedBox(width: 4), Text(label, style: Theme.of(context).textTheme.labelSmall)])); }
}

class _CandRow { _CandRow({required this.ing, required this.qty, required this.unit, required this.approx, required this.pantry, required this.deltaPerServCents}); final ing.Ingredient ing; final double qty; final ing.Unit? unit; final bool approx; final bool pantry; final int? deltaPerServCents; }

class _StoreSwitcher extends StatelessWidget {
  const _StoreSwitcher({
    required this.profilesAsync,
    required this.selectedStoreAsync,
    required this.onChanged,
  });
  final AsyncValue<List<dynamic>> profilesAsync; // List<StoreProfile>
  final AsyncValue<dynamic> selectedStoreAsync; // StoreProfile?
  final Future<void> Function(String id) onChanged;

  @override
  Widget build(BuildContext context) {
    return profilesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, st) => const SizedBox.shrink(),
      data: (profiles) {
        final selected = selectedStoreAsync.value;
        final label = selected != null
            ? '${selected.emoji ?? '🏬'} ${selected.name}'
            : 'Default order';
        return PopupMenuButton<String>(
          tooltip: 'Select store',
          child: Row(
            children: [
              const Icon(Icons.store_mall_directory_outlined, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
          itemBuilder: (context) {
            final items = <PopupMenuEntry<String>>[];
            items.add(const PopupMenuItem<String>(
              value: '',
              child: Text('Default order'),
            ));
            for (final p in profiles) {
              items.add(
                PopupMenuItem<String>(
                  value: p.id,
                  child: Text('${p.emoji ?? '🏬'} ${p.name}'),
                ),
              );
            }
            return items;
          },
          onSelected: (id) async {
            if (id.isEmpty) {
              // Clear selection
              await onChanged('');
            } else {
              await onChanged(id);
            }
          },
        );
      },
    );
  }
}

class _TripTotalBar extends ConsumerWidget {
  const _TripTotalBar({required this.groups, required this.checked, required this.store});
  final List<ShoppingAisleGroup> groups;
  final Set<String> checked;
  final dynamic store; // StoreProfile?

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Flatten items; optionally exclude checked
    final flat = <({String ingredientId, double qty, ing.Unit unit})>[];
    for (final g in groups) {
      for (final it in g.items) {
        final key = '${it.ingredient.id}|${it.unit.name}';
        if (checked.contains(key)) continue; // pending to buy only
        flat.add((ingredientId: it.ingredient.id, qty: it.totalQty, unit: it.unit));
      }
    }

    if (flat.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Estimated Trip Total: \$0.00',
          style: Theme.of(context).textTheme.labelLarge,
        ),
      );
    }

    final ingById = <String, ing.Ingredient>{};
    for (final g in groups) {
      for (final it in g.items) {
        ingById[it.ingredient.id] = it.ingredient;
      }
    }

    return FutureBuilder<int>(
      future: ref.read(tripCostServiceProvider).computeTripTotalCents(
            items: flat,
            store: store,
            ingredientsById: ingById,
          ),
      builder: (context, snapshot) {
        final cents = snapshot.data ?? 0;
        final fmt = NumberFormat.currency(symbol: '\$');
        final totalStr = fmt.format(cents / 100);
        return Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Estimated Trip Total: $totalStr',
            style: Theme.of(context).textTheme.labelLarge,
          ),
        );
      },
    );
  }
}

class _CheapestStoreBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedAsync = ref.watch(selectedStoreProvider);
    final quotesAsync = ref.watch(storeQuotesProvider);

    return quotesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, st) => const SizedBox.shrink(),
      data: (quotes) {
        if (quotes.isEmpty) return const SizedBox.shrink();
        final selected = selectedAsync.value;
        final currentId = selected?.id; // null => baseline
        final current = quotes.firstWhere(
          (q) => q.storeId == currentId,
          orElse: () => quotes.firstWhere((q) => q.storeId == null, orElse: () => quotes.first),
        );
        final sorted = [...quotes]..sort((a, b) => a.totalCents.compareTo(b.totalCents));
        final cheapest = sorted.first;

        if (cheapest.totalCents >= current.totalCents || cheapest.storeId == currentId) {
          return const SizedBox.shrink();
        }

        final savings = current.totalCents - cheapest.totalCents;
        final fmt = NumberFormat.currency(symbol: '\$');
        return Card(
          color: Theme.of(context).colorScheme.surfaceVariant,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cheapest for this trip: ${cheapest.displayName}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Save ~${fmt.format(savings / 100)} vs current',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () async {
                    final svc = ref.read(storeProfileServiceProvider);
                    await svc.setSelected(cheapest.storeId ?? '');
                    ref.invalidate(selectedStoreProvider);
                    ref.invalidate(storeQuotesProvider);
                    ref.invalidate(shoppingListItemsProvider);
                  },
                  child: const Text('Switch'),
                ),
                TextButton(
                  onPressed: () => _showCompareStoresModal(context, ref),
                  child: const Text('Compare'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SplitHeaderAndTotals extends ConsumerWidget {
  const _SplitHeaderAndTotals({required this.checkedKeys});
  final Set<String> checkedKeys;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(currentPlanProvider).asData?.value;
    if (plan == null) return const SizedBox.shrink();

    final modeAsync = ref.watch(splitModeProvider(plan.id));
    final resultAsync = ref.watch(splitResultProvider(plan.id));
    final fmt = NumberFormat.currency(symbol: '\$');

    return Row(
      children: [
        modeAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (mode) {
            final isSplit = mode == 'split';
            return Row(
              children: [
                ChoiceChip(
                  label: const Text('Single store'),
                  selected: !isSplit,
                  onSelected: (v) async {
                    if (v) {
                      await ref.read(splitPrefsServiceProvider).setMode(plan.id, 'single');
                      ref.invalidate(splitModeProvider(plan.id));
                      ref.invalidate(splitResultProvider(plan.id));
                    }
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Split (up to 2)'),
                  selected: isSplit,
                  onSelected: (v) async {
                    if (v) {
                      await ref.read(splitPrefsServiceProvider).setMode(plan.id, 'split');
                      ref.invalidate(splitModeProvider(plan.id));
                      ref.invalidate(splitResultProvider(plan.id));
                    }
                  },
                ),
              ],
            );
          },
        ),
        const Spacer(),
        resultAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (r) {
            final combined = fmt.format(r.combinedTotalCents / 100);
            final savings = r.baselineSingleStoreCents - r.combinedTotalCents;
            final showSavings = savings > 0;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Combined: $combined', style: Theme.of(context).textTheme.labelLarge),
                if (showSavings)
                  Text(
                    'Save ${fmt.format(savings / 100)} vs single',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.tertiary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _SplitStoreBadge extends ConsumerWidget {
  const _SplitStoreBadge({required this.planId, required this.lineId});
  final String planId;
  final String lineId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultAsync = ref.watch(splitResultProvider(planId));
    final storesAsync = ref.watch(storeProfilesProvider);
    return resultAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (r) {
        final storeId = r.assignments[lineId];
        if (storeId == null) return const SizedBox.shrink();
        return storesAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (stores) {
            final sp = stores.firstWhere(
              (s) => s.id == storeId,
              orElse: () => stores.isNotEmpty ? stores.first : StoreProfile(id: 'x', name: 'Store', aisleOrder: const []),
            );
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${sp.emoji ?? '🏬'} ${sp.name}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSecondaryContainer,
                        ),
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Store options',
                  onSelected: (v) async {
                    if (v == 'lock') {
                      await _showLockSheet(context, ref, planId, lineId);
                    } else if (v == 'clear') {
                      await ref.read(splitPrefsServiceProvider).setLock(planId, lineId, null);
                      ref.invalidate(splitLocksProvider(planId));
                      ref.invalidate(splitResultProvider(planId));
                    }
                  },
                  itemBuilder: (ctx) => const [
                    PopupMenuItem<String>(value: 'lock', child: Text('Lock to store…')),
                    PopupMenuItem<String>(value: 'clear', child: Text('Clear lock')),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showLockSheet(BuildContext context, WidgetRef ref, String planId, String lineId) async {
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Consumer(builder: (context, ref, _) {
              final storesAsync = ref.watch(storeProfilesProvider);
              return storesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
                data: (stores) {
                  return ListView(
                    shrinkWrap: true,
                    children: [
                      const ListTile(title: Text('Lock this item to:')),
                      ...stores.map((s) => ListTile(
                            leading: const Icon(Icons.store_mall_directory_outlined),
                            title: Text('${s.emoji ?? '🏬'} ${s.name}'),
                            onTap: () async {
                              await ref.read(splitPrefsServiceProvider).setLock(planId, lineId, s.id);
                              ref.invalidate(splitLocksProvider(planId));
                              ref.invalidate(splitResultProvider(planId));
                              if (Navigator.of(context).canPop()) Navigator.of(context).pop();
                            },
                          )),
                      const SizedBox(height: 8),
                    ],
                  );
                },
              );
            }),
          ),
        );
      },
    );
  }
}

void _showCompareStoresModal(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Consumer(
            builder: (context, ref, _) {
              final selected = ref.watch(selectedStoreProvider).value;
              final quotesAsync = ref.watch(storeQuotesProvider);
              final fmt = NumberFormat.currency(symbol: '\$');
              return quotesAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, st) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Failed to load store quotes'),
                ),
                data: (quotes) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...quotes.map((q) {
                        final isSelected = (selected?.id ?? null) == q.storeId;
                        return ListTile(
                          leading: isSelected ? const Icon(Icons.check) : const SizedBox(width: 24),
                          title: Text(q.displayName),
                          trailing: Text(fmt.format(q.totalCents / 100)),
                          onTap: () async {
                            final svc = ref.read(storeProfileServiceProvider);
                            await svc.setSelected(q.storeId ?? '');
                            ref.invalidate(selectedStoreProvider);
                            ref.invalidate(storeQuotesProvider);
                            ref.invalidate(shoppingListItemsProvider);
                            if (Navigator.of(context).canPop()) Navigator.of(context).pop();
                          },
                        );
                      }),
                      const SizedBox(height: 8),
                      Text(
                        'Prices use store overrides when available; others use default pack prices.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  );
                },
              );
            },
          ),
        ),
      );
    },
  );
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

class _SimpleHeaderDelegate extends SliverPersistentHeaderDelegate {
  _SimpleHeaderDelegate({required this.minExtent, required this.maxExtent, required this.child});

  @override
  final double minExtent;
  @override
  final double maxExtent;
  final Widget child;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _SimpleHeaderDelegate oldDelegate) {
    return oldDelegate.maxExtent != maxExtent || oldDelegate.minExtent != minExtent || oldDelegate.child != child;
  }
}
