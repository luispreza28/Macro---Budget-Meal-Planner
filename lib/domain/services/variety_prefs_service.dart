import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../presentation/providers/database_providers.dart';

final varietyPrefsServiceProvider = Provider<VarietyPrefsService>((ref) => VarietyPrefsService(ref));

class VarietyPrefsService {
  VarietyPrefsService(this.ref);
  final Ref ref;

  static const _kMaxRepeatsPerWeek = 'variety.maxRepeatsPerWeek.v1'; // int (1..2)
  static const _kEnableProteinSpread = 'variety.enableProteinSpread.v1'; // bool
  static const _kEnableCuisineRotation = 'variety.enableCuisineRotation.v1'; // bool
  static const _kEnablePrepMix = 'variety.enablePrepMix.v1'; // bool
  static const _kHistoryLookbackPlans = 'variety.historyLookbackPlans.v1'; // int (0..4)

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  Future<int> maxRepeatsPerWeek() async {
    final v = _prefs.getInt(_kMaxRepeatsPerWeek);
    return (v == null) ? 1 : v.clamp(1, 2);
  }

  Future<void> setMaxRepeatsPerWeek(int n) async {
    final v = n.clamp(1, 2);
    await _prefs.setInt(_kMaxRepeatsPerWeek, v);
  }

  Future<bool> enableProteinSpread() async {
    return _prefs.getBool(_kEnableProteinSpread) ?? true;
  }

  Future<void> setEnableProteinSpread(bool val) async {
    await _prefs.setBool(_kEnableProteinSpread, val);
  }

  Future<bool> enableCuisineRotation() async {
    return _prefs.getBool(_kEnableCuisineRotation) ?? true;
  }

  Future<void> setEnableCuisineRotation(bool val) async {
    await _prefs.setBool(_kEnableCuisineRotation, val);
  }

  Future<bool> enablePrepMix() async {
    return _prefs.getBool(_kEnablePrepMix) ?? true;
  }

  Future<void> setEnablePrepMix(bool val) async {
    await _prefs.setBool(_kEnablePrepMix, val);
  }

  Future<int> historyLookbackPlans() async {
    final v = _prefs.getInt(_kHistoryLookbackPlans);
    return (v == null) ? 2 : v.clamp(0, 4);
  }

  Future<void> setHistoryLookbackPlans(int k) async {
    final v = k.clamp(0, 4);
    await _prefs.setInt(_kHistoryLookbackPlans, v);
  }
}

