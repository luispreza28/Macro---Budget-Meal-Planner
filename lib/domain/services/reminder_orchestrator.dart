import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/plan.dart';
import '../../domain/entities/ingredient.dart' as domain;
import '../../presentation/providers/recipe_providers.dart';
import '../../presentation/providers/ingredient_providers.dart';
import '../../presentation/providers/shopping_list_providers.dart';
import '../../presentation/providers/plan_providers.dart';
import 'reminder_settings_service.dart';
import 'notification_service.dart';

final reminderOrchestratorProvider = Provider<ReminderOrchestrator>((ref) => ReminderOrchestrator(ref));

class ReminderOrchestrator {
  ReminderOrchestrator(this.ref);
  final Ref ref;

  static const _idBreakfast = 2001;
  static const _idLunch = 2002;
  static const _idDinner = 2003;
  static const _idDefrost = 2100;
  static const _idShop = 2200;

  Future<void> rescheduleAll({required Plan plan}) async {
    final settings = await ref.read(reminderSettingsServiceProvider).get();
    if (!settings.enabled) {
      await ref.read(notificationServiceProvider).cancelAll();
      return;
    }

    await ref.read(notificationServiceProvider).init();

    if (settings.mealReminders) {
      await _scheduleDaily(
        _idBreakfast,
        settings.breakfastTime,
        title: 'Breakfast',
        body: _mealBody(plan, 'breakfast'),
        payload: 'route=/plan',
      );
      await _scheduleDaily(
        _idLunch,
        settings.lunchTime,
        title: 'Lunch',
        body: _mealBody(plan, 'lunch'),
        payload: 'route=/plan',
      );
      await _scheduleDaily(
        _idDinner,
        settings.dinnerTime,
        title: 'Dinner',
        body: _mealBody(plan, 'dinner'),
        payload: 'route=/plan',
      );
    }

    if (settings.defrostReminder && await _needsDefrost(plan)) {
      await _scheduleOneShotToday(
        _idDefrost,
        settings.defrostTime,
        title: 'Defrost for tomorrow',
        body: 'You’ll need frozen items for tomorrow’s meals',
        payload: 'route=/plan',
      );
    }

    if (settings.shopReminder && await _hasOutstandingShopping(plan)) {
      await _scheduleDaily(
        _idShop,
        settings.shopTime,
        title: 'Shopping reminder',
        body: 'You still have items to buy for this week',
        payload: 'route=/shopping-list',
      );
    }
  }

  Future<void> snooze(int id, int minutes) async {
    final now = DateTime.now();
    final at = now.add(Duration(minutes: minutes));
    await ref.read(notificationServiceProvider).scheduleOneShot(
          id: id,
          localTime: at,
          title: 'Reminder',
          body: 'Snoozed',
          payload: 'route=/',
        );
  }

  Future<void> _scheduleDaily(
    int id,
    String hhmm, {
    required String title,
    required String body,
    required String payload,
  }) async {
    final parts = hhmm.split(':');
    final now = DateTime.now();
    final at = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
    await ref.read(notificationServiceProvider).scheduleAtLocal(
          id: id,
          localTime: at,
          title: title,
          body: body,
          payload: payload,
        );
  }

  Future<void> _scheduleOneShotToday(
    int id,
    String hhmm, {
    required String title,
    required String body,
    required String payload,
  }) async {
    final parts = hhmm.split(':');
    final now = DateTime.now();
    final at = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
    if (at.isAfter(now)) {
      await ref.read(notificationServiceProvider).scheduleOneShot(
            id: id,
            localTime: at,
            title: title,
            body: body,
            payload: payload,
          );
    }
  }

  Future<bool> _hasOutstandingShopping(Plan plan) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'shopping_checked_${plan.id}';
    final checked = (prefs.getStringList(key) ?? const <String>[]).toSet();
    final groups = await ref.read(shoppingListItemsProvider.future);
    int totalItems = 0;
    for (final g in groups) {
      totalItems += g.items.length;
    }
    return totalItems > checked.length;
  }

  Future<bool> _needsDefrost(Plan plan) async {
    final ings = {for (final i in await ref.read(allIngredientsProvider.future)) i.id: i};
    if (plan.days.length < 2) return false;
    final tomorrow = plan.days[1];
    for (final meal in tomorrow.meals) {
      final r = await ref.read(recipeByIdProvider(meal.recipeId).future);
      if (r == null) continue;
      if (r.dietFlags.contains('frozen')) return true;
      for (final it in r.items) {
        final ing = ings[it.ingredientId];
        if (ing != null && ing.tags.contains('frozen')) return true;
      }
    }
    return false;
  }

  String _mealBody(Plan plan, String slot) {
    return 'Check your plan for $slot';
  }
}

