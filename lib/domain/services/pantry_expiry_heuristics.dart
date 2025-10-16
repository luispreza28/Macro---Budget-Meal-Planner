import '../../domain/entities/ingredient.dart';

class PantryHeuristics {
  // Very rough defaults by aisle; user can edit dates later.
  static int defaultShelfDays(Aisle aisle, {bool opened = false}) {
    switch (aisle) {
      case Aisle.produce:
        return opened ? 3 : 5;
      case Aisle.meat:
        return opened ? 2 : 3;
      case Aisle.dairy:
        return opened ? 5 : 10;
      case Aisle.frozen:
        return opened ? 30 : 90;
      case Aisle.condiments:
        return opened ? 60 : 180;
      case Aisle.bakery:
        return opened ? 2 : 4;
      case Aisle.pantry:
        return opened ? 30 : 180;
      case Aisle.household:
        return 365;
    }
  }
}

