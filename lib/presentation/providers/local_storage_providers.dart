import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/local_storage_service.dart';
import 'database_providers.dart';

/// Provider for local storage service
final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalStorageService(prefs);
});

/// Provider for theme mode preference
final themeModePreferenceProvider = Provider<String>((ref) {
  final localStorage = ref.watch(localStorageServiceProvider);
  return localStorage.getThemeMode();
});

/// Provider for units system preference
final unitsSystemPreferenceProvider = Provider<String>((ref) {
  final localStorage = ref.watch(localStorageServiceProvider);
  return localStorage.getUnitsSystem();
});

/// Provider for currency preference
final currencyPreferenceProvider = Provider<String>((ref) {
  final localStorage = ref.watch(localStorageServiceProvider);
  return localStorage.getCurrency();
});

/// Provider for first launch detection
final isFirstLaunchProvider = Provider<bool>((ref) {
  final localStorage = ref.watch(localStorageServiceProvider);
  return localStorage.isFirstLaunch();
});

/// Provider for pro subscription status
final proSubscriptionStatusProvider = Provider<bool>((ref) {
  final localStorage = ref.watch(localStorageServiceProvider);
  return localStorage.getProSubscriptionStatus();
});

/// Provider for analytics enabled status
final analyticsEnabledProvider = Provider<bool>((ref) {
  final localStorage = ref.watch(localStorageServiceProvider);
  return localStorage.getAnalyticsEnabled();
});

/// Notifier for managing local storage preferences
class LocalStorageNotifier extends StateNotifier<AsyncValue<void>> {
  LocalStorageNotifier(this._localStorage) : super(const AsyncValue.data(null));

  final LocalStorageService _localStorage;

  Future<void> setThemeMode(String themeMode) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _localStorage.setThemeMode(themeMode));
  }

  Future<void> setUnitsSystem(String unitsSystem) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _localStorage.setUnitsSystem(unitsSystem));
  }

  Future<void> setCurrency(String currency) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _localStorage.setCurrency(currency));
  }

  Future<void> setFirstLaunch(bool isFirstLaunch) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _localStorage.setFirstLaunch(isFirstLaunch));
  }

  Future<void> setProSubscriptionStatus(bool isActive) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _localStorage.setProSubscriptionStatus(isActive));
  }

  Future<void> setAnalyticsEnabled(bool enabled) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _localStorage.setAnalyticsEnabled(enabled));
  }

  Future<void> setOnboardingCompleted(bool completed) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _localStorage.setOnboardingCompleted(completed));
  }

  Future<void> clearUserData() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _localStorage.clearUserData());
  }

  Future<void> clearAllData() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _localStorage.clearAllData());
  }

  Future<Map<String, dynamic>> exportUserPreferences() async {
    return _localStorage.exportUserPreferences();
  }

  Future<void> importUserPreferences(Map<String, dynamic> preferences) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _localStorage.importUserPreferences(preferences));
  }
}

/// Provider for local storage operations
final localStorageNotifierProvider = 
    StateNotifierProvider<LocalStorageNotifier, AsyncValue<void>>((ref) {
  final localStorage = ref.watch(localStorageServiceProvider);
  return LocalStorageNotifier(localStorage);
});
