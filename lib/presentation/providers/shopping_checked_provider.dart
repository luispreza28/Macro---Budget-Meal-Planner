import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final shoppingCheckedStoreProvider = Provider<ShoppingCheckedStore>((ref) {
  return ShoppingCheckedStore();
});

class ShoppingCheckedStore {
  static String _key(String planId) => 'shopping_checked::$planId';

  Future<Set<String>> load(String planId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(planId));
    if (raw == null || raw.isEmpty) return <String>{};
    try {
      final list = (json.decode(raw) as List).cast<String>();
      return list.toSet();
    } catch (_) {
      return <String>{};
    }
  }

  Future<void> save(String planId, Set<String> keys) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(planId), json.encode(keys.toList()));
  }
}

class Debouncer {
  Debouncer(this.duration);

  final Duration duration;
  Timer? _timer;

  void call(VoidCallback fn) {
    _timer?.cancel();
    _timer = Timer(duration, fn);
  }

  void dispose() => _timer?.cancel();
}
