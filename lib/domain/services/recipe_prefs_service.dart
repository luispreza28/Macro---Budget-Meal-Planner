import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final recipePrefsServiceProvider = Provider<RecipePrefsService>((ref) => RecipePrefsService(ref));

class RecipePrefsService {
  RecipePrefsService(this.ref);
  final Ref ref;

  static const _kFavKey = 'prefs.favoriteRecipeIds'; // JSON array of strings
  static const _kExKey = 'prefs.excludedRecipeIds'; // JSON array of strings

  Future<Set<String>> getFavorites() async {
    final prefs = await _prefs();
    final raw = prefs.getString(_kFavKey);
    final set = _parseSet(raw);
    if (kDebugMode) debugPrint('[Prefs] getFavorites n=${set.length}');
    return set;
  }

  Future<Set<String>> getExcluded() async {
    final prefs = await _prefs();
    final raw = prefs.getString(_kExKey);
    final set = _parseSet(raw);
    if (kDebugMode) debugPrint('[Prefs] getExcluded n=${set.length}');
    return set;
  }

  Future<void> toggleFavorite(String recipeId, {bool? value}) async {
    final prefs = await _prefs();
    final current = _parseSet(prefs.getString(_kFavKey));
    final shouldAdd = value ?? !current.contains(recipeId);
    if (shouldAdd) {
      current.add(recipeId);
    } else {
      current.remove(recipeId);
    }
    await prefs.setString(_kFavKey, _toJson(current));
    if (kDebugMode) debugPrint('[Prefs] toggleFavorite id=$recipeId -> ${shouldAdd ? 'ON' : 'OFF'}');
  }

  Future<void> toggleExcluded(String recipeId, {bool? value}) async {
    final prefs = await _prefs();
    final current = _parseSet(prefs.getString(_kExKey));
    final shouldAdd = value ?? !current.contains(recipeId);
    if (shouldAdd) {
      current.add(recipeId);
    } else {
      current.remove(recipeId);
    }
    await prefs.setString(_kExKey, _toJson(current));
    if (kDebugMode) debugPrint('[Prefs] toggleExcluded id=$recipeId -> ${shouldAdd ? 'ON' : 'OFF'}');
  }

  Future<bool> isFavorite(String recipeId) async {
    final favs = await getFavorites();
    return favs.contains(recipeId);
  }

  Future<bool> isExcluded(String recipeId) async {
    final ex = await getExcluded();
    return ex.contains(recipeId);
  }

  // Helpers
  Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  Set<String> _parseSet(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return <String>{};
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toSet();
      }
    } catch (_) {
      // ignore malformed
    }
    return <String>{};
  }

  String _toJson(Set<String> ids) => jsonEncode(ids.toList()..sort());
}

