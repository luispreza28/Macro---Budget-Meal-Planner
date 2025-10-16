import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final routePrefsServiceProvider = Provider<RoutePrefsService>((_) => RoutePrefsService());

class RoutePrefsService {
  static String _kMode(String planId) => 'route.mode.$planId.v1'; // 'normal'|'instore'
  static String _kCollapsed(String planId) => 'route.collapsed.$planId.v1'; // Set<String> section keys
  static String _kUncheckedOnly(String planId) => 'route.unchecked.$planId.v1'; // bool

  Future<SharedPreferences> _sp() => SharedPreferences.getInstance();

  Future<String> mode(String planId) async => (await _sp()).getString(_kMode(planId)) ?? 'normal';
  Future<void> setMode(String planId, String mode) async => (await _sp()).setString(_kMode(planId), mode);

  Future<Set<String>> collapsed(String planId) async {
    final raw = (await _sp()).getString(_kCollapsed(planId));
    if (raw == null) return <String>{};
    try {
      return (List<String>.from(jsonDecode(raw))).toSet();
    } catch (_) {
      return <String>{};
    }
  }

  Future<void> setCollapsed(String planId, Set<String> keys) async =>
      (await _sp()).setString(_kCollapsed(planId), jsonEncode(keys.toList()));

  Future<bool> uncheckedOnly(String planId) async => (await _sp()).getBool(_kUncheckedOnly(planId)) ?? false;
  Future<void> setUncheckedOnly(String planId, bool v) async => (await _sp()).setBool(_kUncheckedOnly(planId), v);
}

