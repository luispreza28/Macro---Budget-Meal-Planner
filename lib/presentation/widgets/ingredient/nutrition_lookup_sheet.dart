import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/entities/ingredient.dart' as domain;
import '../../../domain/services/density_service.dart';
import '../../../domain/services/nutrition_cache_service.dart';
import '../../../domain/services/nutrition_lookup_service.dart';
import '../../providers/ingredient_providers.dart';
import '../../providers/nutrition_lookup_providers.dart';

class NutritionLookupSheet extends ConsumerStatefulWidget {
  const NutritionLookupSheet({super.key, required this.ingredient});
  final domain.Ingredient ingredient;

  @override
  ConsumerState<NutritionLookupSheet> createState() => _NutritionLookupSheetState();
}

class _NutritionLookupSheetState extends ConsumerState<NutritionLookupSheet> {
  final TextEditingController _query = TextEditingController();
  bool _loading = false;
  NutritionRecord? _selected;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _persistRecent(String q) async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString('nutrition.recent_queries.v1');
    final List<String> qs = raw == null
        ? <String>[]
        : List<String>.from(((await Future.value(raw)) != null) ? (raw.startsWith('[') ? (raw.substring(1, raw.length - 1).isEmpty ? [] : raw.substring(1, raw.length - 1).split(',').map((e) => e.replaceAll('"', '').trim()).toList()) : <String>[]) : <String>[]);
    // Simpler: override with provider state to avoid naive parser issues
    final current = List<String>.from(ref.read(recentNutritionQueriesProvider));
    final updated = [q, ...current.where((e) => e.toLowerCase() != q.toLowerCase())].take(10).toList();
    ref.read(recentNutritionQueriesProvider.notifier).state = updated;
    // Persist as JSON list
    await sp.setString('nutrition.recent_queries.v1', '[${updated.map((e) => '"${e.replaceAll('"', '')}"').join(',')}]');
  }

  Future<void> _persistLastSource(String src) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('nutrition.last_source', src);
  }

  Future<void> _loadLastSourceIntoProvider() async {
    final sp = await SharedPreferences.getInstance();
    final last = sp.getString('nutrition.last_source');
    if (last != null && (last == 'fdc' || last == 'off')) {
      ref.read(nutritionSearchSourceProvider.notifier).state = last;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadLastSourceIntoProvider();
  }

  Future<void> _onSearch() async {
    final text = _query.text.trim();
    if (text.isEmpty) return;
    final source = ref.read(nutritionSearchSourceProvider);
    setState(() => _loading = true);
    try {
      final items = await ref.read(nutritionLookupServiceProvider).search(query: text, source: source);
      ref.read(nutritionSearchResultsProvider.notifier).state = items;
      await _persistRecent(text);
      await _persistLastSource(source);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lookup failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final source = ref.watch(nutritionSearchSourceProvider);
    final results = ref.watch(nutritionSearchResultsProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _query,
                    decoration: const InputDecoration(
                      labelText: 'Search food name or barcode',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => _onSearch(),
                  ),
                ),
                const SizedBox(width: 12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'fdc', label: Text('FDC')),
                    ButtonSegment(value: 'off', label: Text('OFF')),
                  ],
                  selected: {source},
                  onSelectionChanged: (s) {
                    final v = s.first;
                    ref.read(nutritionSearchSourceProvider.notifier).state = v;
                  },
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _loading ? null : _onSearch,
                  icon: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.search),
                  label: const Text('Search'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (source == 'fdc')
              _FdcKeyHint(),
            Flexible(
              child: results.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'No results yet. Try a query like "olive oil" or scan a barcode.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: results.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final r = results[i];
                        final subtitle = _buildServingSubtitle(r);
                        return ListTile(
                          title: Row(
                            children: [
                              Expanded(child: Text(r.name)),
                              if (r.brand != null && r.brand!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Text(
                                    r.brand!,
                                    style: Theme.of(context).textTheme.labelMedium,
                                  ),
                                ),
                            ],
                          ),
                          subtitle: subtitle == null ? null : Text(subtitle),
                          trailing: _PerHundredPill(r: r),
                          onTap: () => setState(() => _selected = r),
                        );
                      },
                    ),
            ),
            if (_selected != null) ...[
              const Divider(height: 1),
              _PreviewPanel(
                record: _selected!,
                ingredient: widget.ingredient,
                onApplied: () {
                  if (mounted) Navigator.of(context).pop();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  String? _buildServingSubtitle(NutritionRecord r) {
    final parts = <String>[];
    if (r.servingSizeG != null) parts.add('${r.servingSizeG!.toStringAsFixed(0)} g');
    if (r.servingSizeMl != null) parts.add('${r.servingSizeMl!.toStringAsFixed(0)} ml');
    return parts.isEmpty ? null : 'Serving: ${parts.join(' / ')}';
  }
}

class _PerHundredPill extends StatelessWidget {
  const _PerHundredPill({required this.r});
  final NutritionRecord r;
  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).textTheme.labelMedium;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('${r.kcalPer100.toStringAsFixed(0)} kcal', style: s),
        Text('P ${r.proteinPer100G.toStringAsFixed(1)}  C ${r.carbsPer100G.toStringAsFixed(1)}  F ${r.fatPer100G.toStringAsFixed(1)}', style: s),
      ],
    );
  }
}

