import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import 'local_storage_service.dart';
import '../../core/utils/logger.dart';

/// Privacy-respecting crash reporting service
/// 
/// This service follows privacy-first principles:
/// - Opt-in only (user must explicitly enable)
/// - Local storage of crash reports
/// - No automatic external transmission
/// - User can review and delete crash reports
/// - Anonymized device information only
class CrashReportingService {
  CrashReportingService(this._localStorage);

  final LocalStorageService _localStorage;
  
  static const String _crashReportsKey = 'crash_reports';
  static const int _maxCrashReports = 50;

  /// Check if crash reporting is enabled by user
  bool get isEnabled => _localStorage.getCrashReportingEnabled();

  /// Enable crash reporting (user opt-in)
  Future<void> enableCrashReporting() async {
    await _localStorage.setCrashReportingEnabled(true);
    AppLogger.info('Crash reporting enabled');
    
    // Set up Flutter error handlers
    _setupErrorHandlers();
  }

  /// Disable crash reporting (user opt-out)
  Future<void> disableCrashReporting() async {
    await _localStorage.setCrashReportingEnabled(false);
    await clearCrashReports();
    AppLogger.info('Crash reporting disabled');
    
    // Remove error handlers
    _removeErrorHandlers();
  }

  /// Set up Flutter error handlers
  void _setupErrorHandlers() {
    if (!isEnabled) return;

    // Handle Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      _recordFlutterError(details);
      
      // Also log to console in debug mode
      if (kDebugMode) {
        FlutterError.presentError(details);
      }
    };

