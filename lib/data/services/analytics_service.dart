import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';

import 'local_storage_service.dart';

/// Privacy-respecting analytics service for tracking user interactions
/// 
/// This service follows privacy-first principles:
/// - Opt-in only (user must explicitly enable)
/// - No PII (personally identifiable information)
/// - Local storage only (no external services)
/// - Aggregated data only
/// - User can clear data at any time
class AnalyticsService {
  AnalyticsService(this._localStorage);

  final LocalStorageService _localStorage;
  
  static const String _analyticsDataKey = 'analytics_data';
  static const String _sessionIdKey = 'session_id';

  /// Check if analytics is enabled by user
  bool get isEnabled => _localStorage.getAnalyticsEnabled();

  /// Generate a new session ID
  String _generateSessionId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomValue = random.nextInt(10000);
    return '${timestamp}_$randomValue';
  }

  /// Get current session ID, generating one if needed
  String _getSessionId() {
    final existingId = _localStorage.getJsonData(_sessionIdKey)?['id'] as String?;
    final timestamp = _localStorage.getJsonData(_sessionIdKey)?['timestamp'] as int?;
    
    // Generate new session if none exists or if last session was more than 30 minutes ago
    if (existingId == null || timestamp == null || 
        DateTime.now().millisecondsSinceEpoch - timestamp > 30 * 60 * 1000) {
      final newId = _generateSessionId();
      _localStorage.setJsonData(_sessionIdKey, {
        'id': newId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      return newId;
    }
    
    return existingId;
  }

  /// Track an event (only if analytics is enabled)
  Future<void> trackEvent({
    required String event,
    Map<String, dynamic>? properties,
  }) async {
    if (!isEnabled) return;

    try {
      final sessionId = _getSessionId();
      final analyticsData = _localStorage.getJsonData(_analyticsDataKey) ?? {};
      final events = List<Map<String, dynamic>>.from(analyticsData['events'] ?? []);

      final eventData = {
        'event': event,
        'timestamp': DateTime.now().toIso8601String(),
        'session_id': sessionId,
        'properties': properties ?? {},
      };

      events.add(eventData);

      // Keep only last 1000 events to prevent excessive storage
      if (events.length > 1000) {
        events.removeRange(0, events.length - 1000);
      }

      await _localStorage.setJsonData(_analyticsDataKey, {
        'events': events,
        'last_updated': DateTime.now().toIso8601String(),
      });

      debugPrint('Analytics: Tracked event "$event"');
    } catch (e) {
      debugPrint('Analytics error: $e');
    }
  }

  /// Track app launch
  Future<void> trackAppLaunch() async {
    await trackEvent(event: 'app_launch');
  }

  /// Track onboarding completion
  Future<void> trackOnboardingCompleted() async {
    await trackEvent(event: 'onboarding_completed');
  }

  /// Track plan generation
  Future<void> trackPlanGenerated({
    required String planningMode,
    required bool hasBudget,
    required int mealsPerDay,
  }) async {
    await trackEvent(
      event: 'plan_generated',
      properties: {
        'planning_mode': planningMode,
        'has_budget': hasBudget,
        'meals_per_day': mealsPerDay,
      },
    );
  }

  /// Track meal swap
  Future<void> trackMealSwapped({
    required String reason,
    required double costDelta,
    required double proteinDelta,
  }) async {
    await trackEvent(
      event: 'meal_swapped',
      properties: {
        'reason': reason,
        'cost_delta': costDelta,
        'protein_delta': proteinDelta,
      },
    );
  }

  /// Track shopping list export
  Future<void> trackShoppingListExported({
    required String format,
    required bool isPro,
  }) async {
    await trackEvent(
      event: 'shopping_list_exported',
      properties: {
        'format': format,
        'is_pro': isPro,
      },
    );
  }

  /// Track paywall viewed
  Future<void> trackPaywallViewed({
    String? trigger,
    String? highlightFeature,
  }) async {
    await trackEvent(
      event: 'paywall_viewed',
      properties: {
        'trigger': trigger,
        'highlight_feature': highlightFeature,
      },
    );
  }

  /// Track subscription purchase attempt
  Future<void> trackSubscriptionPurchaseAttempt({
    required String productId,
    required bool isAnnual,
  }) async {
    await trackEvent(
      event: 'subscription_purchase_attempt',
      properties: {
        'product_id': productId,
        'is_annual': isAnnual,
      },
    );
  }

  /// Track subscription purchase success
  Future<void> trackSubscriptionPurchaseSuccess({
    required String productId,
    required bool isAnnual,
    required bool wasTrial,
  }) async {
    await trackEvent(
      event: 'subscription_purchase_success',
      properties: {
        'product_id': productId,
        'is_annual': isAnnual,
        'was_trial': wasTrial,
      },
    );
  }

  /// Track trial started
  Future<void> trackTrialStarted() async {
    await trackEvent(event: 'trial_started');
  }

  /// Track Pro feature accessed
  Future<void> trackProFeatureAccessed({
    required String feature,
  }) async {
    await trackEvent(
      event: 'pro_feature_accessed',
      properties: {
        'feature': feature,
      },
    );
  }

  /// Track Pro feature blocked (user doesn't have Pro)
  Future<void> trackProFeatureBlocked({
    required String feature,
    required bool showedPaywall,
  }) async {
    await trackEvent(
      event: 'pro_feature_blocked',
      properties: {
        'feature': feature,
        'showed_paywall': showedPaywall,
      },
    );
  }

  /// Get analytics summary (aggregated, no PII)
  Map<String, dynamic> getAnalyticsSummary() {
    if (!isEnabled) return {};

    final analyticsData = _localStorage.getJsonData(_analyticsDataKey);
    if (analyticsData == null) return {};

    final events = List<Map<String, dynamic>>.from(analyticsData['events'] ?? []);
    
    // Aggregate events by type
    final eventCounts = <String, int>{};
    final eventsByDay = <String, int>{};
    
    for (final event in events) {
      final eventName = event['event'] as String;
      final timestamp = DateTime.tryParse(event['timestamp'] as String? ?? '');
      
      eventCounts[eventName] = (eventCounts[eventName] ?? 0) + 1;
      
      if (timestamp != null) {
        final day = timestamp.toString().substring(0, 10);
        eventsByDay[day] = (eventsByDay[day] ?? 0) + 1;
      }
    }

    return {
      'total_events': events.length,
      'event_counts': eventCounts,
      'events_by_day': eventsByDay,
      'last_updated': analyticsData['last_updated'],
    };
  }

  /// Clear all analytics data
  Future<void> clearAnalyticsData() async {
    await _localStorage.setJsonData(_analyticsDataKey, {});
    await _localStorage.setJsonData(_sessionIdKey, {});
    debugPrint('Analytics: Cleared all data');
  }

  /// Export analytics data for user review
  String exportAnalyticsData() {
    final analyticsData = _localStorage.getJsonData(_analyticsDataKey);
    if (analyticsData == null) return 'No analytics data found.';

    final prettyJson = const JsonEncoder.withIndent('  ').convert(analyticsData);
    return prettyJson;
  }

  /// Get data size in bytes (for user information)
  int getDataSize() {
    final analyticsData = _localStorage.getJsonData(_analyticsDataKey);
    if (analyticsData == null) return 0;

    final jsonString = jsonEncode(analyticsData);
    return utf8.encode(jsonString).length;
  }

  /// Enable analytics (user opt-in)
  Future<void> enableAnalytics() async {
    await _localStorage.setAnalyticsEnabled(true);
    await trackEvent(event: 'analytics_enabled');
  }

  /// Disable analytics (user opt-out)
  Future<void> disableAnalytics() async {
    await clearAnalyticsData();
    await _localStorage.setAnalyticsEnabled(false);
  }
}