class _PreviewPanel extends ConsumerWidget {
  const _PreviewPanel({required this.record, required this.ingredient, required this.onApplied});
  final NutritionRecord record;
  final domain.Ingredient ingredient;
  final VoidCallback onApplied;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final densityChip = (record.densityGPerMl != null)
        ? InputChip(
            avatar: const Icon(Icons.water_drop, size: 16),
            label: Text('Density: ${record.densityGPerMl!.toStringAsFixed(2)} g/ml (${record.provider.toUpperCase()})'),
            onPressed: null,
          )
        : null;

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Preview (per 100)', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('kcal ${record.kcalPer100.toStringAsFixed(0)} • P ${record.proteinPer100G.toStringAsFixed(1)} • C ${record.carbsPer100G.toStringAsFixed(1)} • F ${record.fatPer100G.toStringAsFixed(1)}'),
          if (record.kcalPerPiece != null || record.gramsPerPiece != null || record.mlPerPiece != null) ...[
            const SizedBox(height: 6),
            Text('Per piece: ${record.kcalPerPiece?.toStringAsFixed(0) ?? '-'} kcal, ${record.gramsPerPiece?.toStringAsFixed(0) ?? '-'} g, ${record.mlPerPiece?.toStringAsFixed(0) ?? '-'} ml'),
          ],
          if (densityChip != null) Padding(padding: const EdgeInsets.only(top: 6), child: densityChip),
          const SizedBox(height: 8),
          Row(
            children: [
              FilledButton(
                onPressed: () async {
                  await _applyToIngredient(context, ref, record, ingredient, setDensity: false);
                  onApplied();
                },
                child: const Text('Apply to ingredient'),
              ),
              const SizedBox(width: 8),
              if (record.densityGPerMl != null)
                OutlinedButton(
                  onPressed: () async {
                    await _applyToIngredient(context, ref, record, ingredient, setDensity: true);
                    onApplied();
                  },
                  child: const Text('Apply & set density override'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _applyToIngredient(BuildContext context, WidgetRef ref, NutritionRecord r, Ingredient ing, {required bool setDensity}) async {
    try {
      final updated = ing.copyWith(
        macrosPer100g: domain.MacrosPerHundred(
          kcal: r.kcalPer100,
          proteinG: r.proteinPer100G,
          carbsG: r.carbsPer100G,
          fatG: r.fatPer100G,
        ),
        // per-piece optional
        nutritionPerPieceKcal: () => r.kcalPerPiece,
        nutritionPerPieceProteinG: () => null,
        nutritionPerPieceCarbsG: () => null,
        nutritionPerPieceFatG: () => null,
        gramsPerPiece: () => r.gramsPerPiece,
        mlPerPiece: () => r.mlPerPiece,
      );
      await ref.read(ingredientNotifierProvider.notifier).updateIngredient(updated);
      if (setDensity && r.densityGPerMl != null) {
        await ref.read(densityServiceProvider).setOverride(ing.id, r.densityGPerMl!);
      }
      await ref.read(nutritionCacheServiceProvider).put(r);
      ref.invalidate(allIngredientsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nutrition updated from ${r.provider.toUpperCase()}')),
        );
      }
      if (kDebugMode) debugPrint('[Lookup][apply] ${r.provider}:${r.id} -> ${ing.id}');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to apply: $e')),
        );
      }
    }
  }
}

class _FdcKeyHint extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<String?>(
      future: SharedPreferences.getInstance().then((sp) => sp.getString('settings.api.fdc.key')),
      builder: (context, snap) {
        final has = (snap.data != null && snap.data!.isNotEmpty);
        if (has) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              const Icon(Icons.vpn_key, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'FDC API key not set. Add it in Settings > Nutrition APIs.',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
