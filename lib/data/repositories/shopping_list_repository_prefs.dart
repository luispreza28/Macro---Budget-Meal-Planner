import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/ingredient.dart';
import '../../domain/repositories/shopping_list_repository.dart';
import '../../domain/value/shortfall_item.dart';

class ShoppingListRepositoryPrefs implements ShoppingListRepository {
  ShoppingListRepositoryPrefs(this._prefs);

  final SharedPreferences _prefs;

  @override
  Future<void> addShortfalls(List<ShortfallItem> items, {String? planId}) async {
    if (items.isEmpty) return;
    final key = _key(planId);
    final existing = _loadExtras(key);

    // Merge items by (ingredientId, unit)
    final Map<String, _ExtraItem> byKey = {
      for (final e in existing) _pairKey(e.ingredientId, e.unit): e
    };
    for (final i in items) {
      final k = _pairKey(i.ingredientId, i.unit);
      final prev = byKey[k];
      if (prev == null) {
        byKey[k] = _ExtraItem(
          ingredientId: i.ingredientId,
          name: i.name,
          unit: i.unit,
          aisle: i.aisle,
          qty: i.missingQty,
        );
      } else {
        byKey[k] = prev.copyWith(qty: prev.qty + i.missingQty);
      }
    }

    final list = byKey.values.map((e) => e.toJson()).toList(growable: false);
    await _prefs.setString(key, jsonEncode(list));
  }

  String _key(String? planId) => 'shopping_extras_${planId ?? 'none'}';

  List<_ExtraItem> _loadExtras(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => _ExtraItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<List<({String ingredientId, double qty, Unit unit})>> getCheckedItems({
    String? planId,
  }) async {
    // This prefs-backed impl cannot rebuild plan-derived items.
    // It returns only checked user-added extras that are also checked.
    if (planId == null) return const [];
    final checkedKeys = _prefs.getStringList('shopping_checked_$planId')?.toSet() ?? <String>{};
    if (checkedKeys.isEmpty) return const [];

    final extras = _loadExtras(_key(planId));
    final out = <({String ingredientId, double qty, Unit unit})>[];
    for (final e in extras) {
      final key = _pairKey(e.ingredientId, e.unit);
      if (checkedKeys.contains(key)) {
        out.add((ingredientId: e.ingredientId, qty: e.qty, unit: e.unit));
      }
    }
    return out;
  }

  @override
  Future<void> clearCheckedItems({String? planId}) async {
    final key = 'shopping_checked_${planId ?? 'none'}';
    await _prefs.setStringList(key, <String>[]);
  }
}

class _ExtraItem {
  _ExtraItem({
    required this.ingredientId,
    required this.name,
    required this.unit,
    required this.aisle,
    required this.qty,
  });

  final String ingredientId;
  final String name;
  final Unit unit;
  final Aisle aisle;
  final double qty;

  _ExtraItem copyWith({
    String? ingredientId,
    String? name,
    Unit? unit,
    Aisle? aisle,
    double? qty,
  }) => _ExtraItem(
        ingredientId: ingredientId ?? this.ingredientId,
        name: name ?? this.name,
        unit: unit ?? this.unit,
        aisle: aisle ?? this.aisle,
        qty: qty ?? this.qty,
      );

  Map<String, dynamic> toJson() => {
        'ingredientId': ingredientId,
        'name': name,
        'unit': unit.name,
        'aisle': aisle.name,
        'qty': qty,
      };

  static _ExtraItem fromJson(Map<String, dynamic> j) => _ExtraItem(
        ingredientId: j['ingredientId'] as String,
        name: j['name'] as String,
        unit: Unit.values.firstWhere(
          (u) => u.name == j['unit'],
          orElse: () => Unit.grams,
        ),
        aisle: Aisle.values.firstWhere(
          (a) => a.name == j['aisle'],
          orElse: () => Aisle.pantry,
        ),
        qty: (j['qty'] as num).toDouble(),
      );
}

String _pairKey(String ingredientId, Unit unit) => '$ingredientId|${unit.name}';
