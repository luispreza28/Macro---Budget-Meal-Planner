import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../domain/services/micro_settings_service.dart';
import '../../providers/micro_providers.dart';

class MicrosSettingsPage extends ConsumerStatefulWidget {
  const MicrosSettingsPage({super.key});

  @override
  ConsumerState<MicrosSettingsPage> createState() => _MicrosSettingsPageState();
}

class _MicrosSettingsPageState extends ConsumerState<MicrosSettingsPage> {
  bool _enabled = true;
  final _fiberCtrl = TextEditingController(text: '6.0');
  final _sodiumCtrl = TextEditingController(text: '700');
  final _satFatCtrl = TextEditingController(text: '6.0');
  final _satPctCtrl = TextEditingController(text: '10.0');
  final _weeklyFiberCtrl = TextEditingController(text: '175.0');
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final s = await ref.read(microSettingsServiceProvider).get();
      if (!mounted) return;
      setState(() {
        _enabled = s.hintsEnabled;
        _fiberCtrl.text = s.fiberLowGPerServ.toStringAsFixed(1);
        _sodiumCtrl.text = s.sodiumHighMgPerServ.toString();
        _satFatCtrl.text = s.satFatHighGPerServ.toStringAsFixed(1);
        _satPctCtrl.text = s.satFatHighPctKcal.toStringAsFixed(1);
        _weeklyFiberCtrl.text = s.weeklyFiberTargetG.toStringAsFixed(0);
        _loaded = true;
      });
    });
  }

  @override
  void dispose() {
    _fiberCtrl.dispose();
    _sodiumCtrl.dispose();
    _satFatCtrl.dispose();
    _satPctCtrl.dispose();
    _weeklyFiberCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nf = NumberFormat('#,##0');
    return Scaffold(
      appBar: AppBar(title: const Text('Micronutrient Hints')),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SwitchListTile(
                  title: const Text('Enable Micronutrient Hints'),
                  value: _enabled,
                  onChanged: (v) => setState(() => _enabled = v),
                ),
                const SizedBox(height: 8),
                _numField(
                  label: 'Fiber low (g/serv)',
                  controller: _fiberCtrl,
                  helper: 'Show Low fiber chip when per serving below this',
                ),
                _numField(
                  label: 'Sodium high (mg/serv)',
                  controller: _sodiumCtrl,
                  helper: 'Show High sodium chip when at/above this',
                ),
                _numField(
                  label: 'Sat fat high (g/serv)',
                  controller: _satFatCtrl,
                  helper: 'Show High sat fat chip when at/above this',
                ),
                _numField(
                  label: 'Sat fat high (% kcal)',
                  controller: _satPctCtrl,
                  helper: 'Alternate trigger when sat fat ≥ % of calories',
                ),
                _numField(
                  label: 'Weekly fiber target (g)',
                  controller: _weeklyFiberCtrl,
                  helper: 'Used for weekly fiber progress on Plan',
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Save'),
                  onPressed: () async {
                    final s = MicroSettings(
                      hintsEnabled: _enabled,
                      fiberLowGPerServ: double.tryParse(_fiberCtrl.text.trim()) ?? 6.0,
                      sodiumHighMgPerServ: int.tryParse(_sodiumCtrl.text.trim()) ?? 700,
                      satFatHighGPerServ: double.tryParse(_satFatCtrl.text.trim()) ?? 6.0,
                      satFatHighPctKcal: double.tryParse(_satPctCtrl.text.trim()) ?? 10.0,
                      weeklyFiberTargetG: double.tryParse(_weeklyFiberCtrl.text.trim()) ?? 175.0,
                    );
                    await ref.read(microSettingsServiceProvider).save(s);
                    ref.invalidate(microSettingsProvider);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Micros settings saved')));
                      Navigator.of(context).maybePop();
                    }
                  },
                ),
              ],
            ),
    );
  }

  Widget _numField({required String label, required TextEditingController controller, String? helper}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          helperText: helper,
        ),
      ),
    );
  }
}

