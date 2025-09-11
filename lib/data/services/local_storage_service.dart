import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Service for managing local storage using SharedPreferences
class LocalStorageService {
  const LocalStorageService(this._prefs);

  final SharedPreferences _prefs;

  // Keys for storing various preferences
  static const String _currentTargetsIdKey = 'current_targets_id';
  static const String _currentPlanIdKey = 'current_plan_id';
  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _appThemeModeKey = 'app_theme_mode';
  static const String _unitsSystemKey = 'units_system';
  static const String _currencyKey = 'currency';
  static const String _firstLaunchKey = 'first_launch';
  static const String _lastSeedDataVersionKey = 'last_seed_data_version';
  static const String _proSubscriptionStatusKey = 'pro_subscription_status';
  static const String _analyticsEnabledKey = 'analytics_enabled';
  static const String _crashReportingEnabledKey = 'crash_reporting_enabled';
  static const String _trialInfoKey = 'trial_info';
  static const String _subscriptionInfoKey = 'subscription_info';

  // Current targets management
  Future<void> setCurrentTargetsId(String id) async {
    await _prefs.setString(_currentTargetsIdKey, id);
  }

  String? getCurrentTargetsId() {
    return _prefs.getString(_currentTargetsIdKey);
  }

  Future<void> clearCurrentTargetsId() async {
    await _prefs.remove(_currentTargetsIdKey);
  }

  // Current plan management
  Future<void> setCurrentPlanId(String id) async {
    await _prefs.setString(_currentPlanIdKey, id);
  }

  String? getCurrentPlanId() {
    return _prefs.getString(_currentPlanIdKey);
  }

  Future<void> clearCurrentPlanId() async {
    await _prefs.remove(_currentPlanIdKey);
  }

  // Onboarding status
  Future<void> setOnboardingCompleted(bool completed) async {
    await _prefs.setBool(_onboardingCompletedKey, completed);
  }

  bool getOnboardingCompleted() {
    return _prefs.getBool(_onboardingCompletedKey) ?? false;
  }

  // Theme preferences
  Future<void> setThemeMode(String themeMode) async {
    await _prefs.setString(_appThemeModeKey, themeMode);
  }

  String getThemeMode() {
    return _prefs.getString(_appThemeModeKey) ?? 'system';
  }

  // Units system (metric/imperial)
  Future<void> setUnitsSystem(String unitsSystem) async {
    await _prefs.setString(_unitsSystemKey, unitsSystem);
  }

  String getUnitsSystem() {
    return _prefs.getString(_unitsSystemKey) ?? 'metric';
  }

  // Currency preference
  Future<void> setCurrency(String currency) async {
    await _prefs.setString(_currencyKey, currency);
  }

  String getCurrency() {
    return _prefs.getString(_currencyKey) ?? 'USD';
  }

  // First launch detection
  Future<void> setFirstLaunch(bool isFirstLaunch) async {
    await _prefs.setBool(_firstLaunchKey, isFirstLaunch);
  }

  bool isFirstLaunch() {
    return _prefs.getBool(_firstLaunchKey) ?? true;
  }

  // Seed data version tracking
  Future<void> setLastSeedDataVersion(int version) async {
    await _prefs.setInt(_lastSeedDataVersionKey, version);
  }

  int getLastSeedDataVersion() {
    return _prefs.getInt(_lastSeedDataVersionKey) ?? 0;
  }

  // Pro subscription status
  Future<void> setProSubscriptionStatus(bool isActive) async {
    await _prefs.setBool(_proSubscriptionStatusKey, isActive);
  }

  bool getProSubscriptionStatus() {
    return _prefs.getBool(_proSubscriptionStatusKey) ?? false;
  }

  // Analytics preference
  Future<void> setAnalyticsEnabled(bool enabled) async {
    await _prefs.setBool(_analyticsEnabledKey, enabled);
  }

  bool getAnalyticsEnabled() {
    return _prefs.getBool(_analyticsEnabledKey) ?? false; // Opt-in by default
  }

  // Crash reporting preference
  Future<void> setCrashReportingEnabled(bool enabled) async {
    await _prefs.setBool(_crashReportingEnabledKey, enabled);
  }

  bool getCrashReportingEnabled() {
    return _prefs.getBool(_crashReportingEnabledKey) ?? false; // Opt-in by default
  }

  // Trial information management
  Future<void> setTrialInfo(Map<String, dynamic> trialInfo) async {
    await setJsonData(_trialInfoKey, trialInfo);
  }

  Map<String, dynamic>? getTrialInfo() {
    return getJsonData(_trialInfoKey);
  }

