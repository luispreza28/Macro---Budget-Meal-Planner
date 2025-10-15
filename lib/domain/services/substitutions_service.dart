import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final substitutionsServiceProvider = Provider<SubstitutionsService>((ref) => SubstitutionsService());

class SubstitutionsService {
  static const _kKey = 'subs.catalog.v1'; // JSON { ingredientId: [ { altId, tags[] } ] }

  Future<SharedPreferences> _sp() => SharedPreferences.getInstance();

  Future<Map<String, List<SubCandidate>>> catalog() async {
    final raw = (await _sp()).getString(_kKey);
    if (raw == null) return {};
    try {
      final m = (jsonDecode(raw) as Map<String, dynamic>);
      return m.map((k, v) => MapEntry(k, (v as List).map((e) => SubCandidate.fromJson((e as Map).cast<String, dynamic>())).toList()));
    } catch (e) {
      if (kDebugMode) debugPrint('[Subs] decode failed: $e');
      return {};
    }
  }

  Future<void> upsert(String ingredientId, List<SubCandidate> candidates) async {
    final sp = await _sp();
    final all = await catalog();
    all[ingredientId] = candidates;
    await sp.setString(_kKey, jsonEncode(all.map((k, v) => MapEntry(k, v.map((e) => e.toJson()).toList()))));
  }
}

class SubCandidate {
  final String ingredientId;
  final List<String> tags;
  const SubCandidate({required this.ingredientId, this.tags = const []});
  Map<String, dynamic> toJson() => {'ingredientId': ingredientId, 'tags': tags};
  factory SubCandidate.fromJson(Map<String, dynamic> j) =>
      SubCandidate(ingredientId: j['ingredientId'] as String, tags: ((j['tags'] as List?)?.cast<String>()) ?? const []);
}

