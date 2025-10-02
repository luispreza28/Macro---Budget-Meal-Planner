import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// Application logger with different log levels and contexts
class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;
  AppLogger._internal();

  /// Log levels
  static const int _verbose = 0;
  static const int _debug = 1;
  static const int _info = 2;
  static const int _warning = 3;
  static const int _error = 4;
  static const int _wtf = 5; // What a Terrible Failure

  /// Current log level (only logs at this level or higher will be shown)
  static int _logLevel = kDebugMode ? _verbose : _info;

  /// Set the minimum log level
  static void setLogLevel(LogLevel level) {
    switch (level) {
      case LogLevel.verbose:
        _logLevel = _verbose;
        break;
      case LogLevel.debug:
        _logLevel = _debug;
        break;
      case LogLevel.info:
        _logLevel = _info;
        break;
      case LogLevel.warning:
        _logLevel = _warning;
        break;
      case LogLevel.error:
        _logLevel = _error;
        break;
      case LogLevel.wtf:
        _logLevel = _wtf;
        break;
    }
  }

  /// Log verbose message (most detailed)
  static void v(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(_verbose, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// Log debug message
  static void d(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(_debug, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// Log info message
  static void i(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(_info, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// Log warning message
  static void w(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(_warning, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// Log error message
  static void e(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(_error, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// Log What a Terrible Failure (critical error)
  static void wtf(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(_wtf, message, tag: tag, error: error, stackTrace: stackTrace);
  }


  static void info(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    i(message, tag: tag, error: error, stackTrace: stackTrace);
  }

  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    e(message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// Internal logging method
  static void _log(
    int level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (level < _logLevel) return;

    final levelName = _getLevelName(level);
    final timestamp = DateTime.now().toIso8601String();
    final tagStr = tag != null ? '[$tag] ' : '';
    final fullMessage = '$timestamp $levelName: $tagStr$message';

    // Use developer.log for better debugging in IDEs
    developer.log(
      fullMessage,
      name: 'MacroBudgetMealPlanner',
      level: level,
      error: error,
      stackTrace: stackTrace,
    );

    // Also print to debug console for visibility
    debugPrint(fullMessage);
    if (error != null) {
      debugPrint('Error: $error');
    }
    if (stackTrace != null) {
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Get level name for logging
  static String _getLevelName(int level) {
    switch (level) {
      case _verbose:
        return 'V';
      case _debug:
        return 'D';
      case _info:
        return 'I';
      case _warning:
        return 'W';
      case _error:
        return 'E';
      case _wtf:
        return 'WTF';
      default:
        return 'UNKNOWN';
    }
  }

  /// Log performance timing
  static void timing(String operation, Duration duration, {String? tag}) {
    final message = 'Performance: $operation took ${duration.inMilliseconds}ms';
    d(message, tag: tag ?? 'Performance');
  }

  /// Log app lifecycle events
  static void lifecycle(String event, {Map<String, dynamic>? data}) {
    final dataStr = data != null ? ' - Data: $data' : '';
    i('Lifecycle: $event$dataStr', tag: 'Lifecycle');
  }

  /// Log user actions for analytics
  static void userAction(String action, {Map<String, dynamic>? parameters}) {
    final paramStr = parameters != null ? ' - Params: $parameters' : '';
    i('User Action: $action$paramStr', tag: 'UserAction');
  }

  /// Log database operations
  static void database(String operation, {String? table, Duration? duration}) {
    final tableStr = table != null ? ' on $table' : '';
    final durationStr = duration != null ? ' (${duration.inMilliseconds}ms)' : '';
    d('Database: $operation$tableStr$durationStr', tag: 'Database');
  }

  /// Log network operations
  static void network(String operation, {String? url, int? statusCode, Duration? duration}) {
    final urlStr = url != null ? ' - URL: $url' : '';
    final statusStr = statusCode != null ? ' - Status: $statusCode' : '';
    final durationStr = duration != null ? ' - Duration: ${duration.inMilliseconds}ms' : '';
    d('Network: $operation$urlStr$statusStr$durationStr', tag: 'Network');
  }

  /// Log planning operations
  static void planning(String operation, {Map<String, dynamic>? metrics}) {
    final metricsStr = metrics != null ? ' - Metrics: $metrics' : '';
    i('Planning: $operation$metricsStr', tag: 'Planning');
  }

  /// Log billing operations
  static void billing(String operation, {String? productId, String? result}) {
    final productStr = productId != null ? ' - Product: $productId' : '';
    final resultStr = result != null ? ' - Result: $result' : '';
    i('Billing: $operation$productStr$resultStr', tag: 'Billing');
  }
}

/// Log levels enum for easier configuration
enum LogLevel {
  verbose,
  debug,
  info,
  warning,
  error,
  wtf,
}

/// Extension for easier logging in classes
extension LoggerExtension on Object {
  String get _className => runtimeType.toString();

  void logV(String message, {Object? error, StackTrace? stackTrace}) {
    AppLogger.v(message, tag: _className, error: error, stackTrace: stackTrace);
  }

  void logD(String message, {Object? error, StackTrace? stackTrace}) {
    AppLogger.d(message, tag: _className, error: error, stackTrace: stackTrace);
  }

  void logI(String message, {Object? error, StackTrace? stackTrace}) {
    AppLogger.i(message, tag: _className, error: error, stackTrace: stackTrace);
  }

  void logW(String message, {Object? error, StackTrace? stackTrace}) {
    AppLogger.w(message, tag: _className, error: error, stackTrace: stackTrace);
  }

  void logE(String message, {Object? error, StackTrace? stackTrace}) {
    AppLogger.e(message, tag: _className, error: error, stackTrace: stackTrace);
  }

  void logWtf(String message, {Object? error, StackTrace? stackTrace}) {
    AppLogger.wtf(message, tag: _className, error: error, stackTrace: stackTrace);
  }
}
