import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/ingredient.dart' as domain;

final densityServiceProvider = Provider<DensityService>((ref) => DensityService());

class DensityService {
  // SP keys
  static const _kCatalog = 'density.catalog.v1'; // Map<String key, DensityEntry>
  static const _kOverrides = 'density.overrides.v1'; // Map<String ingredientId, double gPerMl>
  static const _kObserved = 'density.observed.v1'; // Map<String ingredientId, List<Obs>>

  Future<SharedPreferences> _sp() => SharedPreferences.getInstance();

  // ---- Seed catalog (first-run) ----
  Future<void> ensureSeeded() async {
    final sp = await _sp();
    if (sp.getString(_kCatalog) != null) {
      await _warmCacheFromPrefs(sp);
      return;
    }
    final seed = <String, DensityEntry>{
      // key -> approx g/ml (room temp)
      'water': DensityEntry(1.00, 'seed'),
      'milk': DensityEntry(1.03, 'seed'),
      'olive_oil': DensityEntry(0.91, 'seed'),
      'canola_oil': DensityEntry(0.92, 'seed'),
      'honey': DensityEntry(1.42, 'seed'),
      'maple_syrup': DensityEntry(1.32, 'seed'),
      'yogurt': DensityEntry(1.03, 'seed'),
      'broth': DensityEntry(1.01, 'seed'),
      'soy_milk': DensityEntry(1.01, 'seed'),
      'coconut_milk': DensityEntry(0.98, 'seed'),
      'vinegar': DensityEntry(1.01, 'seed'),
      'molasses': DensityEntry(1.45, 'seed'),
    };
    await sp.setString(_kCatalog, jsonEncode(seed.map((k, v) => MapEntry(k, v.toJson()))));
    if (kDebugMode) debugPrint('[Density] seed catalog written (${seed.length})');
    await _warmCacheFromPrefs(sp);
  }

  // ---- Catalog get/put ----
  Future<Map<String, DensityEntry>> catalog() async {
    final raw = (await _sp()).getString(_kCatalog);
    if (raw == null) return {};
    final m = (jsonDecode(raw) as Map<String, dynamic>);
    return m.map((k, v) => MapEntry(k, DensityEntry.fromJson(v)));
  }

  Future<void> upsertCatalog(String key, DensityEntry e) async {
    final sp = await _sp();
    final cat = await catalog();
    cat[key] = e;
    await sp.setString(_kCatalog, jsonEncode(cat.map((k, v) => MapEntry(k, v.toJson()))));
    await _warmCacheFromPrefs(sp);
  }

  // ---- Per-ingredient user overrides ----
  Future<Map<String, double>> overrides() async {
    final raw = (await _sp()).getString(_kOverrides);
    if (raw == null) return {};
    final m = (jsonDecode(raw) as Map<String, dynamic>);
    return m.map((k, v) => MapEntry(k, (v as num).toDouble()));
  }

  Future<void> setOverride(String ingredientId, double gPerMl) async {
    final sp = await _sp();
    final m = await overrides();
    m[ingredientId] = gPerMl;
    await sp.setString(_kOverrides, jsonEncode(m));
    DensityCache.setOverride(ingredientId, gPerMl);
    if (kDebugMode) debugPrint('[Density][apply] override set $ingredientId -> ${gPerMl.toStringAsFixed(3)} g/ml');
  }

  Future<void> clearOverride(String ingredientId) async {
    final sp = await _sp();
    final m = await overrides();
    m.remove(ingredientId);
    await sp.setString(_kOverrides, jsonEncode(m));
    DensityCache.clearOverride(ingredientId);
    if (kDebugMode) debugPrint('[Density][apply] override cleared $ingredientId');
  }

  // ---- Observations (auto-learn queue) ----
  Future<List<DensityObservation>> observedFor(String ingredientId) async {
    final raw = (await _sp()).getString(_kObserved);
    if (raw == null) return const [];
    final m = (jsonDecode(raw) as Map<String, dynamic>);
    final xs = (m[ingredientId] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    return xs.map(DensityObservation.fromJson).toList();
  }

  Future<void> pushObservation(String ingredientId, DensityObservation o, {int cap = 20}) async {
    final sp = await _sp();
    final raw = sp.getString(_kObserved);
    final m = raw == null
        ? <String, List<Map<String, dynamic>>>{}
        : (jsonDecode(raw) as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, (v as List).cast<Map<String, dynamic>>()));
    final list = (m[ingredientId] ?? <Map<String, dynamic>>[]);
    list.insert(0, o.toJson());
    m[ingredientId] = list.take(cap).toList();
    await sp.setString(_kObserved, jsonEncode(m));
    // Update cache-average lazily
    DensityCache.notifyObserved(ingredientId);
    if (kDebugMode) debugPrint('[Density][observe] $ingredientId -> g=${o.grams} ml=${o.ml} g/ml=${o.gPerMl.toStringAsFixed(3)}');
  }

