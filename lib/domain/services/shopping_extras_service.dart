import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/ingredient.dart' as domain;

final shoppingExtrasServiceProvider = Provider<ShoppingExtrasService>((_) => ShoppingExtrasService());

class ShoppingExtrasService {
  // Keyed by planId -> List<ExtraLineJson>
  static const _k = 'shopping.extras.v1';

  Future<SharedPreferences> _sp() => SharedPreferences.getInstance();

  Future<List<ExtraLine>> list(String planId) async {
    final raw = (await _sp()).getString(_k);
    if (raw == null) return const [];
    try {
      final m = (jsonDecode(raw) as Map).cast<String, List>();
      final xs = (m[planId] ?? const []).cast<Map<String, dynamic>>();
      return xs.map(ExtraLine.fromJson).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> add(String planId, ExtraLine x) async {
    final sp = await _sp();
    final raw = sp.getString(_k);
    final m = raw == null
        ? <String, List<Map<String, dynamic>>>{}
        : (jsonDecode(raw) as Map)
            .map((k, v) => MapEntry(k as String, (v as List).cast<Map<String, dynamic>>()));
    final xs = (m[planId] ?? <Map<String, dynamic>>[])..add(x.toJson());
    m[planId] = xs;
    await sp.setString(_k, jsonEncode(m));
  }

  Future<void> remove(String planId, String extraId) async {
    final sp = await _sp();
    final raw = sp.getString(_k);
    if (raw == null) return;
    final m = (jsonDecode(raw) as Map)
        .map((k, v) => MapEntry(k as String, (v as List).cast<Map<String, dynamic>>()));
    m[planId] = (m[planId] ?? []).where((e) => e['id'] != extraId).toList();
    await sp.setString(_k, jsonEncode(m));
  }
}

class ExtraLine {
  final String id; // uuid
  final String ingredientId;
  final double qty; // ingredient base unit
  final domain.Unit unit; // redundancy for display
  final String? storeId; // optional preferred store
  final String reason; // e.g., "Below par", "Upcoming usage"
  const ExtraLine({
    required this.id,
    required this.ingredientId,
    required this.qty,
    required this.unit,
    this.storeId,
    required this.reason,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'ingredientId': ingredientId,
        'qty': qty,
        'unit': unit.value,
        'storeId': storeId,
        'reason': reason,
      };
  factory ExtraLine.fromJson(Map<String, dynamic> j) => ExtraLine(
        id: j['id'],
        ingredientId: j['ingredientId'],
        qty: (j['qty'] as num).toDouble(),
        unit: _unitFrom(j['unit']),
        storeId: j['storeId'],
        reason: j['reason'] ?? '',
      );
}

domain.Unit _unitFrom(String v) => v == 'g'
    ? domain.Unit.grams
    : v == 'ml'
        ? domain.Unit.milliliters
        : domain.Unit.piece;

