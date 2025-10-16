import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/services/sub_rules_service.dart';
import '../../providers/ingredient_providers.dart';
import '../../providers/sub_rules_providers.dart';
import 'sub_rule_editor_sheet.dart';

class SubRulesPage extends ConsumerWidget {
  const SubRulesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesAsync = ref.watch(subRulesProvider);
    final ingredientsAsync = ref.watch(allIngredientsProvider);
    final ingById = {for (final i in (ingredientsAsync.value ?? const [])) i.id: i};

    return Scaffold(
      appBar: AppBar(title: const Text('Substitution Rules')),
      body: rulesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Failed to load rules: $e')),
        data: (rules) {
          if (rules.isEmpty) {
            return const Center(child: Text('No rules yet. Tap + to add.'));
          }
          final controller = ReorderableListView.builder(
            itemCount: rules.length,
            onReorder: (oldIndex, newIndex) async {
              final xs = [...rules];
              if (newIndex > oldIndex) newIndex -= 1;
              final item = xs.removeAt(oldIndex);
              xs.insert(newIndex, item);
              // Update priorities based on new order
              final updated = <SubRule>[];
              for (int i = 0; i < xs.length; i++) {
                updated.add(SubRule(
                  id: xs[i].id,
                  action: xs[i].action,
                  from: xs[i].from,
                  to: xs[i].to,
                  scopeTags: xs[i].scopeTags,
                  maxPpuCents: xs[i].maxPpuCents,
                  priority: i,
                  enabled: xs[i].enabled,
                ));
              }
              await ref.read(subRulesServiceProvider).saveAll(updated);
              ref.invalidate(subRulesProvider);
              ref.invalidate(subRulesIndexProvider);
            },
            itemBuilder: (context, index) {
              final r = rules[index];
              String fromLabel = r.from.kind == 'ingredient'
                  ? (ingById[r.from.value]?.name ?? r.from.value)
                  : (r.from.kind == 'tag' ? '#${r.from.value}' : 'Any');
              String toLabel = r.to == null
                  ? ''
                  : (r.to!.kind == 'ingredient'
                      ? (ingById[r.to!.value]?.name ?? r.to!.value)
                      : '#${r.to!.value}');
              final actionColor = switch (r.action) {
                SubAction.always => Colors.blue,
                SubAction.prefer => Colors.green,
                SubAction.never => Colors.red,
              };
              return Card(
                key: ValueKey(r.id),
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: Icon(Icons.drag_handle),
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: actionColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(r.action.name.toUpperCase(), style: TextStyle(color: actionColor)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          r.action == SubAction.never ? fromLabel : '$fromLabel → $toLabel',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (r.scopeTags.isEmpty)
                        Chip(label: const Text('Any'), visualDensity: VisualDensity.compact()),
                      ...r.scopeTags.map((t) => Chip(label: Text(t), visualDensity: VisualDensity.compact())),
                      if (r.maxPpuCents != null)
                        Chip(label: Text('≤ \$${(r.maxPpuCents! / 100).toStringAsFixed(2)} / unit'), visualDensity: VisualDensity.compact()),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: r.enabled,
                        onChanged: (v) async {
                          await ref.read(subRulesServiceProvider).upsert(SubRule(
                                id: r.id,
                                action: r.action,
                                from: r.from,
                                to: r.to,
                                scopeTags: r.scopeTags,
                                maxPpuCents: r.maxPpuCents,
                                priority: r.priority,
                                enabled: v,
                              ));
                          ref.invalidate(subRulesProvider);
                          ref.invalidate(subRulesIndexProvider);
                        },
                      ),
                      PopupMenuButton<String>(
                        onSelected: (v) async {
                          if (v == 'edit') {
                            await showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (_) => SubRuleEditorSheet(initial: r),
                            );
                            ref.invalidate(subRulesProvider);
                            ref.invalidate(subRulesIndexProvider);
                          } else if (v == 'dup') {
                            final copy = SubRule(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              action: r.action,
                              from: r.from,
                              to: r.to,
                              scopeTags: r.scopeTags,
                              maxPpuCents: r.maxPpuCents,
                              priority: r.priority + 1,
                              enabled: r.enabled,
                            );
                            await ref.read(subRulesServiceProvider).upsert(copy);
                            ref.invalidate(subRulesProvider);
                            ref.invalidate(subRulesIndexProvider);
                          } else if (v == 'del') {
                            await ref.read(subRulesServiceProvider).remove(r.id);
                            ref.invalidate(subRulesProvider);
                            ref.invalidate(subRulesIndexProvider);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Edit')),
                          PopupMenuItem(value: 'dup', child: Text('Duplicate')),
                          PopupMenuItem(value: 'del', child: Text('Delete')),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
          return controller;
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => const SubRuleEditorSheet(),
          );
          ref.invalidate(subRulesProvider);
          ref.invalidate(subRulesIndexProvider);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

