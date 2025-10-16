import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/services/taste_profile_service.dart';
import '../../providers/taste_providers.dart';
import '../../providers/ingredient_providers.dart';
import '../../providers/recipe_providers.dart';

class TasteProfilePage extends ConsumerStatefulWidget {
  const TasteProfilePage({super.key});

  @override
  ConsumerState<TasteProfilePage> createState() => _TasteProfilePageState();
}

class _TasteProfilePageState extends ConsumerState<TasteProfilePage> {
  late TasteProfile _editing;
  bool _loaded = false;
  final TextEditingController _tagCtrl = TextEditingController();
  final TextEditingController _cuisineCtrl = TextEditingController();
  final TextEditingController _dietCtrl = TextEditingController();
  final Map<String, double> _weights = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final p = await ref.read(tasteProfileProvider.future);
      setState(() {
        _editing = p;
        _weights.clear();
        _weights.addAll(p.cuisineWeights);
        _loaded = true;
      });
    });
  }

  @override
  void dispose() {
    _tagCtrl.dispose();
    _cuisineCtrl.dispose();
    _dietCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recipesAsync = ref.watch(allRecipesProvider);
    final ingredientsAsync = ref.watch(allIngredientsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Taste & Allergens'),
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _section(
                  context,
                  title: 'Allergens / Hard bans',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ingredients', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      _IngredientMultiSelect(
                        initial: _editing.hardBanIngredients.toSet(),
                        onChanged: (s) => setState(() => _editing = _editing.copyWith(hardBanIngredients: s.toList()..sort())),
                      ),
                      const SizedBox(height: 12),
                      Text('Tags (e.g., nuts, shellfish, gluten)', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      _TagEditor(
                        values: _editing.hardBanTags.toList(),
                        onAdd: (t) => setState(() => _editing = _editing.copyWith(hardBanTags: [..._editing.hardBanTags, t].toSet().toList()..sort())),
                        onRemove: (t) => setState(() => _editing = _editing.copyWith(hardBanTags: _editing.hardBanTags.where((e) => e != t).toList())),
                      ),
                    ],
                  ),
                ),

                _section(
                  context,
                  title: 'Likes',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ingredients', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      _IngredientMultiSelect(
                        initial: _editing.likeIngredients.toSet(),
                        onChanged: (s) => setState(() => _editing = _editing.copyWith(likeIngredients: s.toList()..sort())),
                      ),
                      const SizedBox(height: 12),
                      Text('Tags / cuisines', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      _TagEditor(
                        values: _editing.likeTags.toList(),
                        onAdd: (t) => setState(() => _editing = _editing.copyWith(likeTags: [..._editing.likeTags, t].toSet().toList()..sort())),
                        onRemove: (t) => setState(() => _editing = _editing.copyWith(likeTags: _editing.likeTags.where((e) => e != t).toList())),
                      ),
                    ],
                  ),
                ),

                _section(
                  context,
                  title: 'Dislikes',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ingredients', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      _IngredientMultiSelect(
                        initial: _editing.dislikeIngredients.toSet(),
                        onChanged: (s) => setState(() => _editing = _editing.copyWith(dislikeIngredients: s.toList()..sort())),
                      ),
                      const SizedBox(height: 12),
                      Text('Tags / cuisines', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      _TagEditor(
                        values: _editing.dislikeTags.toList(),
                        onAdd: (t) => setState(() => _editing = _editing.copyWith(dislikeTags: [..._editing.dislikeTags, t].toSet().toList()..sort())),
                        onRemove: (t) => setState(() => _editing = _editing.copyWith(dislikeTags: _editing.dislikeTags.where((e) => e != t).toList())),
                      ),
                    ],
                  ),
                ),

                _section(
                  context,
                  title: 'Cuisine weights',
                  trailing: TextButton(
                    onPressed: () => setState(() {
                      _weights.clear();
                    }),
                    child: const Text('Reset'),
                  ),
                  child: Column(
                    children: [
                      for (final entry in _weights.entries.toList()..sort((a,b)=>a.key.compareTo(b.key)))
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              SizedBox(width: 100, child: Text(entry.key)),
                              Expanded(
                                child: Slider(
                                  min: 0.7,
                                  max: 1.3,
                                  divisions: 12,
                                  value: entry.value.clamp(0.7, 1.3),
                                  label: entry.value.toStringAsFixed(2),
                                  onChanged: (v) => setState(() => _weights[entry.key] = double.parse(v.toStringAsFixed(2))),
                                ),
                              ),
                              Text(entry.value.toStringAsFixed(2)),
                            ],
                          ),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _cuisineCtrl,
                              decoration: const InputDecoration(hintText: 'Add cuisine tag (e.g., mexican)'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: () {
                              final t = _cuisineCtrl.text.trim();
                              if (t.isEmpty) return;
                              setState(() {
                                _weights[t] = 1.0;
                                _cuisineCtrl.clear();
                              });
                            },
                            child: const Text('Add'),
                          )
                        ],
                      ),
                    ],
                  ),
                ),

                _section(
                  context,
                  title: 'Diet flags',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final preset in const ['veg','gf','df'])
                            FilterChip(
                              label: Text(preset.toUpperCase()),
                              selected: _editing.dietFlags.contains(preset),
                              onSelected: (v) => setState(() {
                                final s = _editing.dietFlags.toSet();
                                v ? s.add(preset) : s.remove(preset);
                                _editing = _editing.copyWith(dietFlags: s.toList());
                              }),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _TagEditor(
                        values: _editing.dietFlags.toList(),
                        onAdd: (t) => setState(() => _editing = _editing.copyWith(dietFlags: [..._editing.dietFlags, t].toSet().toList()..sort())),
                        onRemove: (t) => setState(() => _editing = _editing.copyWith(dietFlags: _editing.dietFlags.where((e) => e != t).toList())),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Save'),
                    onPressed: () async {
                      final svc = ref.read(tasteProfileServiceProvider);
                      final p = _editing.copyWith(cuisineWeights: {..._weights});
                      await svc.save(p);
                      if (mounted) {
                        ref.invalidate(tasteProfileProvider);
                        ref.invalidate(tasteRulesProvider);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Taste profile saved')));
                        Navigator.of(context).maybePop();
                      }
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _section(BuildContext context, {required String title, Widget? trailing, required Widget child}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                if (trailing != null) trailing,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _TagEditor extends StatefulWidget {
  const _TagEditor({required this.values, required this.onAdd, required this.onRemove});
  final List<String> values;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;

  @override
  State<_TagEditor> createState() => _TagEditorState();
}

class _TagEditorState extends State<_TagEditor> {
  final TextEditingController _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in widget.values)
              InputChip(
                label: Text(t),
                onDeleted: () => widget.onRemove(t),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                decoration: const InputDecoration(hintText: 'Add tag'),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () {
                final t = _ctrl.text.trim();
                if (t.isEmpty) return;
                widget.onAdd(t);
                _ctrl.clear();
              },
              child: const Text('Add'),
            )
          ],
        ),
      ],
    );
  }
}

