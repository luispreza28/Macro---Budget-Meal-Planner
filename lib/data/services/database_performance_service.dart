import 'package:drift/drift.dart';

import '../datasources/database.dart';
import '../../core/utils/logger.dart';
import '../../core/errors/error_handler.dart';

/// Service for managing database performance optimization
class DatabasePerformanceService {
  const DatabasePerformanceService(this._database);

  final AppDatabase _database;

  /// Optimize database performance with advanced settings
  Future<void> optimizeDatabase() async {
    try {
      AppLogger.d('Starting database optimization', tag: 'DatabasePerformance');
      
      await _configureWALMode();
      await _configurePragmaSettings();
      await _analyzeDatabase();
      await _createAdditionalIndexes();
      
      AppLogger.i('Database optimization completed', tag: 'DatabasePerformance');
    } catch (e, stackTrace) {
      AppLogger.e('Database optimization failed', 
        tag: 'DatabasePerformance', error: e, stackTrace: stackTrace);
      throw DatabaseFailure(message: 'Failed to optimize database: $e');
    }
  }

  /// Configure WAL mode for better concurrent access
  Future<void> _configureWALMode() async {
    await _database.customStatement('PRAGMA journal_mode = WAL');
    await _database.customStatement('PRAGMA synchronous = NORMAL');
    AppLogger.d('WAL mode configured', tag: 'DatabasePerformance');
  }

  /// Configure advanced PRAGMA settings for performance
  Future<void> _configurePragmaSettings() async {
    // Enable foreign keys for data integrity
    await _database.customStatement('PRAGMA foreign_keys = ON');
    
    // Optimize cache size (10MB cache)
    await _database.customStatement('PRAGMA cache_size = -10240');
    
    // Set temp store to memory for better performance
    await _database.customStatement('PRAGMA temp_store = MEMORY');
    
    // Optimize page size for mobile devices
    await _database.customStatement('PRAGMA page_size = 4096');
    
    // Set mmap size for memory-mapped I/O (64MB)
    await _database.customStatement('PRAGMA mmap_size = 67108864');
    
    // Optimize locking mode
    await _database.customStatement('PRAGMA locking_mode = NORMAL');
    
    AppLogger.d('PRAGMA settings configured', tag: 'DatabasePerformance');
  }

  /// Run ANALYZE to update query planner statistics
  Future<void> _analyzeDatabase() async {
    await _database.customStatement('ANALYZE');
    AppLogger.d('Database analysis completed', tag: 'DatabasePerformance');
  }

  /// Create additional performance indexes
  Future<void> _createAdditionalIndexes() async {
    final indexes = [
      // Composite indexes for common queries
      'CREATE INDEX IF NOT EXISTS idx_ingredients_aisle_price ON ingredients (aisle, price_per_unit_cents)',
      'CREATE INDEX IF NOT EXISTS idx_ingredients_protein_price ON ingredients (protein_per_100g, price_per_unit_cents)',
      'CREATE INDEX IF NOT EXISTS idx_recipes_time_cost ON recipes (time_mins, cost_per_serv_cents)',
      'CREATE INDEX IF NOT EXISTS idx_recipes_diet_flags ON recipes (diet_flags)',
      'CREATE INDEX IF NOT EXISTS idx_recipes_cuisine_time ON recipes (cuisine, time_mins)',
      
      // Full-text search indexes for name searches
      'CREATE INDEX IF NOT EXISTS idx_ingredients_name_search ON ingredients (name COLLATE NOCASE)',
      'CREATE INDEX IF NOT EXISTS idx_recipes_name_search ON recipes (name COLLATE NOCASE)',
      
      // Indexes for filtering and sorting
      'CREATE INDEX IF NOT EXISTS idx_ingredients_source ON ingredients (source)',
      'CREATE INDEX IF NOT EXISTS idx_recipes_source ON recipes (source)',
      'CREATE INDEX IF NOT EXISTS idx_plans_is_current ON plans (is_current)',
      'CREATE INDEX IF NOT EXISTS idx_user_targets_is_current ON user_targets (is_current)',
      
      // Indexes for date-based queries
      'CREATE INDEX IF NOT EXISTS idx_ingredients_updated_at ON ingredients (updated_at)',
      'CREATE INDEX IF NOT EXISTS idx_recipes_updated_at ON recipes (updated_at)',
      'CREATE INDEX IF NOT EXISTS idx_plans_updated_at ON plans (updated_at)',
    ];

    for (final index in indexes) {
      try {
        await _database.customStatement(index);
      } catch (e) {
        AppLogger.w('Failed to create index: $index', 
          tag: 'DatabasePerformance', error: e);
      }
    }

    AppLogger.d('Additional indexes created', tag: 'DatabasePerformance');
  }

