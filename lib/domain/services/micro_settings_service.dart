import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final microSettingsServiceProvider = Provider<MicroSettingsService>((_) => MicroSettingsService());

class MicroSettingsService {
  static const _k = 'micro.settings.v1';
  Future<SharedPreferences> _sp() => SharedPreferences.getInstance();

  Future<MicroSettings> get() async {
    final raw = (await _sp()).getString(_k);
    if (raw == null) return const MicroSettings();
    return MicroSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save(MicroSettings s) async {
    final sp = await _sp();
    await sp.setString(_k, jsonEncode(s.toJson()));
  }
}

class MicroSettings {
  final bool hintsEnabled;
  final double fiberLowGPerServ;   // e.g., 6.0
  final int sodiumHighMgPerServ;   // e.g., 700
  final double satFatHighGPerServ; // e.g., 6.0
  final double satFatHighPctKcal;  // e.g., 10.0 (% kcal)
  final double weeklyFiberTargetG; // e.g., 175 (25g/day * 7)
  const MicroSettings({
    this.hintsEnabled = true,
    this.fiberLowGPerServ = 6.0,
    this.sodiumHighMgPerServ = 700,
    this.satFatHighGPerServ = 6.0,
    this.satFatHighPctKcal = 10.0,
    this.weeklyFiberTargetG = 175.0,
  });

  Map<String, dynamic> toJson() => {
        'hintsEnabled': hintsEnabled,
        'fiberLowGPerServ': fiberLowGPerServ,
        'sodiumHighMgPerServ': sodiumHighMgPerServ,
        'satFatHighGPerServ': satFatHighGPerServ,
        'satFatHighPctKcal': satFatHighPctKcal,
        'weeklyFiberTargetG': weeklyFiberTargetG,
      };
  factory MicroSettings.fromJson(Map<String, dynamic> j) => MicroSettings(
        hintsEnabled: j['hintsEnabled'] ?? true,
        fiberLowGPerServ: (j['fiberLowGPerServ'] ?? 6.0).toDouble(),
        sodiumHighMgPerServ: (j['sodiumHighMgPerServ'] ?? 700).toInt(),
        satFatHighGPerServ: (j['satFatHighGPerServ'] ?? 6.0).toDouble(),
        satFatHighPctKcal: (j['satFatHighPctKcal'] ?? 10.0).toDouble(),
        weeklyFiberTargetG: (j['weeklyFiberTargetG'] ?? 175.0).toDouble(),
      );
}

