import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../domain/entities/plan.dart';
import '../../providers/plan_providers.dart';
import '../../providers/database_providers.dart';
import '../../providers/collections_providers.dart';
import '../../../domain/services/plan_templates_service.dart';
import '../../router/app_router.dart';

class CollectionsPage extends ConsumerStatefulWidget {
  const CollectionsPage({super.key});

  @override
  ConsumerState<CollectionsPage> createState() => _CollectionsPageState();
}

class _CollectionsPageState extends ConsumerState<CollectionsPage> {
  String _search = '';
  final Set<String> _tagFilter = {};

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(localTemplatesProvider);
    final dateFmt = DateFormat.yMMMd();

    return Scaffold(
      appBar: AppBar(title: const Text('Plan Collections')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Save current plan as template
          final currentPlan = await ref.read(currentPlanProvider.future);
          if (currentPlan == null) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No current plan to save.')),
            );
            return;
          }
          _showSaveTemplateSheet(context, currentPlan);
        },
        icon: const Icon(Icons.save_outlined),
        label: const Text('Save current plan as template'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search name or tag…',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Import by code',
                  onPressed: () => context.go('${AppRouter.collectionsImport}'),
                  icon: const Icon(Icons.download_outlined),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: templatesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (list) {
                  final filtered = list.where((t) {
                    final nameHit = t.name.toLowerCase().contains(_search);
                    final tagsHit = t.tags.any((x) => x.toLowerCase().contains(_search));
                    final bySearch = _search.isEmpty || nameHit || tagsHit;
                    final byTag = _tagFilter.isEmpty || t.tags.any(_tagFilter.contains);
                    return bySearch && byTag;
                  }).toList();
                  if (filtered.isEmpty) {
                    return const Center(child: Text('No templates saved yet'));
                  }
                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.5,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final t = filtered[i];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(t.coverEmoji ?? '📦', style: const TextStyle(fontSize: 22)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      t.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (v) => _handleTemplateAction(context, t, v),
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(value: 'apply', child: Text('Apply to Week')),
                                      const PopupMenuItem(value: 'share', child: Text('Share')),
                                      const PopupMenuItem(value: 'preview', child: Text('Preview')),
                                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  for (final tag in t.tags)
                                    Chip(label: Text(tag), visualDensity: VisualDensity.compact),
                                ],
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  Text('${t.days} days • ${dateFmt.format(t.createdAt)}'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleTemplateAction(BuildContext context, PlanTemplate t, String action) async {
    switch (action) {
      case 'apply':
        final plan = await ref.read(instantiateTemplateProvider(t.payload).future);
        final repo = ref.read(planRepositoryProvider);
        await repo.addPlan(plan);
        await repo.setCurrentPlan(plan.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Template applied as current plan')),
        );
        context.go(AppRouter.plan);
        break;
      case 'share':
        final code = await ref.read(shareTemplateProvider(t).future);
        if (!mounted) return;
        if (code == null) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Failed to share template')));
          return;
        }
        final deepLink = 'mealplanner://import?code=$code';
        await Share.share('Template code: $code\n$deepLink');
        // Also show a local copy dialog
        if (!mounted) return;
        showModalBottomSheet(
          context: context,
          builder: (_) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Share Code', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  SelectableText(code),
                  const SizedBox(height: 8),
                  Text('Deep link: $deepLink'),
                ],
              ),
            );
          },
        );
        break;
      case 'preview':
        final p = await ref.read(planTemplateApplyServiceProvider).preview(t.payload);
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Preview: ${t.name}')
                ,
            content: Text(
              'Recipes: ${t.payload['recipes']?.length ?? 0}\nIngredients: ${t.payload['ingredients']?.length ?? 0}\nMissing recipes: ${p.missingRecipes.length}\nMissing ingredients: ${p.missingIngredients.length}',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
            ],
          ),
        );
        break;
      case 'delete':
        await ref.read(planTemplatesServiceProvider).remove(t.id);
        // refresh
        ref.invalidate(localTemplatesProvider);
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Deleted "${t.name}"')));
        break;
    }
  }

  Future<void> _showSaveTemplateSheet(BuildContext context, Plan plan) async {
    final nameCtl = TextEditingController(text: 'Plan ${DateFormat.MMMd().format(DateTime.now())}');
    final tagsCtl = TextEditingController();
    final emojiCtl = TextEditingController(text: '📦');
    final notesCtl = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Save as Template', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(controller: nameCtl, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: tagsCtl, decoration: const InputDecoration(labelText: 'Tags (comma-separated)')),
            TextField(controller: emojiCtl, decoration: const InputDecoration(labelText: 'Cover Emoji')),
            TextField(controller: notesCtl, decoration: const InputDecoration(labelText: 'Notes')),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () async {
                  final tags = tagsCtl.text
                      .split(',')
                      .map((s) => s.trim())
                      .where((s) => s.isNotEmpty)
                      .toList();
                  final t = await ref
                      .read(saveCurrentPlanAsTemplateProvider((plan, nameCtl.text.trim(), tags,
                          emojiCtl.text.trim().isEmpty ? null : emojiCtl.text.trim(),
                          notesCtl.text.trim().isEmpty ? null : notesCtl.text.trim()))
                          .future);
                  if (!mounted) return;
                  Navigator.of(context).pop();
                  if (t != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Saved template "${t.name}"')),
                    );
                    ref.invalidate(localTemplatesProvider);
                  }
                },
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

