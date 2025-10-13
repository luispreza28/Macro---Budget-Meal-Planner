import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final planPinServiceProvider = Provider<PlanPinService>((ref) => PlanPinService(ref));

/// Slot identity uses string key: "d<M>-m<N>" (dayIndex, mealIndex)
class PlanPinService {
  PlanPinService(this.ref);
  final Ref ref;

  static String _keyForPlan(String planId) => 'pins.$planId'; // JSON map slotKey -> recipeId

  Future<Map<String, String>> getPins(String planId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyForPlan(planId));
    if (raw == null || raw.isEmpty) return <String, String>{};
    try {
      final map = jsonDecode(raw);
      if (map is Map) {
        return map.map((k, v) => MapEntry(k.toString(), v.toString()));
      }
    } catch (_) {
      // ignore malformed
    }
    return <String, String>{};
  }

  Future<void> setPin({
    required String planId,
    required String slotKey,
    required String recipeId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _keyForPlan(planId);
    final existing = await getPins(planId);
    existing[slotKey] = recipeId;
    await prefs.setString(key, jsonEncode(existing));
    if (kDebugMode) debugPrint('[Pins] setPin plan=$planId slot=$slotKey -> $recipeId');
  }

  Future<void> clearPin({
    required String planId,
    required String slotKey,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _keyForPlan(planId);
    final existing = await getPins(planId);
    existing.remove(slotKey);
    await prefs.setString(key, jsonEncode(existing));
    if (kDebugMode) debugPrint('[Pins] clearPin plan=$planId slot=$slotKey');
  }

  Future<bool> isPinned({
    required String planId,
    required String slotKey,
  }) async {
    final pins = await getPins(planId);
    return pins.containsKey(slotKey);
  }
}

