import 'dart:io';

import 'logger.dart';

/// Build optimization utilities for reducing app size and improving performance
class BuildOptimizer {
  /// Check current app size and compliance
  static Future<AppSizeReport> checkAppSize() async {
    try {
      AppLogger.d('Checking app size compliance', tag: 'BuildOptimizer');
      
      // In a real implementation, this would check the actual APK/AAB size
      // For now, we'll simulate the check
      final report = AppSizeReport(
        estimatedSizeMB: 35.0, // Simulated size
        targetSizeMB: 40.0,
        isCompliant: true,
        optimizationSuggestions: _getOptimizationSuggestions(),
      );
      
      AppLogger.i('App size check: ${report.estimatedSizeMB}MB / ${report.targetSizeMB}MB (${report.isCompliant ? 'COMPLIANT' : 'OVER LIMIT'})', 
        tag: 'BuildOptimizer');
      
      return report;
    } catch (e, stackTrace) {
      AppLogger.e('Failed to check app size', 
        tag: 'BuildOptimizer', error: e, stackTrace: stackTrace);
      
      return AppSizeReport(
        estimatedSizeMB: 0,
        targetSizeMB: 40.0,
        isCompliant: false,
        optimizationSuggestions: ['Error checking app size'],
      );
    }
  }

  /// Get optimization suggestions for reducing app size
  static List<String> _getOptimizationSuggestions() {
    return [
      'Enable R8/ProGuard obfuscation and minification',
      'Use app bundles instead of APK for dynamic delivery',
      'Optimize image assets with WebP format',
      'Remove unused resources with shrinkResources',
      'Use vector drawables instead of multiple PNG densities',
      'Minimize font files and use system fonts where possible',
      'Remove debug symbols from release builds',
      'Use split-per-abi for architecture-specific APKs',
      'Compress native libraries',
      'Remove unused code with tree shaking',
    ];
  }

  /// Generate build configuration for optimization
  static Map<String, dynamic> getOptimizedBuildConfig() {
    return {
      'android': {
        'buildTypes': {
          'release': {
            'minifyEnabled': true,
            'shrinkResources': true,
            'proguardFiles': [
              'proguard-android-optimize.txt',
              'proguard-rules.pro'
            ],
            'signingConfig': 'signingConfigs.release',
          }
        },
        'bundle': {
          'language': {
            'enableSplit': true
          },
          'density': {
            'enableSplit': true
          },
          'abi': {
            'enableSplit': true
          }
        }
      },
      'flutter': {
        'assets': {
          'optimization': {
            'compress': true,
            'format': 'webp'
          }
        },
        'fonts': {
          'subset': true,
          'compress': true
        }
      }
    };
  }

  /// Analyze asset usage and suggest optimizations
  static Future<AssetAnalysis> analyzeAssets() async {
    try {
      AppLogger.d('Analyzing assets for optimization', tag: 'BuildOptimizer');
      
      final assetDir = Directory('assets');
      if (!await assetDir.exists()) {
        return AssetAnalysis(
          totalAssets: 0,
          totalSizeMB: 0,
          suggestions: ['No assets directory found'],
        );
      }

      int totalAssets = 0;
      int totalSizeBytes = 0;
      final List<String> suggestions = [];
      final Map<String, int> assetsByType = {};

      await for (final entity in assetDir.list(recursive: true)) {
        if (entity is File) {
          totalAssets++;
          final stat = await entity.stat();
          totalSizeBytes += stat.size;
          
          final extension = entity.path.split('.').last.toLowerCase();
          assetsByType[extension] = (assetsByType[extension] ?? 0) + 1;
          
          // Check for optimization opportunities
          if (extension == 'png' || extension == 'jpg' || extension == 'jpeg') {
            suggestions.add('Consider converting ${entity.path} to WebP format');
          }
          
          if (stat.size > 1024 * 1024) { // > 1MB
            suggestions.add('Large asset detected: ${entity.path} (${(stat.size / (1024 * 1024)).toStringAsFixed(1)}MB)');
          }
        }
      }

      final totalSizeMB = totalSizeBytes / (1024 * 1024);
      
      // Add general suggestions
      if (assetsByType.containsKey('png') || assetsByType.containsKey('jpg')) {
        suggestions.add('Use WebP format for better compression');
      }
      
      if (totalSizeMB > 10) {
        suggestions.add('Consider using asset delivery for large assets');
      }

      AppLogger.d('Asset analysis: $totalAssets assets, ${totalSizeMB.toStringAsFixed(1)}MB total', 
        tag: 'BuildOptimizer');

      return AssetAnalysis(
        totalAssets: totalAssets,
        totalSizeMB: totalSizeMB,
        suggestions: suggestions,
        assetsByType: assetsByType,
      );
    } catch (e, stackTrace) {
      AppLogger.e('Failed to analyze assets', 
        tag: 'BuildOptimizer', error: e, stackTrace: stackTrace);
      
      return AssetAnalysis(
        totalAssets: 0,
        totalSizeMB: 0,
        suggestions: ['Error analyzing assets: $e'],
      );
    }
  }

