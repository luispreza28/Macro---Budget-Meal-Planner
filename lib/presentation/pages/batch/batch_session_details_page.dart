import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/entities/recipe.dart';
import '../../../domain/services/batch_session_service.dart';
import '../../../domain/services/cooked_expiry_heuristics.dart';
import '../../../domain/services/leftovers_inventory_service.dart';
import '../../providers/batch_providers.dart';
import '../../providers/recipe_providers.dart';
import '../batch/batch_cook_checklist_sheet.dart';
import 'batch_shopping_page.dart';

class BatchSessionDetailsPage extends ConsumerWidget {
  const BatchSessionDetailsPage({super.key, required this.sessionId});
  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessAsync = ref.watch(batchSessionByIdProvider(sessionId));
    final recipesAsync = ref.watch(allRecipesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Batch Session'),
        actions: [
          IconButton(
            tooltip: 'Edit name/date',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final sess = ref.read(batchSessionByIdProvider(sessionId)).asData?.value;
              if (sess == null) return;
              final nameCtrl = TextEditingController(text: sess.name);
              final newName = await showDialog<String>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Edit name'),
                  content: TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    FilledButton(onPressed: () => Navigator.pop(context, nameCtrl.text.trim()), child: const Text('Save')),
                  ],
                ),
              );
              if (newName != null && newName.isNotEmpty) {
                await ref.read(batchSessionServiceProvider).upsert(sess.copyWith(name: newName));
              }
              final d = await showDatePicker(
                context: context,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                initialDate: sess.cookDate,
              );
              if (d != null) {
                await ref.read(batchSessionServiceProvider).upsert(sess.copyWith(cookDate: d));
              }
              ref.invalidate(batchSessionsProvider);
              ref.invalidate(batchSessionByIdProvider(sessionId));
            },
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline),
            onPressed: sessAsync.asData?.value == null
                ? null
                : () async {
                    final ok = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Delete session?'),
                            content: const Text('This will remove the session. Portions already created remain.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                              FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                            ],
                          ),
                        ) ??
                        false;
                    if (!ok) return;
                    await ref.read(batchSessionServiceProvider).remove(sessionId);
                    if (context.mounted) context.pop();
                    ref.invalidate(batchSessionsProvider);
                  },
          ),
        ],
      ),
      body: sessAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (sess) {
          if (sess == null) return const Center(child: Text('Not found'));
          final costAsync = ref.watch(batchSessionCostCentsProvider(sess));
          final dateStr = DateFormat('yyyy-MM-dd').format(sess.cookDate);

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(sess.name, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        Chip(label: Text('Cook: $dateStr')),
                        if (sess.finished)
                          const Chip(label: Text('Finished'))
                        else if (sess.started)
                          const Chip(label: Text('In Progress'))
                        else if (sess.shoppingGenerated)
                          const Chip(label: Text('Shopping ready'))
                        else
                          const Chip(label: Text('Not started')),
                        Chip(label: Text('${sess.items.length} recipes')),
                      ]),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () async {
                                // Mark generated and open shopping page
                                await ref.read(batchSessionServiceProvider).upsert(sess.copyWith(shoppingGenerated: true));
                                ref.invalidate(batchSessionsProvider);
                                if (context.mounted) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => BatchShoppingPage(sessionId: sessionId)),
                                  );
                                }
                              },
                              icon: const Icon(Icons.shopping_cart_outlined),
                              label: const Text('Generate Shopping'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton.tonalIcon(
                              onPressed: () async {
                                // Start cook by opening first item's checklist if exists
                                if (sess.items.isEmpty) return;
                                await showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  builder: (_) => BatchCookChecklistSheet(sessionId: sessionId, item: sess.items.first),
                                );
                              },
                              icon: const Icon(Icons.timer_outlined),
                              label: const Text('Start Cook'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: sess.finished
                            ? null
                            : () async {
                                await _finishSession(context, ref, sess);
                                ref.invalidate(batchSessionsProvider);
                                ref.invalidate(batchSessionByIdProvider(sessionId));
                              },
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Finish Session'),
                      ),
                      const SizedBox(height: 8),
                      costAsync.maybeWhen(
                        data: (cents) => Text('Estimated cost: \$${(cents / 100).toStringAsFixed(2)}'),
                        orElse: () => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recipes', style: Theme.of(context).textTheme.titleMedium),
                  TextButton.icon(
                    onPressed: () async {
                      await _exportLabels(context, ref, sess);
                    },
                    icon: const Icon(Icons.ios_share),
                    label: const Text('Export Labels'),
                  )
                ],
              ),
              const SizedBox(height: 4),
              recipesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, st) => Text('Failed to load recipes: $e'),
                data: (recipes) {
                  final byId = {for (final r in recipes) r.id: r};
                  return Column(
                    children: [
                      for (final it in sess.items)
                        Card(
                          child: ListTile(
                            title: Text(byId[it.recipeId]?.name ?? it.recipeId),
                            subtitle: Text('Servings: ${it.targetServings} · Portions: ${it.portions}${it.labelNote == null ? '' : ' · Note: ${it.labelNote}'}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.checklist_rtl_outlined),
                              onPressed: () async {
                                await showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  builder: (_) => BatchCookChecklistSheet(sessionId: sessionId, item: it),
                                );
                              },
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _finishSession(BuildContext context, WidgetRef ref, BatchSession sess) async {
    // Create PreparedPortion entries: 1 serving per portion; if portions=0 use targetServings
    final leftovers = ref.read(leftoversInventoryServiceProvider);
    final now = DateTime.now();
    final preparedAt = DateUtils.isSameDay(now, sess.cookDate) ? now : sess.cookDate;
    final expiresAt = preparedAt.add(Duration(days: CookedExpiryHeuristics.cookedShelfDays()));
    for (final item in sess.items) {
      final servingsToPortion = (item.portions > 0 ? item.portions : item.targetServings).clamp(0, 1000000);
      for (var i = 0; i < servingsToPortion; i++) {
        await leftovers.upsert(PreparedPortion(
          id: const Uuid().v4(),
          recipeId: item.recipeId,
          servingsRemaining: 1,
          preparedAt: preparedAt,
          expiresAt: expiresAt,
        ));
      }
    }
    await ref.read(batchSessionServiceProvider).upsert(sess.copyWith(finished: true));
    if (kDebugMode) {
      debugPrint('[Batch] finish created portions for ${sess.items.length} recipes');
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session finished. Portions created.')));
    }
  }

  Future<void> _exportLabels(BuildContext context, WidgetRef ref, BatchSession sess) async {
    final recipes = await ref.read(allRecipesProvider.future);
    final byId = {for (final r in recipes) r.id: r};
    final now = DateTime.now();
    final preparedAt = DateUtils.isSameDay(now, sess.cookDate) ? now : sess.cookDate;
    final expiresAt = preparedAt.add(Duration(days: CookedExpiryHeuristics.cookedShelfDays()));
    final dateFmt = DateFormat('yyyy-MM-dd');

    final rows = <List<String>>[];
    for (final it in sess.items) {
      final servingsToPortion = (it.portions > 0 ? it.portions : it.targetServings).clamp(0, 1000000);
      final name = byId[it.recipeId]?.name ?? it.recipeId;
      for (var i = 0; i < servingsToPortion; i++) {
        rows.add([
          name,
          dateFmt.format(preparedAt),
          dateFmt.format(expiresAt),
          '1',
          it.labelNote ?? '',
        ]);
      }
    }
    final header = ['Recipe Name', 'Prepared At', 'Expires At', 'Servings', 'Note'];
    final csv = StringBuffer()
      ..writeln(header.join(','));
    for (final r in rows) {
      csv.writeln(r.map((e) => '"${e.replaceAll('"', '""')}"').join(','));
    }

    try {
      final dir = await getTemporaryDirectory();
      final f = File('${dir.path}/batch_labels_${sess.id}.csv');
      await f.writeAsString(csv.toString());
      await Share.shareXFiles([XFile(f.path)], text: 'Batch labels for ${sess.name}');
    } catch (e) {
      await Share.share(csv.toString(), subject: 'Batch labels for ${sess.name}');
    }
  }
}
