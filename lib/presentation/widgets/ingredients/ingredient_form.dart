import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/services/density_service.dart';

import '../../../domain/entities/ingredient.dart';

typedef IngredientSubmit = Future<void> Function(Ingredient updated);

class IngredientForm extends StatefulWidget {
  const IngredientForm({super.key, required this.ingredient, required this.onSubmit});

  final Ingredient ingredient;
  final IngredientSubmit onSubmit;

  @override
  State<IngredientForm> createState() => _IngredientFormState();
}

enum _EditMode { per100, perPiece }

class _IngredientFormState extends State<IngredientForm> {
  final _formKey = GlobalKey<FormState>();
  _EditMode _mode = _EditMode.per100;

  late final TextEditingController _kcalPiece;
  late final TextEditingController _proteinPiece;
  late final TextEditingController _carbsPiece;
  late final TextEditingController _fatPiece;
  late final TextEditingController _gPerPiece;
  late final TextEditingController _mlPerPiece;
  late final TextEditingController _densityGPerMl;
  static const double _maxDensity = 3.0;

  @override
  void initState() {
    super.initState();
    _kcalPiece = TextEditingController(text: _fmt(widget.ingredient.nutritionPerPieceKcal));
    _proteinPiece = TextEditingController(text: _fmt(widget.ingredient.nutritionPerPieceProteinG));
    _carbsPiece = TextEditingController(text: _fmt(widget.ingredient.nutritionPerPieceCarbsG));
    _fatPiece = TextEditingController(text: _fmt(widget.ingredient.nutritionPerPieceFatG));
    _gPerPiece = TextEditingController(text: _fmt(widget.ingredient.gramsPerPiece));
    _mlPerPiece = TextEditingController(text: _fmt(widget.ingredient.mlPerPiece));
    _densityGPerMl = TextEditingController(text: _fmt(widget.ingredient.densityGPerMl));
  }

  @override
  void dispose() {
    _kcalPiece.dispose();
    _proteinPiece.dispose();
    _carbsPiece.dispose();
    _fatPiece.dispose();
    _gPerPiece.dispose();
    _mlPerPiece.dispose();
    _densityGPerMl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ing = widget.ingredient;
    final onSurfaceVar = Theme.of(context).colorScheme.onSurfaceVariant;

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ing.name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 6),
            Row(children: [
              Text('Base unit:', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(width: 8),
              Chip(label: Text(ing.unit.value))
            ]),
            if (ing.unit != Unit.piece)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'Per-piece values are stored and used when this ingredient (or a recipe item) is in pieces.',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: onSurfaceVar),
                ),
              ),
            const SizedBox(height: 12),

            SegmentedButton<_EditMode>(
              segments: const [
                ButtonSegment(value: _EditMode.per100, label: Text('Per 100 g/ml')),
                ButtonSegment(value: _EditMode.perPiece, label: Text('Per piece')),
              ],
              selected: {_mode},
              onSelectionChanged: (s) => setState(() => _mode = s.first),
            ),
            const SizedBox(height: 12),

            if (_mode == _EditMode.per100) ...[
              Text(
                'Used for gram/milliliter items. Factor = qty/100.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: onSurfaceVar),
              ),
              const SizedBox(height: 12),
              _ReadOnlyMacrosTile(title: 'Current per 100', m: ing.macrosPer100g),
              const SizedBox(height: 12),
      _numberField(
        _densityGPerMl,
        label: 'Density (g per ml)',
        allowEmpty: true,
        helperText: 'Used to convert grams↔milliliters for this ingredient only.',
        validator: (t) {
          final v = t?.trim() ?? '';
          if (v.isEmpty) return null; // optional
          final d = double.tryParse(v);
          if (d == null) return 'Enter a number';
          if (d <= 0) return 'Must be > 0';
          if (d > _maxDensity) return 'Unreasonably high (> $_maxDensity)';
          return null;
        },
      ),
      // Suggested density (resolver) UI
      _DensitySuggestionRow(ingredient: ing),
      if (ing.unit == Unit.grams || ing.unit == Unit.milliliters)
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Theme.of(context).colorScheme.tertiary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'With density set, we can convert g↔ml in recipes and shortfalls.',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: onSurfaceVar),
                        ),
                      ),
                    ],
                  ),
                ),
            ] else ...[
              Text(
                'Used when counting pieces. Factor = pieces.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: onSurfaceVar),
              ),
              const SizedBox(height: 8),
              _numberField(_kcalPiece, label: 'kcal (per piece)') ,
              _numberField(_proteinPiece, label: 'Protein (g) per piece'),
              _numberField(_carbsPiece, label: 'Carbs (g) per piece'),
              _numberField(_fatPiece, label: 'Fat (g) per piece'),
              const SizedBox(height: 8),
              _numberField(_gPerPiece, label: 'gramsPerPiece (optional)', allowEmpty: true),
              _numberField(_mlPerPiece, label: 'mlPerPiece (optional)', allowEmpty: true),
              const SizedBox(height: 8),
              if (ing.unit == Unit.piece && !_hasEnabledPerPiece())
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Theme.of(context).colorScheme.tertiary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Per-piece macros are recommended for piece-based ingredients to improve accuracy.',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: onSurfaceVar),
                      ),
                    ),
                  ],
                ),
            ],

            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _onSave,
                icon: const Icon(Icons.save),
                label: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasEnabledPerPiece() {
    final kcal = double.tryParse(_kcalPiece.text.trim());
    final p = double.tryParse(_proteinPiece.text.trim());
    final c = double.tryParse(_carbsPiece.text.trim());
    final f = double.tryParse(_fatPiece.text.trim());
    return (kcal != null && kcal > 0) || (p != null && p > 0) || (c != null && c > 0) || (f != null && f > 0);
  }

  Future<void> _onSave() async {
    // Validate numeric inputs (>= 0) and optional helpers (>= 0 if provided)
    if (!_formKey.currentState!.validate()) return;

    final ing = widget.ingredient;

    // Determine if per-piece overrides are enabled
    final enabled = _hasEnabledPerPiece();

    Ingredient updated = ing;

    if (_mode == _EditMode.perPiece) {
      if (!enabled) {
        // Treat as disabled — don’t force-save zeros; set nullable fields to null
        updated = updated.copyWith(
          nutritionPerPieceKcal: () => null,
          nutritionPerPieceProteinG: () => null,
          nutritionPerPieceCarbsG: () => null,
          nutritionPerPieceFatG: () => null,
        );
      } else {
        // At least one > 0 → enable overrides; empty fields default to 0
        double _parseZ(String s) => double.tryParse(s.trim()) ?? 0;
        updated = updated.copyWith(
          nutritionPerPieceKcal: () => _parseZ(_kcalPiece.text),
          nutritionPerPieceProteinG: () => _parseZ(_proteinPiece.text),
          nutritionPerPieceCarbsG: () => _parseZ(_carbsPiece.text),
          nutritionPerPieceFatG: () => _parseZ(_fatPiece.text),
        );
      }

      // Optional helpers
      double? _parseNN(String s) {
        final t = s.trim();
        if (t.isEmpty) return null;
        return double.tryParse(t);
      }
      updated = updated.copyWith(
        gramsPerPiece: () => _parseNN(_gPerPiece.text),
        mlPerPiece: () => _parseNN(_mlPerPiece.text),
      );
    }

    // Density: optional, validated above when provided
    double? _parseDensity(String s) {
      final t = s.trim();
      if (t.isEmpty) return null;
      final d = double.tryParse(t);
      if (d == null) return null;
      if (d <= 0 || d > _maxDensity) return null; // guard double-validate
      return d;
    }
    updated = updated.copyWith(
      densityGPerMl: () => _parseDensity(_densityGPerMl.text),
    );

    await widget.onSubmit(updated);
  }

  Widget _numberField(
    TextEditingController controller, {
    required String label,
    bool allowEmpty = false,
    String? helperText,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          helperText: helperText ?? (allowEmpty ? 'Optional' : null),
        ),
        validator: validator ?? (v) {
          final t = v?.trim() ?? '';
          if (t.isEmpty) return allowEmpty ? null : 'Required';
          final d = double.tryParse(t);
          if (d == null) return 'Enter a number';
          if (d < 0) return 'Must be ≥ 0';
          return null;
        },
      ),
    );
  }

  String _fmt(double? v) {
    if (v == null) return '';
    final r = (v * 10).round() / 10.0;
    return (r % 1 == 0) ? r.toStringAsFixed(0) : r.toStringAsFixed(1);
  }
}