  // ---- Resolver ----
  // Returns (density g/ml, source: explicit|override|catalog|inferred)
  Future<DensityResolution?> resolveFor(domain.Ingredient ing) async {
    // 1) Ingredient explicit density
    if (ing.densityGPerMl != null && ing.densityGPerMl! > 0) {
      if (kDebugMode) debugPrint('[Density][resolve] ${ing.id} explicit=${ing.densityGPerMl}');
      return DensityResolution(ing.densityGPerMl!, DensitySource.explicit);
    }
    // 2) Per-ingredient user override
    final ov = (await overrides())[ing.id];
    if (ov != null && ov > 0) {
      if (kDebugMode) debugPrint('[Density][resolve] ${ing.id} override=$ov');
      return DensityResolution(ov, DensitySource.user_override);
    }
    // 3) Seed catalog by tag/name key
    final key = _catalogKeyFor(ing);
    final cat = await catalog();
    if (key != null && cat[key] != null) {
      if (kDebugMode) debugPrint('[Density][resolve] ${ing.id} catalog=${cat[key]!.gPerMl} key=$key');
      return DensityResolution(cat[key]!.gPerMl, DensitySource.catalog_seed);
    }
    // 4) Inferred from observations (avg)
    final obs = await observedFor(ing.id);
    if (obs.isNotEmpty) {
      final avg = obs.map((e) => e.gPerMl).reduce((a, b) => a + b) / obs.length;
      if (kDebugMode) debugPrint('[Density][resolve] ${ing.id} inferred=$avg (${obs.length} obs)');
      return DensityResolution(avg, DensitySource.inferred);
    }
    if (kDebugMode) debugPrint('[Density][resolve] ${ing.id} none');
    return null;
  }

  // Basic heuristic mapping from tags/name to catalog key
  String? _catalogKeyFor(domain.Ingredient ing) {
    final name = ing.name.toLowerCase();
    final tags = ing.tags.map((t) => t.toLowerCase()).toList();
    bool has(String s) => name.contains(s) || tags.contains(s);

    if (has('water')) return 'water';
    if (has('milk') || has('yogurt')) return has('yogurt') ? 'yogurt' : 'milk';
    if (has('olive oil')) return 'olive_oil';
    if (has('canola oil') || has('vegetable oil')) return 'canola_oil';
    if (has('honey')) return 'honey';
    if (has('maple')) return 'maple_syrup';
    if (has('broth') || has('stock')) return 'broth';
    if (has('soy milk')) return 'soy_milk';
    if (has('coconut milk')) return 'coconut_milk';
    if (has('vinegar')) return 'vinegar';
    if (has('molasses')) return 'molasses';
    return null;
  }

  Future<void> _warmCacheFromPrefs(SharedPreferences sp) async {
    // Catalog
    try {
      final catRaw = sp.getString(_kCatalog);
      final Map<String, DensityEntry> cat = catRaw == null
          ? {}
          : (jsonDecode(catRaw) as Map<String, dynamic>)
              .map((k, v) => MapEntry(k, DensityEntry.fromJson(v)));
      // Overrides
      final ovRaw = sp.getString(_kOverrides);
      final Map<String, double> ov = ovRaw == null
          ? {}
          : (jsonDecode(ovRaw) as Map<String, dynamic>)
              .map((k, v) => MapEntry(k, (v as num).toDouble()));
      // Observed
      final obRaw = sp.getString(_kObserved);
      final Map<String, List<DensityObservation>> ob = {};
      if (obRaw != null) {
        final mm = (jsonDecode(obRaw) as Map<String, dynamic>);
        for (final e in mm.entries) {
          final xs = (e.value as List?)?.cast<Map<String, dynamic>>() ?? const [];
          ob[e.key] = xs.map(DensityObservation.fromJson).toList();
        }
      }
      DensityCache.replaceAll(catalog: cat, overrides: ov, observed: ob);
      if (kDebugMode) debugPrint('[Density] cache warmed: cat=${cat.length} ov=${ov.length} ob=${ob.length}');
    } catch (e) {
      if (kDebugMode) debugPrint('[Density] cache warm failed: $e');
    }
  }
}

