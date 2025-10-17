import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/services/locale_units_service.dart';
import '../../../l10n/l10n.dart';

class LocalizationUnitsPage extends ConsumerStatefulWidget {
  const LocalizationUnitsPage({super.key});

  @override
  ConsumerState<LocalizationUnitsPage> createState() => _LocalizationUnitsPageState();
}

class _LocalizationUnitsPageState extends ConsumerState<LocalizationUnitsPage> {
  String? _localeCode; // null = system default
  String? _currencyCode; // null = auto
  UnitSystem _unitSystem = UnitSystem.metric;
  bool _showOzLb = true;
  bool _showFlOzCups = true;
  bool _showF = false;
  bool _loading = true;

  final _currencies = const ['USD', 'EUR', 'GBP', 'CAD', 'AUD', 'MXN'];
  final _languages = const <String?, String>{
    null: 'System default',
    'en': 'English',
    'es': 'Español',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await ref.read(localeUnitsServiceProvider).get();
    if (!mounted) return;
    setState(() {
      _localeCode = s.localeCode;
      _currencyCode = s.regionCurrency;
      _unitSystem = s.unitSystem;
      _showOzLb = s.showOzLb;
      _showFlOzCups = s.showFlOzCups;
      _showF = s.showFahrenheit;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final svc = ref.read(localeUnitsServiceProvider);
    final s = LocaleUnitsSettings(
      localeCode: _localeCode,
      regionCurrency: _currencyCode,
      unitSystem: _unitSystem,
      showOzLb: _showOzLb,
      showFlOzCups: _showFlOzCups,
      showFahrenheit: _showF,
    );
    await svc.save(s);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(t.localizationTitle),
      ),
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
                        Text(t.language, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String?>(
                          value: _localeCode,
                          items: _languages.entries
                              .map((e) => DropdownMenuItem<String?>(
                                    value: e.key,
                                    child: Text(e.value),
                                  ))
                              .toList(),
                          onChanged: (v) => setState(() => _localeCode = v),
                        ),
                        const SizedBox(height: 16),
                        Text(t.regionCurrency, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String?>(
                          value: _currencyCode,
                          items: [
                            DropdownMenuItem<String?>(value: null, child: Text('Auto')),
                            ..._currencies.map((c) => DropdownMenuItem<String?>(value: c, child: Text(c))),
                          ],
                          onChanged: (v) => setState(() => _currencyCode = v),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.unitSystem, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        RadioListTile<UnitSystem>(
                          title: Text(t.unitSystem_metric),
                          value: UnitSystem.metric,
                          groupValue: _unitSystem,
                          onChanged: (v) => setState(() => _unitSystem = v ?? UnitSystem.metric),
                        ),
                        RadioListTile<UnitSystem>(
                          title: Text(t.unitSystem_us),
                          value: UnitSystem.us,
                          groupValue: _unitSystem,
                          onChanged: (v) => setState(() => _unitSystem = v ?? UnitSystem.us),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 16, top: 4),
                          child: Text(
                            t.unitNoteCups,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.displayToggles, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          value: _showOzLb,
                          onChanged: (v) => setState(() => _showOzLb = v),
                          title: Text(t.toggle_showOzLb),
                        ),
                        SwitchListTile(
                          value: _showFlOzCups,
                          onChanged: (v) => setState(() => _showFlOzCups = v),
                          title: Text(t.toggle_showFlOzCups),
                        ),
                        SwitchListTile(
                          value: _showF,
                          onChanged: (v) => setState(() => _showF = v),
                          title: Text(t.toggle_showFahrenheit),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(t.cancel)),
                    const SizedBox(width: 12),
                    FilledButton(onPressed: _save, child: Text(t.save)),
                  ],
                )
              ],
            ),
    );
  }
}

