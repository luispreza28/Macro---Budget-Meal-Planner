import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/ingredient.dart' as domain;

final pantryExpiryServiceProvider = Provider<PantryExpiryService>((_) => PantryExpiryService());

class PantryExpiryService {
  static const _kItems = 'pantry.expiry.items.v1'; // List<PantryItem>
  Future<SharedPreferences> _sp() => SharedPreferences.getInstance();

  Future<List<PantryItem>> list() async {
    final raw = (await _sp()).getString(_kItems);
    if (raw == null) return const [];
    final xs = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
    final items = xs.map(PantryItem.fromJson).toList();
    if (kDebugMode) {
      debugPrint('[PantryExpiry] list -> ${items.length}');
    }
    return items;
  }

  Future<void> upsert(PantryItem item) async {
    final sp = await _sp();
    final xs = await list();
    final i = xs.indexWhere((x) => x.id == item.id);
    if (i >= 0) {
      xs[i] = item;
    } else {
      xs.insert(0, item);
    }
    await sp.setString(_kItems, jsonEncode(xs.map((e) => e.toJson()).toList()));
    if (kDebugMode) {
      debugPrint('[PantryExpiry] upsert id=${item.id} consumed=${item.consumed} discarded=${item.discarded}');
    }
  }

  Future<void> remove(String id) async {
    final sp = await _sp();
    final xs = await list()..removeWhere((x) => x.id == id);
    await sp.setString(_kItems, jsonEncode(xs.map((e) => e.toJson()).toList()));
    if (kDebugMode) {
      debugPrint('[PantryExpiry] remove id=$id');
    }
  }
}

class PantryItem {
  final String id; // uuid
  final String ingredientId;
  final double qty; // remaining qty in ingredient base unit
  final domain.Unit unit; // base unit
  final DateTime addedAt;
  final DateTime? openedAt; // null = unopened
  final DateTime? bestBy; // best-by date (soft)
  final DateTime? expiresAt; // hard expiry (if known)
  final String? note;
  final bool consumed; // fully consumed & archived
  final bool discarded; // fully discarded & archived

  const PantryItem({
    required this.id,
    required this.ingredientId,
    required this.qty,
    required this.unit,
    required this.addedAt,
    this.openedAt,
    this.bestBy,
    this.expiresAt,
    this.note,
    this.consumed = false,
    this.discarded = false,
  });

  PantryItem copyWith({
    double? qty,
    DateTime? openedAt,
    DateTime? bestBy,
    DateTime? expiresAt,
    String? note,
    bool? consumed,
    bool? discarded,
  }) => PantryItem(
        id: id,
        ingredientId: ingredientId,
        qty: qty ?? this.qty,
        unit: unit,
        addedAt: addedAt,
        openedAt: openedAt ?? this.openedAt,
        bestBy: bestBy ?? this.bestBy,
        expiresAt: expiresAt ?? this.expiresAt,
        note: note ?? this.note,
        consumed: consumed ?? this.consumed,
        discarded: discarded ?? this.discarded,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'ingredientId': ingredientId,
        'qty': qty,
        'unit': unit.value,
        'addedAt': addedAt.toIso8601String(),
        'openedAt': openedAt?.toIso8601String(),
        'bestBy': bestBy?.toIso8601String(),
        'expiresAt': expiresAt?.toIso8601String(),
        'note': note,
        'consumed': consumed,
        'discarded': discarded,
      };

  factory PantryItem.fromJson(Map<String, dynamic> j) => PantryItem(
        id: j['id'],
        ingredientId: j['ingredientId'],
        qty: (j['qty'] as num).toDouble(),
        unit: _unitFrom(j['unit']),
        addedAt: DateTime.parse(j['addedAt']),
        openedAt: j['openedAt'] != null ? DateTime.parse(j['openedAt']) : null,
        bestBy: j['bestBy'] != null ? DateTime.parse(j['bestBy']) : null,
        expiresAt: j['expiresAt'] != null ? DateTime.parse(j['expiresAt']) : null,
        note: j['note'],
        consumed: j['consumed'] ?? false,
        discarded: j['discarded'] ?? false,
      );
}

domain.Unit _unitFrom(String v) {
  switch (v) {
    case 'g':
      return domain.Unit.grams;
    case 'ml':
      return domain.Unit.milliliters;
    default:
      return domain.Unit.piece;
  }
}

