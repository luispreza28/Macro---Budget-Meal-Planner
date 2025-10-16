import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../domain/services/multiweek_series_service.dart';
import '../../providers/multiweek_providers.dart';
import 'multiweek_create_sheet.dart';
import 'multiweek_series_page.dart';

class MultiweekHubPage extends ConsumerWidget {
  const MultiweekHubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seriesAsync = ref.watch(multiweekSeriesListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Multi-Week Planning')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final id = await showModalBottomSheet<String>(
            context: context,
            isScrollControlled: true,
            builder: (_) => const MultiweekCreateSheet(),
          );
          if (id != null && id.isNotEmpty && context.mounted) {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => MultiweekSeriesPage(seriesId: id),
            ));
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('New Multi-Week'),
      ),
      body: seriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (xs) {
          if (xs.isEmpty) {
            return const Center(
              child: Text('No series yet. Tap + to create.'),
            );
          }
          return ListView.separated(
            itemCount: xs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final s = xs[i];
              final start = s.week0Start;
              final end = s.week0Start.add(Duration(days: 7 * s.weeks - 1));
              final fmt = DateFormat('MMM d');
              return ListTile(
                title: Text(s.name),
                subtitle: Text('${fmt.format(start)} - ${fmt.format(end)}'),
                trailing: Wrap(spacing: 8, children: [
                  Chip(label: Text('${s.weeks} weeks')),
                  PopupMenuButton<String>(
                    onSelected: (v) async {
                      switch (v) {
                        case 'rename':
                          final c = TextEditingController(text: s.name);
                          final name = await showDialog<String>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Rename series'),
                              content: TextField(controller: c),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                TextButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('Save')),
                              ],
                            ),
                          );
                          if (name != null && name.isNotEmpty) {
                            final updated = s.copyWith(name: name);
                            await ref.read(multiweekSeriesServiceProvider).upsert(updated);
                            ref.invalidate(multiweekSeriesListProvider);
                          }
                          break;
                        case 'delete':
                          await ref.read(multiweekSeriesServiceProvider).remove(s.id);
                          ref.invalidate(multiweekSeriesListProvider);
                          break;
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'rename', child: Text('Rename')),
                      PopupMenuItem(value: 'delete', child: Text('Delete series')),
                    ],
                  ),
                ]),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => MultiweekSeriesPage(seriesId: s.id),
                  ));
                },
              );
            },
          );
        },
      ),
    );
  }
}


