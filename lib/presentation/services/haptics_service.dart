import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/accessibility_service.dart';

final hapticsServiceProvider = Provider<HapticsService>((ref) => HapticsService(ref));

class HapticsService {
  HapticsService(this._ref);
  final Ref _ref;

  Future<void> lightImpact() async {
    final s = await _ref.read(accessibilityServiceProvider).get();
    if (s.reducedHaptics) return;
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  Future<void> mediumImpact() async {
    final s = await _ref.read(accessibilityServiceProvider).get();
    if (s.reducedHaptics) return;
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }
}

