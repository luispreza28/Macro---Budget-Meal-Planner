import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final barcodeMappingServiceProvider =
    Provider<BarcodeMappingService>((ref) => BarcodeMappingService());

class BarcodeMappingService {
  static const _kMap = 'barcode.map.v1'; // Map<String barcode, String ingredientId>
  static const _kRecent = 'barcode.recent.v1'; // List<RecentScan>

  Future<SharedPreferences> _sp() => SharedPreferences.getInstance();

  Future<Map<String, String>> getMap() async {
    final raw = (await _sp()).getString(_kMap);
    if (raw == null) return {};
    return (jsonDecode(raw) as Map)
        .map((k, v) => MapEntry(k as String, v as String));
  }

  Future<void> upsert(String barcode, String ingredientId) async {
    final sp = await _sp();
    final m = await getMap();
    m[barcode] = ingredientId;
    await sp.setString(_kMap, jsonEncode(m));
  }

  Future<List<RecentScan>> recent() async {
    final raw = (await _sp()).getString(_kRecent);
    if (raw == null) return const [];
    final list = (jsonDecode(raw) as List)
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList();
    return list.map(RecentScan.fromJson).toList();
  }

  Future<void> pushRecent(RecentScan s) async {
    final sp = await _sp();
    final list = await recent();
    final next = [s, ...list].take(10).toList();
    await sp.setString(
      _kRecent,
      jsonEncode(next.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> removeRecent(String id) async {
    final sp = await _sp();
    final list = await recent();
    await sp.setString(
      _kRecent,
      jsonEncode(list
          .where((e) => e.id != id)
          .map((e) => e.toJson())
          .toList()),
    );
  }
}

class RecentScan {
  const RecentScan({
    required this.id,
    required this.barcode,
    this.ingredientId,
    this.label,
    required this.at,
  });

  final String id; // uuid
  final String barcode; // "0123456789012"
  final String? ingredientId; // after mapping
  final String? label; // user-entered name at scan time
  final DateTime at;

  Map<String, dynamic> toJson() => {
        'id': id,
        'barcode': barcode,
        'ingredientId': ingredientId,
        'label': label,
        'at': at.toIso8601String(),
      };

  factory RecentScan.fromJson(Map<String, dynamic> j) => RecentScan(
        id: j['id'] as String,
        barcode: j['barcode'] as String,
        ingredientId: j['ingredientId'] as String?,
        label: j['label'] as String?,
        at: DateTime.parse(j['at'] as String),
      );
}

