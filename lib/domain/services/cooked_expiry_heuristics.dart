class CookedExpiryHeuristics {
  /// Return shelf days for a cooked recipe, rough defaults.
  /// Hot meals: 3–4 days refrigerated; 2–3 months frozen (not applied v1).
  static int cookedShelfDays({bool frozen = false}) {
    if (frozen) return 60; // not used in v1 (fridge default)
    return 4;
  }
}

