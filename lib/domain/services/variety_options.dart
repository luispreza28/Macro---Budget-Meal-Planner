import '../entities/plan.dart';

class VarietyOptions {
  final int maxRepeatsPerWeek;
  final bool enableProteinSpread;
  final bool enableCuisineRotation;
  final bool enablePrepMix;
  final List<Plan> historyPlans; // 0..4
  const VarietyOptions({
    required this.maxRepeatsPerWeek,
    required this.enableProteinSpread,
    required this.enableCuisineRotation,
    required this.enablePrepMix,
    required this.historyPlans,
  });
}

