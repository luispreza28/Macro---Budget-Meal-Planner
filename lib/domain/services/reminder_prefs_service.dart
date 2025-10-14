import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../presentation/providers/database_providers.dart';

final reminderPrefsServiceProvider =
    Provider<ReminderPrefsService>((ref) => ReminderPrefsService(ref));

class ReminderPrefsService {
  ReminderPrefsService(this.ref);
  final Ref ref;

  static const _kShopEnabled = 'reminders.shop.enabled.v1';
  static const _kShopDay = 'reminders.shop.day.v1'; // 1..7 (Mon=1)
  static const _kShopTimeH = 'reminders.shop.timeH.v1';
  static const _kShopTimeM = 'reminders.shop.timeM.v1';

  static const _kPrepEnabled = 'reminders.prep.enabled.v1';
  static const _kPrepTimeH = 'reminders.prep.timeH.v1';
  static const _kPrepTimeM = 'reminders.prep.timeM.v1';

  static const _kReplenishEnabled = 'reminders.replenish.enabled.v1';
  static const _kReplenishTimeH = 'reminders.replenish.timeH.v1';
  static const _kReplenishTimeM = 'reminders.replenish.timeM.v1';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  Future<bool> shopEnabled() async => _prefs.getBool(_kShopEnabled) ?? true;
  Future<void> setShopEnabled(bool v) async => _prefs.setBool(_kShopEnabled, v);

  Future<int> shopDay() async =>
      _prefs.getInt(_kShopDay) ?? DateTime.monday; // 1..7
  Future<void> setShopDay(int day) async => _prefs.setInt(_kShopDay, day);

  Future<TimeOfDay> shopTime() async {
    return TimeOfDay(
      hour: _prefs.getInt(_kShopTimeH) ?? 9,
      minute: _prefs.getInt(_kShopTimeM) ?? 0,
    );
  }

  Future<void> setShopTime(TimeOfDay t) async {
    await _prefs.setInt(_kShopTimeH, t.hour);
    await _prefs.setInt(_kShopTimeM, t.minute);
  }

  Future<bool> prepEnabled() async => _prefs.getBool(_kPrepEnabled) ?? false;
  Future<void> setPrepEnabled(bool v) async => _prefs.setBool(_kPrepEnabled, v);

  Future<TimeOfDay> prepTime() async {
    return TimeOfDay(
      hour: _prefs.getInt(_kPrepTimeH) ?? 18,
      minute: _prefs.getInt(_kPrepTimeM) ?? 0,
    );
  }

  Future<void> setPrepTime(TimeOfDay t) async {
    await _prefs.setInt(_kPrepTimeH, t.hour);
    await _prefs.setInt(_kPrepTimeM, t.minute);
  }

  Future<bool> replenishEnabled() async =>
      _prefs.getBool(_kReplenishEnabled) ?? true;
  Future<void> setReplenishEnabled(bool v) async =>
      _prefs.setBool(_kReplenishEnabled, v);

  Future<TimeOfDay> replenishTime() async {
    return TimeOfDay(
      hour: _prefs.getInt(_kReplenishTimeH) ?? 20,
      minute: _prefs.getInt(_kReplenishTimeM) ?? 0,
    );
  }

  Future<void> setReplenishTime(TimeOfDay t) async {
    await _prefs.setInt(_kReplenishTimeH, t.hour);
    await _prefs.setInt(_kReplenishTimeM, t.minute);
  }
}

