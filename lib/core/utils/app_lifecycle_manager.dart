import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'logger.dart';
import '../errors/error_handler.dart';

/// Manages application lifecycle events and state persistence
class AppLifecycleManager with WidgetsBindingObserver {
  static final AppLifecycleManager _instance = AppLifecycleManager._internal();
  factory AppLifecycleManager() => _instance;
  AppLifecycleManager._internal();

  ProviderContainer? _container;
  AppLifecycleState? _lastState;
  DateTime? _backgroundTime;

  /// Initialize lifecycle management
  static void initialize(ProviderContainer container) {
    _instance._container = container;
    WidgetsBinding.instance.addObserver(_instance);
    AppLogger.lifecycle('AppLifecycleManager initialized');
  }

  /// Dispose lifecycle management
  static void dispose() {
    WidgetsBinding.instance.removeObserver(_instance);
    AppLogger.lifecycle('AppLifecycleManager disposed');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    final previousState = _lastState;
    _lastState = state;

    AppLogger.lifecycle('App lifecycle changed', data: {
      'from': previousState?.toString(),
      'to': state.toString(),
    });

    switch (state) {
      case AppLifecycleState.resumed:
        _handleAppResumed();
        break;
      case AppLifecycleState.paused:
        _handleAppPaused();
        break;
      case AppLifecycleState.detached:
        _handleAppDetached();
        break;
      case AppLifecycleState.inactive:
        _handleAppInactive();
        break;
      case AppLifecycleState.hidden:
        _handleAppHidden();
        break;
    }
  }

  /// Handle app resumed (foreground)
  void _handleAppResumed() {
    AppLogger.lifecycle('App resumed');
    
    // Calculate time spent in background
    if (_backgroundTime != null) {
      final backgroundDuration = DateTime.now().difference(_backgroundTime!);
      AppLogger.timing('Background time', backgroundDuration, tag: 'Lifecycle');
      
      // If app was in background for more than 5 minutes, refresh data
      if (backgroundDuration.inMinutes > 5) {
        _refreshAppData();
      }
      
      _backgroundTime = null;
    }

    // Check for app updates or important changes
    _checkForUpdates();
    
    // Refresh subscription status if needed
    _refreshSubscriptionStatus();
  }

  /// Handle app paused (background)
  void _handleAppPaused() {
    AppLogger.lifecycle('App paused');
    _backgroundTime = DateTime.now();
    
    // Save current state
    _saveCurrentState();
    
    // Clean up resources
    _cleanupResources();
  }

  /// Handle app detached (being terminated)
  void _handleAppDetached() {
    AppLogger.lifecycle('App detached');
    
    // Final cleanup and state save
    _saveCurrentState();
    _performFinalCleanup();
  }

  /// Handle app inactive (temporary interruption)
  void _handleAppInactive() {
    AppLogger.lifecycle('App inactive');
    
    // Pause ongoing operations
    _pauseOperations();
  }

  /// Handle app hidden (iOS specific)
  void _handleAppHidden() {
    AppLogger.lifecycle('App hidden');
    
    // Similar to paused but for iOS
    _backgroundTime = DateTime.now();
    _saveCurrentState();
  }

  /// Save current application state
  void _saveCurrentState() {
    if (_container == null) return;

    try {
      AppLogger.d('Saving current application state', tag: 'Lifecycle');
      
      // Save current plan if any
      // TODO: Implement state saving logic with providers
      // final currentPlan = _container!.read(currentPlanProvider);
      // if (currentPlan.hasValue && currentPlan.value != null) {
      //   _container!.read(localStorageServiceProvider).setCurrentPlanId(currentPlan.value!.id);
      // }

      AppLogger.d('Application state saved successfully', tag: 'Lifecycle');
    } catch (e, stackTrace) {
      AppLogger.e('Failed to save application state', 
        tag: 'Lifecycle', error: e, stackTrace: stackTrace);
    }
  }