  Future<void> startTrial() async {
    final trialInfo = {
      'started_at': DateTime.now().toIso8601String(),
      'used': true,
      'active': true,
    };
    await setTrialInfo(trialInfo);
    await setProSubscriptionStatus(true);
  }

  bool isTrialActive() {
    final trialInfo = getTrialInfo();
    if (trialInfo == null || trialInfo['active'] != true) return false;

    final startedAt = DateTime.tryParse(trialInfo['started_at'] ?? '');
    if (startedAt == null) return false;

    final trialEndDate = startedAt.add(const Duration(days: 7));
    return DateTime.now().isBefore(trialEndDate);
  }

  bool hasTrialBeenUsed() {
    final trialInfo = getTrialInfo();
    return trialInfo?['used'] == true;
  }

  Future<void> endTrial() async {
    final trialInfo = getTrialInfo() ?? {};
    trialInfo['active'] = false;
    trialInfo['ended_at'] = DateTime.now().toIso8601String();
    await setTrialInfo(trialInfo);
    
    // Only set Pro status to false if no active subscription
    final subscriptionInfo = getSubscriptionInfo();
    if (subscriptionInfo == null || subscriptionInfo['active'] != true) {
      await setProSubscriptionStatus(false);
    }
  }

  // Subscription information management
  Future<void> setSubscriptionInfo(Map<String, dynamic> subscriptionInfo) async {
    await setJsonData(_subscriptionInfoKey, subscriptionInfo);
  }

  Map<String, dynamic>? getSubscriptionInfo() {
    return getJsonData(_subscriptionInfoKey);
  }

  Future<void> clearSubscriptionInfo() async {
    await _prefs.remove(_subscriptionInfoKey);
    await setProSubscriptionStatus(false);
  }

  // Generic JSON storage for complex objects
  Future<void> setJsonData(String key, Map<String, dynamic> data) async {
    final jsonString = jsonEncode(data);
    await _prefs.setString(key, jsonString);
  }

  Map<String, dynamic>? getJsonData(String key) {
    final jsonString = _prefs.getString(key);
    if (jsonString == null) return null;
    
    try {
      return jsonDecode(jsonString);
    } catch (e) {
      return null;
    }
  }

  // Generic list storage
  Future<void> setStringList(String key, List<String> list) async {
    await _prefs.setStringList(key, list);
  }

  List<String> getStringList(String key) {
    return _prefs.getStringList(key) ?? [];
  }

  // Clear all data (for logout/reset)
  Future<void> clearAllData() async {
    await _prefs.clear();
  }

  // Clear specific data categories
  Future<void> clearUserData() async {
    await _prefs.remove(_currentTargetsIdKey);
    await _prefs.remove(_currentPlanIdKey);
    await _prefs.remove(_onboardingCompletedKey);
    await _prefs.remove(_proSubscriptionStatusKey);
  }

  // Export user preferences for backup
  Map<String, dynamic> exportUserPreferences() {
    return {
      'theme_mode': getThemeMode(),
      'units_system': getUnitsSystem(),
      'currency': getCurrency(),
      'analytics_enabled': getAnalyticsEnabled(),
      'crash_reporting_enabled': getCrashReportingEnabled(),
      'onboarding_completed': getOnboardingCompleted(),
      'pro_subscription_status': getProSubscriptionStatus(),
    };
  }

  // Import user preferences from backup
  Future<void> importUserPreferences(Map<String, dynamic> preferences) async {
    if (preferences.containsKey('theme_mode')) {
      await setThemeMode(preferences['theme_mode']);
    }
    if (preferences.containsKey('units_system')) {
      await setUnitsSystem(preferences['units_system']);
    }
    if (preferences.containsKey('currency')) {
      await setCurrency(preferences['currency']);
    }
    if (preferences.containsKey('analytics_enabled')) {
      await setAnalyticsEnabled(preferences['analytics_enabled']);
    }
    if (preferences.containsKey('crash_reporting_enabled')) {
      await setCrashReportingEnabled(preferences['crash_reporting_enabled']);
    }
    if (preferences.containsKey('onboarding_completed')) {
      await setOnboardingCompleted(preferences['onboarding_completed']);
    }
    if (preferences.containsKey('pro_subscription_status')) {
      await setProSubscriptionStatus(preferences['pro_subscription_status']);
    }
  }

  // Check if key exists
  bool hasKey(String key) {
    return _prefs.containsKey(key);
  }

  // Get all keys
  Set<String> getAllKeys() {
    return _prefs.getKeys();
  }
}
