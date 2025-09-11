import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../core/constants/app_constants.dart';

part 'database.g.dart';

/// Ingredients table for storing nutritional and cost data
class Ingredients extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get unit => text()(); // 'g', 'ml', 'piece'
  
  // Macros per 100g/ml
  RealColumn get kcalPer100g => real()();
  RealColumn get proteinPer100g => real()();
  RealColumn get carbsPer100g => real()();
  RealColumn get fatPer100g => real()();
  
  // Pricing
  IntColumn get pricePerUnitCents => integer()();
  
  // Purchase pack information
  RealColumn get purchasePackQty => real()();
  TextColumn get purchasePackUnit => text()();
  IntColumn get purchasePackPriceCents => integer().nullable()();
  
  // Organization
  TextColumn get aisle => text()(); // Aisle enum value
  TextColumn get tags => text()(); // JSON array of tags
  
  // Data source tracking
  TextColumn get source => text()(); // 'seed', 'fdc', 'off', 'manual'
  DateTimeColumn get lastVerifiedAt => dateTime().nullable()();
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Recipes table for meal planning
class Recipes extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get servings => integer()();
  IntColumn get timeMins => integer()();
  TextColumn get cuisine => text().nullable()();
  TextColumn get dietFlags => text()(); // JSON array
  TextColumn get items => text()(); // JSON array of ingredient items
  TextColumn get steps => text()(); // JSON array of cooking steps
  
  // Calculated macros per serving
  RealColumn get kcalPerServ => real()();
  RealColumn get proteinPerServ => real()();
  RealColumn get carbsPerServ => real()();
  RealColumn get fatPerServ => real()();
  
  // Calculated cost per serving
  IntColumn get costPerServCents => integer()();
  
  // Data source
  TextColumn get source => text()(); // 'seed', 'manual'
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// User targets and preferences
class UserTargets extends Table {
  TextColumn get id => text()();
  
  // Macro targets
  RealColumn get kcal => real()();
  RealColumn get proteinG => real()();
  RealColumn get carbsG => real()();
  RealColumn get fatG => real()();
  
  // Budget (nullable for no-budget mode)
  IntColumn get budgetCents => integer().nullable()();
  
  // Preferences
  IntColumn get mealsPerDay => integer()();
  IntColumn get timeCapMins => integer().nullable()();
  TextColumn get dietFlags => text()(); // JSON array
  TextColumn get equipment => text()(); // JSON array
  TextColumn get planningMode => text()(); // PlanningMode enum value
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Pantry items for pantry-first planning (Pro feature)
class PantryItems extends Table {
  TextColumn get id => text()();
  TextColumn get ingredientId => text()();
  RealColumn get qty => real()();
  TextColumn get unit => text()();
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Generated meal plans
class Plans extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get userTargetsId => text()();
  TextColumn get days => text()(); // JSON array of days with meals
  
  // Plan totals
  RealColumn get totalKcal => real()();
  RealColumn get totalProteinG => real()();
  RealColumn get totalCarbsG => real()();
  RealColumn get totalFatG => real()();
  IntColumn get totalCostCents => integer()();
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Price overrides for ingredients
class PriceOverrides extends Table {
  TextColumn get id => text()();
  TextColumn get ingredientId => text()();
  IntColumn get pricePerUnitCents => integer()();
  
  // Optional purchase pack override
  RealColumn get purchasePackQty => real().nullable()();
  TextColumn get purchasePackUnit => text().nullable()();
  IntColumn get purchasePackPriceCents => integer().nullable()();
  
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Main database class
@DriftDatabase(tables: [
  Ingredients,
  Recipes,
  UserTargets,
  PantryItems,
  Plans,
  PriceOverrides,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => AppConstants.databaseVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      
      // Create indexes for better performance
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_ingredients_aisle ON ingredients (aisle)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_ingredients_price ON ingredients (price_per_unit_cents)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_ingredients_protein ON ingredients (protein_per_100g)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_recipes_time ON recipes (time_mins)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_recipes_cost ON recipes (cost_per_serv_cents)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_recipes_protein ON recipes (protein_per_serv)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_plans_created_at ON plans (created_at)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_plans_user_targets_id ON plans (user_targets_id)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_pantry_items_ingredient_id ON pantry_items (ingredient_id)',
      );
      await customStatement(
        'CREATE INDEX IF NOT EXISTS idx_price_overrides_ingredient_id ON price_overrides (ingredient_id)',
      );
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // Handle future database migrations here
      if (from <= 1 && to >= 2) {
        // Add indexes if they don't exist (for upgrades from v1)
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_ingredients_aisle ON ingredients (aisle)',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_ingredients_price ON ingredients (price_per_unit_cents)',
        );
        // Add other indexes...
      }
    },
    beforeOpen: (details) async {
      // Basic SQLite configuration
      // More advanced PRAGMA settings will be added in future versions
    },
  );
}

/// Opens a connection to the SQLite database
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, AppConstants.databaseName));
    return NativeDatabase.createInBackground(file);
  });
}
