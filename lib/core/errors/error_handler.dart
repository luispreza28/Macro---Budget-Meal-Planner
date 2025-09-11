import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sqlite3/sqlite3.dart';

import 'failures.dart';
import 'validation_exceptions.dart';

/// Global error handler for the application
class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  /// Initialize error handling
  static void initialize() {
    // Catch Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      _instance._handleFlutterError(details);
    };

    // Catch async errors outside Flutter
    PlatformDispatcher.instance.onError = (error, stack) {
      _instance._handlePlatformError(error, stack);
      return true;
    };
  }

  /// Handle Flutter framework errors
  void _handleFlutterError(FlutterErrorDetails details) {
    // Log error details
    debugPrint('Flutter Error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');

    // Report to crash analytics if enabled
    _reportError(details.exception, details.stack, 'flutter_error');

    // In debug mode, show the error
    if (kDebugMode) {
      FlutterError.presentError(details);
    }
  }

  /// Handle platform errors (async errors outside Flutter)
  void _handlePlatformError(Object error, StackTrace stack) {
    debugPrint('Platform Error: $error');
    debugPrint('Stack trace: $stack');

    // Report to crash analytics if enabled
    _reportError(error, stack, 'platform_error');
  }

  /// Handle repository and service errors
  static Future<T> handleAsync<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on SqliteException catch (e) {
      throw DatabaseFailure(message: 'Database error: ${e.message}');
    } on ValidationException catch (e) {
      throw ValidationFailure(message: e.message);
    } on PlatformException catch (e) {
      throw _mapPlatformException(e);
    } on TimeoutException catch (e) {
      throw NetworkFailure(message: 'Operation timed out: ${e.message}');
    } catch (e) {
      // Log unexpected errors
      debugPrint('Unexpected error: $e');
      _instance._reportError(e, StackTrace.current, 'unexpected_error');
      rethrow;
    }
  }

  /// Handle synchronous operations with error mapping
  static T handleSync<T>(T Function() operation) {
    try {
      return operation();
    } on ValidationException catch (e) {
      throw ValidationFailure(message: e.message);
    } on ArgumentError catch (e) {
      throw ValidationFailure(message: 'Invalid argument: ${e.message}');
    } on StateError catch (e) {
      throw ValidationFailure(message: 'Invalid state: ${e.message}');
    } catch (e) {
      // Log unexpected errors
      debugPrint('Unexpected sync error: $e');
      _instance._reportError(e, StackTrace.current, 'unexpected_sync_error');
      rethrow;
    }
  }

  /// Map PlatformException to appropriate Failure
  static Failure _mapPlatformException(PlatformException e) {
    switch (e.code) {
      case 'permission_denied':
        return PermissionFailure(message: 'Permission denied: ${e.message}');
      case 'network_error':
        return NetworkFailure(message: 'Network error: ${e.message}');
      case 'billing_unavailable':
      case 'billing_error':
        return BillingFailure(message: 'Billing error: ${e.message}');
      default:
        return ValidationFailure(message: 'Platform error: ${e.message ?? e.code}');
    }
  }

  /// Report error to analytics/crash reporting service
  void _reportError(Object error, StackTrace? stack, String context) {
    // TODO: Integrate with crash reporting service (Firebase Crashlytics, Sentry, etc.)
    // For now, just log to debug console
    debugPrint('Error Report:');
    debugPrint('Context: $context');
    debugPrint('Error: $error');
    debugPrint('Stack: $stack');
    
    // In production, this would send to crash reporting service
    // Example:
    // FirebaseCrashlytics.instance.recordError(error, stack, context: context);
  }

  /// Get user-friendly error message from Failure
  static String getDisplayMessage(Failure failure) {
    switch (failure.runtimeType) {
      case DatabaseFailure:
        return 'Unable to access data. Please try again.';
      case NetworkFailure:
        return 'Network connection error. Please check your internet connection.';
      case ValidationFailure:
        return failure.message; // Validation messages are user-friendly
      case BillingFailure:
        return 'Payment processing error. Please try again later.';
      case PermissionFailure:
        return 'Permission required. Please grant the necessary permissions.';
      case CacheFailure:
        return 'Unable to save data. Please try again.';
      case PlanningFailure:
        return 'Unable to generate meal plan. Please check your settings and try again.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  /// Check if error is recoverable
  static bool isRecoverable(Object error) {
    if (error is Failure) {
      return error is! DatabaseFailure && error is! PermissionFailure;
    }
    return false;
  }

  /// Get error severity level
  static ErrorSeverity getSeverity(Object error) {
    if (error is Failure) {
      switch (error.runtimeType) {
        case ValidationFailure:
          return ErrorSeverity.warning;
        case NetworkFailure:
        case CacheFailure:
          return ErrorSeverity.error;
        case DatabaseFailure:
        case BillingFailure:
        case PermissionFailure:
          return ErrorSeverity.critical;
        default:
          return ErrorSeverity.error;
      }
    }
    return ErrorSeverity.critical;
  }
}

/// Error severity levels
enum ErrorSeverity {
  info,
  warning,
  error,
  critical,
}

/// Extension for easier error handling in widgets
extension ErrorHandlerExtension on Object {
  String get displayMessage {
    if (this is Failure) {
      return ErrorHandler.getDisplayMessage(this as Failure);
    }
    return 'An unexpected error occurred';
  }

  bool get isRecoverable => ErrorHandler.isRecoverable(this);
  ErrorSeverity get severity => ErrorHandler.getSeverity(this);
}
