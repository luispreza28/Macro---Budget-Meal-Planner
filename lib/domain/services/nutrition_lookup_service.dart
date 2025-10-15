import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/ingredient.dart' as domain;

// Unified record returned to UI
class NutritionRecord {
  final String provider; // 'fdc' | 'off'
  final String id; // provider id
  final String name; // "Olive Oil"
  final String? brand; // "Kirkland"
  final double? servingSizeG; // g if provided
  final double? servingSizeMl; // ml if provided
  final double kcalPer100;
  final double proteinPer100G;
  final double carbsPer100G;
  final double fatPer100G;
  final double? kcalPerPiece; // if per-piece available
  final double? gramsPerPiece; // size clues
  final double? mlPerPiece;
  final double? densityGPerMl; // if derivable
  final Map<String, dynamic> raw; // original snippet for debugging
  const NutritionRecord({
    required this.provider,
    required this.id,
    required this.name,
    this.brand,
    this.servingSizeG,
    this.servingSizeMl,
    required this.kcalPer100,
    required this.proteinPer100G,
    required this.carbsPer100G,
    required this.fatPer100G,
    this.kcalPerPiece,
    this.gramsPerPiece,
    this.mlPerPiece,
    this.densityGPerMl,
    this.raw = const {},
  });
}

final nutritionLookupServiceProvider = Provider<NutritionLookupService>((ref) => NutritionLookupService(ref));

class NutritionLookupService {
  NutritionLookupService(this.ref);
  final Ref ref;

  Future<List<NutritionRecord>> search({required String query, required String source}) async {
    if (source == 'fdc') return _fdcSearch(query);
    if (source == 'off') return _offSearch(query);
    return const [];
  }

