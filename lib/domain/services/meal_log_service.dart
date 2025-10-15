import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final mealLogServiceProvider = Provider<MealLogService>((ref) => MealLogService());

class MealLogService {
  static const _kKey = 'meal.log.v1'; // JSON list of entries
  Future<SharedPreferences> _sp() => SharedPreferences.getInstance();

  Future<List<MealLogEntry>> list() async {
    final raw = (await _sp()).getString(_kKey);
    if (raw == null) return const [];
    try {
      final xs = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      return xs.map(MealLogEntry.fromJson).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('[MealLog] decode failed: $e');
      return const [];
    }
  }

  Future<void> append(MealLogEntry e) async {
    final sp = await _sp();
    final xs = await list();
    await sp.setString(_kKey, jsonEncode([e.toJson(), ...xs].take(500).toList())); // cap
  }

  Future<void> remove(String id) async {
    final sp = await _sp();
    final xs = await list();
    await sp.setString(_kKey, jsonEncode(xs.where((e) => e.id != id).map((e) => e.toJson()).toList()));
  }
}

class MealLogEntry {
  final String id; // uuid
  final String recipeId;
  final DateTime cookedAt;
  final int servingsCooked; // int ≥1
  const MealLogEntry({required this.id, required this.recipeId, required this.cookedAt, required this.servingsCooked});
  Map<String, dynamic> toJson() => {
        'id': id,
        'recipeId': recipeId,
        'cookedAt': cookedAt.toIso8601String(),
        'servingsCooked': servingsCooked,
      };
  factory MealLogEntry.fromJson(Map<String, dynamic> j) => MealLogEntry(
        id: j['id'],
        recipeId: j['recipeId'],
        cookedAt: DateTime.parse(j['cookedAt']),
        servingsCooked: j['servingsCooked'],
      );
}

