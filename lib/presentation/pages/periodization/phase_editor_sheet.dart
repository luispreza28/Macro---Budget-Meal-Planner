import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/services/periodization_service.dart';

class PhaseEditorSheet extends ConsumerStatefulWidget {
  const PhaseEditorSheet({super.key, required this.initial});
  final Phase? initial;

  @override
  ConsumerState<PhaseEditorSheet> createState() => _PhaseEditorSheetState();
}

class _PhaseEditorSheetState extends ConsumerState<PhaseEditorSheet> {
  late PhaseType _type;
  late DateTime _start;
  late DateTime _end;
  late TextEditingController _note;
  int? _presetWeeks;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _type = widget.initial?.type ?? PhaseType.maintain;
    _start = widget.initial?.start ?? DateTime(now.year, now.month, now.day);
    _end = widget.initial?.end ?? _start.add(const Duration(days: 7 * 4 - 1));
    _note = TextEditingController(text: widget.initial?.note ?? '');
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _start = DateTime(picked.year, picked.month, picked.day);
        // If preset is set, adjust end accordingly
        if (_presetWeeks != null) {
          _end = _start.add(Duration(days: _presetWeeks! * 7 - 1));
        }
      });
    }
  }

  Future<void> _pickEnd() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _end,
      firstDate: _start,
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _end = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat.MMMd();
    final insets = MediaQuery.of(context).viewInsets;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: insets.bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.initial == null ? 'New Phase' : 'Edit Phase',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SegmentedButton<PhaseType>(
                segments: const [
                  ButtonSegment(value: PhaseType.cut, label: Text('Cut')),
                  ButtonSegment(value: PhaseType.maintain, label: Text('Maintain')),
                  ButtonSegment(value: PhaseType.bulk, label: Text('Bulk')),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() => _type = s.first),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _pickStart,
                      child: Text('Start: ${fmt.format(_start)}'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _pickEnd,
                      child: Text('End: ${fmt.format(_end)}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'Preset Length'),
                value: _presetWeeks,
                items: const [
                  DropdownMenuItem(value: 4, child: Text('4 weeks')),
                  DropdownMenuItem(value: 8, child: Text('8 weeks')),
                  DropdownMenuItem(value: 12, child: Text('12 weeks')),
                ],
                onChanged: (v) {
                  setState(() {
                    _presetWeeks = v;
                    if (v != null) {
                      _end = _start.add(Duration(days: v * 7 - 1));
                    }
                  });
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _note,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: const Text('Cancel'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: () async {
                      // v1 conflict: latest-wins (keep all records)
                      final id = widget.initial?.id ?? const Uuid().v4();
                      final phase = Phase(
                        id: id,
                        type: _type,
                        start: _start,
                        end: _end,
                        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
                      );
                      if (!context.mounted) return;
                      Navigator.of(context).pop(phase);
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

