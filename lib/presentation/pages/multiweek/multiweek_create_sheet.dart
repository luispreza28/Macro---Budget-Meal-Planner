import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/multiweek_providers.dart';

class MultiweekCreateSheet extends ConsumerStatefulWidget {
  const MultiweekCreateSheet({super.key});

  @override
  ConsumerState<MultiweekCreateSheet> createState() => _MultiweekCreateSheetState();
}

class _MultiweekCreateSheetState extends ConsumerState<MultiweekCreateSheet> {
  late TextEditingController _name;
  DateTime _start = _nextMonday();
  int _weeks = 2;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final month = DateFormat('MMMM').format(DateTime.now());
    _name = TextEditingController('Plan Series $month');
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  static DateTime _nextMonday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekday = today.weekday; // 1=Mon
    final delta = (8 - weekday) % 7; // days to next Monday (0 -> 0)
    final target = today.add(Duration(days: delta == 0 ? 7 : delta));
    return DateTime(target.year, target.month, target.day);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('New Multi-Week', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 12),
          Row(children: [
            const Text('Start week:'),
            const SizedBox(width: 12),
            TextButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _start,
                  firstDate: DateTime.now().subtract(const Duration(days: 1)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() => _start = DateTime(picked.year, picked.month, picked.day));
                }
              },
              child: Text(DateFormat('EEE, MMM d').format(_start)),
            ),
          ]),
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: [
            ChoiceChip(label: const Text('2 weeks'), selected: _weeks == 2, onSelected: (_) => setState(() => _weeks = 2)),
            ChoiceChip(label: const Text('3 weeks'), selected: _weeks == 3, onSelected: (_) => setState(() => _weeks = 3)),
            ChoiceChip(label: const Text('4 weeks'), selected: _weeks == 4, onSelected: (_) => setState(() => _weeks = 4)),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submitting
                  ? null
                  : () async {
                      setState(() => _submitting = true);
                      final id = newSeriesId();
                      try {
                        final args = GenerateSeriesArgs(seriesId: id, name: _name.text.trim().isEmpty ? 'Plan Series' : _name.text.trim(), week0Start: _start, weeks: _weeks);
                        await ref.read(generateSeriesPlansProvider(args).future);
                        if (!mounted) return;
                        Navigator.of(context).pop(id);
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                      } finally {
                        if (mounted) setState(() => _submitting = false);
                      }
                    },
              child: _submitting ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Generate'),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