  // ---------------- FDC ----------------
  Future<List<NutritionRecord>> _fdcSearch(String query) async {
    final key = await _fdcKey();
    if (key == null || key.isEmpty) {
      if (kDebugMode) debugPrint('[Lookup][fdc] missing API key');
      throw StateError('FDC API key not set');
    }
    final uri = Uri.https('api.nal.usda.gov', '/fdc/v1/foods/search', {
      'api_key': key,
      'query': query,
      'pageSize': '25',
      'dataType': 'Branded,Survey (FNDDS),SR Legacy,Foundation',
    });
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      if (kDebugMode) debugPrint('[Lookup][fdc] search failed ${res.statusCode}: ${res.body}');
      throw StateError('FDC search failed ${res.statusCode}');
    }
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    final foods = (j['foods'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    return foods.map(_fdcNormalize).whereType<NutritionRecord>().toList();
  }

  NutritionRecord? _fdcNormalize(Map<String, dynamic> f) {
    double? by(List xs, String number) {
      final m = xs.cast<Map<String, dynamic>>().firstWhere(
            (e) => '${e['nutrientNumber']}' == number,
        orElse: () => {},
      );
      if (m.isEmpty) return null;
      return (m['value'] as num?)?.toDouble();
    }
    final foodNutrients = (f['foodNutrients'] as List?) ?? const [];
    final kcal = (by(foodNutrients, '208') ?? by(foodNutrients, '1008'))?.toDouble();
    final protein = by(foodNutrients, '203') ?? 0.0;
    final carbs = by(foodNutrients, '205') ?? 0.0;
    final fat = by(foodNutrients, '204') ?? 0.0;

    if (kcal == null) return null;

    final labelNutrients = (f['labelNutrients'] as Map?)?.cast<String, dynamic>();
    double? servG = (f['servingSizeUnit'] == 'g') ? (f['servingSize'] as num?)?.toDouble() : null;
    if (labelNutrients != null && f['servingSize'] != null) {
      final s = (f['servingSize'] as num).toDouble();
      final unit = (f['servingSizeUnit'] ?? '').toString().toLowerCase();
      if (unit == 'g') servG = s;
    }

    double kcal100 = kcal.toDouble();
    double p100 = (protein).toDouble();
    double c100 = (carbs).toDouble();
    double f100 = (fat).toDouble();

    if (labelNutrients != null && servG != null && servG > 0) {
      double _get(String k) => ((labelNutrients[k] as Map?)?['value'] as num?)?.toDouble() ?? 0.0;
      final lkcal = _get('calories');
      final lp = _get('protein');
      final lc = _get('carbohydrates');
      final lf = _get('fat');
      if (lkcal > 0) kcal100 = lkcal * (100.0 / servG);
      if (lp > 0) p100 = lp * (100.0 / servG);
      if (lc > 0) c100 = lc * (100.0 / servG);
      if (lf > 0) f100 = lf * (100.0 / servG);
    }

    return NutritionRecord(
      provider: 'fdc',
      id: '${f['fdcId']}',
      name: (f['description'] ?? f['brandName'] ?? 'FDC item').toString(),
      brand: (f['brandName'] ?? f['brandOwner'])?.toString(),
      servingSizeG: servG,
      servingSizeMl: null,
      kcalPer100: kcal100,
      proteinPer100G: p100,
      carbsPer100G: c100,
      fatPer100G: f100,
      kcalPerPiece: null,
      gramsPerPiece: null,
      mlPerPiece: null,
      densityGPerMl: null,
      raw: f,
    );
  }

  // ---------------- OFF ----------------
  Future<List<NutritionRecord>> _offSearch(String query) async {
    final host = await _offHost();
    final uri = Uri.https(host, '/cgi/search.pl', {
      'search_terms': query,
      'search_simple': '1',
      'json': '1',
      'page_size': '25',
      'fields': 'id,code,product_name,brands,nutriments,serving_size,quantity',
    });
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      if (kDebugMode) debugPrint('[Lookup][off] search failed ${res.statusCode}: ${res.body}');
      throw StateError('OFF search failed ${res.statusCode}');
    }
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    final prods = (j['products'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    return prods.map(_offNormalize).whereType<NutritionRecord>().toList();
  }

  NutritionRecord? _offNormalize(Map<String, dynamic> p) {
    final nutr = (p['nutriments'] as Map?)?.cast<String, dynamic>() ?? const {};
    double _d(String k) => (nutr[k] as num?)?.toDouble() ?? 0.0;
    final unit = (nutr['energy-kcal_unit'] ?? nutr['energy_unit'] ?? '').toString();
    final kcal100 = _d('energy-kcal_100g') > 0
        ? _d('energy-kcal_100g')
        : (unit == 'kcal' ? _d('energy_100g') : _d('energy-kcal_100g'));
    if (kcal100 == 0) return null;

    final servingSize = (p['serving_size'] ?? '').toString().toLowerCase();
    double? servG;
    double? servMl;
    final m = RegExp(r'([\d\.]+)\s*(g|ml)').firstMatch(servingSize);
    if (m != null) {
      final val = double.tryParse(m.group(1) ?? '');
      final u = m.group(2);
      if (val != null) {
        if (u == 'g') servG = val;
        if (u == 'ml') servMl = val;
      }
    }

    double? gramsPerPiece;

    String? _firstBrand(String s) {
      final parts = s.split(',');
      if (parts.isEmpty) return null;
      final first = parts.first.trim();
      return first.isEmpty ? null : first;
    }

    return NutritionRecord(
      provider: 'off',
      id: (p['code'] ?? p['id'] ?? '').toString(),
      name: (p['product_name'] ?? 'OFF item').toString(),
      brand: _firstBrand((p['brands'] ?? '').toString()),
      servingSizeG: servG,
      servingSizeMl: servMl,
      kcalPer100: kcal100,
      proteinPer100G: _d('proteins_100g'),
      carbsPer100G: _d('carbohydrates_100g'),
      fatPer100G: _d('fat_100g'),
      kcalPerPiece: null,
      gramsPerPiece: gramsPerPiece,
      mlPerPiece: null,
      densityGPerMl: (servG != null && servMl != null && servMl > 0) ? (servG / servMl) : null,
      raw: p,
    );
  }

  // --- Keys & prefs ---
  Future<String?> _fdcKey() async {
    final sp = await _prefs();
    return sp.getString('settings.api.fdc.key');
  }
  Future<void> saveFdcKey(String key) async {
    final sp = await _prefs();
    await sp.setString('settings.api.fdc.key', key);
  }

  Future<String> _offHost() async {
    final sp = await _prefs();
    final region = sp.getString('settings.api.off.region') ?? 'world';
    return '$region.openfoodfacts.org';
  }

  Future<SharedPreferences> _prefs() async => SharedPreferences.getInstance();
}

