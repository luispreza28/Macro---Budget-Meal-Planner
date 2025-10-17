import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macro_budget_meal_planner/domain/entities/ingredient.dart' as domain;
import '../../../domain/services/replenishment_prefs_service.dart';
import '../../providers/replenishment_providers.dart';

class ParEditorSheet extends ConsumerStatefulWidget {
  const ParEditorSheet({super.key, required this.ingredient});
  final domain.Ingredient ingredient;

  @override
  ConsumerState<ParEditorSheet> createState() => _ParEditorSheetState();
}

class _ParEditorSheetState extends ConsumerState<ParEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _par;
  late TextEditingController _minBuy;
  bool _auto = true;

  @override
  void initState() {
    super.initState();
    _par = TextEditingController();
    _minBuy = TextEditingController();
    _load();
  }

  Future<void> _load() async {
    final svc = ref.read(replenishmentPrefsServiceProvider);
    final pref = await svc.get(widget.ingredient.id);
    if (!mounted) return;
    setState(() {
      _par.text = (pref?.parQty ?? 0).toStringAsFixed(
          (pref?.parQty ?? 0).truncateToDouble() == (pref?.parQty ?? 0) ? 0 : 1);
      _minBuy.text = (pref?.minBuyQty ?? 0).toStringAsFixed(
          (pref?.minBuyQty ?? 0).truncateToDouble() == (pref?.minBuyQty ?? 0) ? 0 : 1);
      _auto = pref?.autoSuggest ?? true;
    });
  }

  @override
  void dispose() {
    _par.dispose();
    _minBuy.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unitLabel = widget.ingredient.unit.value;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          top: 12,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Par Level', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(widget.ingredient.name, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 12),
              TextFormField(
                controller: _par,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Par Qty ($unitLabel)',
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _minBuy,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Min Buy Qty ($unitLabel)',
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _auto,
                onChanged: (v) => setState(() => _auto = v),
                title: const Text('Auto-Suggest'),
                subtitle: const Text('Include in restock suggestions automatically'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        final svc = ref.read(replenishmentPrefsServiceProvider);
                        final par = double.tryParse(_par.text.trim()) ?? 0;
                        final minBuy = double.tryParse(_minBuy.text.trim()) ?? 0;
                        await svc.upsert(
                          widget.ingredient.id,
                          ReplenishPref(parQty: par, minBuyQty: minBuy, autoSuggest: _auto),
                        );
                        // bump prefs version to refresh suggestions dependents
                        ref.read(replenishmentPrefsVersionProvider.notifier).state++;
                        if (!mounted) return;
                        Navigator.of(context).pop();
                      },
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

