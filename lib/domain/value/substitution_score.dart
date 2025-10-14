class SubstitutionScore {
  final String candidateRecipeId;
  // Normalized 0..1 contributions (higher is better)
  final double pantryGain; // = max(coverageDelta, 0)
  final double budgetGain; // = max(costDeltaNormalized, 0)
  final double macroGain; // = improvement toward targets (0..1)
  // Raw deltas for UI (signed)
  final double coverageDelta; // +0.35 means +35% pantry coverage
  final int weeklyCostDeltaCents; // negative means cheaper
  final ({double kcal, double proteinG, double carbsG, double fatG})
      macroDeltaPerServ; // candidate - current
  // Composite score used for ranking
  final double composite;
  const SubstitutionScore({
    required this.candidateRecipeId,
    required this.pantryGain,
    required this.budgetGain,
    required this.macroGain,
    required this.coverageDelta,
    required this.weeklyCostDeltaCents,
    required this.macroDeltaPerServ,
    required this.composite,
  });
}

