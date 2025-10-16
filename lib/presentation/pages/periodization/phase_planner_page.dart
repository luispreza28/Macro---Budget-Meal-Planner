import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/services/periodization_service.dart';
import '../../providers/periodization_providers.dart';
import 'phase_editor_sheet.dart';

class PhasePlannerPage extends ConsumerWidget {
  const PhasePlannerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phasesAsync = ref.watch(phasesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Macros Periodization')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New Phase'),
        onPressed: () async {
          final created = await showModalBottomSheet<Phase?>(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            builder: (_) => PhaseEditorSheet(
              initial: null,
            ),
          );
          if (created != null) {
            await ref.read(periodizationServiceProvider).upsert(created);
            ref.invalidate(phasesProvider);
          }
        },
      ),
      body: phasesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Failed to load phases')),
        data: (phases) {
          final now = DateTime.now();
          final activeUpcoming = phases.where((p) => !p.end.isBefore(DateTime(now.year, now.month, now.day))).toList();
          final past = phases.where((p) => p.end.isBefore(DateTime(now.year, now.month, now.day))).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
            children: [
              Text('Active / Upcoming', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (activeUpcoming.isEmpty)
                const Text('No active or upcoming phases'),
              ...activeUpcoming.map((p) => _PhaseCard(phase: p)),
              const SizedBox(height: 16),
              _PastSection(phases: past),
            ],
          );
        },
      ),
    );
  }
}

class _PastSection extends StatefulWidget {
  const _PastSection({required this.phases});
  final List<Phase> phases;
  @override
  State<_PastSection> createState() => _PastSectionState();
}

class _PastSectionState extends State<_PastSection> {
  bool _expanded = false;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Past', style: Theme.of(context).textTheme.titleMedium),
            ),
            IconButton(
              icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () => setState(() => _expanded = !_expanded),
            )
          ],
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: _expanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: Column(children: widget.phases.map((p) => _PhaseCard(phase: p)).toList()),
          secondChild: const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _PhaseCard extends ConsumerWidget {
  const _PhaseCard({required this.phase});
  final Phase phase;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = DateFormat.MMMd();
    final now = DateTime.now();
    final isActive = phase.contains(now);
    final chip = switch (phase.type) {
      PhaseType.cut => const Chip(label: Text('CUT')),
      PhaseType.maintain => const Chip(label: Text('MAINTAIN')),
      PhaseType.bulk => const Chip(label: Text('BULK')),
    };
    return Card(
      child: ListTile(
        leading: chip,
        title: Text('${fmt.format(phase.start)} → ${fmt.format(phase.end)}'),
        subtitle: phase.note == null || phase.note!.isEmpty ? null : Text(phase.note!),
        trailing: PopupMenuButton<String>(
          onSelected: (v) async {
            switch (v) {
              case 'edit':
                final updated = await showModalBottomSheet<Phase?>(
                  context: context,
                  isScrollControlled: true,
                  showDragHandle: true,
                  builder: (_) => PhaseEditorSheet(initial: phase),
                );
                if (updated != null) {
                  await ref.read(periodizationServiceProvider).upsert(updated);
                  ref.invalidate(phasesProvider);
                }
                break;
              case 'delete':
                await ref.read(periodizationServiceProvider).remove(phase.id);
                ref.invalidate(phasesProvider);
                break;
              case 'duplicate':
                final dup = Phase(
                  id: const Uuid().v4(),
                  type: phase.type,
                  start: phase.start,
                  end: phase.end,
                  note: phase.note,
                );
                await ref.read(periodizationServiceProvider).upsert(dup);
                ref.invalidate(phasesProvider);
                break;
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
            PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
          ],
        ),
        isThreeLine: phase.note != null && phase.note!.isNotEmpty,
        selected: isActive,
      ),
    );
  }
}

