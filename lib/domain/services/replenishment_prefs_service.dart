import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final replenishmentPrefsServiceProvider = Provider<ReplenishmentPrefsService>((_) => ReplenishmentPrefsService());

class ReplenishmentPrefsService {
  static const _k = 'replenish.prefs.v1'; // Map<ingredientId, PrefJson>

  Future<SharedPreferences> _sp() => SharedPreferences.getInstance();

  Future<Map<String, ReplenishPref>> all() async {
    final raw = (await _sp()).getString(_k);
    if (raw == null) return {};
    try {
      final m = (jsonDecode(raw) as Map).cast<String, Map<String, dynamic>>();
      return m.map((k, v) => MapEntry(k, ReplenishPref.fromJson(v)));
    } catch (_) {
      if (kDebugMode) {
        debugPrint('[Replenish] prefs decode failed, resetting');
      }
      return {};
    }
  }

  Future<ReplenishPref?> get(String ingredientId) async {
    final m = await all();
    return m[ingredientId];
  }

  Future<void> upsert(String ingredientId, ReplenishPref pref) async {
    final sp = await _sp();
    final m = await all();
    m[ingredientId] = pref;
    await sp.setString(
      _k,
      jsonEncode(m.map((k, v) => MapEntry(k, v.toJson()))),
    );
  }

  Future<void> remove(String ingredientId) async {
    final sp = await _sp();
    final m = await all();
    m.remove(ingredientId);
    await sp.setString(
      _k,
      jsonEncode(m.map((k, v) => MapEntry(k, v.toJson()))),
    );
  }
}

class ReplenishPref {
  final double parQty; // in ingredient base unit
  final double minBuyQty; // suggested purchase size (base unit)
  final bool autoSuggest; // include in suggestions automatically
  const ReplenishPref({this.parQty = 0, this.minBuyQty = 0, this.autoSuggest = true});

  Map<String, dynamic> toJson() => {
        'parQty': parQty,
        'minBuyQty': minBuyQty,
        'autoSuggest': autoSuggest,
      };

  factory ReplenishPref.fromJson(Map<String, dynamic> j) => ReplenishPref(
        parQty: (j['parQty'] ?? 0).toDouble(),
        minBuyQty: (j['minBuyQty'] ?? 0).toDouble(),
        autoSuggest: j['autoSuggest'] ?? true,
      );
}

