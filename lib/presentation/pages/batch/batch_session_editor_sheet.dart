import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/recipe.dart';
import '../../../domain/services/batch_session_service.dart';
import '../../providers/batch_providers.dart';
import '../../providers/recipe_providers.dart';

class BatchSessionEditorSheet extends ConsumerStatefulWidget {
  const BatchSessionEditorSheet({super.key});

  @override
  ConsumerState<BatchSessionEditorSheet> createState() => _BatchSessionEditorSheetState();
}

class _BatchSessionEditorSheetState extends ConsumerState<BatchSessionEditorSheet> {
  final _nameCtrl = TextEditingController();
  DateTime _cookDate = DateTime.now();
  final List<_ItemEdit> _items = [];

  @override
  void initState() {
    super.initState();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _nameCtrl.text = 'Meal Prep $today';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recipesAsync = ref.watch(allRecipesProvider);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.9,
          builder: (context, controller) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('New Batch Session'),
                automaticallyImplyLeading: false,
                actions: [
                  TextButton(
                    onPressed: _items.isEmpty ? null : () async {
                      final s = BatchSession(
                        id: newSessionId(),
                        name: _nameCtrl.text.trim().isEmpty ? 'Meal Prep' : _nameCtrl.text.trim(),
                        createdAt: DateTime.now(),
                        cookDate: _cookDate,
                        items: _items
                            .map((e) => BatchItem(
                                  recipeId: e.recipe.id,
                                  targetServings: e.targetServings,
                                  portions: e.portions,
                                  labelNote: e.note?.trim().isEmpty == true ? null : e.note,
                                ))
                            .toList(),
                      );
                      await ref.read(batchSessionServiceProvider).upsert(s);
                      if (!mounted) return;
                      Navigator.of(context).pop(s);
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
              body: ListView(
                controller: controller,
                padding: const EdgeInsets.all(12),
                children: [
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event),
                    title: const Text('Cook date'),
                    subtitle: Text(DateFormat('yyyy-MM-dd').format(_cookDate)),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                        initialDate: _cookDate,
                      );
                      if (d != null) setState(() => _cookDate = d);
                    },
                  ),
                  const Divider(),
                  const Text('Recipes', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  recipesAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(12),
                      child: LinearProgressIndicator(),
                    ),
                    error: (e, st) => Text('Failed to load recipes: $e'),
                    data: (recipes) {
                      return Column(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () async {
                                final r = await _pickRecipe(context, recipes);
                                if (r != null) {
                                  setState(() {
                                    _items.add(_ItemEdit(recipe: r, targetServings: r.servings, portions: r.servings));
                                  });
                                }
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Add recipe'),
                            ),
                          ),
                          for (int i = 0; i < _items.length; i++) _buildItemCard(_items[i]),
                        ],
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildItemCard(_ItemEdit it) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(it.recipe.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                IconButton(
                  tooltip: 'Remove',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => setState(() => _items.remove(it)),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: it.targetServings.toString(),
                    decoration: const InputDecoration(labelText: 'Target servings'),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => it.targetServings = int.tryParse(v) ?? it.targetServings,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: it.portions.toString(),
                    decoration: const InputDecoration(labelText: 'Portions'),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => it.portions = int.tryParse(v) ?? it.portions,
                  ),
                ),
              ],
            ),
            TextFormField(
              initialValue: it.note,
              decoration: const InputDecoration(labelText: 'Label note (optional)'),
              onChanged: (v) => it.note = v,
            ),
          ],
        ),
      ),
    );
  }

  Future<Recipe?> _pickRecipe(BuildContext context, List<Recipe> recipes) async {
    return showDialog<Recipe>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select recipe'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: recipes.length,
            itemBuilder: (context, i) => ListTile(
              title: Text(recipes[i].name),
              subtitle: Text('${recipes[i].servings} servings'),
              onTap: () => Navigator.of(context).pop(recipes[i]),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ],
      ),
    );
  }
}

class _ItemEdit {
  _ItemEdit({required this.recipe, required this.targetServings, required this.portions, this.note});
  final Recipe recipe;
  int targetServings;
  int portions;
  String? note;
}

