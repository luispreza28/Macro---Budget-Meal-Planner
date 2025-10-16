import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/ingredient.dart' as ing;
import '../../../domain/services/batch_session_service.dart';
import '../../../domain/services/unit_align.dart';
import '../../providers/batch_providers.dart';
import '../../providers/ingredient_providers.dart';
import '../../providers/recipe_providers.dart';
import '../../providers/database_providers.dart';
import '../../providers/route_providers.dart';
import '../../../domain/services/route_prefs_service.dart';
import '../../providers/store_providers.dart';
import '../../../domain/services/split_shopping_prefs.dart';

class BatchShoppingPage extends ConsumerStatefulWidget {
  const BatchShoppingPage({super.key, required this.sessionId});
  final String sessionId;

  @override
  ConsumerState<BatchShoppingPage> createState() => _BatchShoppingPageState();
}

class _BatchShoppingPageState extends ConsumerState<BatchShoppingPage> {
  Set<String> _checked = <String>{};
  late final String _scopeId; // for prefs scoping, reuse route/split prefs via batch.<id>
  Map<String, String> _locks = <String, String>{};

  @override
  void initState() {
    super.initState();
    _scopeId = 'batch.${widget.sessionId}';
    _loadChecked();
    _loadLocks();
  }

  Future<void> _loadChecked() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final key = 'batch.checked.${widget.sessionId}.v1';
    final raw = prefs.getString(key);
    if (raw == null) return;
    try {
      final list = (jsonDecode(raw) as List).cast<String>();
      setState(() => _checked = list.toSet());
    } catch (_) {}
  }

  Future<void> _saveChecked() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final key = 'batch.checked.${widget.sessionId}.v1';
    await prefs.setString(key, jsonEncode(_checked.toList()));
  }

  Future<void> _loadLocks() async {
    final m = await ref.read(splitPrefsServiceProvider).locks(_scopeId);
    if (!mounted) return;
    setState(() => _locks = m);
  }

  @override
  Widget build(BuildContext context) {
    final sessAsync = ref.watch(batchSessionByIdProvider(widget.sessionId));
    final recipesAsync = ref.watch(allRecipesProvider);
    final ingsAsync = ref.watch(allIngredientsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Shopping'),
        actions: [
          IconButton(
            tooltip: 'Clear checked',
            onPressed: _checked.isEmpty
                ? null
                : () async {
                    setState(() => _checked.clear());
                    await _saveChecked();
                  },
            icon: const Icon(Icons.checklist_rtl_outlined),
          ),
          PopupMenuButton<String>(
            tooltip: 'Route',
            onSelected: (v) async {
              if (v == 'instore') {
                await ref.read(routePrefsServiceProvider).setMode(_scopeId, 'instore');
              } else if (v == 'normal') {
                await ref.read(routePrefsServiceProvider).setMode(_scopeId, 'normal');
              } else if (v == 'unchecked') {
                final cur = await ref.read(routePrefsServiceProvider).uncheckedOnly(_scopeId);
                await ref.read(routePrefsServiceProvider).setUncheckedOnly(_scopeId, !cur);
              } else if (v == 'split1') {
                await ref.read(splitPrefsServiceProvider).setMode(_scopeId, 'single');
                await ref.read(splitPrefsServiceProvider).setCap(_scopeId, 1);
              } else if (v == 'split2') {
                await ref.read(splitPrefsServiceProvider).setMode(_scopeId, 'split');
                await ref.read(splitPrefsServiceProvider).setCap(_scopeId, 2);
              }
              setState(() {});
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'instore', child: Text('In-store mode')),
              PopupMenuItem(value: 'normal', child: Text('Normal mode')),
              PopupMenuItem(value: 'unchecked', child: Text('Toggle unchecked-only')),
              PopupMenuItem(value: 'split1', child: Text('Single store')),
              PopupMenuItem(value: 'split2', child: Text('Split (up to 2 stores)')),
            ],
          ),
        ],
      ),
      body: sessAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (sess) {
          if (sess == null) return const Center(child: Text('Not found'));
          return recipesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Failed: $e')),
            data: (recipes) {
              return ingsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Failed: $e')),
                data: (ings) {
                  final byR = {for (final r in recipes) r.id: r};
                  final byI = {for (final i in ings) i.id: i};
                  final groups = _aggregate(sess, byR, byI);

                  // Route prefs
                  final modeAsync = ref.watch(instoreModeProvider(_scopeId));
                  final uncheckedOnlyAsync = ref.watch(showUncheckedOnlyProvider(_scopeId));
                  final collapsedAsync = ref.watch(collapsedSectionsProvider(_scopeId));
                  final orderAsync = ref.watch(routeAisleOrderProvider);

                  final mode = modeAsync.value ?? 'normal';
                  final isInstore = mode == 'instore';
                  final uncheckedOnly = uncheckedOnlyAsync.value ?? false;
                  final collapsed = collapsedAsync.value ?? <String>{};
                  final order = orderAsync.value ?? ing.Aisle.values.map((a) => a.value).toList();

                  // Split shopping summary (optional cost view) using scopeId and locks
                  final split = _computeSplit(groups, byI);

                  // Sort by aisle order
                  final sorted = [...groups];
                  int idxOf(ing.Aisle a) {
                    final i = order.indexOf(a.value);
                    return i < 0 ? 999 : i;
                  }
                  sorted.sort((a, b) => idxOf(a.aisle).compareTo(idxOf(b.aisle)));

                  // Apply unchecked filter
                  final visible = <_AisleGroup>[];
                  for (final g in sorted) {
                    final items = isInstore && uncheckedOnly ? g.items.where((it) => !_isChecked(it)).toList() : g.items;
                    if (items.isNotEmpty) visible.add(_AisleGroup(aisle: g.aisle, items: items));
                  }

                  return Column(
                    children: [
                      Expanded(
                        child: visible.isEmpty
                            ? const Center(child: Text('No items'))
                            : ListView.builder(
                                itemCount: visible.length,
                                itemBuilder: (context, i) {
                                  final g = visible[i];
                                  final isCollapsed = collapsed.contains(g.aisle.value);
                                  return Card(
                                    child: ExpansionTile(
                                      initiallyExpanded: !isCollapsed,
                                      onExpansionChanged: (v) async {
                                        final c = {...collapsed};
                                        if (v) {
                                          c.remove(g.aisle.value);
                                        } else {
                                          c.add(g.aisle.value);
                                        }
                                        await ref.read(routePrefsServiceProvider).setCollapsed(_scopeId, c);
                                        setState(() {});
                                      },
                                      title: Text(_aisleLabel(g.aisle)),
                                      children: [
                                        for (final it in g.items)
                                          CheckboxListTile(
                                            value: _isChecked(it),
                                            onChanged: (v) async {
                                              setState(() {
                                                if (v == true) {
                                                  _checked.add(it.id);
                                                } else {
                                                  _checked.remove(it.id);
                                                }
                                              });
                                              await _saveChecked();
                                            },
                                            title: Text(it.ingredient.name),
                                            subtitle: Text('${it.totalQty.toStringAsFixed(2)} ${it.unit.value}'),
                                            secondary: IconButton(
                                              tooltip: _locks.containsKey(it.id)
                                                  ? 'Unlock (clear lock)'
                                                  : 'Lock to selected store',
                                              icon: Icon(_locks.containsKey(it.id)
                                                  ? Icons.lock
                                                  : Icons.lock_open_outlined),
                                              onPressed: () async {
                                                final store = await ref.read(selectedStoreProvider.future);
                                                if (store == null) return;
                                                if (_locks.containsKey(it.id)) {
                                                  await ref.read(splitPrefsServiceProvider).setLock(_scopeId, it.id, null);
                                                } else {
                                                  await ref.read(splitPrefsServiceProvider).setLock(_scopeId, it.id, store.id);
                                                }
                                                await _loadLocks();
                                              },
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: FilledButton.icon(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.check),
                            label: const Text('Mark Purchased'),
                          ),
                        ),
                      )
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  bool _isChecked(_AggItem it) => _checked.contains(it.id);

  List<_AisleGroup> _aggregate(BatchSession s, Map<String, dynamic> recipesById, Map<String, ing.Ingredient> ingsById) {
    final Map<String, Map<ing.Unit, double>> totals = {};
    for (final item in s.items) {
      final r = recipesById[item.recipeId] as dynamic?;
      if (r == null) continue;
      if (r.items == null) continue;
      final factor = item.targetServings / (r.servings as int);
      for (final ri in r.items as List) {
        final ingId = (ri.ingredientId as String);
        final qty = (ri.qty as num).toDouble() * factor;
        final unit = ri.unit as ing.Unit;
        final meta = ingsById[ingId];
        if (meta == null) continue;
        final qtyBase = alignQty(qty: qty, from: unit, to: meta.unit, ing: meta);
        if (qtyBase == null) continue; // warn/skip if unresolved
        final byUnit = totals.putIfAbsent(ingId, () => {});
        byUnit[meta.unit] = (byUnit[meta.unit] ?? 0) + qtyBase;
      }
    }
    final items = <_AggItem>[];
    totals.forEach((ingId, map) {
      final meta = ingsById[ingId]!;
      map.forEach((unit, qty) {
        items.add(_AggItem(
          id: '$ingId|${unit.name}',
          ingredient: meta,
          totalQty: qty,
          unit: unit,
        ));
      });
    });
    // group by aisle
    final byAisle = <ing.Aisle, List<_AggItem>>{};
    for (final it in items) {
      byAisle.putIfAbsent(it.ingredient.aisle, () => []).add(it);
    }
    final groups = byAisle.entries
        .map((e) => _AisleGroup(aisle: e.key, items: e.value..sort((a, b) => a.ingredient.name.compareTo(b.ingredient.name))))
        .toList();
    return groups;
  }

  // Split computation intentionally omitted in v1 for batch scope (UI supports route prefs only).

  String _aisleLabel(ing.Aisle a) => a.value[0].toUpperCase() + a.value.substring(1);
}

class _AggItem {
  _AggItem({required this.id, required this.ingredient, required this.totalQty, required this.unit});
  final String id;
  final ing.Ingredient ingredient;
  final double totalQty;
  final ing.Unit unit;
}

class _AisleGroup {
  _AisleGroup({required this.aisle, required this.items});
  final ing.Aisle aisle;
  final List<_AggItem> items;
}