class _ReadOnlyMacrosTile extends StatelessWidget {
  const _ReadOnlyMacrosTile({required this.title, required this.m});
  final String title;
  final MacrosPerHundred m;

  @override
  Widget build(BuildContext context) {
    final onVar = Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          Text('kcal: ${m.kcal.toStringAsFixed(0)}', style: TextStyle(color: onVar)),
          Text('Protein: ${m.proteinG.toStringAsFixed(1)} g', style: TextStyle(color: onVar)),
          Text('Carbs: ${m.carbsG.toStringAsFixed(1)} g', style: TextStyle(color: onVar)),
          Text('Fat: ${m.fatG.toStringAsFixed(1)} g', style: TextStyle(color: onVar)),
        ],
      ),
    );
  }
}

class _DensitySuggestionRow extends ConsumerWidget {
  const _DensitySuggestionRow({required this.ingredient});
  final Ingredient ingredient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: ref.read(densityServiceProvider).resolveFor(ingredient),
      builder: (context, snap) {
        final res = snap.data as DensityResolution?;
        final hasExplicit = ingredient.densityGPerMl != null && ingredient.densityGPerMl! > 0;
        if (res == null) {
          return const SizedBox.shrink();
        }
        final sourceLabel = switch (res.source) {
          DensitySource.explicit => 'Explicit',
          DensitySource.user_override => 'Override',
          DensitySource.catalog_seed => 'Catalog',
          DensitySource.inferred => 'Inferred',
        };
        final valueStr = res.gPerMl.toStringAsFixed(2);

        return Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('$sourceLabel • $valueStr g/ml', style: Theme.of(context).textTheme.labelSmall),
              ),
              const SizedBox(width: 8),
              if (!hasExplicit && res.source != DensitySource.explicit)
                TextButton(
                  onPressed: () async {
                    await ref.read(densityServiceProvider).setOverride(ingredient.id, res.gPerMl);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Applied ${valueStr} g/ml as override')),);
                    }
                  },
                  child: const Text('Use suggested'),
                ),
              const SizedBox(width: 4),
              FutureBuilder(
                future: ref.read(densityServiceProvider).overrides(),
                builder: (context, ovSnap) {
                  final ov = (ovSnap.data as Map<String, double>?) ?? const {};
                  final hasOverride = ov.containsKey(ingredient.id);
                  if (!hasOverride) return const SizedBox.shrink();
                  return TextButton(
                    onPressed: () async {
                      await ref.read(densityServiceProvider).clearOverride(ingredient.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Override cleared')),
                        );
                      }
                    },
                    child: const Text('Clear override'),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
