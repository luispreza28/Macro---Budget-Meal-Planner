import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final reminderSettingsServiceProvider = Provider<ReminderSettingsService>((_) => ReminderSettingsService());

class ReminderSettingsService {
  static const _k = 'reminders.settings.v1';
  Future<SharedPreferences> _sp() => SharedPreferences.getInstance();

  Future<ReminderSettings> get() async {
    final raw = (await _sp()).getString(_k);
    if (raw == null) return const ReminderSettings();
    return ReminderSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save(ReminderSettings s) async {
    final sp = await _sp();
    await sp.setString(_k, jsonEncode(s.toJson()));
  }
}

class ReminderSettings {
  final bool enabled;
  final bool mealReminders;
  final String breakfastTime;
  final String lunchTime;
  final String dinnerTime;
  final bool defrostReminder;
  final String defrostTime;
  final bool shopReminder;
  final String shopTime;
  final int snoozeMinutes;

  const ReminderSettings({
    this.enabled = true,
    this.mealReminders = true,
    this.breakfastTime = '07:30',
    this.lunchTime = '12:30',
    this.dinnerTime = '18:30',
    this.defrostReminder = true,
    this.defrostTime = '20:00',
    this.shopReminder = true,
    this.shopTime = '18:00',
    this.snoozeMinutes = 30,
  });

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'mealReminders': mealReminders,
        'breakfastTime': breakfastTime,
        'lunchTime': lunchTime,
        'dinnerTime': dinnerTime,
        'defrostReminder': defrostReminder,
        'defrostTime': defrostTime,
        'shopReminder': shopReminder,
        'shopTime': shopTime,
        'snoozeMinutes': snoozeMinutes,
      };

  factory ReminderSettings.fromJson(Map<String, dynamic> j) => ReminderSettings(
        enabled: j['enabled'] ?? true,
        mealReminders: j['mealReminders'] ?? true,
        breakfastTime: j['breakfastTime'] ?? '07:30',
        lunchTime: j['lunchTime'] ?? '12:30',
        dinnerTime: j['dinnerTime'] ?? '18:30',
        defrostReminder: j['defrostReminder'] ?? true,
        defrostTime: j['defrostTime'] ?? '20:00',
        shopReminder: j['shopReminder'] ?? true,
        shopTime: j['shopTime'] ?? '18:00',
        snoozeMinutes: (j['snoozeMinutes'] ?? 30).toInt(),
      );
}

