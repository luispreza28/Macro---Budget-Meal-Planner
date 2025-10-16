import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/services/sub_rules_service.dart';
import '../../providers/sub_rules_providers.dart';
import '../../providers/ingredient_providers.dart';

class SubRuleEditorSheet extends ConsumerStatefulWidget {
  const SubRuleEditorSheet({super.key, this.initial});
  final SubRule? initial;

  @override
  ConsumerState<SubRuleEditorSheet> createState() => _SubRuleEditorSheetState();
}

class _SubRuleEditorSheetState extends ConsumerState<SubRuleEditorSheet> {
  SubAction _action = SubAction.prefer;
  final TextEditingController _fromCtrl = TextEditingController();
  final TextEditingController _toCtrl = TextEditingController();
  final TextEditingController _scopeCtrl = TextEditingController();
  final TextEditingController _ppuCtrl = TextEditingController();
  bool _enabled = true;

  @override
  void initState() {
    super.initState();
    final r = widget.initial;
    if (r != null) {
      _action = r.action;
      _fromCtrl.text = r.from.kind == 'ingredient' ? r.from.value : (r.from.kind == 'tag' ? '#${r.from.value}' : '*');
      _toCtrl.text = r.to == null
          ? ''
          : (r.to!.kind == 'ingredient' ? r.to!.value : '#${r.to!.value}');
      _scopeCtrl.text = r.scopeTags.join(',');
      _ppuCtrl.text = r.maxPpuCents?.toStringAsFixed(0) ?? '';
      _enabled = r.enabled;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ingAsync = ref.watch(allIngredientsProvider);
    final ingById = {for (final i in (ingAsync.value ?? const [])) i.id: i};

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Action'),
                  const SizedBox(width: 12),
                  SegmentedButton<SubAction>(
                    segments: const [
                      ButtonSegment(value: SubAction.always, label: Text('Always')),
                      ButtonSegment(value: SubAction.prefer, label: Text('Prefer')),
                      ButtonSegment(value: SubAction.never, label: Text('Never')),
                    ],
                    selected: {_action},
                    onSelectionChanged: (s) => setState(() => _action = s.first),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _fromCtrl,
                decoration: const InputDecoration(
                  labelText: 'From (ingredient id or #tag, or *)',
                ),
              ),
              const SizedBox(height: 12),
              if (_action != SubAction.never)
                TextField(
                  controller: _toCtrl,
                  decoration: const InputDecoration(
                    labelText: 'To (ingredient id)',
                  ),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: _scopeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Scope tags (comma separated)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _ppuCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Max PPU cents (optional)',
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Enabled'),
                value: _enabled,
                onChanged: (v) => setState(() => _enabled = v),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () async {
                      final id = widget.initial?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
                      final fromRaw = _fromCtrl.text.trim();
                      Target from;
                      if (fromRaw == '*' || fromRaw.isEmpty) {
                        from = const Target.any();
                      } else if (fromRaw.startsWith('#')) {
                        from = Target.tag(fromRaw.substring(1));
                      } else {
                        from = Target.ingredient(fromRaw);
                      }
                      Target? to;
                      if (_action != SubAction.never) {
                        final toRaw = _toCtrl.text.trim();
                        if (toRaw.isNotEmpty) {
                          to = Target.ingredient(toRaw);
                        }
                      }
                      final scope = _scopeCtrl.text
                          .split(',')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toList();
                      final ppu = _ppuCtrl.text.trim().isEmpty ? null : double.tryParse(_ppuCtrl.text.trim());
                      final rule = SubRule(
                        id: id,
                        action: _action,
                        from: from,
                        to: to,
                        scopeTags: scope,
                        maxPpuCents: ppu,
                        priority: widget.initial?.priority ?? 100,
                        enabled: _enabled,
                      );
                      await ref.read(subRulesServiceProvider).upsert(rule);
                      ref.invalidate(subRulesProvider);
                      ref.invalidate(subRulesIndexProvider);
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    child: const Text('Save'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

