import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final accessibilityServiceProvider = Provider<AccessibilityService>((_) => AccessibilityService());

class AccessibilityService {
  static const _k = 'accessibility.settings.v1';
  Future<SharedPreferences> _sp() => SharedPreferences.getInstance();

  Future<A11ySettings> get() async {
    final raw = (await _sp()).getString(_k);
    if (raw == null) return const A11ySettings();
    return A11ySettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save(A11ySettings s) async {
    final sp = await _sp();
    await sp.setString(_k, jsonEncode(s.toJson()));
  }
}

enum TextScalePreset { system, large, xlarge }

class A11ySettings {
  final TextScalePreset textScale;
  final bool highContrast;
  final bool reduceMotion;
  final bool reducedHaptics;
  final bool showFocusRect; // dev overlay

  const A11ySettings({
    this.textScale = TextScalePreset.system,
    this.highContrast = false,
    this.reduceMotion = false,
    this.reducedHaptics = false,
    this.showFocusRect = false,
  });

  Map<String, dynamic> toJson() => {
        'textScale': textScale.name,
        'highContrast': highContrast,
        'reduceMotion': reduceMotion,
        'reducedHaptics': reducedHaptics,
        'showFocusRect': showFocusRect,
      };

  factory A11ySettings.fromJson(Map<String, dynamic> j) => A11ySettings(
        textScale: TextScalePreset.values.firstWhere((e) => e.name == (j['textScale'] ?? 'system')),
        highContrast: j['highContrast'] ?? false,
        reduceMotion: j['reduceMotion'] ?? false,
        reducedHaptics: j['reducedHaptics'] ?? false,
        showFocusRect: j['showFocusRect'] ?? false,
      );
}