// Data classes
class DensityEntry {
  final double gPerMl;
  final String source; // 'seed' or 'user'
  const DensityEntry(this.gPerMl, this.source);
  Map<String, dynamic> toJson() => {'gPerMl': gPerMl, 'source': source};
  factory DensityEntry.fromJson(Map<String, dynamic> j) =>
      DensityEntry((j['gPerMl'] as num).toDouble(), j['source'] as String? ?? 'seed');
}

class DensityObservation {
  final double grams;
  final double ml;
  final DateTime at;
  const DensityObservation({required this.grams, required this.ml, required this.at});
  double get gPerMl => grams / ml;
  Map<String, dynamic> toJson() => {'g': grams, 'ml': ml, 'at': at.toIso8601String()};
  factory DensityObservation.fromJson(Map<String, dynamic> j) =>
      DensityObservation(grams: (j['g'] as num).toDouble(), ml: (j['ml'] as num).toDouble(), at: DateTime.parse(j['at']));
}

class DensityResolution {
  final double gPerMl;
  final DensitySource source;
  const DensityResolution(this.gPerMl, this.source);
}

enum DensitySource { explicit, user_override, catalog_seed, inferred }

// Lightweight in-memory cache to support fast, synchronous best-effort lookups
class DensityCache {
  static Map<String, DensityEntry> _catalog = {};
  static Map<String, double> _overrides = {};
  static Map<String, List<DensityObservation>> _observed = {};

  static void replaceAll({
    required Map<String, DensityEntry> catalog,
    required Map<String, double> overrides,
    required Map<String, List<DensityObservation>> observed,
  }) {
    _catalog = Map.of(catalog);
    _overrides = Map.of(overrides);
    _observed = {for (final e in observed.entries) e.key: List.of(e.value)};
  }

  static void setOverride(String ingredientId, double gPerMl) {
    _overrides[ingredientId] = gPerMl;
  }

  static void clearOverride(String ingredientId) {
    _overrides.remove(ingredientId);
  }

  static void notifyObserved(String ingredientId) {
    // No-op; lazy averaging occurs on lookup if observations present
  }

  // Synchronous best-effort resolution for g<->ml conversions in sync code paths
  static DensityResolution? tryResolve(domain.Ingredient ing) {
    if (ing.densityGPerMl != null && ing.densityGPerMl! > 0) {
      return DensityResolution(ing.densityGPerMl!, DensitySource.explicit);
    }
    final ov = _overrides[ing.id];
    if (ov != null && ov > 0) {
      return DensityResolution(ov, DensitySource.user_override);
    }
    // Catalog heuristic
    final key = _catalogKeyFor(ing);
    final ce = key == null ? null : _catalog[key];
    if (ce != null && ce.gPerMl > 0) {
      return DensityResolution(ce.gPerMl, DensitySource.catalog_seed);
    }
    // Inferred avg
    final obs = _observed[ing.id] ?? const <DensityObservation>[];
    if (obs.isNotEmpty) {
      final avg = obs.map((e) => e.gPerMl).reduce((a, b) => a + b) / obs.length;
      return DensityResolution(avg, DensitySource.inferred);
    }
    return null;
  }

  static String? _catalogKeyFor(domain.Ingredient ing) {
    final name = ing.name.toLowerCase();
    final tags = ing.tags.map((t) => t.toLowerCase()).toList();
    bool has(String s) => name.contains(s) || tags.contains(s);
    if (has('water')) return 'water';
    if (has('milk') || has('yogurt')) return has('yogurt') ? 'yogurt' : 'milk';
    if (has('olive oil')) return 'olive_oil';
    if (has('canola oil') || has('vegetable oil')) return 'canola_oil';
    if (has('honey')) return 'honey';
    if (has('maple')) return 'maple_syrup';
    if (has('broth') || has('stock')) return 'broth';
    if (has('soy milk')) return 'soy_milk';
    if (has('coconut milk')) return 'coconut_milk';
    if (has('vinegar')) return 'vinegar';
    if (has('molasses')) return 'molasses';
    return null;
  }
}

