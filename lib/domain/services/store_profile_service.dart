import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/store_profile.dart';
import '../../domain/entities/ingredient.dart' as ing;
import '../../presentation/providers/database_providers.dart';
import '../../presentation/providers/shopping_list_providers.dart';

final storeProfileServiceProvider =
    Provider<StoreProfileService>((ref) => StoreProfileService(ref));

class StoreProfileService {
  StoreProfileService(this.ref);
  final Ref ref;
  static const _kProfilesKey = 'stores.profiles.v1'; // JSON list
  static const _kSelectedIdKey = 'stores.selectedId.v1';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  Future<List<StoreProfile>> getProfiles() async {
    final raw = _prefs.getString(_kProfilesKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .whereType<Map<String, dynamic>>()
          .map((j) => StoreProfile.fromJson(j))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('[Store] Failed to parse profiles: $e');
      return const [];
    }
  }

  Future<void> _saveProfiles(List<StoreProfile> profiles) async {
    final raw = jsonEncode(profiles.map((p) => p.toJson()).toList());
    await _prefs.setString(_kProfilesKey, raw);
  }

  Future<StoreProfile?> getSelected() async {
    final id = _prefs.getString(_kSelectedIdKey);
    if (id == null || id.isEmpty) return null;
    final all = await getProfiles();
    try {
      return all.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> setSelected(String storeId) async {
    if (storeId.isEmpty) {
      await _prefs.remove(_kSelectedIdKey);
    } else {
      await _prefs.setString(_kSelectedIdKey, storeId);
    }
    _invalidateAll();
  }

  Future<StoreProfile> create(String name, {String? emoji}) async {
    final all = await getProfiles();
    final defaultOrder = ing.Aisle.values.map((a) => a.value).toList();
    final id = _uuid();
    final profile = StoreProfile(
      id: id,
      name: name,
      emoji: emoji,
      aisleOrder: defaultOrder,
    );
    final updated = [...all, profile];
    await _saveProfiles(updated);
    _invalidateAll();
    return profile;
  }

  Future<void> update(StoreProfile profile) async {
    final all = await getProfiles();
    final idx = all.indexWhere((p) => p.id == profile.id);
    if (idx == -1) return;
    all[idx] = profile;
    await _saveProfiles(all);
    _invalidateAll();
  }

  Future<void> delete(String storeId) async {
    final all = await getProfiles();
    final filtered = all.where((p) => p.id != storeId).toList();
    await _saveProfiles(filtered);
    final selected = _prefs.getString(_kSelectedIdKey);
    if (selected == storeId) {
      await _prefs.remove(_kSelectedIdKey);
    }
    _invalidateAll();
  }

  Future<void> setAisleOrder(String storeId, List<String> order) async {
    final all = await getProfiles();
    final idx = all.indexWhere((p) => p.id == storeId);
    if (idx == -1) return;
    all[idx] = all[idx].copyWith(aisleOrder: _normalizedOrder(order));
    await _saveProfiles(all);
    _invalidateAll();
  }

  Future<void> upsertPriceOverride({
    required String storeId,
    required String ingredientId,
    required int cents,
  }) async {
    final all = await getProfiles();
    final idx = all.indexWhere((p) => p.id == storeId);
    if (idx == -1) return;
    final map = Map<String, int>.from(
        all[idx].priceOverrideCentsByIngredientId ?? const {});
    map[ingredientId] = cents;
    all[idx] = all[idx]
        .copyWith(priceOverrideCentsByIngredientId: Map<String, int>.from(map));
    await _saveProfiles(all);
    _invalidateAll();
  }

  Future<void> clearPriceOverride({
    required String storeId,
    required String ingredientId,
  }) async {
    final all = await getProfiles();
    final idx = all.indexWhere((p) => p.id == storeId);
    if (idx == -1) return;
    final map = Map<String, int>.from(
        all[idx].priceOverrideCentsByIngredientId ?? const {});
    map.remove(ingredientId);
    all[idx] = all[idx]
        .copyWith(priceOverrideCentsByIngredientId: Map<String, int>.from(map));
    await _saveProfiles(all);
    _invalidateAll();
  }

  List<String> _normalizedOrder(List<String> input) {
    final known = ing.Aisle.values.map((a) => a.value).toList();
    final seen = <String>{};
    final out = <String>[];
    for (final s in input) {
      if (known.contains(s) && !seen.contains(s)) {
        out.add(s);
        seen.add(s);
      }
    }
    for (final s in known) {
      if (!seen.contains(s)) out.add(s);
    }
    return out;
  }

  void _invalidateAll() {
    // selection and profiles
    ref.invalidate(selectedStoreProvider);
    ref.invalidate(storeProfilesProvider);
    // re-group shopping list
    ref.invalidate(shoppingListItemsProvider);
  }

  String _uuid() {
    // Simple UUID v4-ish without package dependency, sufficient for prefs keys
    final now = DateTime.now().microsecondsSinceEpoch;
    final rand = (now ^ 0x9e3779b97f4a7c15).abs();
    return 's_${now.toRadixString(16)}_${rand.toRadixString(16)}';
  }
}
