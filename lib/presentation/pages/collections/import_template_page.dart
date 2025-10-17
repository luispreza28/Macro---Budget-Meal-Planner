import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/collections_providers.dart';
import '../../providers/database_providers.dart';
import '../../providers/plan_providers.dart';
import '../../router/app_router.dart';

class ImportTemplatePage extends ConsumerStatefulWidget {
  final String? initialCode;
  const ImportTemplatePage({super.key, this.initialCode});

  @override
  ConsumerState<ImportTemplatePage> createState() => _ImportTemplatePageState();
}

class _ImportTemplatePageState extends ConsumerState<ImportTemplatePage> {
  late final TextEditingController _codeCtl;
  @override
  void initState() {
    super.initState();
    _codeCtl = TextEditingController(text: widget.initialCode ?? '');
  }

  @override
  void dispose() {
    _codeCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final code = _codeCtl.text.trim();
    final async = code.isEmpty
        ? const AsyncValue.data(null)
        : ref.watch(importTemplateByCodeProvider(code));

    return Scaffold(
      appBar: AppBar(title: const Text('Import Template')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _codeCtl,
              decoration: const InputDecoration(
                labelText: 'Enter code',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (pair) {
                  if (pair == null) {
                    return const Center(child: Text('Enter a code to preview template'));
                  }
                  final (preview, payload) = pair;
                  final name = (payload['plan']?['name'] as String?) ?? 'Template';
                  final days = ((payload['plan']?['days'] as List?)?.length ?? 0);
                  final recipesCount = (payload['recipes'] as List?)?.length ?? 0;
                  final ingsCount = (payload['ingredients'] as List?)?.length ?? 0;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: Theme.of(context).textTheme.titleLarge),
                      Text('$days days • $recipesCount recipes • $ingsCount ingredients'),
                      const SizedBox(height: 12),
                      Text('Missing items:', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 6),
                      Text('Recipes: ${preview.missingRecipes.length}'),
                      Text('Ingredients: ${preview.missingIngredients.length}'),
                      const Spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                await ref.read(acceptImportProvider((payload, name, const <String>[], null)).future);
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Template imported')),
                                );
                              },
                              child: const Text('Import'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: () async {
                                await ref.read(acceptImportProvider((payload, name, const <String>[], null)).future);
                                final plan = await ref.read(instantiateTemplateProvider(payload).future);
                                final repo = ref.read(planRepositoryProvider);
                                await repo.addPlan(plan);
                                await repo.setCurrentPlan(plan.id);
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Imported and applied')),
                                );
                                context.go(AppRouter.plan);
                              },
                              child: const Text('Import & Apply'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