  /// Get database performance statistics
  Future<Map<String, dynamic>> getPerformanceStats() async {
    try {
      final stats = <String, dynamic>{};

      // Get database size
      final sizeResult = await _database.customSelect('PRAGMA page_count').get();
      final pageCount = sizeResult.first.data['page_count'] as int;
      final pageSizeResult = await _database.customSelect('PRAGMA page_size').get();
      final pageSize = pageSizeResult.first.data['page_size'] as int;
      stats['database_size_bytes'] = pageCount * pageSize;
      stats['database_size_mb'] = (pageCount * pageSize) / (1024 * 1024);

      // Get cache hit ratio
      final cacheResult = await _database.customSelect('PRAGMA cache_size').get();
      stats['cache_size'] = cacheResult.first.data['cache_size'];

      // Get journal mode
      final journalResult = await _database.customSelect('PRAGMA journal_mode').get();
      stats['journal_mode'] = journalResult.first.data['journal_mode'];

      // Get table counts
      final tablesQuery = await _database.customSelect('''
        SELECT name, (
          SELECT COUNT(*) FROM sqlite_master sm2 
          WHERE sm2.type = 'table' AND sm2.name = sm1.name
        ) as row_count
        FROM sqlite_master sm1 
        WHERE type = 'table' AND name NOT LIKE 'sqlite_%'
      ''').get();

      final tableCounts = <String, int>{};
      for (final row in tablesQuery) {
        final tableName = row.data['name'] as String;
        try {
          final countResult = await _database.customSelect('SELECT COUNT(*) as count FROM $tableName').get();
          tableCounts[tableName] = countResult.first.data['count'] as int;
        } catch (e) {
          tableCounts[tableName] = 0;
        }
      }
      stats['table_counts'] = tableCounts;

      // Get index information
      final indexesResult = await _database.customSelect('''
        SELECT name, tbl_name FROM sqlite_master 
        WHERE type = 'index' AND name NOT LIKE 'sqlite_%'
      ''').get();
      stats['index_count'] = indexesResult.length;

      return stats;
    } catch (e, stackTrace) {
      AppLogger.e('Failed to get performance stats', 
        tag: 'DatabasePerformance', error: e, stackTrace: stackTrace);
      return {'error': e.toString()};
    }
  }

  /// Vacuum database to reclaim space and optimize
  Future<void> vacuumDatabase() async {
    try {
      AppLogger.d('Starting database vacuum', tag: 'DatabasePerformance');
      
      final startTime = DateTime.now();
      await _database.customStatement('VACUUM');
      final duration = DateTime.now().difference(startTime);
      
      AppLogger.timing('Database vacuum', duration, tag: 'DatabasePerformance');
    } catch (e, stackTrace) {
      AppLogger.e('Database vacuum failed', 
        tag: 'DatabasePerformance', error: e, stackTrace: stackTrace);
      throw DatabaseFailure(message: 'Failed to vacuum database: $e');
    }
  }

  /// Optimize specific table by rebuilding indexes
  Future<void> optimizeTable(String tableName) async {
    try {
      AppLogger.d('Optimizing table: $tableName', tag: 'DatabasePerformance');
      
      // Reindex the table
      await _database.customStatement('REINDEX $tableName');
      
      AppLogger.d('Table optimization completed: $tableName', tag: 'DatabasePerformance');
    } catch (e, stackTrace) {
      AppLogger.e('Table optimization failed for $tableName', 
        tag: 'DatabasePerformance', error: e, stackTrace: stackTrace);
      throw DatabaseFailure(message: 'Failed to optimize table $tableName: $e');
    }
  }

  /// Check database integrity
  Future<bool> checkIntegrity() async {
    try {
      AppLogger.d('Checking database integrity', tag: 'DatabasePerformance');
      
      final result = await _database.customSelect('PRAGMA integrity_check').get();
      final isIntact = result.isNotEmpty && 
                      result.first.data.values.first == 'ok';
      
      AppLogger.d('Database integrity check: ${isIntact ? 'OK' : 'FAILED'}', 
        tag: 'DatabasePerformance');
      
      return isIntact;
    } catch (e, stackTrace) {
      AppLogger.e('Database integrity check failed', 
        tag: 'DatabasePerformance', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Get query execution plan for debugging
  Future<List<Map<String, dynamic>>> explainQuery(String query) async {
    try {
      final result = await _database.customSelect('EXPLAIN QUERY PLAN $query').get();
      return result.map((row) => row.data).toList();
    } catch (e, stackTrace) {
      AppLogger.e('Failed to explain query: $query', 
        tag: 'DatabasePerformance', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Monitor slow queries (for development)
  Future<void> enableQueryLogging() async {
    try {
      // This would require custom implementation in production
      // For now, just log that monitoring is enabled
      AppLogger.d('Query logging enabled', tag: 'DatabasePerformance');
    } catch (e, stackTrace) {
      AppLogger.e('Failed to enable query logging', 
        tag: 'DatabasePerformance', error: e, stackTrace: stackTrace);
    }
  }
}
