import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final dietAllergenPrefsServiceProvider = Provider<DietAllergenPrefsService>((ref) => DietAllergenPrefsService());

class DietAllergenPrefsService {
  static const _kAllergensKey = 'prefs.allergens.v1';           // JSON list<String>
  static const _kStrictModeKey = 'prefs.allergens.strict.v1';   // bool (exclude vs warn)
  static const _kDietFlagsKey = 'prefs.dietFlags.v1';           // JSON list<String>

  Future<SharedPreferences> _sp() => SharedPreferences.getInstance();

  Future<List<String>> allergens() async {
    final raw = (await _sp()).getString(_kAllergensKey);
    return raw == null ? const [] : (jsonDecode(raw) as List).cast<String>();
  }
  Future<void> setAllergens(List<String> ids) async {
    await (await _sp()).setString(_kAllergensKey, jsonEncode(ids));
  }

  Future<bool> strictMode() async => (await _sp()).getBool(_kStrictModeKey) ?? true;
  Future<void> setStrictMode(bool v) async => (await _sp()).setBool(_kStrictModeKey, v);

  Future<List<String>> dietFlags() async {
    final raw = (await _sp()).getString(_kDietFlagsKey);
    return raw == null ? const [] : (jsonDecode(raw) as List).cast<String>();
  }
  Future<void> setDietFlags(List<String> ids) async {
    await (await _sp()).setString(_kDietFlagsKey, jsonEncode(ids));
  }
}

