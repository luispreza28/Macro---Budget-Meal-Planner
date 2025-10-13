class TargetsPresetService {
  // Base kcal used for simple presets
  static const double _baseMaintainKcal = 2200;

  // Macro splits as fractions for presets
  static const ({double p, double c, double f}) _cutSplit = (p: 0.35, c: 0.35, f: 0.30);
  static const ({double p, double c, double f}) _maintainSplit = (p: 0.30, c: 0.40, f: 0.30);
  static const ({double p, double c, double f}) _bulkSplit = (p: 0.25, c: 0.50, f: 0.25);

  /// Returns (kcal, p, c, f) for the chosen preset.
  /// Keep it simple & transparent; users can edit on next step.
  static ({double kcal, double proteinG, double carbsG, double fatG}) fromPreset(String preset) {
    double kcal;
    ({double p, double c, double f}) split;

    switch (preset) {
      case 'cut':
        kcal = _baseMaintainKcal * 0.85; // -15%
        split = _cutSplit;
        break;
      case 'bulk':
        kcal = _baseMaintainKcal * 1.15; // +15%
        split = _bulkSplit;
        break;
      case 'maintain':
      default:
        kcal = _baseMaintainKcal;
        split = _maintainSplit;
        break;
    }

    // Convert macro kcal to grams
    final proteinKcal = kcal * split.p;
    final carbsKcal = kcal * split.c;
    final fatKcal = kcal * split.f;

    final proteinG = (proteinKcal / 4).roundToDouble();
    final carbsG = (carbsKcal / 4).roundToDouble();
    final fatG = (fatKcal / 9).roundToDouble();

    return (
      kcal: kcal.roundToDouble(),
      proteinG: proteinG,
      carbsG: carbsG,
      fatG: fatG,
    );
  }
}