  /// Check for unused dependencies
  static Future<DependencyAnalysis> analyzeDependencies() async {
    try {
      AppLogger.d('Analyzing dependencies', tag: 'BuildOptimizer');
      
      final pubspecFile = File('pubspec.yaml');
      if (!await pubspecFile.exists()) {
        return DependencyAnalysis(
          totalDependencies: 0,
          suggestions: ['pubspec.yaml not found'],
        );
      }

      final pubspecContent = await pubspecFile.readAsString();
      final dependencies = <String>[];
      final suggestions = <String>[];

      // Simple parsing - in production, use yaml package
      final lines = pubspecContent.split('\n');
      bool inDependencies = false;
      
      for (final line in lines) {
        if (line.trim() == 'dependencies:') {
          inDependencies = true;
          continue;
        }
        
        if (inDependencies && line.trim().isEmpty) {
          inDependencies = false;
          continue;
        }
        
        if (inDependencies && line.startsWith('  ') && line.contains(':')) {
          final dep = line.trim().split(':').first;
          dependencies.add(dep);
        }
      }

      // Check for potentially heavy dependencies
      final heavyDeps = [
        'camera',
        'video_player',
        'webview_flutter',
        'google_maps_flutter',
        'firebase_core',
      ];

      for (final dep in dependencies) {
        if (heavyDeps.contains(dep)) {
          suggestions.add('Heavy dependency detected: $dep - ensure it\'s necessary');
        }
      }

      // General suggestions
      suggestions.add('Regularly audit dependencies for unused packages');
      suggestions.add('Use lightweight alternatives where possible');
      suggestions.add('Consider lazy loading for optional features');

      AppLogger.d('Dependency analysis: ${dependencies.length} dependencies', 
        tag: 'BuildOptimizer');

      return DependencyAnalysis(
        totalDependencies: dependencies.length,
        dependencies: dependencies,
        suggestions: suggestions,
      );
    } catch (e, stackTrace) {
      AppLogger.e('Failed to analyze dependencies', 
        tag: 'BuildOptimizer', error: e, stackTrace: stackTrace);
      
      return DependencyAnalysis(
        totalDependencies: 0,
        suggestions: ['Error analyzing dependencies: $e'],
      );
    }
  }

  /// Generate optimization report
  static Future<OptimizationReport> generateOptimizationReport() async {
    AppLogger.i('Generating optimization report', tag: 'BuildOptimizer');
    
    final appSize = await checkAppSize();
    final assets = await analyzeAssets();
    final dependencies = await analyzeDependencies();
    
    final report = OptimizationReport(
      appSize: appSize,
      assets: assets,
      dependencies: dependencies,
      timestamp: DateTime.now(),
    );
    
    AppLogger.i('Optimization report generated', tag: 'BuildOptimizer');
    return report;
  }

  /// Get build optimization recommendations
  static List<String> getBuildOptimizationRecommendations() {
    return [
      // Build configuration
      'Enable R8 code shrinking and obfuscation',
      'Use --split-per-abi for smaller APKs',
      'Enable resource shrinking with shrinkResources',
      'Use Android App Bundle format',
      
      // Asset optimization
      'Convert PNG/JPEG images to WebP',
      'Use vector drawables for icons',
      'Optimize image sizes for different densities',
      'Remove unused assets',
      
      // Code optimization
      'Remove unused imports and code',
      'Use const constructors where possible',
      'Minimize package dependencies',
      'Use tree shaking for unused code removal',
      
      // Performance
      'Enable AOT compilation',
      'Use profile builds for testing',
      'Optimize widget rebuilds',
      'Implement lazy loading for heavy features',
    ];
  }
}

/// App size report data class
class AppSizeReport {
  final double estimatedSizeMB;
  final double targetSizeMB;
  final bool isCompliant;
  final List<String> optimizationSuggestions;

  const AppSizeReport({
    required this.estimatedSizeMB,
    required this.targetSizeMB,
    required this.isCompliant,
    required this.optimizationSuggestions,
  });

  double get compliancePercentage => (estimatedSizeMB / targetSizeMB) * 100;
  double get remainingSpaceMB => targetSizeMB - estimatedSizeMB;
}

/// Asset analysis data class
class AssetAnalysis {
  final int totalAssets;
  final double totalSizeMB;
  final List<String> suggestions;
  final Map<String, int> assetsByType;

  const AssetAnalysis({
    required this.totalAssets,
    required this.totalSizeMB,
    required this.suggestions,
    this.assetsByType = const {},
  });
}

/// Dependency analysis data class
class DependencyAnalysis {
  final int totalDependencies;
  final List<String> dependencies;
  final List<String> suggestions;

  const DependencyAnalysis({
    required this.totalDependencies,
    this.dependencies = const [],
    required this.suggestions,
  });
}

/// Complete optimization report
class OptimizationReport {
  final AppSizeReport appSize;
  final AssetAnalysis assets;
  final DependencyAnalysis dependencies;
  final DateTime timestamp;

  const OptimizationReport({
    required this.appSize,
    required this.assets,
    required this.dependencies,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'app_size': {
        'estimated_size_mb': appSize.estimatedSizeMB,
        'target_size_mb': appSize.targetSizeMB,
        'is_compliant': appSize.isCompliant,
        'compliance_percentage': appSize.compliancePercentage,
        'remaining_space_mb': appSize.remainingSpaceMB,
        'suggestions': appSize.optimizationSuggestions,
      },
      'assets': {
        'total_assets': assets.totalAssets,
        'total_size_mb': assets.totalSizeMB,
        'assets_by_type': assets.assetsByType,
        'suggestions': assets.suggestions,
      },
      'dependencies': {
        'total_dependencies': dependencies.totalDependencies,
        'dependencies': dependencies.dependencies,
        'suggestions': dependencies.suggestions,
      },
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
