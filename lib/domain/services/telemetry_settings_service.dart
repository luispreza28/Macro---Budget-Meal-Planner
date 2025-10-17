import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../presentation/providers/database_providers.dart';

final telemetrySettingsServiceProvider = Provider<TelemetrySettingsService>((ref) => TelemetrySettingsService(ref));

class TelemetrySettingsService {
  TelemetrySettingsService(this.ref);
  final Ref ref;
  static const _k = 'telemetry.settings.v1';
  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  Future<TelemetrySettings> get() async {
    final raw = _prefs.getString(_k);
    if (raw == null) return const TelemetrySettings();
    try {
      return TelemetrySettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const TelemetrySettings();
    }
  }

  Future<void> save(TelemetrySettings s) async {
    await _prefs.setString(_k, jsonEncode(s.toJson()));
  }
}

class TelemetrySettings {
  final bool enabled;        // master switch
  final bool crashReporting; // Crashlytics/Sentry
  final bool analytics;      // Analytics events
  final bool performance;    // Perf traces
  final bool breadcrumbs;    // nav/provider breadcrumbs
  const TelemetrySettings({
    this.enabled = true,
    this.crashReporting = true,
    this.analytics = true,
    this.performance = true,
    this.breadcrumbs = true,
  });
  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'crashReporting': crashReporting,
        'analytics': analytics,
        'performance': performance,
        'breadcrumbs': breadcrumbs,
      };
  factory TelemetrySettings.fromJson(Map<String, dynamic> j) => TelemetrySettings(
        enabled: (j['enabled'] as bool?) ?? true,
        crashReporting: (j['crashReporting'] as bool?) ?? true,
        analytics: (j['analytics'] as bool?) ?? true,
        performance: (j['performance'] as bool?) ?? true,
        breadcrumbs: (j['breadcrumbs'] as bool?) ?? true,
      );
}
