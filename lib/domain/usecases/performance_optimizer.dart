import 'dart:async';
import 'dart:isolate';

import '../entities/recipe.dart';
import '../entities/ingredient.dart';
import '../entities/user_targets.dart';
import '../entities/plan.dart';
import '../entities/pantry_item.dart';

/// Performance optimization utilities for plan generation
class PerformanceOptimizer {
  PerformanceOptimizer();

  /// Recipe filtering cache to avoid repeated filtering
  static final Map<String, List<Recipe>> _recipeFilterCache = {};
  
  /// Ingredient lookup cache for faster access
  static final Map<String, Ingredient> _ingredientCache = {};
  
  /// Performance metrics tracking
  static final Map<String, List<int>> _performanceMetrics = {};

  /// Pre-filter and cache recipes for faster plan generation
  List<Recipe> getOptimizedRecipes({
    required List<Recipe> allRecipes,
    required UserTargets targets,
    bool useCache = true,
  }) {
    final cacheKey = _generateRecipeCacheKey(targets);
    
    if (useCache && _recipeFilterCache.containsKey(cacheKey)) {
      return _recipeFilterCache[cacheKey]!;
    }

    // Filter recipes by constraints
    final filteredRecipes = allRecipes
        .where((recipe) => recipe.isCompatibleWithDiet(targets.dietFlags))
        .where((recipe) => recipe.fitsTimeConstraint(targets.timeCapMins))
        .toList();

    // Sort by mode-specific criteria for faster selection
    _sortRecipesByMode(filteredRecipes, targets.planningMode);

    // Limit to reasonable number for performance
    final optimizedRecipes = filteredRecipes.take(50).toList();

    if (useCache) {
      _recipeFilterCache[cacheKey] = optimizedRecipes;
    }

    return optimizedRecipes;
  }

  /// Build ingredient lookup cache for faster access
  Map<String, Ingredient> buildIngredientCache(List<Ingredient> ingredients) {
    if (_ingredientCache.isEmpty) {
      for (final ingredient in ingredients) {
        _ingredientCache[ingredient.id] = ingredient;
      }
    }
    return _ingredientCache;
  }

  /// Get ingredient by ID with caching
  Ingredient? getCachedIngredient(String ingredientId) {
    return _ingredientCache[ingredientId];
  }

  /// Pre-calculate recipe metrics for faster optimization
  Map<String, Map<String, double>> precalculateRecipeMetrics({
    required List<Recipe> recipes,
    required List<Ingredient> ingredients,
  }) {
    final metrics = <String, Map<String, double>>{};
    final ingredientCache = buildIngredientCache(ingredients);

    for (final recipe in recipes) {
      final recipeMetrics = <String, double>{};
      
      // Calculate cost efficiency
      recipeMetrics['costEfficiency'] = recipe.getCostEfficiency();
      
      // Calculate protein density
      recipeMetrics['proteinDensity'] = recipe.getProteinDensity();
      
      // Calculate calorie density
      recipeMetrics['calorieDensity'] = recipe.macrosPerServ.kcal;
      
      // Calculate prep time score (lower is better)
      recipeMetrics['prepTimeScore'] = recipe.timeMins.toDouble();
      
      // Calculate ingredient availability score
      int availableIngredients = 0;
      for (final item in recipe.items) {
        if (ingredientCache.containsKey(item.ingredientId)) {
          availableIngredients++;
        }
      }
      recipeMetrics['availabilityScore'] = availableIngredients / recipe.items.length;

      metrics[recipe.id] = recipeMetrics;
    }

    return metrics;
  }

  /// Optimize plan generation with time constraints
  Future<T> runWithTimeLimit<T>({
    required Future<T> Function() operation,
    required Duration timeLimit,
    required T fallbackValue,
  }) async {
    try {
      return await operation().timeout(timeLimit);
    } on TimeoutException {
      // Return fallback if operation times out
      return fallbackValue;
    }
  }

  /// Run plan generation in isolate for better performance
  static Future<Plan?> generatePlanInIsolate({
    required UserTargets targets,
    required List<Recipe> recipes,
    required List<Ingredient> ingredients,
    List<PantryItem> pantryItems = const [],
  }) async {
    final receivePort = ReceivePort();
    
    try {
      await Isolate.spawn(
        _isolatePlanGeneration,
        {
          'sendPort': receivePort.sendPort,
          'targets': targets,
          'recipes': recipes,
          'ingredients': ingredients,
          'pantryItems': pantryItems,
        },
      );

      final result = await receivePort.first;
      return result as Plan?;
    } catch (e) {
      // Fallback to main thread if isolate fails
      return null;
    } finally {
      receivePort.close();
    }
  }

  /// Track performance metrics
  void trackPerformance(String operation, int durationMs) {
    _performanceMetrics.putIfAbsent(operation, () => []).add(durationMs);
    
    // Keep only last 100 measurements to prevent memory bloat
    final metrics = _performanceMetrics[operation]!;
    if (metrics.length > 100) {
      metrics.removeRange(0, metrics.length - 100);
    }
  }

  /// Get performance statistics
  Map<String, Map<String, double>> getPerformanceStats() {
    final stats = <String, Map<String, double>>{};
    
    for (final entry in _performanceMetrics.entries) {
      final operation = entry.key;
      final measurements = entry.value;
      
      if (measurements.isEmpty) continue;
      
      final sum = measurements.reduce((a, b) => a + b);
      final avg = sum / measurements.length;
      final min = measurements.reduce((a, b) => a < b ? a : b);
      final max = measurements.reduce((a, b) => a > b ? a : b);
      
      // Calculate 95th percentile
      final sorted = List<int>.from(measurements)..sort();
      final p95Index = (sorted.length * 0.95).floor();
      final p95 = sorted[p95Index];
      
      stats[operation] = {
        'average': avg,
        'min': min.toDouble(),
        'max': max.toDouble(),
        'p95': p95.toDouble(),
        'count': measurements.length.toDouble(),
      };
    }
    
    return stats;
  }

