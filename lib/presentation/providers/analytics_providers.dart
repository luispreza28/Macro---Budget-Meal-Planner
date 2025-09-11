import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/analytics_service.dart';
import 'local_storage_providers.dart';

/// Provider for analytics service
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final localStorage = ref.watch(localStorageServiceProvider);
  return AnalyticsService(localStorage);
});

/// Provider for analytics enabled status
final analyticsEnabledProvider = Provider<bool>((ref) {
  final analyticsService = ref.watch(analyticsServiceProvider);
  return analyticsService.isEnabled;
});

/// Provider for analytics summary
final analyticsSummaryProvider = Provider<Map<String, dynamic>>((ref) {
  final analyticsService = ref.watch(analyticsServiceProvider);
  return analyticsService.getAnalyticsSummary();
});

/// Provider for analytics data size
final analyticsDataSizeProvider = Provider<int>((ref) {
  final analyticsService = ref.watch(analyticsServiceProvider);
  return analyticsService.getDataSize();
});

/// Notifier for managing analytics operations
class AnalyticsNotifier extends StateNotifier<AsyncValue<void>> {
  AnalyticsNotifier(this._analyticsService) : super(const AsyncValue.data(null));

  final AnalyticsService _analyticsService;

  Future<void> enableAnalytics() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _analyticsService.enableAnalytics());
  }

  Future<void> disableAnalytics() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _analyticsService.disableAnalytics());
  }

  Future<void> clearAnalyticsData() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _analyticsService.clearAnalyticsData());
  }

  Future<void> trackEvent({
    required String event,
    Map<String, dynamic>? properties,
  }) async {
    // Don't show loading state for tracking events
    await _analyticsService.trackEvent(
      event: event,
      properties: properties,
    );
  }

  // Convenience methods for common events

  Future<void> trackAppLaunch() async {
    await _analyticsService.trackAppLaunch();
  }

  Future<void> trackOnboardingCompleted() async {
    await _analyticsService.trackOnboardingCompleted();
  }

  Future<void> trackPlanGenerated({
    required String planningMode,
    required bool hasBudget,
    required int mealsPerDay,
  }) async {
    await _analyticsService.trackPlanGenerated(
      planningMode: planningMode,
      hasBudget: hasBudget,
      mealsPerDay: mealsPerDay,
    );
  }

  Future<void> trackMealSwapped({
    required String reason,
    required double costDelta,
    required double proteinDelta,
  }) async {
    await _analyticsService.trackMealSwapped(
      reason: reason,
      costDelta: costDelta,
      proteinDelta: proteinDelta,
    );
  }

  Future<void> trackShoppingListExported({
    required String format,
    required bool isPro,
  }) async {
    await _analyticsService.trackShoppingListExported(
      format: format,
      isPro: isPro,
    );
  }

  Future<void> trackPaywallViewed({
    String? trigger,
    String? highlightFeature,
  }) async {
    await _analyticsService.trackPaywallViewed(
      trigger: trigger,
      highlightFeature: highlightFeature,
    );
  }

  Future<void> trackSubscriptionPurchaseAttempt({
    required String productId,
    required bool isAnnual,
  }) async {
    await _analyticsService.trackSubscriptionPurchaseAttempt(
      productId: productId,
      isAnnual: isAnnual,
    );
  }

  Future<void> trackSubscriptionPurchaseSuccess({
    required String productId,
    required bool isAnnual,
    required bool wasTrial,
  }) async {
    await _analyticsService.trackSubscriptionPurchaseSuccess(
      productId: productId,
      isAnnual: isAnnual,
      wasTrial: wasTrial,
    );
  }

  Future<void> trackTrialStarted() async {
    await _analyticsService.trackTrialStarted();
  }

  Future<void> trackProFeatureAccessed({
    required String feature,
  }) async {
    await _analyticsService.trackProFeatureAccessed(feature: feature);
  }

  Future<void> trackProFeatureBlocked({
    required String feature,
    required bool showedPaywall,
  }) async {
    await _analyticsService.trackProFeatureBlocked(
      feature: feature,
      showedPaywall: showedPaywall,
    );
  }

  String exportAnalyticsData() {
    return _analyticsService.exportAnalyticsData();
  }
}

/// Provider for analytics notifier
final analyticsNotifierProvider = StateNotifierProvider<AnalyticsNotifier, AsyncValue<void>>((ref) {
  final analyticsService = ref.watch(analyticsServiceProvider);
  return AnalyticsNotifier(analyticsService);
});
