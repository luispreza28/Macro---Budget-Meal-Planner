import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/multiweek_providers.dart';
import '../../router/app_router.dart';
import 'calendar_export_sheet.dart';

class MultiweekSeriesPage extends ConsumerWidget {
  final String seriesId;
  const MultiweekSeriesPage({super.key, required this.seriesId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(multiweekSeriesByIdProvider(seriesId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan Series'),
        actions: [
          IconButton(
            onPressed: () async {
              final s = async.asData?.value;
              if (s == null) return;
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
                await ref.read(multiweekSeriesServiceProvider).upsert(s.copyWith(name: name));
                ref.invalidate(multiweekSeriesByIdProvider);
                ref.invalidate(multiweekSeriesListProvider);
              }
            },
            icon: const Icon(Icons.edit),
            tooltip: 'Rename',
          )
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (s) {
          if (s == null) return const Center(child: Text('Not found'));
          final fmt = DateFormat('MMM d');
          final start = s.week0Start;
          final end = s.week0Start.add(Duration(days: 7 * s.weeks - 1));
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.name, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text('${fmt.format(start)} - ${fmt.format(end)}', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              SizedBox(
                height: 56,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  scrollDirection: Axis.horizontal,
                  itemCount: s.weeks,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final wkStart = s.week0Start.add(Duration(days: i * 7));
                    final label = 'Week ${i + 1}\n${fmt.format(wkStart)}';
                    return InputChip(
                      label: Text(label, textAlign: TextAlign.center),
                      onPressed: () {},
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: s.planIds.length,
                  itemBuilder: (context, i) {
                    final id = s.planIds[i];
                    final wkStart = s.week0Start.add(Duration(days: i * 7));
                    final wkEnd = wkStart.add(const Duration(days: 6));
                    return ListTile(
                      title: Text('Week ${i + 1} • ${fmt.format(wkStart)} - ${fmt.format(wkEnd)}'),
                      subtitle: Text(id),
                      trailing: Wrap(spacing: 8, children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Open Week'),
                          onPressed: () {
                            context.go('${AppRouter.plan}?id=$id');
                          },
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.event),
                          label: const Text('Export'),
                          onPressed: () async {
                            await showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              builder: (_) => CalendarExportSheet(seriesId: s.id, selectedWeekIndex: i),
                            );
                          },
                        ),
                      ]),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.event_available),
                    label: const Text('Export All Weeks'),
                    onPressed: () async {
                      await showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => CalendarExportSheet(seriesId: s.id, selectedWeekIndex: null),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