  /// Clear performance caches
  void clearCaches() {
    _recipeFilterCache.clear();
    _ingredientCache.clear();
    _performanceMetrics.clear();
  }

  /// Check if plan generation meets performance requirements
  bool meetsPerformanceRequirements(int generationTimeMs) {
    return generationTimeMs <= 2000; // 2 second requirement from PRD
  }

  /// Get optimization recommendations based on performance
  List<String> getOptimizationRecommendations({
    required int generationTimeMs,
    required int recipeCount,
    required int ingredientCount,
  }) {
    final recommendations = <String>[];
    
    if (generationTimeMs > 2000) {
      recommendations.add('Plan generation exceeded 2s requirement');
      
      if (recipeCount > 100) {
        recommendations.add('Consider reducing recipe pool size for faster generation');
      }
      
      if (ingredientCount > 500) {
        recommendations.add('Consider implementing ingredient caching');
      }
    }
    
    if (generationTimeMs > 5000) {
      recommendations.add('Critical: Plan generation too slow, consider isolate-based generation');
    }
    
    final stats = getPerformanceStats();
    if (stats.containsKey('planGeneration')) {
      final planStats = stats['planGeneration']!;
      if (planStats['p95']! > 3000) {
        recommendations.add('95th percentile generation time exceeds acceptable limits');
      }
    }
    
    return recommendations;
  }

  /// Generate cache key for recipe filtering
  String _generateRecipeCacheKey(UserTargets targets) {
    return '${targets.planningMode.value}_${targets.dietFlags.join(',')}_${targets.timeCapMins}';
  }

  /// Sort recipes by mode-specific criteria
  void _sortRecipesByMode(List<Recipe> recipes, PlanningMode mode) {
    switch (mode) {
      case PlanningMode.cutting:
        recipes.sort((a, b) {
          final aScore = a.getProteinDensity() * (a.isHighVolume() ? 1.5 : 1.0);
          final bScore = b.getProteinDensity() * (b.isHighVolume() ? 1.5 : 1.0);
          return bScore.compareTo(aScore);
        });
        break;
        
      case PlanningMode.bulkingBudget:
        recipes.sort((a, b) => a.getCostEfficiency().compareTo(b.getCostEfficiency()));
        break;
        
      case PlanningMode.bulkingNoBudget:
        recipes.sort((a, b) {
          final aScore = a.macrosPerServ.kcal / (a.timeMins + 1);
          final bScore = b.macrosPerServ.kcal / (b.timeMins + 1);
          return bScore.compareTo(aScore);
        });
        break;
        
      case PlanningMode.maintenance:
        // No specific sorting for maintenance
        break;
    }
  }

  /// Isolate function for plan generation
  static void _isolatePlanGeneration(Map<String, dynamic> args) {
    // This is a simplified version - in a full implementation,
    // would recreate the plan generator and run generation
    // For now, just send null back
    final sendPort = args['sendPort'] as SendPort;
    sendPort.send(null);
  }
}

/// Performance monitoring mixin for plan generation classes
mixin PerformanceMonitoring {
  final PerformanceOptimizer _optimizer = PerformanceOptimizer();

  /// Measure execution time of an operation
  Future<T> measurePerformance<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await operation();
      return result;
    } finally {
      stopwatch.stop();
      _optimizer.trackPerformance(operationName, stopwatch.elapsedMilliseconds);
    }
  }

  /// Measure synchronous operation performance
  T measureSyncPerformance<T>(
    String operationName,
    T Function() operation,
  ) {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = operation();
      return result;
    } finally {
      stopwatch.stop();
      _optimizer.trackPerformance(operationName, stopwatch.elapsedMilliseconds);
    }
  }

  /// Get performance optimizer instance
  PerformanceOptimizer get performanceOptimizer => _optimizer;
}

/// Performance configuration for plan generation
class PerformanceConfig {
  const PerformanceConfig({
    this.maxRecipePoolSize = 50,
    this.maxGenerationTimeMs = 2000,
    this.enableCaching = true,
    this.enableIsolateGeneration = false,
    this.maxIterationsPerSecond = 100,
  });

  /// Maximum number of recipes to consider for optimization
  final int maxRecipePoolSize;
  
  /// Maximum time allowed for plan generation
  final int maxGenerationTimeMs;
  
  /// Whether to enable recipe and ingredient caching
  final bool enableCaching;
  
  /// Whether to use isolate-based generation for heavy operations
  final bool enableIsolateGeneration;
  
  /// Maximum optimization iterations per second
  final int maxIterationsPerSecond;

  /// Create performance config for different modes
  factory PerformanceConfig.forMode(PlanningMode mode) {
    switch (mode) {
      case PlanningMode.cutting:
        return const PerformanceConfig(
          maxRecipePoolSize: 40, // Smaller pool for faster filtering
          maxGenerationTimeMs: 1800,
        );
      case PlanningMode.bulkingBudget:
        return const PerformanceConfig(
          maxRecipePoolSize: 60, // Larger pool for cost optimization
          maxGenerationTimeMs: 2200,
        );
      case PlanningMode.bulkingNoBudget:
        return const PerformanceConfig(
          maxRecipePoolSize: 30, // Smallest pool for speed
          maxGenerationTimeMs: 1500,
        );
      case PlanningMode.maintenance:
        return const PerformanceConfig(); // Default config
    }
  }
}
