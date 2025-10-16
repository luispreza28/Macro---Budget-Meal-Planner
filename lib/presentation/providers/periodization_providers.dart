import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/services/periodization_service.dart';
import 'user_targets_providers.dart';
import '../../domain/entities/user_targets.dart';

final phasesProvider = FutureProvider<List<Phase>>((ref) async {
  return ref.read(periodizationServiceProvider).list();
});

/// The active phase for "today" (local), latest-wins among overlaps.
final activePhaseProvider = FutureProvider<Phase?>((ref) async {
  final xs = await ref.watch(phasesProvider.future);
  final now = DateTime.now();
  final matches = xs.where((p) => p.contains(now)).toList();
  if (matches.isEmpty) return null;
  // Simplified: choose the phase with the latest start among matches.
  matches.sort((a, b) => a.start.compareTo(b.start));
  final picked = matches.last;
  if (kDebugMode) {
    debugPrint('[Periodization] active=${picked.type.name} start=${DateFormat('yyyy-MM-dd').format(picked.start)}');
  }
  return picked;
});

/// Decorated targets for today, based on active phase.
/// Reads currentUserTargetsProvider and applies a deterministic overlay.
final decoratedUserTargetsProvider = FutureProvider<DecoratedTargets?>((ref) async {
  // currentUserTargetsProvider is a StreamProvider<UserTargets?>; grab latest.
  final base = await ref.watch(currentUserTargetsProvider.stream).first;
  if (base == null) return null;
  final phase = await ref.watch(activePhaseProvider.future);
  if (phase == null) {
    return DecoratedTargets(
      base: base,
      phase: null,
      kcal: base.kcal,
      p: base.proteinG,
      c: base.carbsG,
      f: base.fatG,
    );
  }

  double kcal = base.kcal;
  double p = base.proteinG;
  double f = base.fatG;
  double c = base.carbsG;

  switch (phase.type) {
    case PhaseType.cut:
      final delta = (-0.20 * kcal).clamp(-10000.0, -300.0); // at least -300 kcal
      kcal = (kcal + delta);
      p = (p * 1.10);
      f = (f * 0.90);
      break;
    case PhaseType.maintain:
      // no change
      break;
    case PhaseType.bulk:
      final delta = (0.10 * kcal).clamp(200.0, 10000.0); // at least +200 kcal
      kcal = (kcal + delta);
      p = (p * 1.05);
      f = (f * 1.10);
      break;
  }
  // carbs balances to meet kcal target (approx 4 kcal/g for carbs, 4 for protein, 9 for fat)
  final kcalFromPF = (p * 4.0) + (f * 9.0);
  final cKcal = (kcal - kcalFromPF).clamp(0.0, 20000.0);
  c = cKcal / 4.0;

  if (kDebugMode) {
    debugPrint('[Periodization] decorate -> phase=${phase.type.name} kcal=${kcal.toStringAsFixed(0)} p=${p.toStringAsFixed(0)} c=${c.toStringAsFixed(0)} f=${f.toStringAsFixed(0)}');
  }

  return DecoratedTargets(
    base: base,
    phase: phase,
    kcal: kcal,
    p: p,
    c: c,
    f: f,
  );
});

class DecoratedTargets {
  final UserTargets base;
  final Phase? phase;
  final double kcal, p, c, f;
  const DecoratedTargets({
    required this.base,
    required this.phase,
    required this.kcal,
    required this.p,
    required this.c,
    required this.f,
  });

  /// Convenience: convert to a UserTargets copy for consumers expecting that type.
  UserTargets toUserTargets() => base.copyWith(
        kcal: kcal,
        proteinG: p,
        carbsG: c,
        fatG: f,
      );
}

