import 'package:drift/drift.dart';
import '../datasources/database.dart';
import 'database_performance_service.dart';
import '../../core/utils/logger.dart';

/// Service for handling database migrations
class DatabaseMigrationService {
  const DatabaseMigrationService(this._database);

  final AppDatabase _database;

  /// Get the migration strategy for the database
  MigrationStrategy get migrationStrategy => MigrationStrategy(
    onCreate: _onCreate,
    onUpgrade: _onUpgrade,
    beforeOpen: (details) async => await _beforeOpen(details.executor),
  );

  /// Create all tables on first run
  Future<void> _onCreate(Migrator m) async {
    await m.createAll();
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Migrator m, int from, int to) async {
    // Migration from version 1 to 2
    if (from <= 1 && to >= 2) {
      await _migrateToV2(m);
    }

    // Migration from version 2 to 3
    if (from <= 2 && to >= 3) {
      await _migrateToV3(m);
    }

    // Add more migrations as needed
  }

  /// Called before opening the database
  Future<void> _beforeOpen(QueryExecutor e) async {
    AppLogger.d('Configuring database before opening', tag: 'DatabaseMigration');
    
    // Enable foreign key constraints
    await e.runCustom('PRAGMA foreign_keys = ON');
    
    // Apply performance optimizations
    final performanceService = DatabasePerformanceService(_database);
    try {
      await performanceService.optimizeDatabase();
      AppLogger.d('Database performance optimization completed', tag: 'DatabaseMigration');
    } catch (e, stackTrace) {
      AppLogger.w('Database performance optimization failed', 
        tag: 'DatabaseMigration', error: e, stackTrace: stackTrace);
    }
  }

  /// Migration to version 2 - Example: Add indexes for better performance
  Future<void> _migrateToV2(Migrator m) async {
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_ingredients_aisle ON ingredients (aisle)',
    );
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_ingredients_price ON ingredients (price_per_unit_cents)',
    );
    // NEW: corrected column name
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_ingredients_protein ON ingredients (protein_per100g)',
    );
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_recipes_time ON recipes (time_mins)',
    );
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_recipes_cost ON recipes (cost_per_serv_cents)',
    );
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_plans_created_at ON plans (created_at)',
    );
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_pantry_items_ingredient_id ON pantry_items (ingredient_id)',
    );
    await m.database.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_price_overrides_ingredient_id ON price_overrides (ingredient_id)',
    );
  }


  /// Migration to version 3 - Example: Add new columns or tables
  Future<void> _migrateToV3(Migrator m) async {
    // Example: Add a new column to ingredients table
    // await m.addColumn(database.ingredients, database.ingredients.newColumn);
    
    // Example: Create a new table
    // await m.create(database.newTable);
    
    // For now, this is a placeholder for future migrations
  }

  /// Backup database before major migrations
  Future<void> backupDatabase() async {
    // Implementation would depend on platform
    // For now, this is a placeholder
  }

  /// Restore database from backup
  Future<void> restoreDatabase() async {
    // Implementation would depend on platform
    // For now, this is a placeholder
  }

  /// Check database integrity
  Future<bool> checkDatabaseIntegrity() async {
    try {
      final result = await _database.customSelect('PRAGMA integrity_check').get();
      return result.isNotEmpty && result.first.data['integrity_check'] == 'ok';
    } catch (e) {
      return false;
    }
  }

  /// Optimize database (vacuum and analyze)
  Future<void> optimizeDatabase() async {
    try {
      await _database.customStatement('VACUUM');
      await _database.customStatement('ANALYZE');
    } catch (e) {
      // Handle optimization errors
    }
  }

  /// Get database size in bytes
  Future<int> getDatabaseSize() async {
    try {
      final result = await _database.customSelect('PRAGMA page_count').getSingle();
      final pageCount = result.data['page_count'] as int;
      
      final pageSizeResult = await _database.customSelect('PRAGMA page_size').getSingle();
      final pageSize = pageSizeResult.data['page_size'] as int;
      
      return pageCount * pageSize;
    } catch (e) {
      return 0;
    }
  }

  /// Get table information
  Future<Map<String, dynamic>> getTableInfo() async {
    final tables = <String, dynamic>{};
    
    try {
      // Get list of tables
      final tableList = await _database.customSelect(
        "SELECT name FROM sqlite_master WHERE type='table'",
      ).get();
      
      for (final table in tableList) {
        final tableName = table.data['name'] as String;
        
        // Get row count for each table
        final countResult = await _database.customSelect(
          'SELECT COUNT(*) as count FROM $tableName',
        ).getSingle();
        
        tables[tableName] = {
          'row_count': countResult.data['count'],
        };
      }
    } catch (e) {
      // Handle errors
    }
    
    return tables;
  }

  /// Reset database (drop all tables and recreate)
  Future<void> resetDatabase() async {
    // Get all table names
    final tables = await _database.customSelect(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
    ).get();
    
    // Drop all tables
    for (final table in tables) {
      final tableName = table.data['name'] as String;
      await _database.customStatement('DROP TABLE IF EXISTS $tableName');
    }
    
    // Recreate all tables using the migration strategy
    await _database.transaction(() async {
      final migrator = Migrator(_database);
      await migrator.createAll();
    });
  }

  /// Export database schema
  Future<String> exportSchema() async {
    final result = await _database.customSelect(
      "SELECT sql FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
    ).get();
    
    return result.map((row) => row.data['sql'] as String).join('\n\n');
  }

  /// Validate foreign key constraints
  Future<List<Map<String, dynamic>>> validateForeignKeys() async {
    final result = await _database.customSelect('PRAGMA foreign_key_check').get();
    return result.map((row) => row.data).toList();
  }
}
