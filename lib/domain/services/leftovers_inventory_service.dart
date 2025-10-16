import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final leftoversInventoryServiceProvider = Provider<LeftoversInventoryService>((_) => LeftoversInventoryService());

class LeftoversInventoryService {
  static const _kTag = '[LeftoverInv]';
  // Stored as: List<PreparedPortion>
  static const _kInventory = 'leftovers.inventory.v1';

  Future<SharedPreferences> _sp() => SharedPreferences.getInstance();

  Future<List<PreparedPortion>> list() async {
    final raw = (await _sp()).getString(_kInventory);
    if (raw == null) return const [];
    final xs = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    final list = xs.map(PreparedPortion.fromJson).toList();
    if (kDebugMode) {
      debugPrint('$_kTag loaded ${list.length} portions');
    }
    return list;
  }

  Future<void> upsert(PreparedPortion p) async {
    final sp = await _sp();
    final all = await list();
    final i = all.indexWhere((x) => x.id == p.id);
    if (i >= 0) {
      all[i] = p;
    } else {
      all.insert(0, p);
    }
    await sp.setString(_kInventory, jsonEncode(all.map((e) => e.toJson()).toList()));
    if (kDebugMode) {
      debugPrint('$_kTag upserted ${p.id} (remain=${p.servingsRemaining})');
    }
  }

  Future<void> remove(String id) async {
    final sp = await _sp();
    final all = await list();
    all.removeWhere((x) => x.id == id);
    await sp.setString(_kInventory, jsonEncode(all.map((e) => e.toJson()).toList()));
    if (kDebugMode) {
      debugPrint('$_kTag removed $id');
    }
  }
}

class PreparedPortion {
  final String id; // uuid
  final String recipeId;
  final int servingsRemaining; // >=1
  final DateTime preparedAt;
  final DateTime expiresAt; // scheduling target
  const PreparedPortion({
    required this.id,
    required this.recipeId,
    required this.servingsRemaining,
    required this.preparedAt,
    required this.expiresAt,
  });

  PreparedPortion copyWith({int? servingsRemaining, DateTime? expiresAt}) => PreparedPortion(
        id: id,
        recipeId: recipeId,
        servingsRemaining: servingsRemaining ?? this.servingsRemaining,
        preparedAt: preparedAt,
        expiresAt: expiresAt ?? this.expiresAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'recipeId': recipeId,
        'servingsRemaining': servingsRemaining,
        'preparedAt': preparedAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
      };

  factory PreparedPortion.fromJson(Map<String, dynamic> j) => PreparedPortion(
        id: j['id'],
        recipeId: j['recipeId'],
        servingsRemaining: j['servingsRemaining'],
        preparedAt: DateTime.parse(j['preparedAt']),
        expiresAt: DateTime.parse(j['expiresAt']),
      );
}

