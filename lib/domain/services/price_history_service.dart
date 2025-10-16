import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/ingredient.dart' as domain;

final priceHistoryServiceProvider =
    Provider<PriceHistoryService>((_) => PriceHistoryService());

class PriceHistoryService {
  static const _k = 'price.history.v1'; // Map<ingredientId, List<PricePointJson>>

  Future<SharedPreferences> _sp() => SharedPreferences.getInstance();

  Future<Map<String, List<PricePoint>>> _all() async {
    final raw = (await _sp()).getString(_k);
    if (raw == null) return {};
    try {
      final m = (jsonDecode(raw) as Map).cast<String, List>();
      return m.map((k, v) => MapEntry(
            k,
            v
                .cast<Map<String, dynamic>>()
                .map(PricePoint.fromJson)
                .toList()
              ..sort((a, b) => a.at.compareTo(b.at)),
          ));
    } catch (_) {
      return {};
    }
  }

  Future<List<PricePoint>> list(String ingredientId) async {
    final all = await _all();
    return all[ingredientId] ?? const [];
  }

  Future<void> add(PricePoint p) async {
    final sp = await _sp();
    final all = await _all();
    final xs = all[p.ingredientId] ?? <PricePoint>[];
    // dedupe same day/store/pack if a recent entry exists, keep latest
    final idx = xs.lastIndexWhere((x) =>
        x.storeId == p.storeId &&
        x.packQty == p.packQty &&
        x.packUnit == p.packUnit &&
        _sameDay(x.at, p.at));
    if (idx >= 0) {
      xs[idx] = p;
    } else {
      xs.add(p);
    }
    all[p.ingredientId] = xs..sort((a, b) => a.at.compareTo(b.at));
    await sp.setString(
      _k,
      jsonEncode(
        all.map((k, v) => MapEntry(k, v.map((e) => e.toJson()).toList())),
      ),
    );
    if (kDebugMode) {
      debugPrint('[PriceHistory] add ${p.ingredientId} ${p.storeId} ppu=${p.ppuCents}/unit');
    }
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class PricePoint {
  final String id; // uuid
  final String ingredientId;
  final String storeId; // from Store Profiles (string id)
  final int priceCents; // total price paid for the pack
  final double packQty; // quantity purchased
  final domain.Unit packUnit; // unit of pack (g/ml/piece)
  final int ppuCents; // computed price per base unit in cents (stored canonical)
  final DateTime at; // timestamp
  final String? note; // e.g., "promo", "club card"

  const PricePoint({
    required this.id,
    required this.ingredientId,
    required this.storeId,
    required this.priceCents,
    required this.packQty,
    required this.packUnit,
    required this.ppuCents,
    required this.at,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'ingredientId': ingredientId,
        'storeId': storeId,
        'priceCents': priceCents,
        'packQty': packQty,
        'packUnit': packUnit.value,
        'ppuCents': ppuCents,
        'at': at.toIso8601String(),
        'note': note,
      };

  factory PricePoint.fromJson(Map<String, dynamic> j) => PricePoint(
        id: j['id'],
        ingredientId: j['ingredientId'],
        storeId: j['storeId'],
        priceCents: j['priceCents'],
        packQty: (j['packQty'] as num).toDouble(),
        packUnit: _unitFrom(j['packUnit']),
        ppuCents: j['ppuCents'],
        at: DateTime.parse(j['at']),
        note: j['note'],
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

