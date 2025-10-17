import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final localeUnitsServiceProvider = Provider<LocaleUnitsService>((_) => LocaleUnitsService());

class LocaleUnitsService {
  static const _k = 'locale.units.settings.v1'; // JSON blob

  Future<SharedPreferences> _sp() => SharedPreferences.getInstance();

  Future<LocaleUnitsSettings> get() async {
    final raw = (await _sp()).getString(_k);
    if (raw == null) return const LocaleUnitsSettings();
    return LocaleUnitsSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save(LocaleUnitsSettings s) async {
    final sp = await _sp();
    await sp.setString(_k, jsonEncode(s.toJson()));
  }
}

class LocaleUnitsSettings {
  final String? localeCode; // e.g., 'en', 'es', 'en_US'
  final String? regionCurrency; // e.g., 'USD', 'EUR' (fallback from locale if null)
  final UnitSystem unitSystem; // metric or us
  // Fine-grained display toggles (best effort, safe-only)
  final bool showOzLb;
  final bool showFlOzCups;
  final bool showFahrenheit;

  const LocaleUnitsSettings({
    this.localeCode,
    this.regionCurrency,
    this.unitSystem = UnitSystem.metric,
    this.showOzLb = true,
    this.showFlOzCups = true,
    this.showFahrenheit = false,
  });

  Map<String, dynamic> toJson() => {
        'localeCode': localeCode,
        'regionCurrency': regionCurrency,
        'unitSystem': unitSystem.name,
        'showOzLb': showOzLb,
        'showFlOzCups': showFlOzCups,
        'showFahrenheit': showFahrenheit,
      };
  factory LocaleUnitsSettings.fromJson(Map<String, dynamic> j) => LocaleUnitsSettings(
        localeCode: j['localeCode'],
        regionCurrency: j['regionCurrency'],
        unitSystem: UnitSystem.values.firstWhere((e) => e.name == (j['unitSystem'] ?? 'metric')),
        showOzLb: j['showOzLb'] ?? true,
        showFlOzCups: j['showFlOzCups'] ?? true,
        showFahrenheit: j['showFahrenheit'] ?? false,
      );
}

enum UnitSystem { metric, us }

