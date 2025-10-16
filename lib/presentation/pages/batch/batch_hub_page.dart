import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../domain/services/batch_session_service.dart';
import '../../providers/batch_providers.dart';
import '../../router/app_router.dart';
import 'batch_session_editor_sheet.dart';

class BatchHubPage extends ConsumerWidget {
  const BatchHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(batchSessionsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Batch Cook Planner')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await showModalBottomSheet<BatchSession>(
            context: context,
            isScrollControlled: true,
            builder: (_) => const BatchSessionEditorSheet(),
          );
          if (created != null) {
            ref.invalidate(batchSessionsProvider);
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('New Session'),
      ),
      body: sessionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No sessions yet. Tap New Session to start.'),
              ),
            );
          }
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, i) {
              final s = list[i];
              final date = DateFormat('yyyy-MM-dd').format(s.cookDate);
              final chips = <Widget>[];
              if (s.finished) {
                chips.add(const Chip(label: Text('Finished')));
              } else if (s.started) {
                chips.add(const Chip(label: Text('In Progress')));
              } else if (s.shoppingGenerated) {
                chips.add(const Chip(label: Text('Shopping')));
              } else {
                chips.add(const Chip(label: Text('Not started')));
              }
              chips.add(Chip(label: Text('${s.items.length} recipes')));

              final totalServings = s.items.fold<int>(0, (a, b) => a + b.targetServings);
              chips.add(Chip(label: Text('$totalServings servings')));

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(s.name),
                  subtitle: Wrap(spacing: 6, runSpacing: 6, children: [
                    Text('Cook: $date'),
                    ...chips,
                  ]),
                  onTap: () => context.push('${AppRouter.batch}/' + s.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

