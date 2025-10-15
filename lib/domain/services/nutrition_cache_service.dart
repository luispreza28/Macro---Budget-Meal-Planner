import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'nutrition_lookup_service.dart';

final nutritionCacheServiceProvider = Provider<NutritionCacheService>((ref) => NutritionCacheService());

class NutritionCacheService {
  static const _kKey = 'nutrition.cache.v1'; // Map<provider:id, record>

  Future<void> put(NutritionRecord r) async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kKey);
    final Map<String, dynamic> m = raw == null ? <String, dynamic>{} : (jsonDecode(raw) as Map<String, dynamic>);
    m['${r.provider}:${r.id}'] = {
      'provider': r.provider,
      'id': r.id,
      'name': r.name,
      'brand': r.brand,
      'servingSizeG': r.servingSizeG,
      'servingSizeMl': r.servingSizeMl,
      'kcalPer100': r.kcalPer100,
      'proteinPer100G': r.proteinPer100G,
      'carbsPer100G': r.carbsPer100G,
      'fatPer100G': r.fatPer100G,
      'kcalPerPiece': r.kcalPerPiece,
      'gramsPerPiece': r.gramsPerPiece,
      'mlPerPiece': r.mlPerPiece,
      'densityGPerMl': r.densityGPerMl,
    };
    await sp.setString(_kKey, jsonEncode(m));
  }
}

