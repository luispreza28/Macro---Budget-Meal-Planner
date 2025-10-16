import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final leftoversOverlayServiceProvider = Provider<LeftoversOverlayService>((_) => LeftoversOverlayService());

class LeftoversOverlayService {
  static const _kTag = '[LeftoverOverlay]';
  // Keyed by planWeekKey: "planId|YYYY-Www" -> List<LeftoverPlacement>
  static const _kOverlays = 'leftovers.overlays.v1';
  static const _kAutoEnabled = 'leftovers.auto.enabled.v1'; // Map<planWeekKey,bool>

  Future<SharedPreferences> _sp() => SharedPreferences.getInstance();

  String planWeekKey({required String planId, required DateTime weekStart}) {
    final week = _isoWeekKey(weekStart);
    return '$planId|$week';
  }

  Future<List<LeftoverPlacement>> listFor(String planWeekKey) async {
    final raw = (await _sp()).getString(_kOverlays);
    if (raw == null) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return const [];
    final Map<String, dynamic> map = decoded.cast<String, dynamic>();
    final list = (map[planWeekKey] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final xs = list.map(LeftoverPlacement.fromJson).toList();
    if (kDebugMode) {
      debugPrint('$_kTag loaded ${xs.length} placements for $planWeekKey');
    }
    return xs;
  }

  Future<void> saveAll(String planWeekKey, List<LeftoverPlacement> xs) async {
    final sp = await _sp();
    final raw = sp.getString(_kOverlays);
    final Map<String, List<Map<String, dynamic>>> m = raw == null
        ? <String, List<Map<String, dynamic>>>{}
        : (jsonDecode(raw) as Map)
            .map((k, v) => MapEntry(k as String, (v as List).cast<Map<String, dynamic>>()));
    m[planWeekKey] = xs.map((e) => e.toJson()).toList();
    await sp.setString(_kOverlays, jsonEncode(m));
    if (kDebugMode) {
      debugPrint('$_kTag saved ${xs.length} placements for $planWeekKey');
    }
  }

  Future<bool> autoEnabled(String planWeekKey) async {
    final raw = (await _sp()).getString(_kAutoEnabled);
    if (raw == null) return false;
    final m = (jsonDecode(raw) as Map).cast<String, dynamic>();
    return (m[planWeekKey] as bool?) ?? false;
  }

  Future<void> setAutoEnabled(String planWeekKey, bool v) async {
    final sp = await _sp();
    final raw = sp.getString(_kAutoEnabled);
    final m = raw == null ? <String, bool>{} : (jsonDecode(raw) as Map).cast<String, bool>();
    m[planWeekKey] = v;
    await sp.setString(_kAutoEnabled, jsonEncode(m));
    if (kDebugMode) {
      debugPrint('$_kTag autoEnabled[$planWeekKey]=$v');
    }
  }

  String _isoWeekKey(DateTime d) {
    // Simple ISO week-ish key: YYYY-Www (week starting Monday from given weekStart param)
    final y = d.year;
    final w = ((DateTime.utc(d.year, d.month, d.day)
                    .difference(DateTime.utc(d.year, 1, 1))
                    .inDays) /
                7)
            .floor() +
        1;
    final ww = w.toString().padLeft(2, '0');
    return '$y-W$ww';
  }
}

class LeftoverPlacement {
  final String portionId; // PreparedPortion.id (links inventory)
  final String recipeId;
  final int dayIndex; // 0..6
  final int mealIndex; // within day (usually 0..n-1)
  final int servings; // default 1 per placement
  final bool confirmed; // user approved (applied); false means suggested
  const LeftoverPlacement({
    required this.portionId,
    required this.recipeId,
    required this.dayIndex,
    required this.mealIndex,
    required this.servings,
    required this.confirmed,
  });

  LeftoverPlacement copyWith({int? dayIndex, int? mealIndex, int? servings, bool? confirmed}) => LeftoverPlacement(
        portionId: portionId,
        recipeId: recipeId,
        dayIndex: dayIndex ?? this.dayIndex,
        mealIndex: mealIndex ?? this.mealIndex,
        servings: servings ?? this.servings,
        confirmed: confirmed ?? this.confirmed,
      );

  Map<String, dynamic> toJson() => {
        'portionId': portionId,
        'recipeId': recipeId,
        'dayIndex': dayIndex,
        'mealIndex': mealIndex,
        'servings': servings,
        'confirmed': confirmed,
      };

  factory LeftoverPlacement.fromJson(Map<String, dynamic> j) => LeftoverPlacement(
        portionId: j['portionId'],
        recipeId: j['recipeId'],
        dayIndex: j['dayIndex'],
        mealIndex: j['mealIndex'],
        servings: j['servings'],
        confirmed: j['confirmed'] ?? false,
      );
}

