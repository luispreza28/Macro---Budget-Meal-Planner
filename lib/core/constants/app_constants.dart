/// Application constants and configuration values
class AppConstants {
  // Database
  static const String databaseName = 'macro_budget_meal_planner.db';
  static const int databaseVersion = 1;

  // Performance requirements (from PRD)
  static const Duration planGenerationTimeout = Duration(seconds: 2);
  static const Duration swapTimeout = Duration(milliseconds: 300);

  // App limits
  static const int maxAppSizeMB = 40;
  static const double crashFreeSessionsTarget = 99.5;

  // Macro calculation precision
  static const double macroErrorTolerance = 0.05; // ±5%
  static const double proteinPenaltyMultiplier = 2.0; // Under-protein penalized 2×

  // Seed data sizes (from PRD)
  static const int seedIngredientsCount = 300;
  static const int seedRecipesCount = 100;

  // Free tier limits
  static const int freeActivePlansLimit = 1;
  static const int freeRecipeLibrarySize = 20;

  // Pro features
  static const int proActivePlansLimit = -1; // Unlimited
  static const int proRecipeLibrarySize = 100;

  // Subscription pricing (from PRD)
  static const String monthlyPrice = '\$3.99';
  static const String annualPrice = '\$24.00';
  static const int trialDays = 7;

  // Planning modes
  static const String modeCutting = 'cutting';
  static const String modeBulkingBudget = 'bulking_budget';
  static const String modeBulkingNoBudget = 'bulking_no_budget';

  // Objective function weights (tunable parameters)
  static const double macroErrorWeight = 1.0;
  static const double budgetErrorWeight = 1.0;
  static const double varietyPenaltyWeight = 0.5;
  static const double prepTimePenaltyWeight = 0.3;
  static const double pantryBonusWeight = 0.2;

  // Default user preferences
  static const int defaultMealsPerDay = 3;
  static const int defaultTimeCap = 30; // minutes
  static const double defaultBudget = 50.0; // dollars per week
}

/// Aisle categories for shopping list organization
enum Aisle {
  produce('produce'),
  meat('meat'),
  dairy('dairy'),
  pantry('pantry'),
  frozen('frozen'),
  condiments('condiments'),
  bakery('bakery'),
  household('household');

  const Aisle(this.value);
  final String value;
}

/// Planning modes for different user goals
enum PlanningMode {
  cutting('cutting'),
  bulkingBudget('bulking_budget'),
  bulkingNoBudget('bulking_no_budget');

  const PlanningMode(this.value);
  final String value;
}

/// Units for ingredient measurements
enum Unit {
  grams('g'),
  milliliters('ml'),
  pieces('piece');

  const Unit(this.value);
  final String value;
}
