import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/services/batch_session_service.dart';
import '../../providers/batch_providers.dart';

class BatchCookChecklistSheet extends ConsumerStatefulWidget {
  const BatchCookChecklistSheet({super.key, required this.sessionId, required this.item});
  final String sessionId;
  final BatchItem item;

  @override
  ConsumerState<BatchCookChecklistSheet> createState() => _BatchCookChecklistSheetState();
}

class _BatchCookChecklistSheetState extends ConsumerState<BatchCookChecklistSheet> {
  late bool _prepped = widget.item.progress.prepped;
  late bool _cooked = widget.item.progress.cooked;
  late bool _portioned = widget.item.progress.portioned;
  late final TextEditingController _noteCtrl = TextEditingController(text: widget.item.progress.note ?? '');
  late final TextEditingController _servCtrl = TextEditingController(text: widget.item.targetServings.toString());
  late final TextEditingController _portionsCtrl = TextEditingController(text: widget.item.portions.toString());

  @override
  void dispose() {
    _noteCtrl.dispose();
    _servCtrl.dispose();
    _portionsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          builder: (context, controller) => Scaffold(
            appBar: AppBar(
              title: const Text('Cook Checklist'),
              automaticallyImplyLeading: false,
              actions: [
                TextButton(
                  onPressed: () async {
                    final sess = await ref.read(batchSessionServiceProvider).byId(widget.sessionId);
                    if (sess == null) return;
                    final idx = sess.items.indexWhere((x) => x.recipeId == widget.item.recipeId);
                    if (idx < 0) return;
                    final updated = [...sess.items];
                    final newServ = int.tryParse(_servCtrl.text.trim());
                    final newPortions = int.tryParse(_portionsCtrl.text.trim());
                    updated[idx] = updated[idx].copyWith(
                      targetServings: newServ ?? updated[idx].targetServings,
                      portions: newPortions ?? updated[idx].portions,
                      progress: BatchProgress(
                        prepped: _prepped,
                        cooked: _cooked,
                        portioned: _portioned,
                        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
                      ),
                    );
                    await ref.read(batchSessionServiceProvider).upsert(sess.copyWith(
                          started: true,
                          items: updated,
                        ));
                    if (mounted) Navigator.of(context).pop(true);
                    ref.invalidate(batchSessionsProvider);
                    ref.invalidate(batchSessionByIdProvider(widget.sessionId));
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
            body: ListView(
              controller: controller,
              padding: const EdgeInsets.all(16),
              children: [
                CheckboxListTile(
                  value: _prepped,
                  onChanged: (v) => setState(() => _prepped = v ?? false),
                  title: const Text('Prepped'),
                ),
                CheckboxListTile(
                  value: _cooked,
                  onChanged: (v) => setState(() => _cooked = v ?? false),
                  title: const Text('Cooked'),
                ),
                CheckboxListTile(
                  value: _portioned,
                  onChanged: (v) => setState(() => _portioned = v ?? false),
                  title: const Text('Portioned'),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _servCtrl,
                        decoration: const InputDecoration(labelText: 'Target servings'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _portionsCtrl,
                        decoration: const InputDecoration(labelText: 'Portions'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                TextField(
                  controller: _noteCtrl,
                  decoration: const InputDecoration(labelText: 'Note (optional)'),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
