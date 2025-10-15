import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final preparedInventoryServiceProvider = Provider<PreparedInventoryService>((ref) => PreparedInventoryService());

class PreparedInventoryService {
  static const _kKey = 'prepared.inventory.v1'; // JSON { recipeId: [Entry] }
  static const _kRescuedKey = 'prepared.rescued.v1'; // JSON { yyyy-ww: int }
  Future<SharedPreferences> _sp() => SharedPreferences.getInstance();

  Future<Map<String, List<PreparedEntry>>> all() async {
    final raw = (await _sp()).getString(_kKey);
    if (raw == null) return {};
    try {
      final m = (jsonDecode(raw) as Map<String, dynamic>);
      return m.map((k, v) => MapEntry(k, (v as List).map((e) => PreparedEntry.fromJson((e as Map).cast<String, dynamic>())).toList()));
    } catch (e) {
      if (kDebugMode) debugPrint('[Prepared] decode failed: $e');
      return {};
    }
  }

  Future<void> _put(Map<String, List<PreparedEntry>> m) async {
    final sp = await _sp();
    await sp.setString(
      _kKey,
      jsonEncode(m.map((k, v) => MapEntry(k, v.map((e) => e.toJson()).toList()))),
    );
  }

  Future<List<PreparedEntry>> forRecipe(String recipeId) async => (await all())[recipeId] ?? const [];

  Future<void> add(String recipeId, PreparedEntry e) async {
    final m = await all();
    final list = List<PreparedEntry>.from(m[recipeId] ?? const []);
    list.insert(0, e);
    m[recipeId] = _squash(list);
    await _put(m);
  }

  Future<void> consume(String recipeId, int servings) async {
    if (servings <= 0) return;
    final m = await all();
    var list = List<PreparedEntry>.from(m[recipeId] ?? const []);
    // Remove expired first
    final now = DateTime.now();
    list = list.where((e) => e.expiresAt == null || e.expiresAt!.isAfter(now)).toList();
    var remaining = servings;
    for (var i = 0; i < list.length && remaining > 0; i++) {
      final take = remaining.clamp(0, list[i].servings);
      list[i] = list[i].copyWith(servings: list[i].servings - take);
      remaining -= take;
    }
    final consumed = servings - remaining;
    list = list.where((e) => e.servings > 0).toList();
    m[recipeId] = list;
    await _put(m);
    if (consumed > 0) {
      await _bumpRescued(consumed);
      if (kDebugMode) debugPrint('[Leftovers] Consumed rescued=$consumed');
    }
  }

  Future<int> availableServings(String recipeId) async {
    final now = DateTime.now();
    final list = await forRecipe(recipeId);
    return list
        .where((e) => e.expiresAt == null || e.expiresAt!.isAfter(now))
        .fold(0, (a, e) => a + e.servings);
  }

  Future<int> removeExpired() async {
    final m = await all();
    final now = DateTime.now();
    int removed = 0;
    m.updateAll((_, list) {
      final before = list.length;
      final after = list.where((e) => e.expiresAt == null || e.expiresAt!.isAfter(now)).toList();
      removed += (before - after.length);
      return after;
    });
    await _put(m);
    return removed;
  }

  // Merge adjacent entries with same storage/expiry day to keep lists short
  List<PreparedEntry> _squash(List<PreparedEntry> xs) {
    xs.sort((a, b) => (b.madeAt.compareTo(a.madeAt)));
    final out = <PreparedEntry>[];
    for (final e in xs) {
      if (out.isNotEmpty) {
        final last = out.last;
        final sameDay = e.expiresAt?.toIso8601String().substring(0, 10) ==
            last.expiresAt?.toIso8601String().substring(0, 10);
        if (sameDay && e.storage == last.storage) {
          out[out.length - 1] = last.copyWith(servings: last.servings + e.servings);
          continue;
        }
      }
      out.add(e);
    }
    return out;
  }

  // Simple weekly counter for insights: map yyyy-ww -> int
  Future<void> _bumpRescued(int by) async {
    try {
      final sp = await _sp();
      final raw = sp.getString(_kRescuedKey);
      Map<String, int> m = {};
      if (raw != null) {
        final x = (jsonDecode(raw) as Map<String, dynamic>);
        m = x.map((k, v) => MapEntry(k, (v as num).toInt()));
      }
      final now = DateTime.now();
      final wn = _isoWeekKey(now);
      m[wn] = (m[wn] ?? 0) + by;
      await sp.setString(_kRescuedKey, jsonEncode(m));
    } catch (_) {}
  }

  Future<int> rescuedThisWeek() async {
    try {
      final sp = await _sp();
      final raw = sp.getString(_kRescuedKey);
      if (raw == null) return 0;
      final x = (jsonDecode(raw) as Map<String, dynamic>);
      final m = x.map((k, v) => MapEntry(k, (v as num).toInt()));
      return m[_isoWeekKey(DateTime.now())] ?? 0;
    } catch (_) {
      return 0;
    }
  }

  String _isoWeekKey(DateTime d) {
    // Very small ISO week approximation: week starts Monday
    final monday = d.subtract(Duration(days: (d.weekday - DateTime.monday)));
    final week = int.parse('${monday.difference(DateTime(monday.year)).inDays ~/ 7 + 1}');
    return '${monday.year.toString().padLeft(4, '0')}-${week.toString().padLeft(2, '0')}';
  }
}

enum Storage { fridge, freezer }

class PreparedEntry {
  final int servings; // int > 0
  final DateTime madeAt;
  final DateTime? expiresAt;
  final Storage storage;
  const PreparedEntry({required this.servings, required this.madeAt, this.expiresAt, required this.storage});
  PreparedEntry copyWith({int? servings, DateTime? madeAt, DateTime? expiresAt, Storage? storage}) =>
      PreparedEntry(
        servings: servings ?? this.servings,
        madeAt: madeAt ?? this.madeAt,
        expiresAt: expiresAt ?? this.expiresAt,
        storage: storage ?? this.storage,
      );
  Map<String, dynamic> toJson() => {
        'servings': servings,
        'madeAt': madeAt.toIso8601String(),
        'expiresAt': expiresAt?.toIso8601String(),
        'storage': storage.name,
      };
  factory PreparedEntry.fromJson(Map<String, dynamic> j) => PreparedEntry(
        servings: (j['servings'] as num).toInt(),
        madeAt: DateTime.parse(j['madeAt'] as String),
        expiresAt: j['expiresAt'] == null ? null : DateTime.parse(j['expiresAt'] as String),
        storage: Storage.values.firstWhere((s) => s.name == j['storage'], orElse: () => Storage.fridge),
      );
}

