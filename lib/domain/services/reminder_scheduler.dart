import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notification_service.dart';
import 'reminder_prefs_service.dart';

final reminderSchedulerProvider =
    Provider<ReminderScheduler>((ref) => ReminderScheduler(ref));

class ReminderScheduler {
  ReminderScheduler(this.ref);
  final Ref ref;

  // Notification IDs to avoid collisions (reserve ranges)
  static const int idShop = 10001;
  static const int idPrep = 10002;
  static const int idReplenish = 10003;

  Day _mapWeekdayToDayEnum(int weekday) {
    // DateTime.monday == 1 ... DateTime.sunday == 7
    switch (weekday) {
      case DateTime.monday:
        return Day.monday;
      case DateTime.tuesday:
        return Day.tuesday;
      case DateTime.wednesday:
        return Day.wednesday;
      case DateTime.thursday:
        return Day.thursday;
      case DateTime.friday:
        return Day.friday;
      case DateTime.saturday:
        return Day.saturday;
      case DateTime.sunday:
      default:
        return Day.sunday;
    }
  }

  Future<void> rescheduleAll() async {
    final notif = ref.read(notificationServiceProvider);
    await notif.init();
    await notif.requestPermissionIfNeeded();

    final prefs = ref.read(reminderPrefsServiceProvider);

    // Shop
    if (await prefs.shopEnabled()) {
      final day = await prefs.shopDay();
      final time = await prefs.shopTime();
      await notif.scheduleWeeklyOnDay(
        id: idShop,
        day: _mapWeekdayToDayEnum(day),
        time: time,
        title: 'Shopping day',
        body: 'Open your Shopping List and get the trip done 👟',
        payload: 'open:shopping_list',
      );
    } else {
      await notif.cancel(idShop);
    }

    // Prep
    if (await prefs.prepEnabled()) {
      await notif.scheduleDaily(
        id: idPrep,
        time: await prefs.prepTime(),
        title: 'Meal prep time',
        body: 'Prep tonight’s meals to stay on track 🍳',
        payload: 'open:plan_today',
      );
    } else {
      await notif.cancel(idPrep);
    }

    // Replenish
    if (await prefs.replenishEnabled()) {
      await notif.scheduleDaily(
        id: idReplenish,
        time: await prefs.replenishTime(),
        title: 'Restock pantry?',
        body:
            'Mark Purchased → Replenish Pantry from your Shopping List 🧺',
        payload: 'open:shopping_list_replenish',
      );
    } else {
      await notif.cancel(idReplenish);
    }

    if (kDebugMode) {
      // ignore: avoid_print
      print('[Reminders] rescheduled all');
    }
  }
}