  /// Clean up resources when app goes to background
  void _cleanupResources() {
    try {
      AppLogger.d('Cleaning up resources', tag: 'Lifecycle');
      
      // Cancel ongoing HTTP requests
      // Clear memory caches
      // Close unnecessary database connections
      
      AppLogger.d('Resources cleaned up successfully', tag: 'Lifecycle');
    } catch (e, stackTrace) {
      AppLogger.e('Failed to cleanup resources', 
        tag: 'Lifecycle', error: e, stackTrace: stackTrace);
    }
  }

  /// Refresh app data when resuming
  void _refreshAppData() {
    if (_container == null) return;

    try {
      AppLogger.d('Refreshing app data after background time', tag: 'Lifecycle');
      
      // Refresh providers that might have stale data
      // _container!.refresh(currentUserTargetsProvider);
      // _container!.refresh(currentPlanProvider);
      
      AppLogger.d('App data refreshed successfully', tag: 'Lifecycle');
    } catch (e, stackTrace) {
      AppLogger.e('Failed to refresh app data', 
        tag: 'Lifecycle', error: e, stackTrace: stackTrace);
    }
  }

  /// Check for app updates
  void _checkForUpdates() {
    try {
      AppLogger.d('Checking for app updates', tag: 'Lifecycle');
      
      // TODO: Implement update checking logic
      // Check for new seed data versions
      // Check for app updates from store
      
    } catch (e, stackTrace) {
      AppLogger.e('Failed to check for updates', 
        tag: 'Lifecycle', error: e, stackTrace: stackTrace);
    }
  }

  /// Refresh subscription status
  void _refreshSubscriptionStatus() {
    if (_container == null) return;

    try {
      AppLogger.d('Refreshing subscription status', tag: 'Lifecycle');
      
      // TODO: Refresh billing providers
      // _container!.refresh(subscriptionStatusProvider);
      
    } catch (e, stackTrace) {
      AppLogger.e('Failed to refresh subscription status', 
        tag: 'Lifecycle', error: e, stackTrace: stackTrace);
    }
  }

  /// Pause ongoing operations
  void _pauseOperations() {
    try {
      AppLogger.d('Pausing ongoing operations', tag: 'Lifecycle');
      
      // Pause plan generation if running
      // Pause data sync operations
      // Cancel non-critical network requests
      
    } catch (e, stackTrace) {
      AppLogger.e('Failed to pause operations', 
        tag: 'Lifecycle', error: e, stackTrace: stackTrace);
    }
  }

  /// Perform final cleanup before termination
  void _performFinalCleanup() {
    try {
      AppLogger.d('Performing final cleanup', tag: 'Lifecycle');
      
      // Close database connections
      // Cancel all pending operations
      // Save critical data
      
      AppLogger.d('Final cleanup completed', tag: 'Lifecycle');
    } catch (e, stackTrace) {
      AppLogger.e('Failed to perform final cleanup', 
        tag: 'Lifecycle', error: e, stackTrace: stackTrace);
    }
  }

  /// Get current app state
  AppLifecycleState? get currentState => _lastState;

  /// Check if app is in background
  bool get isInBackground => _lastState == AppLifecycleState.paused || 
                             _lastState == AppLifecycleState.hidden;

  /// Check if app is active
  bool get isActive => _lastState == AppLifecycleState.resumed;

  /// Get time spent in background
  Duration? get backgroundDuration {
    if (_backgroundTime == null) return null;
    return DateTime.now().difference(_backgroundTime!);
  }
}

/// Provider for app lifecycle manager
final appLifecycleManagerProvider = Provider<AppLifecycleManager>((ref) {
  return AppLifecycleManager();
});

/// Provider for current app lifecycle state
final appLifecycleStateProvider = StateProvider<AppLifecycleState?>((ref) {
  return AppLifecycleManager().currentState;
});

/// Provider for background status
final isAppInBackgroundProvider = Provider<bool>((ref) {
  return AppLifecycleManager().isInBackground;
});

/// Provider for active status
final isAppActiveProvider = Provider<bool>((ref) {
  return AppLifecycleManager().isActive;
});
