import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../presentation/providers/database_providers.dart';

final splitPrefsServiceProvider = Provider<SplitPrefsService>((ref) => SplitPrefsService(ref));

class SplitPrefsService {
  SplitPrefsService(this.ref);
  final Ref ref;

  // Keys: by planId
  static String kMode(String planId) => 'split.mode.$planId.v1'; // 'single' | 'split'
  static String kCap(String planId) => 'split.cap.$planId.v1'; // int (1 or 2)
  static String kLocks(String planId) => 'split.locks.$planId.v1'; // Map<lineId, storeId>

  SharedPreferences get _sp => ref.read(sharedPreferencesProvider);

  Future<String> mode(String planId) async => _sp.getString(kMode(planId)) ?? 'single';
  Future<void> setMode(String planId, String m) async => _sp.setString(kMode(planId), m);

  Future<int> cap(String planId) async => _sp.getInt(kCap(planId)) ?? 2;
  Future<void> setCap(String planId, int cap) async => _sp.setInt(kCap(planId), cap);

  Future<Map<String, String>> locks(String planId) async {
    final raw = _sp.getString(kLocks(planId));
    if (raw == null) return {};
    try {
      return (jsonDecode(raw) as Map).map((k, v) => MapEntry(k as String, v as String));
    } catch (_) {
      return {};
    }
  }

  Future<void> setLock(String planId, String lineId, String? storeId) async {
    final m = await locks(planId);
    if (storeId == null || storeId.isEmpty) {
      m.remove(lineId);
    } else {
      m[lineId] = storeId;
    }
    await _sp.setString(kLocks(planId), jsonEncode(m));
  }
}

