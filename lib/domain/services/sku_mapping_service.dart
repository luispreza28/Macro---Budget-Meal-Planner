import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final skuMappingServiceProvider = Provider<SkuMappingService>((_) => SkuMappingService());

class SkuMappingService {
  static const _k = 'sku.map.v1'; // Map<ean, ingredientId>
  Future<SharedPreferences> _sp() => SharedPreferences.getInstance();

  Future<Map<String, String>> all() async {
    final raw = (await _sp()).getString(_k);
    if (raw == null) return {};
    try {
      return (jsonDecode(raw) as Map).cast<String, String>();
    } catch (_) {
      return {};
    }
  }

  Future<String?> get(String ean) async => (await all())[ean];

  Future<void> put(String ean, String ingredientId) async {
    final sp = await _sp();
    final m = await all();
    m[ean] = ingredientId;
    await sp.setString(_k, jsonEncode(m));
  }

  Future<void> remove(String ean) async {
    final sp = await _sp();
    final m = await all();
    m.remove(ean);
    await sp.setString(_k, jsonEncode(m));
  }
}