class _IngredientMultiSelect extends ConsumerStatefulWidget {
  const _IngredientMultiSelect({required this.initial, required this.onChanged});
  final Set<String> initial;
  final ValueChanged<Set<String>> onChanged;

  @override
  ConsumerState<_IngredientMultiSelect> createState() => _IngredientMultiSelectState();
}

class _IngredientMultiSelectState extends ConsumerState<_IngredientMultiSelect> {
  final TextEditingController _searchCtrl = TextEditingController();
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = {...widget.initial};
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchCtrl.text.trim();
    final searchAsync = ref.watch(ingredientSearchProvider(query));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final id in _selected)
              InputChip(
                label: Text(id), // ID for now; keeps unit stable
                onDeleted: () {
                  setState(() => _selected.remove(id));
                  widget.onChanged(_selected);
                },
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _searchCtrl,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search ingredients to add',
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        searchAsync.when(
          loading: () => const LinearProgressIndicator(minHeight: 2),
          error: (e, _) => Text('Search failed: $e'),
          data: (ings) {
            if (ings.isEmpty || query.isEmpty) {
              return const SizedBox.shrink();
            }
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final i in ings.take(12))
                  FilterChip(
                    label: Text(i.name),
                    selected: _selected.contains(i.id),
                    onSelected: (v) {
                      setState(() {
                        if (v) {
                          _selected.add(i.id);
                        } else {
                          _selected.remove(i.id);
                        }
                        widget.onChanged(_selected);
                      });
                    },
                  )
              ],
            );
          },
        ),
      ],
    );
  }
}

