import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/accessibility_service.dart';

final a11ySettingsProvider = FutureProvider<A11ySettings>((ref) async {
  return ref.read(accessibilityServiceProvider).get();
});

// Effective textScale (double) consumed by MaterialApp.builder
final a11yTextScaleProvider = FutureProvider<double>((ref) async {
  final s = await ref.read(accessibilityServiceProvider).get();
  switch (s.textScale) {
    case TextScalePreset.system:
      return 1.0; // let system override via MediaQuery if desired
    case TextScalePreset.large:
      return 1.15;
    case TextScalePreset.xlarge:
      return 1.3;
  }
});

/// Animation duration helper based on accessibility settings
class A11yDurations {
  final Duration fast;
  final Duration medium;
  final Duration long;
  const A11yDurations({required this.fast, required this.medium, required this.long});
}

final a11yAnimationsProvider = FutureProvider<A11yDurations>((ref) async {
  final s = await ref.read(accessibilityServiceProvider).get();
  if (s.reduceMotion) {
    return const A11yDurations(fast: Duration(milliseconds: 0), medium: Duration(milliseconds: 100), long: Duration(milliseconds: 150));
  }
  return const A11yDurations(fast: Duration(milliseconds: 100), medium: Duration(milliseconds: 250), long: Duration(milliseconds: 400));
});

