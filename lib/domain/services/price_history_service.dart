import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final priceHistoryServiceProvider =
    Provider<PriceHistoryService>((_) => PriceHistoryService());

/// Lightweight price history (offline-first) stored in SharedPreferences.
class PriceHistoryService {
  static const _k = 'price.history.v1'; // List<PricePoint>

  Future<SharedPreferences> _sp() => SharedPreferences.getInstance();

  Future<List<PricePoint>> all() async {
    final raw = (await _sp()).getString(_k);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => (e as Map).cast<String, dynamic>())
          .toList();
      return list.map(PricePoint.fromJson).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('[PriceHistory] parse error: $e');
      return const [];
    }
  }

  Future<void> add(PricePoint p) async {
    final sp = await _sp();
    final list = await all();
    final next = [...list, p];
    await sp.setString(_k, jsonEncode(next.map((e) => e.toJson()).toList()));
  }
}

class PricePoint {
  const PricePoint({
    required this.id,
    required this.ingredientId,
    required this.storeId,
    required this.ppuCents,
    required this.unit,
    required this.at,
    this.source,
  });

  final String id;
  final String ingredientId;
  final String storeId;
  final int ppuCents; // price per base-unit in cents
  final String unit; // 'g'|'ml'|'piece'
  final DateTime at;
  final String? source;

  Map<String, dynamic> toJson() => {
        'id': id,
        'ingredientId': ingredientId,
        'storeId': storeId,
        'ppuCents': ppuCents,
        'unit': unit,
        'at': at.toIso8601String(),
        'source': source,
      };

  factory PricePoint.fromJson(Map<String, dynamic> j) => PricePoint(
        id: j['id'] as String,
        ingredientId: j['ingredientId'] as String,
        storeId: j['storeId'] as String,
        ppuCents: (j['ppuCents'] as num).toInt(),
        unit: j['unit'] as String,
        at: DateTime.parse(j['at'] as String),
        source: j['source'] as String?,
      );
}

