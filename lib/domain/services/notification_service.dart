import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationServiceProvider =
    Provider<NotificationService>((ref) => NotificationService());

class NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    if (kDebugMode) {
      // ignore: avoid_print
      print('[Reminders] notifications initialized');
    }
  }

  Future<bool> requestPermissionIfNeeded() async {
    final ios = await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    final mac = await _plugin
        .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    // Android 13+ permission:
    final android = await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    final granted = (ios ?? true) && (mac ?? true) && (android ?? true);
    if (kDebugMode) {
      // ignore: avoid_print
      print('[Reminders] permission result: $granted');
    }
    return granted;
  }

  Future<void> scheduleDaily({
    required int id,
    required TimeOfDay time,
    required String title,
    required String body,
    String? payload,
    String androidChannelId = 'reminders',
    String androidChannelName = 'Reminders',
  }) async {
    final tzTime = Time(time.hour, time.minute);
    await _plugin.showDailyAtTime(
      id,
      title,
      body,
      tzTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          androidChannelId,
          androidChannelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: payload,
    );
    if (kDebugMode) {
      // ignore: avoid_print
      print('[Reminders] scheduled daily id=$id at ${time.hour}:${time.minute.toString().padLeft(2, '0')}');
    }
  }

  Future<void> scheduleWeeklyOnDay({
    required int id,
    required Day day,
    required TimeOfDay time,
    required String title,
    required String body,
    String? payload,
    String androidChannelId = 'reminders',
    String androidChannelName = 'Reminders',
  }) async {
    await _plugin.showWeeklyAtDayAndTime(
      id,
      title,
      body,
      day,
      Time(time.hour, time.minute),
      NotificationDetails(
        android: AndroidNotificationDetails(
          androidChannelId,
          androidChannelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: payload,
    );
    if (kDebugMode) {
      // ignore: avoid_print
      print('[Reminders] scheduled weekly id=$id on $day @ ${time.hour}:${time.minute.toString().padLeft(2, '0')}');
    }
  }

  Future<void> cancel(int id) async {
    await _plugin.cancel(id);
    if (kDebugMode) {
      // ignore: avoid_print
      print('[Reminders] canceled id=$id');
    }
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
    if (kDebugMode) {
      // ignore: avoid_print
      print('[Reminders] canceled all');
    }
  }
}

