import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../domain/services/budget_settings_service.dart';
import '../../../domain/services/store_profile_service.dart';

class BudgetSettingsPage extends ConsumerStatefulWidget {
  const BudgetSettingsPage({super.key});

  @override
  ConsumerState<BudgetSettingsPage> createState() => _BudgetSettingsPageState();
}

class _BudgetSettingsPageState extends ConsumerState<BudgetSettingsPage> {
  late BudgetSettings _model;
  bool _loading = true;
  final _currency = NumberFormat.simpleCurrency();
  final _budgetCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await ref.read(budgetSettingsServiceProvider).get();
    setState(() {
      _model = s;
      _budgetCtl.text = (s.weeklyBudgetCents / 100).toStringAsFixed(2);
      _loading = false;
    });
  }

  @override
  void dispose() {
    _budgetCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storesAsync = FutureProvider((ref) => ref.read(storeProfileServiceProvider).getProfiles());
    return Scaffold(
      appBar: AppBar(title: const Text('Budget Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Weekly Budget', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _budgetCtl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(prefixText: _currency.currencySymbol),
                          onChanged: (v) {
                            final parsed = double.tryParse(v.replaceAll(',', ''));
                            if (parsed != null) {
                              _model = _model.copyWith(weeklyBudgetCents: (parsed * 100).round());
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Show budget nudges'),
                        value: _model.showNudges,
                        onChanged: (v) => setState(() => _model = _model.copyWith(showNudges: v)),
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text('Auto-cheap mode'),
                        subtitle: const Text('Apply up to N cheaper swaps after generation if over budget'),
                        value: _model.autoCheapMode,
                        onChanged: (v) => setState(() => _model = _model.copyWith(autoCheapMode: v)),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        title: const Text('Max auto-swaps'),
                        subtitle: Text('${_model.maxAutoSwaps}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: _model.maxAutoSwaps > 0
                                  ? () => setState(() => _model = _model.copyWith(maxAutoSwaps: _model.maxAutoSwaps - 1))
                                  : null,
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: _model.maxAutoSwaps < 3
                                  ? () => setState(() => _model = _model.copyWith(maxAutoSwaps: _model.maxAutoSwaps + 1))
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Macro Tolerances', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        ListTile(
                          title: const Text('Calorie tolerance'),
                          subtitle: Text('${_model.kcalTolerancePct.toStringAsFixed(0)}%'),
                        ),
                        Slider(
                          value: _model.kcalTolerancePct,
                          min: 1,
                          max: 20,
                          divisions: 19,
                          label: '${_model.kcalTolerancePct.toStringAsFixed(0)}%'
                              ,
                          onChanged: (v) => setState(() => _model = _model.copyWith(kcalTolerancePct: v)),
                        ),
                        ListTile(
                          title: const Text('Protein tolerance'),
                          subtitle: Text('${_model.proteinTolerancePct.toStringAsFixed(0)}%'),
                        ),
                        Slider(
                          value: _model.proteinTolerancePct,
                          min: 1,
                          max: 20,
                          divisions: 19,
                          label: '${_model.proteinTolerancePct.toStringAsFixed(0)}%'
                              ,
                          onChanged: (v) => setState(() => _model = _model.copyWith(proteinTolerancePct: v)),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                Consumer(builder: (context, ref, _) {
                  final stores = ref.watch(storesAsync);
                  return stores.when(
                    loading: () => const SizedBox.shrink(),
                    error: (e, st) => const SizedBox.shrink(),
                    data: (profiles) {
                      return Card(
                        child: ListTile(
                          title: const Text('Preferred store'),
                          subtitle: DropdownButton<String?>(
                            isExpanded: true,
                            value: _model.preferredStoreId,
                            items: [
                              const DropdownMenuItem<String?>(value: null, child: Text('Any')),
                              ...profiles.map((p) => DropdownMenuItem<String?>(value: p.id, child: Text(p.name))),
                            ],
                            onChanged: (v) => setState(() => _model = _model.copyWith(preferredStoreId: v)),
                          ),
                        ),
                      );
                    },
                  );
                }),

                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      await ref.read(budgetSettingsServiceProvider).save(_model);
                      if (!mounted) return;
                      Navigator.of(context).maybePop();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Budget settings saved')));
                    },
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
    );
  }
}