    // Handle platform errors (outside Flutter)
    PlatformDispatcher.instance.onError = (error, stack) {
      _recordPlatformError(error, stack);
      return true;
    };
  }

  /// Remove error handlers
  void _removeErrorHandlers() {
    // Reset to default Flutter error handler
    FlutterError.onError = FlutterError.presentError;
    PlatformDispatcher.instance.onError = null;
  }

  /// Record a Flutter framework error
  void _recordFlutterError(FlutterErrorDetails details) {
    if (!isEnabled) return;

    final crashReport = {
      'type': 'flutter_error',
      'timestamp': DateTime.now().toIso8601String(),
      'error': details.exception.toString(),
      'stack_trace': details.stack?.toString(),
      'library': details.library,
      'context': details.context?.toString(),
      'information_collector': details.informationCollector?.call().join('\n'),
      'silent': details.silent,
      'device_info': _getAnonymizedDeviceInfo(),
      'app_info': _getAppInfo(),
    };

    _saveCrashReport(crashReport);
  }

  /// Record a platform error
  void _recordPlatformError(Object error, StackTrace? stack) {
    if (!isEnabled) return;

    final crashReport = {
      'type': 'platform_error',
      'timestamp': DateTime.now().toIso8601String(),
      'error': error.toString(),
      'stack_trace': stack?.toString(),
      'device_info': _getAnonymizedDeviceInfo(),
      'app_info': _getAppInfo(),
    };

    _saveCrashReport(crashReport);
  }

  /// Record a custom error
  Future<void> recordError({
    required Object error,
    StackTrace? stackTrace,
    String? context,
    Map<String, dynamic>? additionalData,
    bool fatal = false,
  }) async {
    if (!isEnabled) return;

    final crashReport = {
      'type': 'custom_error',
      'timestamp': DateTime.now().toIso8601String(),
      'error': error.toString(),
      'stack_trace': stackTrace?.toString(),
      'context': context,
      'additional_data': additionalData ?? {},
      'fatal': fatal,
      'device_info': _getAnonymizedDeviceInfo(),
      'app_info': _getAppInfo(),
    };

    _saveCrashReport(crashReport);
  }

  /// Record a performance issue
  Future<void> recordPerformanceIssue({
    required String operation,
    required Duration duration,
    String? context,
    Map<String, dynamic>? additionalData,
  }) async {
    if (!isEnabled) return;

    final performanceReport = {
      'type': 'performance_issue',
      'timestamp': DateTime.now().toIso8601String(),
      'operation': operation,
      'duration_ms': duration.inMilliseconds,
      'context': context,
      'additional_data': additionalData ?? {},
      'device_info': _getAnonymizedDeviceInfo(),
      'app_info': _getAppInfo(),
    };

    _saveCrashReport(performanceReport);
  }

  /// Save crash report to local storage
  void _saveCrashReport(Map<String, dynamic> crashReport) {
    try {
      final existingReports = _localStorage.getJsonData(_crashReportsKey) ?? {};
      final reports = List<Map<String, dynamic>>.from(existingReports['reports'] ?? []);

      reports.add(crashReport);

      // Keep only the most recent crash reports
      if (reports.length > _maxCrashReports) {
        reports.removeRange(0, reports.length - _maxCrashReports);
      }

      _localStorage.setJsonData(_crashReportsKey, {
        'reports': reports,
        'last_updated': DateTime.now().toIso8601String(),
        'total_reports': reports.length,
      });

      AppLogger.error('Crash report saved: ${crashReport['type']}');
    } catch (e) {
      // Avoid infinite recursion by not using crash reporting here
      AppLogger.error('Failed to save crash report: $e');
    }
  }

  /// Get anonymized device information
  Map<String, dynamic> _getAnonymizedDeviceInfo() {
    return {
      'platform': Platform.operatingSystem,
      'platform_version': Platform.operatingSystemVersion,
      'dart_version': Platform.version,
      'is_debug': kDebugMode,
      'is_profile': kProfileMode,
      'is_release': kReleaseMode,
      // Note: No device identifiers or user-specific info
    };
  }

  /// Get app information
  Map<String, dynamic> _getAppInfo() {
    return {
      'app_name': 'Macro + Budget Meal Planner',
      'app_version': '1.0.0', // This would come from package_info in production
      'build_number': '1',
      'flutter_version': 'Flutter 3.16+', // This would be dynamic in production
    };
  }

  /// Get all crash reports for user review
  List<Map<String, dynamic>> getCrashReports() {
    if (!isEnabled) return [];

    final crashData = _localStorage.getJsonData(_crashReportsKey);
    if (crashData == null) return [];

    return List<Map<String, dynamic>>.from(crashData['reports'] ?? []);
  }

  /// Get crash report summary
  Map<String, dynamic> getCrashReportSummary() {
    if (!isEnabled) return {};

    final crashData = _localStorage.getJsonData(_crashReportsKey);
    if (crashData == null) return {};

    final reports = List<Map<String, dynamic>>.from(crashData['reports'] ?? []);
    
    // Aggregate by type
    final reportsByType = <String, int>{};
    final reportsByDay = <String, int>{};
    
    for (final report in reports) {
      final type = report['type'] as String;
      final timestamp = DateTime.tryParse(report['timestamp'] as String? ?? '');
      
      reportsByType[type] = (reportsByType[type] ?? 0) + 1;
      
      if (timestamp != null) {
        final day = timestamp.toString().substring(0, 10);
        reportsByDay[day] = (reportsByDay[day] ?? 0) + 1;
      }
    }

    return {
      'total_reports': reports.length,
      'reports_by_type': reportsByType,
      'reports_by_day': reportsByDay,
      'last_updated': crashData['last_updated'],
    };
  }

  /// Clear all crash reports
  Future<void> clearCrashReports() async {
    await _localStorage.setJsonData(_crashReportsKey, {});
    AppLogger.info('Crash reports cleared');
  }

  /// Export crash reports for user review or support
  String exportCrashReports() {
    final reports = getCrashReports();
    if (reports.isEmpty) return 'No crash reports found.';

    final exportData = {
      'export_timestamp': DateTime.now().toIso8601String(),
      'total_reports': reports.length,
      'reports': reports,
    };

    return const JsonEncoder.withIndent('  ').convert(exportData);
  }

  /// Save crash reports to file for sharing with support
  Future<File?> saveCrashReportsToFile() async {
    try {
      final reports = getCrashReports();
      if (reports.isEmpty) return null;

      final directory = await getApplicationDocumentsDirectory();
      final file = File(path.join(directory.path, 'crash_reports.json'));
      
      final exportData = exportCrashReports();
      await file.writeAsString(exportData);
      
      AppLogger.info('Crash reports saved to: ${file.path}');
      return file;
    } catch (e) {
      AppLogger.error('Failed to save crash reports to file: $e');
      return null;
    }
  }

  /// Get data size in bytes (for user information)
  int getDataSize() {
    final crashData = _localStorage.getJsonData(_crashReportsKey);
    if (crashData == null) return 0;

    final jsonString = jsonEncode(crashData);
    return utf8.encode(jsonString).length;
  }

  /// Initialize crash reporting if enabled
  Future<void> initialize() async {
    if (isEnabled) {
      _setupErrorHandlers();
      AppLogger.info('Crash reporting initialized');
    }
  }

  /// Record app lifecycle events
  void recordAppLifecycleEvent(String event) {
    if (!isEnabled) return;

    final lifecycleReport = {
      'type': 'lifecycle_event',
      'timestamp': DateTime.now().toIso8601String(),
      'event': event,
      'device_info': _getAnonymizedDeviceInfo(),
      'app_info': _getAppInfo(),
    };

    _saveCrashReport(lifecycleReport);
  }

  /// Test crash reporting (for debugging)
  void testCrashReporting() {
    if (!isEnabled || !kDebugMode) return;

    recordError(
      error: Exception('Test crash report'),
      context: 'Testing crash reporting functionality',
      additionalData: {'test': true},
      fatal: false,
    );

    AppLogger.info('Test crash report generated');
  }
}
