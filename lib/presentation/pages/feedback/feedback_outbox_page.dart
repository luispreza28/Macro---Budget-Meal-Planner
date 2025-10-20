import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/services/feedback_service.dart';
import '../../providers/feedback_providers.dart';

class FeedbackOutboxPage extends ConsumerWidget {
  const FeedbackOutboxPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draftsAsync = ref.watch(feedbackQueueProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Feedback Outbox')),
      body: draftsAsync.when(
        data: (drafts) {
          if (drafts.isEmpty) {
            return const Center(child: Text('No saved drafts'));
          }
          return ListView.separated(
            itemCount: drafts.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final d = drafts[i];
              return ListTile(
                title: Text(d.title.isEmpty ? '(untitled)' : d.title),
                subtitle: Text('${d.kind.name} • ${d.createdAt}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    await ref.read(feedbackServiceProvider).remove(d.id);
                    // cleanup screenshots
                    for (final p in d.screenshotPaths) {
                      try { final f = File(p); if (await f.exists()) { await f.delete(); } } catch (_) {}
                    }
                    ref.invalidate(feedbackQueueProvider);
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

