import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../domain/services/offline_center.dart';

class QueuedActionsPage extends ConsumerWidget {
  const QueuedActionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(offlineTasksProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Queued Actions')),
      body: tasksAsync.when(
        data: (tasks) {
          if (tasks.isEmpty) {
            return const Center(child: Text('No queued actions'));
          }
          // Group by type
          final groups = <OfflineTaskType, List<OfflineTask>>{};
          for (final t in tasks) {
            groups.putIfAbsent(t.type, () => []).add(t);
          }
          final typeOrder = OfflineTaskType.values;
          return ListView(
            children: [
              for (final type in typeOrder)
                if (groups.containsKey(type)) ...[
                  _SectionHeader(title: _typeLabel(type), icon: _typeIcon(type)),
                  for (final t in groups[type]!) _TaskTile(task: t),
                  const Divider(height: 1),
                ],
              const SizedBox(height: 24),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: _ActionsFab(),
    );
  }

  static String _typeLabel(OfflineTaskType t) {
    switch (t) {
      case OfflineTaskType.priceHistoryPush:
        return 'Price Updates';
      case OfflineTaskType.feedbackUpload:
        return 'Feedback Uploads';
      case OfflineTaskType.templatePublish:
        return 'Template Publishes';
      case OfflineTaskType.cloudDeltaPush:
        return 'Cloud Deltas';
    }
  }

  static IconData _typeIcon(OfflineTaskType t) {
    switch (t) {
      case OfflineTaskType.priceHistoryPush:
        return Icons.attach_money;
      case OfflineTaskType.feedbackUpload:
        return Icons.cloud_upload;
      case OfflineTaskType.templatePublish:
        return Icons.ios_share;
      case OfflineTaskType.cloudDeltaPush:
        return Icons.cloud_sync;
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon});
  final String title;
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(children: [
        Icon(icon),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
      ]),
    );
  }
}

class _TaskTile extends ConsumerWidget {
  const _TaskTile({required this.task});
  final OfflineTask task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final remaining = task.nextAt.isAfter(now) ? task.nextAt.difference(now) : Duration.zero;
    final subtitle = _subtitle(task, remaining);
    final statusColor = _statusColor(context, task.status);

    return ListTile(
      leading: Icon(_leadingIcon(task.type)),
      title: Text(_title(task)),
      subtitle: Text(subtitle),
      trailing: Wrap(spacing: 8, children: [
        _StatusPill(status: task.status, color: statusColor),
        IconButton(
          tooltip: 'Retry now',
          icon: const Icon(Icons.refresh),
          onPressed: () async {
            await ref.read(offlineCenterProvider).retryNow(task.id);
            ref.invalidate(offlineTasksProvider);
          },
        ),
        IconButton(
          tooltip: 'Remove',
          icon: const Icon(Icons.delete_outline),
          onPressed: () async {
            await ref.read(offlineCenterProvider).remove(task.id);
            ref.invalidate(offlineTasksProvider);
          },
        ),
        IconButton(
          tooltip: 'Details',
          icon: const Icon(Icons.info_outline),
          onPressed: () => _showDetails(context, ref, task),
        ),
      ]),
    );
  }

  static IconData _leadingIcon(OfflineTaskType type) {
    switch (type) {
      case OfflineTaskType.priceHistoryPush:
        return Icons.storefront;
      case OfflineTaskType.feedbackUpload:
        return Icons.bug_report;
      case OfflineTaskType.templatePublish:
        return Icons.ios_share;
      case OfflineTaskType.cloudDeltaPush:
        return Icons.cloud_sync;
    }
  }

  static String _title(OfflineTask t) {
    switch (t.type) {
      case OfflineTaskType.priceHistoryPush:
        return 'Price update for ingredient ${t.payload['ingredientId']} (store ${t.payload['storeId']})';
      case OfflineTaskType.feedbackUpload:
        return 'Feedback upload ${t.payload['manifest']?['id'] ?? ''}';
      case OfflineTaskType.templatePublish:
        return 'Template publish';
      case OfflineTaskType.cloudDeltaPush:
        return 'Cloud delta ${t.payload['kind'] ?? ''}';
    }
  }

  static String _subtitle(OfflineTask t, Duration remaining) {
    final fmt = DateFormat('y-MM-dd HH:mm');
    final wait = remaining > Duration.zero ? ' • retry in ${remaining.inSeconds}s' : '';
    return 'status: ${t.status.name} • attempts: ${t.attempt}$wait\ncreated: ${fmt.format(t.createdAt)} • updated: ${fmt.format(t.updatedAt)}';
  }

  static Color _statusColor(BuildContext ctx, OfflineTaskStatus s) {
    final cs = Theme.of(ctx).colorScheme;
    switch (s) {
      case OfflineTaskStatus.pending:
        return cs.secondary;
      case OfflineTaskStatus.running:
        return cs.primary;
      case OfflineTaskStatus.done:
        return cs.tertiary;
      case OfflineTaskStatus.failed:
        return cs.error;
      case OfflineTaskStatus.cancelled:
        return cs.outline;
    }
  }

  void _showDetails(BuildContext context, WidgetRef ref, OfflineTask t) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final hint = _hintFor(t);
        return Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_title(t), style: Theme.of(ctx).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('Status: ${t.status.name} (attempts: ${t.attempt})'),
                if (t.lastError != null) ...[
                  const SizedBox(height: 8),
                  Text('Last error: ${t.lastError}'),
                ],
                const SizedBox(height: 8),
                Text('Payload: ${t.payload}'),
                const SizedBox(height: 12),
                if (hint != null) Text('Hint: $hint', style: Theme.of(ctx).textTheme.bodyMedium),
              ],
            ),
          ),
        );
      },
    );
  }

  static String? _hintFor(OfflineTask t) {
    switch (t.type) {
      case OfflineTaskType.priceHistoryPush:
        return 'If the ingredient unit changed since you scanned, verify the pack size unit and try again.';
      case OfflineTaskType.templatePublish:
        return 'If you renamed the template, re-share from Collections.';
      case OfflineTaskType.feedbackUpload:
        return 'You can still share the ZIP manually from the Preview screen.';
      case OfflineTaskType.cloudDeltaPush:
        return 'If the same item was edited on another device, keep the most recent change and retry.';
    }
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status, required this.color});
  final OfflineTaskStatus status;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Text(status.name, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color)),
    );
  }
}

class _ActionsFab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (key) async {
        switch (key) {
          case 'process':
            // Only process if online
            final online = await ref.read(connectivityStatusProvider.future).then((s) => s.online).catchError((_) => false);
            await ref.read(offlineCenterProvider).processEligible(online: online);
            ref.invalidate(offlineTasksProvider);
            break;
          case 'clear':
            await ref.read(offlineCenterProvider).clearDone();
            ref.invalidate(offlineTasksProvider);
            break;
        }
      },
      itemBuilder: (ctx) => const [
        PopupMenuItem<String>(value: 'process', child: Text('Process All')),
        PopupMenuItem<String>(value: 'clear', child: Text('Clear Done')),
      ],
    );
  }
}

