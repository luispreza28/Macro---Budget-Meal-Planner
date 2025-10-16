import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final wasteLogServiceProvider = Provider<WasteLogService>((_) => WasteLogService());

class WasteLogService {
  static const _kWaste = 'waste.log.v1'; // List<WasteEvent>
  Future<SharedPreferences> _sp() => SharedPreferences.getInstance();

  Future<List<WasteEvent>> list() async {
    final raw = (await _sp()).getString(_kWaste);
    if (raw == null) return const [];
    final xs = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    final events = xs.map(WasteEvent.fromJson).toList();
    if (kDebugMode) {
      debugPrint('[WasteLog] list -> ${events.length}');
    }
    return events;
  }

  Future<void> add(WasteEvent e) async {
    final sp = await _sp();
    final xs = await list();
    xs.insert(0, e);
    await sp.setString(_kWaste, jsonEncode(xs.map((e) => e.toJson()).toList()));
    if (kDebugMode) {
      debugPrint('[WasteLog] add id=${e.id} reason=${e.reason} cents=${e.costCentsEstimate}');
    }
  }
}

class WasteEvent {
  final String id; // uuid
  final String ingredientId;
  final double qty;
  final String unit; // 'g' | 'ml' | 'piece'
  final DateTime at;
  final String reason; // 'expired' | 'spoiled' | 'other'
  final int costCentsEstimate;
  const WasteEvent({
    required this.id,
    required this.ingredientId,
    required this.qty,
    required this.unit,
    required this.at,
    required this.reason,
    required this.costCentsEstimate,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'ingredientId': ingredientId,
        'qty': qty,
        'unit': unit,
        'at': at.toIso8601String(),
        'reason': reason,
        'costCentsEstimate': costCentsEstimate,
      };
  factory WasteEvent.fromJson(Map<String, dynamic> j) => WasteEvent(
        id: j['id'],
        ingredientId: j['ingredientId'],
        qty: (j['qty'] as num).toDouble(),
        unit: j['unit'],
        at: DateTime.parse(j['at']),
        reason: j['reason'],
        costCentsEstimate: j['costCentsEstimate'] ?? 0,
      );
}

