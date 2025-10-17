import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/services/micros_overlay_service.dart';

class IngredientMicrosSheet extends ConsumerStatefulWidget {
  const IngredientMicrosSheet({super.key, required this.ingredientId});
  final String ingredientId;

  @override
  ConsumerState<IngredientMicrosSheet> createState() => _IngredientMicrosSheetState();
}

class _IngredientMicrosSheetState extends ConsumerState<IngredientMicrosSheet> {
  final _fiberCtrl = TextEditingController();
  final _sodiumCtrl = TextEditingController();
  final _satCtrl = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final svc = ref.read(microsOverlayServiceProvider);
      final cur = await svc.getFor(widget.ingredientId);
      if (!mounted) return;
      setState(() {
        _fiberCtrl.text = (cur?.fiberG ?? 0).toStringAsFixed(1);
        _sodiumCtrl.text = (cur?.sodiumMg ?? 0).toStringAsFixed(0);
        _satCtrl.text = (cur?.satFatG ?? 0).toStringAsFixed(1);
        _loading = false;
      });
    });
  }

  @override
  void dispose() {
    _fiberCtrl.dispose();
    _sodiumCtrl.dispose();
    _satCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: _loading
          ? const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Micros (per 100 base units)', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _fiberCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Fiber (g) per 100'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _sodiumCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Sodium (mg) per 100'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _satCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Sat fat (g) per 100'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        child: const Text('Cancel'),
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text('Save'),
                        onPressed: () async {
                          final fiber = double.tryParse(_fiberCtrl.text.trim()) ?? 0;
                          final sodium = double.tryParse(_sodiumCtrl.text.trim()) ?? 0;
                          final sat = double.tryParse(_satCtrl.text.trim()) ?? 0;
                          final svc = ref.read(microsOverlayServiceProvider);
                          await svc.upsert(widget.ingredientId, MicrosPerHundred(fiberG: fiber, sodiumMg: sodium, satFatG: sat));
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Micros saved')));
                            Navigator.of(context).maybePop();
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

