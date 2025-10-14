import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/services/insights_service.dart';
import '../../providers/insights_providers.dart';

class MacroAdherenceCard extends ConsumerWidget {
  const MacroAdherenceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(insightsMacroProvider);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 140,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: async.when(
            loading: () => const Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))),
            error: (e, _) => Text('Macro adherence failed: $e', style: Theme.of(context).textTheme.labelSmall),
            data: (m) {
              final badgeColor = switch (m.badge) {
                AdherenceBadge.onTrack => Colors.green,
                AdherenceBadge.close => Colors.orange,
                AdherenceBadge.off => Colors.red,
              };
              final headline = '±${m.avgDeltaKcal.round()} kcal';
              final subtitle = '±${m.avgDeltaP.round()}g P • ±${m.avgDeltaC.round()}g C • ±${m.avgDeltaF.round()}g F';
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Macro Adherence', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          m.badge.name,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: badgeColor, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(headline, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.labelSmall),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

