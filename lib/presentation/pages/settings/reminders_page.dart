import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/plan.dart';
import '../../providers/plan_providers.dart';
import '../../providers/reminder_providers.dart';
import '../../../domain/services/reminder_settings_service.dart';
import '../../router/app_router.dart';

class RemindersSettingsPage extends ConsumerStatefulWidget {
  const RemindersSettingsPage({super.key});

  @override
  ConsumerState<RemindersSettingsPage> createState() => _RemindersSettingsPageState();
}

class _RemindersSettingsPageState extends ConsumerState<RemindersSettingsPage> {
  ReminderSettings _s = const ReminderSettings();
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final s = await ref.read(reminderSettingsServiceProvider).get();
    if (!mounted) return;
    setState(() {
      _s = s;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final plan = ref.watch(currentPlanProvider).asData?.value;
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) {
            if (context.canPop()) {
              return IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back',
                onPressed: () => context.pop(),
              );
            }
            return IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: 'Home',
              onPressed: () => context.go(AppRouter.home),
            );
          },
        ),
        title: const Text('Reminders & Widgets'),
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                SwitchListTile(
                  title: const Text('Enable Reminders'),
                  value: _s.enabled,
                  onChanged: (v) => setState(() => _s = _s.copyWith(enabled: v)),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Meal reminders'),
                  subtitle: Text('${_s.breakfastTime} • ${_s.lunchTime} • ${_s.dinnerTime}'),
                  value: _s.mealReminders,
                  onChanged: (v) => setState(() => _s = _s.copyWith(mealReminders: v)),
                ),
                if (_s.mealReminders) _timeRow('Breakfast', _s.breakfastTime, (t) => _s = _s.copyWith(breakfastTime: t)),
                if (_s.mealReminders) _timeRow('Lunch', _s.lunchTime, (t) => _s = _s.copyWith(lunchTime: t)),
                if (_s.mealReminders) _timeRow('Dinner', _s.dinnerTime, (t) => _s = _s.copyWith(dinnerTime: t)),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Defrost tonight'),
                  subtitle: Text('At ${_s.defrostTime} when needed'),
                  value: _s.defrostReminder,
                  onChanged: (v) => setState(() => _s = _s.copyWith(defrostReminder: v)),
                ),
                if (_s.defrostReminder) _timeRow('Defrost time', _s.defrostTime, (t) => _s = _s.copyWith(defrostTime: t)),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Shop reminder'),
                  subtitle: Text('At ${_s.shopTime} if items outstanding'),
                  value: _s.shopReminder,
                  onChanged: (v) => setState(() => _s = _s.copyWith(shopReminder: v)),
                ),
                if (_s.shopReminder) _timeRow('Shop time', _s.shopTime, (t) => _s = _s.copyWith(shopTime: t)),
                const Divider(height: 1),
                ListTile(
                  title: const Text('Snooze default'),
                  subtitle: Text('${_s.snoozeMinutes} minutes'),
                  trailing: DropdownButton<int>(
                    value: _s.snoozeMinutes,
                    items: const [15, 30, 60]
                        .map((m) => DropdownMenuItem<int>(value: m, child: Text('$m')))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _s = _s.copyWith(snoozeMinutes: v));
                    },
                  ),
                ),
                const SizedBox(height: 8),
                _sectionHeader('Widget Options'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Home/lock-screen widget shows next two meals and quick actions.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: FilledButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Update Widget Now'),
                    onPressed: plan == null
                        ? null
                        : () async {
                            await ref.read(rescheduleRemindersProvider(plan).future);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Widget refreshed')),
                            );
                          },
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: FilledButton(
                    onPressed: () async {
                      await ref.read(reminderSettingsServiceProvider).save(_s);
                      final p = ref.read(currentPlanProvider).asData?.value;
                      if (p != null) {
                        await ref.read(rescheduleRemindersProvider(p).future);
                      }
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Reminder settings saved')),
                      );
                    },
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _timeRow(String label, String hhmm, void Function(String) onChanged) {
    return ListTile(
      title: Text(label),
      subtitle: Text(hhmm),
      trailing: const Icon(Icons.access_time),
      onTap: () async {
        final parts = hhmm.split(':');
        final initial = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        final picked = await showTimePicker(context: context, initialTime: initial);
        if (picked != null) {
          final t = _formatTime(picked);
          setState(() => onChanged(t));
        }
      },
    );
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
        ),
      );
}

extension on ReminderSettings {
  ReminderSettings copyWith({
    bool? enabled,
    bool? mealReminders,
    String? breakfastTime,
    String? lunchTime,
    String? dinnerTime,
    bool? defrostReminder,
    String? defrostTime,
    bool? shopReminder,
    String? shopTime,
    int? snoozeMinutes,
  }) {
    return ReminderSettings(
      enabled: enabled ?? this.enabled,
      mealReminders: mealReminders ?? this.mealReminders,
      breakfastTime: breakfastTime ?? this.breakfastTime,
      lunchTime: lunchTime ?? this.lunchTime,
      dinnerTime: dinnerTime ?? this.dinnerTime,
      defrostReminder: defrostReminder ?? this.defrostReminder,
      defrostTime: defrostTime ?? this.defrostTime,
      shopReminder: shopReminder ?? this.shopReminder,
      shopTime: shopTime ?? this.shopTime,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
    );
  }
}

