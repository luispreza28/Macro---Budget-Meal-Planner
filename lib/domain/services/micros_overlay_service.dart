import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final microsOverlayServiceProvider = Provider<MicrosOverlayService>((_) => MicrosOverlayService());

class MicrosOverlayService {
  static const _k = 'micros.overlay.v1'; // Map<ingredientId, MicrosPerHundredJson>

  Future<SharedPreferences> _sp() => SharedPreferences.getInstance();

  Future<Map<String, MicrosPerHundred>> getAll() async {
    final raw = (await _sp()).getString(_k);
    if (raw == null) return {};
    final m = (jsonDecode(raw) as Map).cast<String, dynamic>();
    return m.map((k, v) => MapEntry(k, MicrosPerHundred.fromJson((v as Map).cast<String, dynamic>())));
  }

  Future<MicrosPerHundred?> getFor(String ingredientId) async {
    final all = await getAll();
    return all[ingredientId];
  }

  Future<void> upsert(String ingredientId, MicrosPerHundred micros) async {
    final sp = await _sp();
    final all = await getAll();
    all[ingredientId] = micros;
    await sp.setString(_k, jsonEncode(all.map((k, v) => MapEntry(k, v.toJson()))));
    if (kDebugMode) {
      debugPrint('[Micros] overlay/upsert id=$ingredientId fiber=${micros.fiberG} sod=${micros.sodiumMg} sat=${micros.satFatG}');
    }
  }

  Future<void> remove(String ingredientId) async {
    final sp = await _sp();
    final all = await getAll();
    all.remove(ingredientId);
    await sp.setString(_k, jsonEncode(all.map((k, v) => MapEntry(k, v.toJson()))));
  }
}

class MicrosPerHundred {
  final double fiberG;   // per 100 g/ml or per piece (if ingredient base is piece)
  final double sodiumMg; // per 100
  final double satFatG;  // per 100
  const MicrosPerHundred({this.fiberG = 0, this.sodiumMg = 0, this.satFatG = 0});

  Map<String, dynamic> toJson() => {'fiberG': fiberG, 'sodiumMg': sodiumMg, 'satFatG': satFatG};
  factory MicrosPerHundred.fromJson(Map<String, dynamic> j) => MicrosPerHundred(
        fiberG: (j['fiberG'] ?? 0).toDouble(),
        sodiumMg: (j['sodiumMg'] ?? 0).toDouble(),
        satFatG: (j['satFatG'] ?? 0).toDouble(),
      );
}

