import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/ingredient.dart';
import '../../providers/ingredient_providers.dart';
import '../../widgets/ingredients/ingredient_form.dart';
import '../../providers/sub_rules_providers.dart';
import '../../router/app_router.dart';

class IngredientEditPage extends ConsumerWidget {
  const IngredientEditPage({super.key, required this.ingredientId});

  final String ingredientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ingredientAsync = ref.watch(ingredientByIdProvider(ingredientId));
    final saving = ref.watch(ingredientNotifierProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Ingredient'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
        actions: [
          if (saving) const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()),
        ],
      ),
      body: ingredientAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load ingredient: $e')),
        data: (ing) {
          if (ing == null) {
            return const Center(child: Text('Ingredient not found'));
          }
          return ListView(
            children: [
              IngredientForm(
                ingredient: ing,
                onSubmit: (updated) async {
                  await ref.read(ingredientNotifierProvider.notifier).updateIngredient(updated);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ingredient saved')),
                    );
                  }
                },
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: _SubRulesSection(ingredientId: ing.id),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SubRulesSection extends ConsumerWidget {
  const _SubRulesSection({required this.ingredientId});
  final String ingredientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesAsync = ref.watch(subRulesProvider);
    return rulesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const SizedBox.shrink(),
      data: (rules) {
        final xs = rules.where((r) => (r.from.kind == 'ingredient' && r.from.value == ingredientId)).toList();
        if (xs.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Substitution Rules', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text('No rules for this ingredient.', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              FilledButton.tonal(
                onPressed: () => context.push(AppRouter.substitutionSettings),
                child: const Text('Add rule'),
              ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Substitution Rules', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final r in xs)
                  InputChip(
                    label: Text(
                      r.action == SubAction.never
                          ? 'Never'
                          : '${r.action.name.toUpperCase()} → ${(r.to?.value ?? '-')}',
                    ),
                    selected: r.enabled,
                    onSelected: (v) async {
                      await ref.read(subRulesServiceProvider).upsert(SubRule(
                            id: r.id,
                            action: r.action,
                            from: r.from,
                            to: r.to,
                            scopeTags: r.scopeTags,
                            maxPpuCents: r.maxPpuCents,
                            priority: r.priority,
                            enabled: !r.enabled,
                          ));
                      ref.invalidate(subRulesProvider);
                      ref.invalidate(subRulesIndexProvider);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: () => context.push(AppRouter.substitutionSettings),
              child: const Text('Manage rules'),
            ),
          ],
        );
      },
    );
  }
}

