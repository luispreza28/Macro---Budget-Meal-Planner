import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final leftoverCommitServiceProvider = Provider<LeftoverCommitService>((ref) => LeftoverCommitService());

class LeftoverCommitService {
  static const _kKey = 'leftover.commitments.v1'; // JSON { planId: { slotId: servingsCommittedInt } }
  Future<SharedPreferences> _sp() => SharedPreferences.getInstance();

  Future<Map<String, Map<String, int>>> all() async {
    final raw = (await _sp()).getString(_kKey);
    if (raw == null) return {};
    final m = (jsonDecode(raw) as Map<String, dynamic>);
    return m.map((plan, slots) => MapEntry(plan, (slots as Map).map((sid, v) => MapEntry(sid as String, (v as num).toInt()))));
  }

  Future<int> committed(String planId, String slotId) async {
    final m = await all();
    return m[planId]?[slotId] ?? 0;
  }

  Future<void> setCommitted(String planId, String slotId, int servings) async {
    final sp = await _sp();
    final m = await all();
    final slots = Map<String, int>.from(m[planId] ?? {});
    if (servings <= 0) {
      slots.remove(slotId);
    } else {
      slots[slotId] = servings;
    }
    m[planId] = slots;
    await sp.setString(_kKey, jsonEncode(m));
  }
}

