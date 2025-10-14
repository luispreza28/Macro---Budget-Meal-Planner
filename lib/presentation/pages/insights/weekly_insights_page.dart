import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/insights_providers.dart';
import '../../widgets/insights/macro_adherence_card.dart';
import '../../widgets/insights/budget_card.dart';
import '../../widgets/insights/pantry_usage_card.dart';
import '../../widgets/insights/variety_card.dart';
import '../../widgets/insights/trends_card.dart';
import '../../widgets/insights/top_movers_card.dart';
import '../../widgets/insights/quick_actions_card.dart';

class WeeklyInsightsPage extends ConsumerWidget {
  const WeeklyInsightsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Insights')),
      body: const _InsightsBody(),
    );
  }
}

class _InsightsBody extends ConsumerWidget {
  const _InsightsBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Prime some base providers to ensure graceful states
    final currentPlan = ref.watch(currentPlanNonNullProvider);

    return currentPlan.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Failed to load current plan: $e', style: Theme.of(context).textTheme.bodyMedium),
      ),
      data: (_) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            final runSpacing = 12.0;
            final spacing = 12.0;
            final cardWidth = isWide ? (constraints.maxWidth - spacing * 3) / 3 : constraints.maxWidth;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: spacing,
                runSpacing: runSpacing,
                children: [
                  SizedBox(width: cardWidth, child: const MacroAdherenceCard()),
                  SizedBox(width: cardWidth, child: const BudgetCard()),
                  SizedBox(width: cardWidth, child: const PantryUsageCard()),
                  SizedBox(width: cardWidth, child: const VarietyCard()),
                  SizedBox(width: cardWidth, child: const TrendsCard()),
                  SizedBox(width: cardWidth, child: const TopMoversCard()),
                  SizedBox(width: cardWidth, child: const QuickActionsCard()),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

