import 'package:flutter_test/flutter_test.dart';
import 'package:macro_budget_meal_planner/core/constants/app_constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppConstants', () {
    test('should have correct database configuration', () {
      expect(AppConstants.databaseName, 'macro_budget_meal_planner.db');
      expect(AppConstants.databaseVersion, 1);
    });

    test('should have correct performance requirements', () {
      expect(AppConstants.planGenerationTimeout.inSeconds, 2);
      expect(AppConstants.swapTimeout.inMilliseconds, 300);
    });

    test('should have correct macro calculation constants', () {
      expect(AppConstants.macroErrorTolerance, 0.05);
      expect(AppConstants.proteinPenaltyMultiplier, 2.0);
    });

    test('should have correct seed data sizes', () {
      expect(AppConstants.seedIngredientsCount, 300);
      expect(AppConstants.seedRecipesCount, 100);
    });
  });

  group('Aisle enum', () {
    test('should have correct values', () {
      expect(Aisle.produce.value, 'produce');
      expect(Aisle.meat.value, 'meat');
      expect(Aisle.dairy.value, 'dairy');
    });
  });

  group('PlanningMode enum', () {
    test('should have correct values', () {
      expect(PlanningMode.cutting.value, 'cutting');
      expect(PlanningMode.bulkingBudget.value, 'bulking_budget');
      expect(PlanningMode.bulkingNoBudget.value, 'bulking_no_budget');
    });
  });

  group('Unit enum', () {
    test('should have correct values', () {
      expect(Unit.grams.value, 'g');
      expect(Unit.milliliters.value, 'ml');
      expect(Unit.pieces.value, 'piece');
    });
  });
}
