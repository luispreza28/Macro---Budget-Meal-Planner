import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/ingredient.dart' as ing;
import '../../../domain/entities/store_profile.dart';
import '../../../domain/services/store_profile_service.dart';
import '../../providers/store_providers.dart';

class StoreProfilesPage extends ConsumerWidget {
  const StoreProfilesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(storeProfilesProvider);
    final selectedAsync = ref.watch(selectedStoreProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Store Profiles')),
      body: profilesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (profiles) {
          final selectedId = selectedAsync.value?.id;
          if (profiles.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Add a store to customize your aisle order. Your list will follow this aisle order when this store is selected.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            itemCount: profiles.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final p = profiles[i];
              return ListTile(
                leading: Text(p.emoji ?? '🏬', style: const TextStyle(fontSize: 20)),
                title: Text(p.name),
                subtitle: Text(p.id == selectedId ? 'Default' : ''),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    switch (value) {
                      case 'edit':
                        // push edit
                        await Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => EditStoreProfilePage(profile: p)),
                        );
                        ref.invalidate(storeProfilesProvider);
                        break;
                      case 'default':
                        await ref.read(storeProfileServiceProvider).setSelected(p.id);
                        ref.invalidate(selectedStoreProvider);
                        break;
                      case 'delete':
                        await ref.read(storeProfileServiceProvider).delete(p.id);
                        ref.invalidate(storeProfilesProvider);
                        ref.invalidate(selectedStoreProvider);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'default', child: Text('Set as default')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await _showCreateDialog(context, ref);
          ref.invalidate(storeProfilesProvider);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    final emojiCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add Store'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Store name'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: emojiCtrl,
                  decoration: const InputDecoration(labelText: 'Emoji (optional)')
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                await ref
                    .read(storeProfileServiceProvider)
                    .create(nameCtrl.text.trim(), emoji: emojiCtrl.text.trim().isEmpty ? null : emojiCtrl.text.trim());
                if (context.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }
}

class EditStoreProfilePage extends ConsumerStatefulWidget {
  const EditStoreProfilePage({super.key, required this.profile});
  final StoreProfile profile;

  @override
  ConsumerState<EditStoreProfilePage> createState() => _EditStoreProfilePageState();
}

class _EditStoreProfilePageState extends ConsumerState<EditStoreProfilePage> {
  late TextEditingController _nameCtrl;
  late TextEditingController _emojiCtrl;
  late List<String> _order;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.profile.name);
    _emojiCtrl = TextEditingController(text: widget.profile.emoji ?? '');
    final known = ing.Aisle.values.map((a) => a.value).toList();
    final normalized = <String>[];
    final seen = <String>{};
    for (final s in widget.profile.aisleOrder) {
      if (known.contains(s) && !seen.contains(s)) {
        normalized.add(s);
        seen.add(s);
      }
    }
    for (final s in known) {
      if (!seen.contains(s)) normalized.add(s);
    }
    _order = normalized;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Store')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _emojiCtrl,
              decoration: const InputDecoration(labelText: 'Emoji'),
            ),
            const SizedBox(height: 16),
            Text(
              'Aisle order',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ReorderableListView.builder(
                itemCount: _order.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final item = _order.removeAt(oldIndex);
                    _order.insert(newIndex, item);
                  });
                },
                itemBuilder: (context, index) {
                  final key = _order[index];
                  return ListTile(
                    key: ValueKey(key),
                    title: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(label: Text(_aisleLabel(key))),
                      ],
                    ),
                    trailing: const Icon(Icons.drag_handle),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Card(
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Per-store price overrides: coming soon'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  final svc = ref.read(storeProfileServiceProvider);
                  // update name/emoji
                  final updated = widget.profile.copyWith(
                    name: _nameCtrl.text.trim().isEmpty ? widget.profile.name : _nameCtrl.text.trim(),
                    emoji: _emojiCtrl.text.trim().isEmpty ? null : _emojiCtrl.text.trim(),
                  );
                  await svc.update(updated);
                  await svc.setAisleOrder(widget.profile.id, _order);
                  if (mounted) Navigator.of(context).pop();
                },
                child: const Text('Save'),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your list will follow this aisle order when this store is selected.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  String _aisleLabel(String value) {
    switch (value) {
      case 'produce':
        return 'Produce';
      case 'meat':
        return 'Meat';
      case 'dairy':
        return 'Dairy';
      case 'pantry':
        return 'Pantry';
      case 'frozen':
        return 'Frozen';
      case 'condiments':
        return 'Condiments';
      case 'bakery':
        return 'Bakery';
      case 'household':
        return 'Household';
      default:
        return value;
    }
  }
}

