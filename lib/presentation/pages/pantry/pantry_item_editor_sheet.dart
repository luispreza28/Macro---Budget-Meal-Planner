import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/entities/ingredient.dart' as domain;
import '../../../domain/services/pantry_expiry_heuristics.dart';
import '../../../domain/services/pantry_expiry_service.dart';
import '../../providers/ingredient_providers.dart';
import '../../providers/pantry_expiry_providers.dart';

class PantryItemEditorSheet extends ConsumerStatefulWidget {
  const PantryItemEditorSheet({super.key, this.initial, this.prefillIngredient, this.prefillQty});
  final PantryItem? initial;
  final domain.Ingredient? prefillIngredient;
  final double? prefillQty; // in ingredient base unit

  @override
  ConsumerState<PantryItemEditorSheet> createState() => _PantryItemEditorSheetState();
}

class _PantryItemEditorSheetState extends ConsumerState<PantryItemEditorSheet> {
  domain.Ingredient? _ingredient;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _noteCtrl;
  bool _opened = false;
  DateTime? _openedAt;
  DateTime? _bestBy;
  DateTime? _expiresAt;

  @override
  void initState() {
    super.initState();
    _ingredient = widget.prefillIngredient;
    _qtyCtrl = TextEditingController(text: _formatQty(widget.prefillQty ?? widget.initial?.qty ?? 0));
    _noteCtrl = TextEditingController(text: widget.initial?.note ?? '');
    _opened = widget.initial?.openedAt != null;
    _openedAt = widget.initial?.openedAt;
    _bestBy = widget.initial?.bestBy;
    _expiresAt = widget.initial?.expiresAt;

    // Pre-fill heuristic dates if creating new and ingredient known
    if (widget.initial == null && _ingredient != null) {
      final days = PantryHeuristics.defaultShelfDays(_ingredient!.aisle, opened: _opened);
      final base = DateTime.now();
      _bestBy ??= base.add(Duration(days: days));
    }
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allAsync = ref.watch(allIngredientsProvider);
    final fmt = DateFormat.yMMMd();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.initial == null ? 'Add to Pantry' : 'Edit Pantry Item', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              // Ingredient picker
              allAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Failed to load ingredients: $e'),
                data: (list) {
                  return Autocomplete<domain.Ingredient>(
                    initialValue: _ingredient == null ? null : TextEditingValue(text: _ingredient!.name),
                    displayStringForOption: (i) => i.name,
                    optionsBuilder: (t) {
                      final q = t.text.toLowerCase();
                      if (q.isEmpty) return list;
                      return list.where((i) => i.name.toLowerCase().contains(q));
                    },
                    onSelected: (i) {
                      setState(() {
                        _ingredient = i;
                        // Refresh default dates on ingredient change
                        final days = PantryHeuristics.defaultShelfDays(i.aisle, opened: _opened);
                        _bestBy ??= DateTime.now().add(Duration(days: days));
                      });
                    },
                    fieldViewBuilder: (ctx, ctrl, focus, onSubmit) => TextField(
                      controller: ctrl,
                      focusNode: focus,
                      decoration: const InputDecoration(labelText: 'Ingredient', border: OutlineInputBorder()),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              // Qty + unit
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _qtyCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Quantity',
                      border: const OutlineInputBorder(),
                      suffixText: _ingredient?.unit.value ?? '',
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              // Opened toggle + date
              Row(children: [
                Switch.adaptive(
                  value: _opened,
                  onChanged: (v) {
                    setState(() {
                      _opened = v;
                      _openedAt = v ? (_openedAt ?? DateTime.now()) : null;
                      // Adjust heuristic best-by if set by default
                      if (_ingredient != null && _bestBy == null) {
                        final days = PantryHeuristics.defaultShelfDays(_ingredient!.aisle, opened: _opened);
                        _bestBy = DateTime.now().add(Duration(days: days));
                      }
                    });
                  },
                ),
                const SizedBox(width: 8),
                const Text('Opened?'),
                const Spacer(),
                if (_opened)
                  TextButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime.now().subtract(const Duration(days: 3650)),
                        lastDate: DateTime.now().add(const Duration(days: 3650)),
                        initialDate: _openedAt ?? DateTime.now(),
                      );
                      if (picked != null) setState(() => _openedAt = picked);
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: Text(_openedAt == null ? 'Opened date' : fmt.format(_openedAt!)),
                  ),
              ]),
              const SizedBox(height: 12),
              // Best-by / Expiry
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime.now().subtract(const Duration(days: 3650)),
                        lastDate: DateTime.now().add(const Duration(days: 3650)),
                        initialDate: _bestBy ?? DateTime.now(),
                      );
                      if (picked != null) setState(() => _bestBy = picked);
                    },
                    icon: const Icon(Icons.event_available),
                    label: Text(_bestBy == null ? 'Best-by (optional)' : 'Best-by: ${fmt.format(_bestBy!)}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime.now().subtract(const Duration(days: 3650)),
                        lastDate: DateTime.now().add(const Duration(days: 3650)),
                        initialDate: _expiresAt ?? DateTime.now(),
                      );
                      if (picked != null) setState(() => _expiresAt = picked);
                    },
                    icon: const Icon(Icons.event_busy),
                    label: Text(_expiresAt == null ? 'Expiry (optional)' : 'Expiry: ${fmt.format(_expiresAt!)}'),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              TextField(
                controller: _noteCtrl,
                decoration: const InputDecoration(labelText: 'Note', border: OutlineInputBorder()),
                minLines: 1,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(children: [
                const Spacer(),
                FilledButton(
                  onPressed: _ingredient == null ? null : () async {
                    final qty = double.tryParse(_qtyCtrl.text) ?? 0;
                    if (qty <= 0) {
                      Navigator.of(context).pop();
                      return;
                    }
                    final ing = _ingredient!;
                    final item = PantryItem(
                      id: widget.initial?.id ?? const Uuid().v4(),
                      ingredientId: ing.id,
                      qty: qty,
                      unit: ing.unit,
                      addedAt: widget.initial?.addedAt ?? DateTime.now(),
                      openedAt: _opened ? _openedAt ?? DateTime.now() : null,
                      bestBy: _bestBy,
                      expiresAt: _expiresAt,
                      note: _noteCtrl.text.isEmpty ? null : _noteCtrl.text,
                      consumed: widget.initial?.consumed ?? false,
                      discarded: widget.initial?.discarded ?? false,
                    );

                    await ref.read(pantryExpiryServiceProvider).upsert(item);
                    ref.invalidate(pantryItemsProvider);
                    if (!mounted) return;
                    Navigator.of(context).pop(item);
                  },
                  child: const Text('Save'),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  String _formatQty(double v) {
    if (v == 0) return '';
    return v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 1);
  }
}

