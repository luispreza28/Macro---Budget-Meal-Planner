import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../domain/services/ics_export_service.dart';
import '../../../domain/services/multiweek_series_service.dart';
import '../../providers/multiweek_providers.dart';
import '../../providers/recipe_providers.dart';
import '../../providers/plan_providers.dart';

class CalendarExportSheet extends ConsumerStatefulWidget {
  final String seriesId;
  final int? selectedWeekIndex; // null => all weeks
  const CalendarExportSheet({super.key, required this.seriesId, required this.selectedWeekIndex});

  @override
  ConsumerState<CalendarExportSheet> createState() => _CalendarExportSheetState();
}

class _CalendarExportSheetState extends ConsumerState<CalendarExportSheet> {
  TimeOfDay _breakfast = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _lunch = const TimeOfDay(hour: 12, minute: 30);
  TimeOfDay _dinner = const TimeOfDay(hour: 18, minute: 30);
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final asyncSeries = ref.watch(multiweekSeriesByIdProvider(widget.seriesId));

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: asyncSeries.when(
        loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
        error: (e, st) => SizedBox(height: 200, child: Center(child: Text('Error: $e'))),
        data: (s) {
          if (s == null) return const SizedBox();
          final weeks = widget.selectedWeekIndex == null ? 'All Weeks' : 'Week ${widget.selectedWeekIndex! + 1}';
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Export $weeks to Calendar', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              _timeRow('Breakfast', _breakfast, (t) => setState(() => _breakfast = t)),
              _timeRow('Lunch', _lunch, (t) => setState(() => _lunch = t)),
              _timeRow('Dinner', _dinner, (t) => setState(() => _dinner = t)),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.save_alt),
                  label: Text(_busy ? 'Exporting…' : 'Export'),
                  onPressed: _busy
                      ? null
                      : () async {
                          setState(() => _busy = true);
                          try {
                            await _exportSeries(s);
                            if (!mounted) return;
                            Navigator.of(context).pop();
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
                          } finally {
                            if (mounted) setState(() => _busy = false);
                          }
                        },
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  Widget _timeRow(String label, TimeOfDay t, ValueChanged<TimeOfDay> onPick) {
    return Row(children: [
      Text(label),
      const SizedBox(width: 12),
      TextButton(
        onPressed: () async {
          final picked = await showTimePicker(context: context, initialTime: t);
          if (picked != null) onPick(picked);
        },
        child: Text(t.format(context)),
      )
    ]);
  }

  Future<void> _exportSeries(MultiweekSeries s) async {
    final recipes = await ref.read(allRecipesProvider.future);
    final recipeById = {for (final r in recipes) r.id: r};
    final planIds = widget.selectedWeekIndex == null ? s.planIds : [s.planIds[widget.selectedWeekIndex!]];

    final events = <IcsEvent>[];
    for (int wi = 0; wi < planIds.length; wi++) {
      final pid = planIds[wi];
      final plan = await ref.read(planByIdProvider(pid).future);
      if (plan == null) continue;
      for (int d = 0; d < plan.days.length; d++) {
        final day = plan.days[d];
        final date = DateTime.tryParse(day.date);
        if (date == null) continue;
        for (int m = 0; m < day.meals.length; m++) {
          final meal = day.meals[m];
          final recipe = recipeById[meal.recipeId];
          if (recipe == null) continue;
          final tod = _timeForIndex(m);
          final start = DateTime(date.year, date.month, date.day, tod.hour, tod.minute);
          final end = start.add(const Duration(minutes: 45));
          final summary = '${recipe.name} (serv x${meal.servings.toStringAsFixed(0)})';
          final kcal = recipe.macrosPerServ.kcal.round();
          final p = recipe.macrosPerServ.proteinG.round();
          final c = recipe.macrosPerServ.carbsG.round();
          final f = recipe.macrosPerServ.fatG.round();
          final desc = 'kcal $kcal • P $p • C $c • F $f per serving';
          events.add(IcsEvent(
            uid: '$pid-$d-$m@macroplanner',
            start: start,
            end: end,
            summary: summary,
            description: desc,
          ));
        }
      }
    }

    final file = await IcsExportService().buildIcs(
      calendarName: s.name,
      events: events,
      filenameHint: _filenameFor(s, widget.selectedWeekIndex),
    );
    await Share.shareXFiles([XFile(file.path)], text: 'Meal plan calendar');
  }

  String _filenameFor(MultiweekSeries s, int? idx) {
    final fmt = DateFormat('yyyyMMdd');
    if (idx == null) {
      final start = s.week0Start;
      final end = s.week0Start.add(Duration(days: 7 * s.weeks - 1));
      return 'meal_plan_${fmt.format(start)}_${fmt.format(end)}';
    } else {
      final wkStart = s.week0Start.add(Duration(days: 7 * idx));
      final wkEnd = wkStart.add(const Duration(days: 6));
      return 'meal_plan_${fmt.format(wkStart)}_${fmt.format(wkEnd)}';
    }
  }

  TimeOfDay _timeForIndex(int mealIndex) {
    // Map 0->breakfast, 1->lunch, 2+ -> dinner
    if (mealIndex == 0) return _breakfast;
    if (mealIndex == 1) return _lunch;
    return _dinner;
  }
}

