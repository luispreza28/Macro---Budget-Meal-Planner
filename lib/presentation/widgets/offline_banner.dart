import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/services/offline_center.dart';

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(connectivityStatusProvider);
    final online = c.asData?.value.online ?? true;
    if (online) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.errorContainer,
      child: InkWell(
        onTap: () => context.push('/offline/queued'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(children: [
            Icon(Icons.wifi_off, size: 18, color: cs.onErrorContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Offline — actions will retry when back online. Tap to view queue.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onErrorContainer),
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: cs.onErrorContainer),
          ]),
        ),
      ),
    );
  }
}

